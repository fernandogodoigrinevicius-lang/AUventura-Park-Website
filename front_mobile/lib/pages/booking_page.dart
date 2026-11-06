import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/aviso.dart';
import '../components/barra_voltar.dart';
import '../components/campo_data.dart';
import '../components/campo_form.dart';
import '../components/seletor_horario.dart';
import '../components/seletor_pet.dart';
import '../models/pet.dart';
import '../models/servico_info.dart';
import '../services/agendamentos_service.dart';
import '../services/api_client.dart';
import '../services/pets_service.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';

// Agendamento de banho, tosa, banho e tosa ou adestramento: pet, data,
// horário livre e observações. O Daycare tem a tela dele (daycare_page.dart).
class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.servico});

  final ServicoInfo servico;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _observacoes = TextEditingController();

  List<Pet> _pets = [];
  bool _carregandoPets = true;
  String? _erroPets;
  Pet? _pet;

  DateTime? _data;
  String? _horario;
  List<String> _ocupados = [];
  bool _buscandoHorarios = false;

  bool _enviando = false;
  String? _erro;
  String? _sucesso;
  Timer? _voltarAposSucesso;

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

  // Os pets vêm do back sempre que a tela abre: o tutor pode ter cadastrado
  // ou removido algum na aba My Pet.
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

  Future<void> _escolherData(DateTime data) async {
    setState(() {
      _data = data;
      _horario = null;
      _buscandoHorarios = true;
    });

    List<String> ocupados = [];
    try {
      ocupados = await apiGetHorariosOcupados(
        data: dataIso(data),
        servico: widget.servico.id,
      );
    } catch (_) {
      // Igual ao site: sem a resposta, mostra todos os horários livres.
    }
    // Se o tutor trocou a data enquanto esperava, vale só a última.
    if (!mounted || _data != data) return;
    setState(() {
      _ocupados = ocupados;
      _buscandoHorarios = false;
    });
  }

  Future<void> _confirmar() async {
    final token = sessao.token;
    final pet = _pet;
    final data = _data;
    final horario = _horario;
    String? erro;
    if (token == null) {
      erro = 'Faça login para concluir o agendamento.';
    } else if (pet == null) {
      erro = 'Por favor, selecione ou cadastre um pet.';
    } else if (data == null) {
      erro = 'Por favor, escolha a data do agendamento.';
    } else if (horario == null) {
      erro = 'Por favor, selecione um horário disponível.';
    }
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await apiCreateAgendamento(
        token!,
        nomeCachorro: pet!.nome,
        servico: widget.servico.id,
        data: dataIso(data!),
        horario: horario!,
        observacoes: _observacoes.text.trim(),
      );
      if (!mounted) return;
      setState(() => _sucesso = 'Agendamento criado com sucesso!');
      // Volta para a aba Serviços, que recarrega "Meus Agendamentos".
      _voltarAposSucesso = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) Navigator.of(context).popUntil((rota) => rota.isFirst);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: const BarraVoltar('Agendamento'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Cores.border),
            ),
            child: _formulario(),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    final servico = widget.servico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(),
        _titulo('1. Qual pet vai ser atendido?'),
        SeletorPet(
          pets: _pets,
          selecionadoId: _pet?.id,
          carregando: _carregandoPets,
          erro: _erroPets,
          onSelecionar: (pet) => setState(() => _pet = pet),
          onCadastrado: (pet) => setState(() {
            _pets = [..._pets, pet];
            _pet = pet;
          }),
        ),
        _divisor(),
        _titulo('2. Escolha a data'),
        CampoData(valor: _data, onEscolher: _escolherData),
        _divisor(),
        _titulo('3. Escolha o horário disponível'),
        SeletorHorario(
          horarios: _data != null ? servico.gerarSlots() : [],
          selecionado: _horario,
          ocupados: _ocupados,
          carregando: _buscandoHorarios,
          onSelecionar: (horario) => setState(() => _horario = horario),
        ),
        _divisor(),
        _titulo('4. Observações adicionais (opcional)'),
        CampoForm(
          controller: _observacoes,
          rotulo: 'Observações',
          dica: 'Alguma recomendação de alergia, comportamento, etc.?',
          linhas: 3,
          limite: 1000,
          obrigatorio: false,
        ),
        const SizedBox(height: 14),
        // O aviso fica junto do botão: no celular o topo do formulário já
        // saiu da tela quando o tutor confirma.
        if (_erro != null) Aviso.erro(_erro!),
        if (_sucesso != null) Aviso.sucesso(_sucesso!),
        FilledButton.icon(
          onPressed: _enviando || _sucesso != null ? null : _confirmar,
          icon: _enviando
              ? const SizedBox.shrink()
              : const Icon(Icons.check_circle_outline),
          label: _enviando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Confirmar Agendamento',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          style: FilledButton.styleFrom(
            backgroundColor: Cores.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cabecalho() {
    final servico = widget.servico;
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
              '${servico.emoji} ${servico.label}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Cores.forest,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Confirmar agendamento',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Cores.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Olá, ${sessao.usuario?.nome ?? 'Tutor'}! Escolha o pet e o melhor horário.',
            style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Cores.forest,
        ),
      ),
    );
  }

  Widget _divisor() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Divider(color: Cores.border),
    );
  }
}
