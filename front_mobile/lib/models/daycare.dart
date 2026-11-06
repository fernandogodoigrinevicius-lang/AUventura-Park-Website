// Planos, preços e regras do Daycare. São os mesmos do site
// (front/src/pages/Daycare.jsx): se mudar um valor lá, mude aqui também.

class PlanoDaycare {
  const PlanoDaycare({required this.id, required this.label});

  final String id;
  final String label;

  // O avulso é um dia só; os outros repetem toda semana.
  bool get avulso => id == planoAvulso;
}

const planoAvulso = 'dayuse';

const planosDaycare = <PlanoDaycare>[
  PlanoDaycare(id: planoAvulso, label: 'Dia Teste / Avulso'),
  PlanoDaycare(id: 'mensal', label: 'Mensal'),
  PlanoDaycare(id: 'trimestral', label: 'Trimestral (3 meses)'),
  PlanoDaycare(id: 'semestral', label: 'Semestral (6 meses)'),
  PlanoDaycare(id: 'anual', label: 'Anual (12 meses)'),
];

const frequenciasDaycare = <String>[
  '1x por semana',
  '2x por semana',
  '3x por semana',
  '4x por semana',
  '5x por semana',
];

// O valor de "dia" é o mesmo do getDay() do JavaScript, que o back usa para
// gerar as datas do plano (1 = segunda ... 5 = sexta).
const diasSemanaDaycare = <({int valor, String label})>[
  (valor: 1, label: 'Seg'),
  (valor: 2, label: 'Ter'),
  (valor: 3, label: 'Qua'),
  (valor: 4, label: 'Qui'),
  (valor: 5, label: 'Sex'),
];

class LinhaPrecoDaycare {
  const LinhaPrecoDaycare({
    required this.plano,
    required this.mensal,
    this.trimestral,
    this.semestral,
    this.anual,
  });

  final String plano;
  final double mensal;
  final double? trimestral;
  final double? semestral;
  final double? anual;

  double? valorDo(String planoId) => switch (planoId) {
    'mensal' => mensal,
    'trimestral' => trimestral,
    'semestral' => semestral,
    'anual' => anual,
    _ => null,
  };
}

const precoDiaAvulso = 160.0;

const tabelaPrecosDaycare = <LinhaPrecoDaycare>[
  LinhaPrecoDaycare(
    plano: '1x por semana',
    mensal: 465.80,
    trimestral: 419.22,
    semestral: 395.93,
    anual: 372.64,
  ),
  LinhaPrecoDaycare(
    plano: '2x por semana',
    mensal: 816.00,
    trimestral: 734.40,
    semestral: 693.60,
    anual: 652.80,
  ),
  LinhaPrecoDaycare(
    plano: '3x por semana',
    mensal: 1050.60,
    trimestral: 945.54,
    semestral: 893.01,
    anual: 840.48,
  ),
  LinhaPrecoDaycare(
    plano: '4x por semana',
    mensal: 1169.60,
    trimestral: 1052.64,
    semestral: 994.16,
    anual: 935.68,
  ),
  LinhaPrecoDaycare(
    plano: '5x por semana',
    mensal: 1394.00,
    trimestral: 1254.60,
    semestral: 1184.90,
    anual: 1115.20,
  ),
  LinhaPrecoDaycare(plano: 'Dia Teste / Avulso', mensal: precoDiaAvulso),
];

// Valor que aparece no "Valor estimado" e vai para o back. Nulo enquanto
// falta escolher o plano ou a frequência.
double? precoDaycare(String? planoId, String? frequencia) {
  if (planoId == planoAvulso) return precoDiaAvulso;
  if (planoId == null || frequencia == null) return null;
  for (final linha in tabelaPrecosDaycare) {
    if (linha.plano == frequencia) return linha.valorDo(planoId);
  }
  return null;
}

// Quantos dias da semana o tutor pode marcar: "3x por semana" libera 3.
int maxDiasDaFrequencia(String? frequencia) {
  if (frequencia == null) return 0;
  final numero = RegExp(r'^(\d+)').firstMatch(frequencia)?.group(1);
  return numero == null ? 0 : int.parse(numero);
}

// Resposta de GET /api/daycare/vagas para um dia do plano avulso.
class VagasDaycare {
  const VagasDaycare({
    required this.ocupados,
    required this.maximo,
    required this.disponivel,
  });

  final int ocupados;
  final int maximo;
  final bool disponivel;

  int get livres => maximo - ocupados;

  factory VagasDaycare.fromJson(Map<String, dynamic> json) {
    return VagasDaycare(
      ocupados: json['ocupados'] is int
          ? json['ocupados'] as int
          : int.tryParse('${json['ocupados']}') ?? 0,
      maximo: json['maximo'] is int
          ? json['maximo'] as int
          : int.tryParse('${json['maximo']}') ?? 0,
      disponivel: json['disponivel'] == true,
    );
  }
}

// Mesmo formato do site: "R$ 1050,60" (sem separador de milhar).
String formatarReais(double? valor) => valor == null
    ? '—'
    : 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
