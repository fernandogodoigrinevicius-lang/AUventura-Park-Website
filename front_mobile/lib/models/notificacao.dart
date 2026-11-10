class Notificacao {
  const Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    this.criadoEm,
  });

  final int id;
  final String titulo;
  final String mensagem;
  final String tipo;
  final bool lida;
  final DateTime? criadoEm;

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    final data = json['criado_em'] as String?;

    return Notificacao(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      mensagem: json['mensagem'] as String,
      tipo: json['tipo'] as String,
      lida: json['lida'] == 1 || json['lida'] == true,
      criadoEm: data == null ? null : DateTime.tryParse(data)?.toLocal(),
    );
  }
}