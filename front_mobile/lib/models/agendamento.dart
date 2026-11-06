class Agendamento {
  const Agendamento({
    required this.id,
    required this.userId,
    required this.nomeCachorro,
    required this.servico,
    required this.data,
    required this.horario,
    this.observacoes,
    this.criadoEm,
  });

  final int id;
  final int userId;
  final String nomeCachorro;
  final String servico;
  final String data; // YYYY-MM-DD
  final String horario; // HH:mm
  final String? observacoes;
  final DateTime? criadoEm;

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}') ?? 0,
      nomeCachorro: json['nomeCachorro'] as String? ?? '',
      servico: json['servico'] as String? ?? '',
      data: _extrairData(json['data']),
      horario: json['horario'] as String? ?? '',
      observacoes: json['observacoes'] as String?,
      criadoEm: _lerData(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nomeCachorro': nomeCachorro,
        'servico': servico,
        'data': data,
        'horario': horario,
        if (observacoes != null) 'observacoes': observacoes,
      };

  static String _extrairData(Object? val) {
    if (val == null) return '';
    final str = '$val';
    if (str.contains('T')) {
      return str.split('T').first;
    }
    return str;
  }

  static DateTime? _lerData(Object? valor) {
    if (valor == null) return null;
    final texto = '$valor'.replaceFirst(' ', 'T');
    return DateTime.tryParse(texto.endsWith('Z') ? texto : '${texto}Z')?.toLocal();
  }

  String get servicoFormatado {
    switch (servico.toLowerCase()) {
      case 'banho':
        return 'Banho 🛁';
      case 'tosa':
        return 'Tosa ✂️';
      case 'banho_tosa':
      case 'banho e tosa':
        return 'Banho e Tosa 🛁✂️';
      case 'adestramento':
        return 'Adestramento 🎓';
      case 'daycare':
        return 'Daycare 🏡';
      default:
        return servico;
    }
  }

  String get dataFormatada {
    try {
      final partes = data.split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}
    return data;
  }
}
