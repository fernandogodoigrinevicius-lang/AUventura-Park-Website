class ServicoInfo {
  const ServicoInfo({
    required this.id,
    required this.label,
    required this.emoji,
    required this.imagemAsset,
    required this.resumo,
    required this.descricao,
    required this.duracaoMinutos,
  });

  final String id;
  final String label;
  final String emoji;
  final String imagemAsset;
  final String resumo;
  final String descricao;
  final int duracaoMinutos;

  bool get temSlots => duracaoMinutos > 0;

  List<String> gerarSlots() {
    final slots = <String>[];
    final intervalo = duracaoMinutos == 60 ? 60 : 30;
    const fimH = 17;
    final fimM = duracaoMinutos == 60 ? 0 : 30;

    var h = 8;
    var m = 0;
    while (h < fimH || (h == fimH && m <= fimM)) {
      final horaStr = h.toString().padLeft(2, '0');
      final minStr = m.toString().padLeft(2, '0');
      slots.add('$horaStr:$minStr');
      m += intervalo;
      if (m >= 60) {
        h += m ~/ 60;
        m = m % 60;
      }
    }
    return slots;
  }
}

const servicosDisponiveis = <ServicoInfo>[
  ServicoInfo(
    id: 'banho',
    label: 'Banho',
    emoji: '🛁',
    imagemAsset: 'assets/images/banho.jpg',
    resumo: 'Banho completo com produtos premium e secagem profissional.',
    descricao:
        'Utilizamos produtos hipoalergênicos e adequados para cada tipo de pelagem. O banho inclui limpeza de ouvidos, corte de unhas e secagem profissional.',
    duracaoMinutos: 30,
  ),
  ServicoInfo(
    id: 'tosa',
    label: 'Tosa',
    emoji: '✂️',
    imagemAsset: 'assets/images/tosa.jpg',
    resumo: 'Tosa personalizada por profissionais experientes.',
    descricao:
        'A tosa pode ser higiênica, padrão da raça ou personalizada conforme sua preferência. Realizada por profissionais com anos de experiência.',
    duracaoMinutos: 30,
  ),
  ServicoInfo(
    id: 'banho_tosa',
    label: 'Banho e Tosa',
    emoji: '🛁✂️',
    imagemAsset: 'assets/images/banhoEtosa.png',
    resumo: 'Banho completo mais tosa personalizada para seu pet.',
    descricao:
        'Combine o banho completo com uma tosa feita por profissionais experientes. Deixamos seu pet impecável de ponta a ponta.',
    duracaoMinutos: 60,
  ),
  ServicoInfo(
    id: 'adestramento',
    label: 'Adestramento',
    emoji: '🎓',
    imagemAsset: 'assets/images/adestramento.jpg',
    resumo:
        'Sessões individuais com adestrador certificado para obediência e boas maneiras.',
    descricao:
        'Trabalhamos comandos básicos e avançados com método positivo. Cada sessão é adaptada ao perfil do seu cão, respeitando seu ritmo e personalidade.',
    duracaoMinutos: 60,
  ),
  ServicoInfo(
    id: 'daycare',
    label: 'Daycare',
    emoji: '🏡',
    imagemAsset: 'assets/images/daycare.jpg',
    resumo: 'Cuidado e diversão o dia todo enquanto você trabalha.',
    descricao:
        'No nosso Daycare, seu pet passa o dia em um ambiente seguro, supervisionado e cheio de amigos. Oferecemos atividades lúdicas, socialização controlada e muito carinho para que ele chegue em casa feliz e saudável.',
    duracaoMinutos: 0,
  ),
];

const racasPopulares = <String>[
  'Akita',
  'American Bully',
  'Basenji',
  'Beagle',
  'Bichon Frisé',
  'Border Collie',
  'Boston Terrier',
  'Boxer',
  'Buldogue Francês',
  'Buldogue Inglês',
  'Cavalier King Charles',
  'Chihuahua',
  'Chow Chow',
  'Cocker Spaniel',
  'Dachshund',
  'Dálmata',
  'Dobermann',
  'Dogo Argentino',
  'Fila Brasileiro',
  'Golden Retriever',
  'Husky Siberiano',
  'Jack Russell Terrier',
  'Labrador Retriever',
  'Lhasa Apso',
  'Malamute do Alasca',
  'Maltês',
  'Mastiff',
  'Pinscher Miniatura',
  'Pit Bull',
  'Pomerânia',
  'Poodle',
  'Pug',
  'Rottweiler',
  'Samoieda',
  'Schnauzer',
  'Shar Pei',
  'Shih Tzu',
  'Spitz Alemão',
  'Sem raça definida (SRD)',
  'Weimaraner',
  'Yorkshire Terrier',
];

class VacinaInfo {
  const VacinaInfo({required this.id, required this.label});
  final String id;
  final String label;
}

const vacinasDisponiveis = <VacinaInfo>[
  VacinaInfo(id: 'antirrabica', label: 'Antirrábica'),
  VacinaInfo(id: 'polivalente', label: 'Polivalente'),
  VacinaInfo(id: 'traqueobronquite', label: 'Traqueobronquite'),
];
