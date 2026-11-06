import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

// Barra das telas que abrem por cima das abas (detalhe do serviço e
// formulários de agendamento), com a seta de voltar. Mesmo visual da barra
// da tela de login.
class BarraVoltar extends StatelessWidget implements PreferredSizeWidget {
  const BarraVoltar(this.titulo, {super.key});

  final String titulo;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      foregroundColor: Cores.forest,
      title: Text(
        titulo,
        style: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Cores.forest,
        ),
      ),
    );
  }
}
