import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

// Horários do dia separados em manhã e tarde. Os ocupados aparecem riscados
// e não podem ser escolhidos.
class SeletorHorario extends StatelessWidget {
  const SeletorHorario({
    super.key,
    required this.horarios,
    required this.selecionado,
    required this.ocupados,
    required this.carregando,
    required this.onSelecionar,
  });

  final List<String> horarios;
  final String? selecionado;
  final List<String> ocupados;
  final bool carregando;
  final ValueChanged<String> onSelecionar;

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Cores.bark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Buscando horários disponíveis...',
              style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
            ),
          ],
        ),
      );
    }

    if (horarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Cores.sand.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Selecione uma data para visualizar os horários.',
          style: GoogleFonts.dmSans(fontSize: 13, color: Cores.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final manha = horarios.where((h) => _hora(h) < 12).toList();
    final tarde = horarios.where((h) => _hora(h) >= 12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (manha.isNotEmpty) ...[
          _blocoPeriodo('🌅 Manhã', manha),
          const SizedBox(height: 14),
        ],
        if (tarde.isNotEmpty) ...[_blocoPeriodo('☀️ Tarde', tarde)],
      ],
    );
  }

  int _hora(String horario) => int.tryParse(horario.split(':').first) ?? 0;

  Widget _blocoPeriodo(String titulo, List<String> horariosDoPeriodo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Cores.forest,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: horariosDoPeriodo.map((horario) {
            final ocupado = ocupados.contains(horario);
            final ativo = selecionado == horario;

            if (ocupado) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      horario,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ocupado',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return InkWell(
              onTap: () => onSelecionar(horario),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: ativo ? Cores.bark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ativo ? Cores.bark : Cores.border,
                    width: ativo ? 1.5 : 1,
                  ),
                  boxShadow: ativo
                      ? [
                          BoxShadow(
                            color: Cores.bark.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  horario,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                    color: ativo ? Colors.white : Cores.forest,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
