import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/aviso.dart';
import '../components/card_agendamento.dart';
import '../components/dialog_cadastrar_pet.dart';
import '../components/header_auventura.dart';
import '../components/selo.dart';
import '../components/time_slot_picker.dart';
import '../models/agendamento.dart';
import '../models/pet.dart';
import '../models/servico_info.dart';
import '../services/agendamentos_service.dart';
import '../services/api_client.dart';
import '../services/pets_service.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';
import 'login_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

enum _Visao { catalogo, detalhes, formAgendamento }

class _ServicesPageState extends State<ServicesPage> {
  _Visao _visaoAtual = _Visao.catalogo;
  ServicoInfo? _servicoSelecionado;

  List<Agendamento> _meusAgendamentos = [];
  List<Pet> _meusPets = [];
  bool _carregandoAgendamentos = false;
  String? _erroAgendamentos;

  // Estado do formulário de agendamento
  Pet? _petEscolhido;
  DateTime? _dataEscolhida;
  String? _horarioEscolhido;
  final _observacoesController = TextEditingController();
  List<String> _horariosOcupados = [];
  bool _buscandoSlots = false;
  bool _enviandoAgendamento = false;
  String? _erroForm;
  String? _sucessoForm;

  @override
  void initState() {
    super.initState();
    sessao.addListener(_aoMudarSessao);
    if (sessao.logado) {
      _carregarDadosUsuario();
    }
  }

  @override
  void dispose() {
    sessao.removeListener(_aoMudarSessao);
    _observacoesController.dispose();
    super.dispose();
  }

  void _aoMudarSessao() {
    if (sessao.logado) {
      _carregarDadosUsuario();
    } else {
      setState(() {
        _meusAgendamentos = [];
        _meusPets = [];
        _petEscolhido = null;
      });
    }
  }

  Future<void> _carregarDadosUsuario() async {
    final token = sessao.token;
    if (token == null) return;

    setState(() {
      _carregandoAgendamentos = true;
      _erroAgendamentos = null;
    });

    try {
      final futures = await Future.wait([
        apiGetAgendamentos(token),
        apiGetPets(token),
      ]);
      if (!mounted) return;
      setState(() {
        _meusAgendamentos = futures[0] as List<Agendamento>;
        _meusPets = futures[1] as List<Pet>;
        if (_petEscolhido == null && _meusPets.isNotEmpty) {
          _petEscolhido = _meusPets.first;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erroAgendamentos = e.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroAgendamentos = 'Não foi possível carregar os dados.');
    } finally {
      if (mounted) setState(() => _carregandoAgendamentos = false);
    }
  }

  Future<void> _abrirDetalhes(ServicoInfo servico) async {
    setState(() {
      _servicoSelecionado = servico;
      _visaoAtual = _Visao.detalhes;
    });
  }

  Future<void> _iniciarAgendamento(ServicoInfo servico) async {
    if (!sessao.logado) {
      final logou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      if (logou != true && !sessao.logado) return;
      await _carregarDadosUsuario();
    }

    setState(() {
      _servicoSelecionado = servico;
      _visaoAtual = _Visao.formAgendamento;
      _dataEscolhida = null;
      _horarioEscolhido = null;
      _observacoesController.clear();
      _erroForm = null;
      _sucessoForm = null;
      _horariosOcupados = [];
      if (_meusPets.isNotEmpty && _petEscolhido == null) {
        _petEscolhido = _meusPets.first;
      }
    });
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final limite = hoje.add(const Duration(days: 90));

    final data = await showDatePicker(
      context: context,
      initialDate: _dataEscolhida ?? hoje,
      firstDate: hoje,
      lastDate: limite,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Cores.forest,
              onPrimary: Colors.white,
              onSurface: Cores.forest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data == null) return;

    setState(() {
      _dataEscolhida = data;
      _horarioEscolhido = null;
    });

    await _buscarSlotsOcupados(data);
  }

  Future<void> _buscarSlotsOcupados(DateTime data) async {
    final servico = _servicoSelecionado;
    if (servico == null || !servico.temSlots) return;

    final dataStr =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    setState(() {
      _buscandoSlots = true;
    });

    try {
      final ocupados = await apiGetHorariosOcupados(
        data: dataStr,
        servico: servico.id,
      );
      if (!mounted) return;
      setState(() => _horariosOcupados = ocupados);
    } catch (_) {
      if (!mounted) return;
      setState(() => _horariosOcupados = []);
    } finally {
      if (mounted) setState(() => _buscandoSlots = false);
    }
  }

  Future<void> _cadastrarNovoPetInline() async {
    final novoPet = await ModalCadastrarPet.show(context);
    if (novoPet != null && mounted) {
      setState(() {
        _meusPets.add(novoPet);
        _petEscolhido = novoPet;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${novoPet.nome} cadastrado com sucesso!'),
          backgroundColor: Cores.forest,
        ),
      );
    }
  }

  Future<void> _confirmarAgendamento() async {
    final token = sessao.token;
    if (token == null) {
      setState(() => _erroForm = 'Faça login para concluir o agendamento.');
      return;
    }
    if (_petEscolhido == null) {
      setState(() => _erroForm = 'Por favor, selecione ou cadastre um pet.');
      return;
    }
    if (_dataEscolhida == null) {
      setState(() => _erroForm = 'Por favor, escolha a data do agendamento.');
      return;
    }
    if (_servicoSelecionado?.temSlots == true && (_horarioEscolhido == null || _horarioEscolhido!.isEmpty)) {
      setState(() => _erroForm = 'Por favor, selecione um horário disponível.');
      return;
    }

    final servico = _servicoSelecionado!;
    final data = _dataEscolhida!;
    final dataStr =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    final horarioStr = servico.temSlots ? _horarioEscolhido! : '08:00';

    setState(() {
      _enviandoAgendamento = true;
      _erroForm = null;
      _sucessoForm = null;
    });

    try {
      await apiCreateAgendamento(
        token,
        nomeCachorro: _petEscolhido!.nome,
        servico: servico.id,
        data: dataStr,
        horario: horarioStr,
        observacoes: _observacoesController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _sucessoForm = 'Agendamento criado com sucesso!';
      });

      await _carregarDadosUsuario();

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _visaoAtual = _Visao.catalogo;
          _sucessoForm = null;
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erroForm = e.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroForm = 'Não foi possível concluir o agendamento.');
    } finally {
      if (mounted) setState(() => _enviandoAgendamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: const HeaderAuventura(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _construirConteudo(),
        ),
      ),
    );
  }

  Widget _construirConteudo() {
    switch (_visaoAtual) {
      case _Visao.catalogo:
        return _telaCatalogo();
      case _Visao.detalhes:
        return _telaDetalhes();
      case _Visao.formAgendamento:
        return _telaFormulario();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TELA CATÁLOGO & MEUS AGENDAMENTOS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _telaCatalogo() {
    return RefreshIndicator(
      color: Cores.bark,
      backgroundColor: Colors.white,
      onRefresh: () async {
        if (sessao.logado) await _carregarDadosUsuario();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroSection(),
            const SizedBox(height: 28),
            _catalogoServicos(),
            const SizedBox(height: 36),
            _secaoMeusAgendamentos(),
          ],
        ),
      ),
    );
  }

  Widget _heroSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Cores.forest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Selo('Nossos Serviços'),
          const SizedBox(height: 14),
          Text(
            'O que podemos fazer pelo seu pet?',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuidado profissional com muito amor, carinho e infraestrutura de ponta. Escolha um serviço para ver detalhes e agendar.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogoServicos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Serviços Disponíveis',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Cores.forest,
              ),
            ),
            Text(
              '${servicosDisponiveis.length} opções',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Cores.bark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...servicosDisponiveis.map((servico) => _cardServicoCatalogo(servico)),
      ],
    );
  }

  Widget _cardServicoCatalogo(ServicoInfo servico) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Cores.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirDetalhes(servico),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      servico.imagemAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Cores.sand,
                          child: Center(
                            child: Text(
                              servico.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(servico.emoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(
                              servico.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Cores.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servico.label,
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Cores.forest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      servico.resumo,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.4,
                        color: Cores.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ver detalhes →',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Cores.bark,
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _iniciarAgendamento(servico),
                          style: FilledButton.styleFrom(
                            backgroundColor: Cores.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '🗓 Agendar',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secaoMeusAgendamentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Meus Agendamentos',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Cores.forest,
                ),
              ),
            ),
            if (sessao.logado && _meusAgendamentos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Cores.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_meusAgendamentos.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Cores.forest,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (!sessao.logado) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Cores.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: Cores.bark,
                ),
                const SizedBox(height: 10),
                Text(
                  'Acesse sua conta para ver seus agendamentos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Faça login para acompanhar horários marcados ou agendar serviços para o seu pet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Cores.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Entrar / Criar Conta'),
                ),
              ],
            ),
          ),
        ] else if (_carregandoAgendamentos) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Cores.bark),
            ),
          ),
        ] else if (_erroAgendamentos != null) ...[
          Aviso.erro(_erroAgendamentos!),
        ] else if (_meusAgendamentos.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Cores.border),
            ),
            child: Column(
              children: [
                const Text('🐾', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 10),
                Text(
                  'Nenhum agendamento ativo',
                  style: GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seus próximos agendamentos de banho, tosa ou adestramento aparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
                ),
              ],
            ),
          ),
        ] else ...[
          ..._meusAgendamentos.map((a) => CardAgendamento(agendamento: a)),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. TELA DETALHES DO SERVIÇO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _telaDetalhes() {
    final servico = _servicoSelecionado;
    if (servico == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _visaoAtual = _Visao.catalogo),
                icon: const Icon(Icons.arrow_back, size: 18, color: Cores.forest),
                label: Text(
                  'Voltar aos serviços',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Cores.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        servico.imagemAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Cores.sand,
                            child: Center(
                              child: Text(
                                servico.emoji,
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${servico.emoji} ${servico.label}',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Cores.forest,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servico.resumo,
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Cores.forest,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        servico.descricao,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.6,
                          color: Cores.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Cores.cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _itemBeneficio('✨', 'Profissionais capacitados e carinhosos'),
                            const SizedBox(height: 8),
                            _itemBeneficio('🌿', 'Produtos hipoalergênicos e seguros'),
                            const SizedBox(height: 8),
                            _itemBeneficio('🐾', 'Ambiente monitorado e climatizado'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _iniciarAgendamento(servico),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          '🗓 Agendar já',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Cores.bark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      if (!sessao.logado) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Você precisará fazer login para confirmar o agendamento.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Cores.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemBeneficio(String icone, String texto) {
    return Row(
      children: [
        Text(icone, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Cores.forest,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. TELA FORMULÁRIO DE AGENDAMENTO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _telaFormulario() {
    final servico = _servicoSelecionado;
    if (servico == null) return const SizedBox.shrink();

    final dataFormatadaStr = _dataEscolhida != null
        ? '${_dataEscolhida!.day.toString().padLeft(2, '0')}/${_dataEscolhida!.month.toString().padLeft(2, '0')}/${_dataEscolhida!.year}'
        : 'Selecionar data';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _visaoAtual = _Visao.detalhes),
                icon: const Icon(Icons.arrow_back, size: 18, color: Cores.forest),
                label: Text(
                  'Voltar ao serviço',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Cores.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                  ],
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
                const SizedBox(height: 18),
                if (_erroForm != null) Aviso.erro(_erroForm!),
                if (_sucessoForm != null) Aviso.sucesso(_sucessoForm!),

                // 1. ESCOLHA DO PET
                Text(
                  '1. Qual pet vai ser atendido?',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._meusPets.map((pet) {
                      final ativo = _petEscolhido?.id == pet.id;
                      return ChoiceChip(
                        label: Text('🐶 ${pet.nome}'),
                        selected: ativo,
                        selectedColor: Cores.forest,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: ativo ? Cores.forest : Cores.border,
                        ),
                        labelStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                          color: ativo ? Colors.white : Cores.forest,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _petEscolhido = pet);
                        },
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: Cores.bark),
                      label: Text(
                        'Cadastrar pet',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Cores.bark,
                        ),
                      ),
                      backgroundColor: Cores.cream,
                      side: const BorderSide(color: Cores.bark, style: BorderStyle.solid),
                      onPressed: _cadastrarNovoPetInline,
                    ),
                  ],
                ),
                if (_meusPets.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Você ainda não possui nenhum pet cadastrado. Toque em "+ Cadastrar pet" acima.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Cores.muted,
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                const Divider(color: Cores.border),
                const SizedBox(height: 18),

                // 2. ESCOLHA DA DATA
                Text(
                  '2. Escolha a data',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _selecionarData,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Cores.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Cores.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Cores.forest,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dataFormatadaStr,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dataEscolhida != null ? Cores.forest : Cores.muted,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Cores.muted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                const Divider(color: Cores.border),
                const SizedBox(height: 18),

                // 3. ESCOLHA DO HORÁRIO
                if (servico.temSlots) ...[
                  Text(
                    '3. Escolha o horário disponível',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Cores.forest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TimeSlotPicker(
                    slots: _dataEscolhida != null ? servico.gerarSlots() : [],
                    selectedSlot: _horarioEscolhido,
                    occupiedSlots: _horariosOcupados,
                    isLoading: _buscandoSlots,
                    onSelected: (slot) {
                      setState(() => _horarioEscolhido = slot);
                    },
                  ),
                  const SizedBox(height: 22),
                  const Divider(color: Cores.border),
                  const SizedBox(height: 18),
                ],

                // 4. OBSERVAÇÕES
                Text(
                  '${servico.temSlots ? '4' : '3'}. Observações adicionais (opcional)',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Cores.forest,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _observacoesController,
                  maxLines: 3,
                  style: GoogleFonts.dmSans(fontSize: 14, color: Cores.forest),
                  decoration: InputDecoration(
                    hintText: 'Alguma recomendação de alergia, comportamento, etc.?',
                    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
                    filled: true,
                    fillColor: Cores.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Cores.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Cores.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Cores.forest, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // BOTÃO DE CONFIRMAR
                FilledButton.icon(
                  onPressed: _enviandoAgendamento ? null : _confirmarAgendamento,
                  icon: _enviandoAgendamento
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_outline),
                  label: _enviandoAgendamento
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
            ),
          ),
        ],
      ),
    );
  }
}