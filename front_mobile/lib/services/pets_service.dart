import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pet.dart';
import 'api_client.dart';

Future<List<Pet>> apiGetPets(String token) async {
  final corpo = await apiRequest(
    () => http.get(
      Uri.parse('$apiBaseUrl/api/pets'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
    'Falha ao buscar pets.',
  );

  if (corpo is! List) throw ApiException('Resposta inválida do servidor.');
  try {
    return corpo
        .map((item) => Pet.fromJson(item as Map<String, dynamic>))
        .toList();
  } on TypeError {
    throw ApiException('Resposta inválida do servidor.');
  }
}

Future<Pet> apiCreatePet(
  String token, {
  required String nome,
  required int idade,
  required double peso,
  required String raca,
  required List<String> vacinas,
}) async {
  final corpo = await apiRequest(
    () => http.post(
      Uri.parse('$apiBaseUrl/api/pets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'idade': idade,
        'peso': peso,
        'raca': raca,
        'vacinas': vacinas,
      }),
    ),
    'Falha ao cadastrar pet.',
  );

  if (corpo is! Map<String, dynamic>) {
    throw ApiException('Resposta inválida do servidor ao cadastrar pet.');
  }

  return Pet.fromJson(corpo);
}

Future<void> apiDeletePet(String token, int petId) async {
  await apiRequest(
    () => http.delete(
      Uri.parse('$apiBaseUrl/api/pets/$petId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
    'Falha ao remover pet.',
  );
}
