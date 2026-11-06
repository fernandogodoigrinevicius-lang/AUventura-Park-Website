import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/daycare.dart';
import 'api_client.dart';

Future<VagasDaycare> apiVerificarVagas(String token, String data) async {
  final corpo = await apiRequest(
    () => http.get(
      Uri.parse('$apiBaseUrl/api/daycare/vagas')
          .replace(queryParameters: {'data': data}),
      headers: {'Authorization': 'Bearer $token'},
    ),
    'Erro ao verificar vagas.',
  );
  if (corpo is! Map<String, dynamic>) {
    throw ApiException('Resposta inválida do servidor.');
  }
  return VagasDaycare.fromJson(corpo);
}

// Mesmo corpo que o site manda: no avulso vai só dataAvulso; nos planos
// recorrentes vão frequência, dias da semana e data de início.
Future<void> apiCriarAgendamentoDaycare(
  String token, {
  required int petId,
  required String plano,
  String? frequencia,
  List<int> diasSemana = const [],
  String? dataInicio,
  String? dataAvulso,
  String observacoes = '',
  double? valorTotal,
}) async {
  await apiRequest(
    () => http.post(
      Uri.parse('$apiBaseUrl/api/daycare/agendar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'petId': petId,
        'plano': plano,
        'frequencia': frequencia,
        'diasSemana': diasSemana,
        'dataInicio': dataInicio,
        'dataAvulso': dataAvulso,
        'observacoes': observacoes,
        'valorTotal': valorTotal,
      }),
    ),
    'Erro ao criar agendamento.',
  );
}
