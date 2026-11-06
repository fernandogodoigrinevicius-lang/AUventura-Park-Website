import 'package:flutter_test/flutter_test.dart';
import 'package:front_mobile/models/agendamento.dart';
import 'package:front_mobile/models/pet.dart';
import 'package:front_mobile/models/servico_info.dart';

void main() {
  group('Modelos de Agendamento e Pet', () {
    test('Agendamento deve converter de/para JSON corretamente', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'nomeCachorro': 'Rex',
        'servico': 'banho_tosa',
        'data': '2026-11-15',
        'horario': '10:00',
        'observacoes': 'Tosa na tesoura',
        'criado_em': '2026-11-01T10:00:00Z',
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.id, 1);
      expect(ag.userId, 10);
      expect(ag.nomeCachorro, 'Rex');
      expect(ag.servico, 'banho_tosa');
      expect(ag.servicoFormatado, 'Banho e Tosa 🛁✂️');
      expect(ag.dataFormatada, '15/11/2026');
      expect(ag.horario, '10:00');
      expect(ag.observacoes, 'Tosa na tesoura');
    });

    test('Pet deve parsear vacinas em formato de lista ou string separada por virgula', () {
      final jsonList = {
        'id': 2,
        'user_id': 10,
        'nome': 'Mel',
        'idade': 4,
        'peso': 15.5,
        'raca': 'Golden Retriever',
        'vacinas': ['antirrabica', 'polivalente'],
      };

      final petList = Pet.fromJson(jsonList);
      expect(petList.nome, 'Mel');
      expect(petList.vacinas.length, 2);
      expect(petList.vacinas, contains('antirrabica'));

      final jsonStr = {
        'id': 3,
        'user_id': 10,
        'nome': 'Thor',
        'idade': 2,
        'peso': 8.0,
        'raca': 'Beagle',
        'vacinas': 'antirrabica,traqueobronquite',
      };

      final petStr = Pet.fromJson(jsonStr);
      expect(petStr.nome, 'Thor');
      expect(petStr.vacinas.length, 2);
      expect(petStr.vacinas, contains('traqueobronquite'));
    });

    test('ServicoInfo gera slots de 30 minutos ou 60 minutos dependendo da duracao', () {
      final banho = servicosDisponiveis.firstWhere((s) => s.id == 'banho');
      final slotsBanho = banho.gerarSlots();
      expect(slotsBanho.first, '08:00');
      expect(slotsBanho[1], '08:30');
      expect(slotsBanho.last, '17:30');

      final tosaCompleta =
          servicosDisponiveis.firstWhere((s) => s.id == 'banho_tosa');
      final slotsTosa = tosaCompleta.gerarSlots();
      expect(slotsTosa.first, '08:00');
      expect(slotsTosa[1], '09:00');
      expect(slotsTosa.last, '17:00');
    });
  });
}
