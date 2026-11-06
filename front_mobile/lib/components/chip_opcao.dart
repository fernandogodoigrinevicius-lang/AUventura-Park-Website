import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

// Opção de escolha única dos formulários (pet, plano, frequência, dia da
// semana). Sem onTap ela aparece desabilitada.
class ChipOpcao extends StatelessWidget {
  const ChipOpcao({
    super.key,
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  final String texto;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return ChoiceChip(
      label: Text(texto),
      selected: selecionado,
      showCheckmark: false,
      selectedColor: Cores.forest,
      backgroundColor: Colors.white,
      disabledColor: Colors.grey.shade100,
      side: BorderSide(color: selecionado ? Cores.forest : Cores.border),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        color: selecionado
            ? Colors.white
            : habilitado
            ? Cores.forest
            : Colors.grey.shade400,
      ),
      onSelected: habilitado ? (_) => onTap!() : null,
    );
  }
}
