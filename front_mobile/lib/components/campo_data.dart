import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

// Formato que o back espera: 2026-11-15.
String dataIso(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}-${_doisDigitos(data.month)}-${_doisDigitos(data.day)}';

// Formato para mostrar na tela: 15/11/2026.
String dataBr(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';

// Campo que abre o calendário. Só deixa escolher de hoje em diante, como o
// min={hoje} dos inputs de data do site.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.valor,
    required this.onEscolher,
    this.dica = 'Selecionar data',
  });

  final DateTime? valor;
  final ValueChanged<DateTime> onEscolher;
  final String dica;

  Future<void> _abrirCalendario(BuildContext context) async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final atual = valor;
    final data = await showDatePicker(
      context: context,
      initialDate: atual != null && !atual.isBefore(hoje) ? atual : hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Cores.forest,
            onPrimary: Colors.white,
            onSurface: Cores.forest,
          ),
        ),
        child: child!,
      ),
    );
    if (data != null) onEscolher(data);
  }

  @override
  Widget build(BuildContext context) {
    final escolhida = valor;
    return InkWell(
      onTap: () => _abrirCalendario(context),
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
            Expanded(
              child: Text(
                escolhida == null ? dica : dataBr(escolhida),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: escolhida == null ? Cores.muted : Cores.forest,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Cores.muted),
          ],
        ),
      ),
    );
  }
}
