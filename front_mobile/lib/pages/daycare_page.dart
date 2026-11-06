import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/aviso.dart';
import '../components/barra_voltar.dart';
import '../components/campo_data.dart';
import '../components/campo_form.dart';
import '../components/chip_opcao.dart';
import '../components/seletor_pet.dart';
import '../components/tabela_precos_daycare.dart';
import '../models/daycare.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/daycare_service.dart';
import '../services/pets_service.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';

// Formulário do Daycare, o mesmo fluxo de front/src/pages/Daycare.jsx:
// plano avulso (um dia, com consulta de vagas) ou plano recorrente
// (frequência, dias da semana e data de início).
class DaycarePage extends StatefulWidget {
  const DaycarePage({super.key});

  @override
  State<DaycarePage> createState() => _DaycarePageState();
}

class _DaycarePageState extends State<DaycarePage> {
  final _observacoes = TextEditingController();

  List<Pet> _pets = [];
  bool _carregandoPets = true;
  String? _erroPets;

  int? _petId;
  String? _plano;
  String? _frequencia;
  final List<int> _dias = [];
  DateTime? _dataInicio;
  DateTime? _dataAvulso;

  VagasDaycare? _vagas;
  bool _verificandoVagas = false;

  bool _enviando = false;
  String? _erro;
  String? _sucesso;
  bool _mostrarAvisoPrecos = true;
  Timer? _voltarAposSucesso;

  int get _maxDias => maxDiasDaFrequencia(_frequencia);
  bool get _avulso => _plano == planoAvulso;

  @override
  void initState() {
    super.initState();
    _carregarPets();
  }

  @override
  void dispose() {
    _voltarAposSucesso?.cancel();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _carregarPets() async {
    final token = sessao.token;
    if (token == null) {
      setState(() => _carregandoPets = false);
      return;
    }
    try {
      final pets = await apiGetPets(token);
      if (!mounted) return;
      setState(() => _pets = pets);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erroPets = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregandoPets = false);
    }
  }

  // Trocar de plano zera o resto, como no site.
  void _escolherPlano(String plano) {
    setState(() {
      _plano = plano;
      _frequencia = null;
      _dias.clear();
      _dataInicio = null;
      _dataAvulso = null;
      _vagas = null;
      _verificandoVagas = false;
    });
  }

  void _escolherFrequencia(String frequencia) {
    setState(() {
      _frequencia = frequencia;
      _dias.clear();
    });
  }

  // Desmarcar sempre pode; marcar só até o limite da frequência.
  void _alternarDia(int dia) {
    setState(() {
      if (_dias.contains(dia)) {
        _dias.remove(dia);
      } else if (_dias.length < _maxDias) {
        _dias.add(dia);
      }
    });
  }

  Future<void> _escolherDataAvulso(DateTime data) async {
    setState(() {
      _dataAvulso = data;
      _vagas = null;
      _verificandoVagas = true;
    });
    final token = sessao.token;
    VagasDaycare? vagas;
    try {
      if (token != null) vagas = await apiVerificarVagas(token, dataIso(data));
    } on ApiException {
      // Igual ao site: sem a resposta, só não mostra a contagem de vagas.
    }
    // Se o tutor trocou a data ou o plano enquanto esperava, ignora.
    if (!mounted || _dataAvulso != data) return;
    setState(() {
      _vagas = vagas;
      _verificandoVagas = false;
    });
  }

  String? _validar() {
    if (_petId == null) return 'Selecione o pet.';
    if (_plano == null) return 'Selecione um plano.';
    if (_avulso) {
      if (_dataAvulso == null) return 'Informe a data do dia avulso.';
    } else {
      if (_frequencia == null) return 'Selecione a frequência.';
      if (_dias.isEmpty) return 'Selecione os dias da semana.';
      if (_dias.length != _maxDias) {
        return 'Selecione exatamente $_maxDias dia(s) conforme a frequência escolhida.';
      }
      if (_dataInicio == null) return 'Informe a data de início.';
    }
    final vagas = _vagas;
    if (vagas != null && !vagas.disponivel) {
      return 'Não há vagas disponíveis nesta data.';
    }
    return null;
  }

  Future<void> _confirmar() async {
    final erro = _validar();
    final token = sessao.token;
    if (erro != null || token == null) {
      setState(() => _erro = erro ?? 'Faça login para concluir o agendamento.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await apiCriarAgendamentoDaycare(
        token,
        petId: _petId!,
        plano: _plano!,
        frequencia: _frequencia,
        diasSemana: [..._dias]..sort(),
        dataInicio: _avulso ? null : dataIso(_dataInicio!),
        dataAvulso: _avulso ? dataIso(_dataAvulso!) : null,
        observacoes: _observacoes.text.trim(),
        valorTotal: precoDaycare(_plano, _frequencia),
      );
      if (!mounted) return;
      setState(
        () => _sucesso = 'Agendamento de Daycare criado com sucesso! 🎉',
      );
      // Volta para a aba Serviços, como o site faz depois de 2 segundos.
      _voltarAposSucesso = Timer(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).popUntil((rota) => rota.isFirst);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _verPrecos() async {
    setState(() => _mostrarAvisoPrecos = false);
    await TabelaPrecosDaycare.abrir(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: const BarraVoltar('Daycare'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mostrarAvisoPrecos) ...[
                _avisoPrecos(),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Cores.border),
                ),
                child: _formulario(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    final valor = precoDaycare(_plano, _frequencia);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(),
        _secao(
          'Qual pet vai frequentar o Daycare?',
          SeletorPet(
            pets: _pets,
            selecionadoId: _petId,
            carregando: _carregandoPets,
            erro: _erroPets,
            onSelecionar: (pet) => setState(() => _petId = pet.id),
            onCadastrado: (pet) => setState(() {
              _pets = [..._pets, pet];
              _petId = pet.id;
            }),
          ),
        ),
        _secao(
          'Plano',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final plano in planosDaycare)
                ChipOpcao(
                  texto: plano.label,
                  selecionado: _plano == plano.id,
                  onTap: () => _escolherPlano(plano.id),
                ),
            ],
          ),
        ),
        if (_avulso)
          _secao(
            'Data',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CampoData(valor: _dataAvulso, onEscolher: _escolherDataAvulso),
                _textoVagas(),
              ],
            ),
          ),
        if (_plano != null && !_avulso) ..._camposRecorrentes(),
        if (valor != null) _resumoValor(valor),
        CampoForm(
          controller: _observacoes,
          rotulo: 'Observações (opcional)',
          dica: 'Alguma instrução especial?',
          linhas: 3,
          limite: 1000,
          obrigatorio: false,
        ),
        const SizedBox(height: 6),
        if (_erro != null) Aviso.erro(_erro!),
        if (_sucesso != null) Aviso.sucesso(_sucesso!),
        OutlinedButton(
          onPressed: _verPrecos,
          style: OutlinedButton.styleFrom(
            foregroundColor: Cores.forest,
            side: const BorderSide(color: Cores.forest),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            '📋 Ver tabela de preços',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _enviando || _sucesso != null ? null : _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: Cores.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            _enviando ? 'Confirmando...' : '🗓 Confirmar agendamento',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _camposRecorrentes() {
    final marcados = _dias.length;
    final completo = marcados == _maxDias;
    return [
      _secao(
        'Frequência semanal',
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final frequencia in frequenciasDaycare)
              ChipOpcao(
                texto: frequencia,
                selecionado: _frequencia == frequencia,
                onTap: () => _escolherFrequencia(frequencia),
              ),
          ],
        ),
      ),
      if (_frequencia != null)
        _secao(
          'Dias da semana — selecione $_maxDias dia${_maxDias > 1 ? 's' : ''}',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final dia in diasSemanaDaycare)
                    ChipOpcao(
                      texto: dia.label,
                      selecionado: _dias.contains(dia.valor),
                      // Com o limite atingido, só os dias marcados respondem.
                      onTap: _dias.contains(dia.valor) || !completo
                          ? () => _alternarDia(dia.valor)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$marcados/$_maxDias dia${_maxDias > 1 ? 's' : ''} '
                'selecionado${marcados != 1 ? 's' : ''}${completo ? ' ✅' : ''}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: completo ? const Color(0xFF2E7D4F) : Cores.muted,
                ),
              ),
            ],
          ),
        ),
      _secao(
        'Data de início',
        CampoData(
          valor: _dataInicio,
          onEscolher: (data) => setState(() => _dataInicio = data),
        ),
      ),
    ];
  }

  Widget _avisoPrecos() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.sand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Cores.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Deseja ver a tabela de preços do Daycare?',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Cores.forest,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _verPrecos,
                style: FilledButton.styleFrom(
                  backgroundColor: Cores.forest,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ver preços'),
              ),
              TextButton(
                onPressed: () => setState(() => _mostrarAvisoPrecos = false),
                style: TextButton.styleFrom(foregroundColor: Cores.muted),
                child: const Text('Agora não'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Cores.forest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Daycare 🏡',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Cores.forest,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Confirmar agendamento de Daycare',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Cores.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Olá, ${sessao.usuario?.nome ?? 'Tutor'}! Escolha o plano ideal para o seu pet.',
            style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
          ),
        ],
      ),
    );
  }

  Widget _textoVagas() {
    final vagas = _vagas;
    final String texto;
    final Color cor;
    if (_verificandoVagas) {
      texto = 'Verificando vagas...';
      cor = Cores.muted;
    } else if (vagas == null) {
      return const SizedBox.shrink();
    } else if (vagas.disponivel) {
      texto = '✅ ${vagas.livres} vaga(s) disponível(eis)';
      cor = const Color(0xFF2E7D4F);
    } else {
      texto = '❌ Lotado — sem vagas nesta data';
      cor = const Color(0xFFB3261E);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        texto,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

  Widget _resumoValor(double valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Cores.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.bark.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '💰 Valor estimado:',
              style: GoogleFonts.dmSans(fontSize: 14, color: Cores.forest),
            ),
          ),
          Text(
            formatarReais(valor),
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Cores.forest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(String titulo, Widget conteudo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Cores.forest,
            ),
          ),
          const SizedBox(height: 10),
          conteudo,
        ],
      ),
    );
  }
}
