class Pet {
  const Pet({
    required this.id,
    required this.userId,
    required this.nome,
    required this.idade,
    required this.peso,
    required this.raca,
    this.vacinas = const [],
    this.criadoEm,
  });

  final int id;
  final int userId;
  final String nome;
  final int idade;
  final double peso;
  final String raca;
  final List<String> vacinas;
  final DateTime? criadoEm;

  factory Pet.fromJson(Map<String, dynamic> json) {
    List<String> vacinasList = [];
    final rawVacinas = json['vacinas'];
    if (rawVacinas is List) {
      vacinasList = rawVacinas.map((e) => e.toString()).toList();
    } else if (rawVacinas is String && rawVacinas.isNotEmpty) {
      vacinasList = rawVacinas.split(',').where((v) => v.trim().isNotEmpty).toList();
    }

    return Pet(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}') ?? 0,
      nome: json['nome'] as String? ?? '',
      idade: json['idade'] is int
          ? json['idade'] as int
          : int.tryParse('${json['idade']}') ?? 0,
      peso: json['peso'] is num
          ? (json['peso'] as num).toDouble()
          : double.tryParse('${json['peso']}') ?? 0.0,
      raca: json['raca'] as String? ?? '',
      vacinas: vacinasList,
      criadoEm: _lerData(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nome': nome,
        'idade': idade,
        'peso': peso,
        'raca': raca,
        'vacinas': vacinas,
      };

  static DateTime? _lerData(Object? valor) {
    if (valor == null) return null;
    final texto = '$valor'.replaceFirst(' ', 'T');
    return DateTime.tryParse(texto.endsWith('Z') ? texto : '${texto}Z')?.toLocal();
  }
}

// Listas usadas no cadastro de pet (as mesmas do site).
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
