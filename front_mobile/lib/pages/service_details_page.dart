import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/barra_voltar.dart';
import '../models/servico_info.dart';
import '../services/sessao.dart';
import '../theme/cores.dart';
import 'booking_page.dart';
import 'daycare_page.dart';
import 'login_page.dart';

// Abre o formulário certo para o serviço: o do Daycare ou o de horário.
// Sem login, passa antes pela tela de login e, como no site, segue direto
// para o formulário. loginParaAgendar avisa a navegação para não pular para
// o My Pet nesse login (ver main.dart).
Future<void> abrirAgendamento(
  BuildContext context,
  ServicoInfo servico, {
  ValueChanged<bool>? loginParaAgendar,
}) async {
  final navegador = Navigator.of(context);
  if (!sessao.logado) {
    loginParaAgendar?.call(true);
    await navegador.push(MaterialPageRoute(builder: (_) => const LoginPage()));
    loginParaAgendar?.call(false);
    if (!sessao.logado) return;
  }
  await navegador.push(
    MaterialPageRoute(
      builder: (_) => servico.ehDaycare
          ? const DaycarePage()
          : BookingPage(servico: servico),
    ),
  );
}

class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({
    super.key,
    required this.servico,
    this.loginParaAgendar,
  });

  final ServicoInfo servico;
  final ValueChanged<bool>? loginParaAgendar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.cream,
      appBar: BarraVoltar(servico.label),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 38),
          child: Container(
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
                _imagem(),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: _descricao(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagem() {
    return SizedBox(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _descricao(BuildContext context) {
    return Column(
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
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => abrirAgendamento(
            context,
            servico,
            loginParaAgendar: loginParaAgendar,
          ),
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
        ListenableBuilder(
          listenable: sessao,
          builder: (context, _) {
            if (sessao.logado) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Você precisará fazer login para confirmar o agendamento.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 12, color: Cores.muted),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
