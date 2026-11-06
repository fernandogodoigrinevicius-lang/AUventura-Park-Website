import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

String? validarEmail(String texto) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto) ? null : 'E-mail inválido';

// Os limites de cada campo espelham as colunas do banco (VARCHAR e TEXT).
class CampoForm extends StatelessWidget {
  const CampoForm({
    super.key,
    required this.controller,
    required this.rotulo,
    required this.dica,
    this.linhas = 1,
    this.limite = 100,
    this.obrigatorio = true,
    this.teclado,
    this.capitalizacao = TextCapitalization.sentences,
    this.validar,
    this.aoMudar,
    this.senha = false,
    this.autofill,
  });

  final TextEditingController controller;
  final String rotulo;
  final String dica;
  final int linhas;
  final int limite;
  final bool obrigatorio;
  final TextInputType? teclado;
  final TextCapitalization capitalizacao;
  final String? Function(String texto)? validar;
  final ValueChanged<String>? aoMudar;
  final bool senha;
  final Iterable<String>? autofill;

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Cores.border),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: linhas,
        maxLines: linhas,
        keyboardType: teclado ?? (linhas > 1 ? TextInputType.multiline : null),
        textCapitalization: capitalizacao,
        obscureText: senha,
        enableSuggestions: !senha,
        autocorrect: !senha,
        autofillHints: autofill,
        inputFormatters: [LengthLimitingTextInputFormatter(limite)],
        onChanged: aoMudar,
        style: GoogleFonts.dmSans(fontSize: 14, color: Cores.forest),
        validator: (valor) {
          final texto = valor?.trim() ?? '';
          if (texto.isEmpty) return obrigatorio ? 'Preencha este campo' : null;
          return validar?.call(texto);
        },
        decoration: InputDecoration(
          labelText: rotulo,
          alignLabelWithHint: true,
          hintText: dica,
          filled: true,
          fillColor: Cores.cream,
          border: borda,
          enabledBorder: borda,
          focusedBorder: borda.copyWith(
            borderSide: const BorderSide(color: Cores.forest, width: 1.5),
          ),
        ),
      ),
    );
  }
}
