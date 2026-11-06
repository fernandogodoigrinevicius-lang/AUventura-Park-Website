import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/agendamento.dart';
import '../theme/cores.dart';

class CardAgendamento extends StatelessWidget {
  const CardAgendamento({super.key, required this.agendamento});

  final Agendamento agendamento;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Cores.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Cores.sand,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🐶', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agendamento.nomeCachorro,
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Cores.forest,
                      ),
                    ),
                    Text(
                      'Pet agendado',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Cores.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Cores.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Cores.forest.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  agendamento.servicoFormatado,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Cores.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Cores.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Cores.bark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      agendamento.dataFormatada,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Cores.forest,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Cores.bark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    agendamento.horario,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Cores.forest,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (agendamento.observacoes != null &&
              agendamento.observacoes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Cores.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      agendamento.observacoes!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Cores.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
