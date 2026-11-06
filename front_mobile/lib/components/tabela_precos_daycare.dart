import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daycare.dart';
import '../theme/cores.dart';

// A mesma tabela do modal do site. No celular ela rola para o lado.
class TabelaPrecosDaycare extends StatelessWidget {
  const TabelaPrecosDaycare({super.key});

  static Future<void> abrir(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TabelaPrecosDaycare(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Cores.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '🏡 Tabela de Preços — Daycare',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Cores.forest,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close, color: Cores.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Planos mensais por frequência semanal, com descontos progressivos para contratos de maior duração.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.4,
                color: Cores.muted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Cores.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Cores.forest),
                      children: [
                        _cabecalho('Plano'),
                        _cabecalho('Mensal'),
                        _cabecalho('Trimestral', desconto: '-10%'),
                        _cabecalho('Semestral', desconto: '-15%'),
                        _cabecalho('Anual', desconto: '-20%'),
                      ],
                    ),
                    for (var i = 0; i < tabelaPrecosDaycare.length; i++)
                      _linha(tabelaPrecosDaycare[i], zebra: i.isOdd),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Entendido!',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _linha(LinhaPrecoDaycare linha, {required bool zebra}) {
    return TableRow(
      decoration: BoxDecoration(color: zebra ? Cores.cream : Colors.white),
      children: [
        _celula(linha.plano, negrito: true),
        _celula(formatarReais(linha.mensal)),
        _celula(formatarReais(linha.trimestral)),
        _celula(formatarReais(linha.semestral)),
        _celula(formatarReais(linha.anual)),
      ],
    );
  }

  Widget _cabecalho(String texto, {String? desconto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (desconto != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Cores.bark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                desconto,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _celula(String texto, {bool negrito = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        texto,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: negrito ? FontWeight.w700 : FontWeight.w500,
          color: Cores.forest,
        ),
      ),
    );
  }
}
