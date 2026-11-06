import 'package:flutter_test/flutter_test.dart';
import 'package:front_mobile/models/daycare.dart';

void main() {
  group('Preços do Daycare (mesma tabela do site)', () {
    test('avulso custa R\$ 160 sem precisar de frequência', () {
      expect(precoDaycare(planoAvulso, null), 160.0);
    });

    test('planos recorrentes pegam o valor da linha da frequência', () {
      expect(precoDaycare('mensal', '2x por semana'), 816.00);
      expect(precoDaycare('trimestral', '3x por semana'), 945.54);
      expect(precoDaycare('semestral', '4x por semana'), 994.16);
      expect(precoDaycare('anual', '5x por semana'), 1115.20);
    });

    test('sem plano ou sem frequência ainda não tem valor', () {
      expect(precoDaycare(null, null), isNull);
      expect(precoDaycare('mensal', null), isNull);
      expect(precoDaycare('mensal', 'frequência que não existe'), isNull);
    });

    test('formata como o site: vírgula e sem separador de milhar', () {
      expect(formatarReais(1050.6), r'R$ 1050,60');
      expect(formatarReais(160), r'R$ 160,00');
      expect(formatarReais(null), '—');
    });
  });

  group('Regras do Daycare', () {
    test('a frequência define quantos dias podem ser marcados', () {
      expect(maxDiasDaFrequencia('1x por semana'), 1);
      expect(maxDiasDaFrequencia('5x por semana'), 5);
      expect(maxDiasDaFrequencia(null), 0);
    });

    test('dias da semana usam a numeração do getDay() do back', () {
      expect(diasSemanaDaycare.map((d) => d.valor), [1, 2, 3, 4, 5]);
      expect(diasSemanaDaycare.first.label, 'Seg');
    });

    test('só o Dia Teste é avulso', () {
      expect(planosDaycare.where((p) => p.avulso).map((p) => p.id), [
        planoAvulso,
      ]);
    });
  });
}
