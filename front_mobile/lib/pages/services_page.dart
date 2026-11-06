import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/aviso.dart';
import '../components/card_agendamento.dart';
import '../components/header_auventura.dart';
import '../components/selo.dart';
import '../models/agendamento.dart';
import '../models/servico_info.dart';
import '../services/agendamentos_service.dart';
import '../services/api_client.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';
import 'login_page.dart';
import 'service_details_page.dart';

// Aba Serviços: o catálogo e, para quem está logado, "Meus Agendamentos".
// O detalhe do serviço e os formulários abrem por cima, como o login.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, this.loginParaAgendar});

  // Chamado com true antes de abrir o login pelo "Agendar" e com false
  // depois. A navegação usa isso para não pular para o My Pet ao entrar.
  final ValueChanged<bool>? loginParaAgendar;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Agendamento> _meusAgendamentos = [];
  bool _carregandoAgendamentos = false;
  String? _erroAgendamentos;

  @override
  void initState() {
    super.initState();
    sessao.addListener(_aoMudarSessao);
    if (sessao.logado) _carregarAgendamentos();
  }

  @override
  void dispose() {
    sessao.removeListener(_aoMudarSessao);
    super.dispose();
  }

  void _aoMudarSessao() {
    if (sessao.logado) {
      _carregarAgendamentos();
    } else {
      setState(() => _meusAgendamentos = []);
    }
  }

  Future<void> _carregarAgendamentos() async {
    final token = sessao.token;
    if (token == null) return;

    setState(() {
      _carregandoAgendamentos = true;
      _erroAgendamentos = null;
    });
    try {
      final agendamentos = await apiGetAgendamentos(token);
      if (!mounted) return;
      setState(() => _meusAgendamentos = agendamentos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erroAgendamentos = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregandoAgendamentos = false);
    }
  }

  // Ao voltar do detalhe ou do formulário, recarrega a lista: pode ter
  // entrado um agendamento novo.
  Future<void> _abrirDetalhes(ServicoInfo servico) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailsPage(
          servico: servico,
          loginParaAgendar: widget.loginParaAgendar,
        ),
      ),
    );
    if (mounted && sessao.logado) _carregarAgendamentos();
  }

  Future<void> _agendar(ServicoInfo servico) async {
    await abrirAgendamento(
      context,
      servico,
      loginParaAgendar: widget.loginParaAgendar,
    );
    if (mounted && sessao.logado) _carregarAgendamentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: const HeaderAuventura(),
      body: SafeArea(
        child: RefreshIndicator(
          color: Cores.bark,
          backgroundColor: Colors.white,
          onRefresh: () async {
            if (sessao.logado) await _carregarAgendamentos();
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
            Expanded(
              child: Text(
                'Serviços Disponíveis',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Cores.forest,
                ),
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
                            Text(
                              servico.emoji,
                              style: const TextStyle(fontSize: 13),
                            ),
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
                        Expanded(
                          child: Text(
                            'Ver detalhes →',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Cores.bark,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _agendar(servico),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                const Icon(Icons.lock_outline, size: 36, color: Cores.bark),
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
}
