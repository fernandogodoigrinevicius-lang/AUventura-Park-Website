import 'package:http/http.dart' as http;

import '../models/notificacao.dart';
import 'api_client.dart';

Future<List<Notificacao>> apiGetNotificacoes(String token) async {
  final corpo = await apiRequest(
    () => http.get(
      Uri.parse('$apiBaseUrl/api/notificacoes'),
      headers: {'Authorization': 'Bearer $token'},
    ),
    'Falha ao buscar notificações.',
  );

  if (corpo is! List) {
    throw ApiException('Resposta inválida do servidor.');
  }

  try {
    return corpo
        .map((item) => Notificacao.fromJson(item as Map<String, dynamic>))
        .toList();
  } on TypeError {
    throw ApiException('Resposta inválida do servidor.');
  }
}

Future<void> apiMarcarNotificacaoComoLida(String token, int id) async {
  await apiRequest(
    () => http.patch(
      Uri.parse('$apiBaseUrl/api/notificacoes/$id/lida'),
      headers: {'Authorization': 'Bearer $token'},
    ),
    'Falha ao marcar a notificação como lida.',
  );
}

Future<void> apiExcluirNotificacao(String token, int id) async {
  await apiRequest(
    () => http.delete(
      Uri.parse('$apiBaseUrl/api/notificacoes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    ),
    'Falha ao excluir a notificação.',
  );
}