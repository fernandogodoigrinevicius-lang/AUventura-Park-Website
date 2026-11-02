import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/cores.dart';

class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.occupiedSlots,
    required this.isLoading,
    required this.onSelected,
  });

  final List<String> slots;
  final String? selectedSlot;
  final List<String> occupiedSlots;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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

    if (slots.isEmpty) {
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

    final slotsManha = slots.where((s) {
      final h = int.tryParse(s.split(':').first) ?? 0;
      return h < 12;
    }).toList();

    final slotsTarde = slots.where((s) {
      final h = int.tryParse(s.split(':').first) ?? 0;
      return h >= 12;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slotsManha.isNotEmpty) ...[
          _blocoPeriodo('🌅 Manhã', slotsManha),
          const SizedBox(height: 14),
        ],
        if (slotsTarde.isNotEmpty) ...[
          _blocoPeriodo('☀️ Tarde', slotsTarde),
        ],
      ],
    );
  }

  Widget _blocoPeriodo(String titulo, List<String> slotsPeriodo) {
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
          children: slotsPeriodo.map((slot) {
            final ocupado = occupiedSlots.contains(slot);
            final selecionado = selectedSlot == slot;

            if (ocupado) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slot,
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
              onTap: () => onSelected(slot),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selecionado ? Cores.bark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selecionado ? Cores.bark : Cores.border,
                    width: selecionado ? 1.5 : 1,
                  ),
                  boxShadow: selecionado
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
                  slot,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                    color: selecionado ? Colors.white : Cores.forest,
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
