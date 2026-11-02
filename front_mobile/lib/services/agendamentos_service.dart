import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/agendamento.dart';
import 'api_client.dart';

Future<List<Agendamento>> apiGetAgendamentos(String token) async {
  final corpo = await apiRequest(
    () => http.get(
      Uri.parse('$apiBaseUrl/api/agendamentos'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
    'Falha ao buscar agendamentos.',
  );

  if (corpo is! List) throw ApiException('Resposta inválida do servidor.');
  try {
    return corpo
        .map((item) => Agendamento.fromJson(item as Map<String, dynamic>))
        .toList();
  } on TypeError {
    throw ApiException('Resposta inválida do servidor.');
  }
}

Future<Agendamento> apiCreateAgendamento(
  String token, {
  required String nomeCachorro,
  required String servico,
  required String data,
  required String horario,
  String? observacoes,
}) async {
  final corpo = await apiRequest(
    () => http.post(
      Uri.parse('$apiBaseUrl/api/agendamentos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nomeCachorro': nomeCachorro,
        'servico': servico,
        'data': data,
        'horario': horario,
        'observacoes': observacoes ?? '',
      }),
    ),
    'Falha ao criar agendamento.',
  );

  if (corpo is! Map<String, dynamic>) {
    throw ApiException('Resposta inválida do servidor ao criar agendamento.');
  }

  return Agendamento.fromJson(corpo);
}

Future<List<String>> apiGetHorariosOcupados({
  required String data,
  required String servico,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/agendamentos/horarios-ocupados')
      .replace(queryParameters: {
    'data': data,
    'servico': servico,
  });

  final corpo = await apiRequest(
    () => http.get(uri),
    'Falha ao buscar horários ocupados.',
  );

  if (corpo is! List) return [];
  return corpo.map((e) => e.toString()).toList();
}
