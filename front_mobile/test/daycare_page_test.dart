import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_mobile/components/campo_data.dart';
import 'package:front_mobile/models/usuario.dart';
import 'package:front_mobile/pages/daycare_page.dart';
import 'package:front_mobile/services/sessao.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object? corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

const _thor = {
  'id': 7,
  'user_id': 1,
  'nome': 'Thor',
  'idade': 3,
  'peso': 12.5,
  'raca': 'Beagle',
  'vacinas': <String>[],
};

final _hoje = dataIso(DateTime.now());

// Simula o back: pets, vagas e o POST do agendamento. Guarda o que chegou.
class _BackFalso {
  _BackFalso({this.vagas, this.respostaAgendar});

  final Map<String, Object>? vagas;
  final http.Response? respostaAgendar;
  final requisicoes = <http.Request>[];

  late final client = MockClient((req) async {
    requisicoes.add(req);
    switch (req.url.path) {
      case '/api/pets':
        return _json([_thor]);
      case '/api/daycare/vagas':
        return _json(
          vagas ?? {'ocupados': 0, 'disponivel': true, 'maximo': 10},
        );
      case '/api/daycare/agendar':
        return respostaAgendar ?? _json({'id': 1, 'status': 'pendente'}, 201);
    }
    return _json({'error': 'rota inesperada'}, 404);
  });

  http.Request? get agendamento => requisicoes
      .where((r) => r.url.path == '/api/daycare/agendar')
      .firstOrNull;
}

// Abre o Daycare por cima de outra tela, como a aba Serviços faz.
Future<void> _abrir(WidgetTester tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DaycarePage())),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

// Abre o calendário e confirma o dia que já vem marcado (hoje).
Future<void> _escolherHoje(WidgetTester tester) async {
  await _tocar(tester, 'Selecionar data');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sessao.entrar(
      'tok',
      const Usuario(id: 1, nome: 'Ana', email: 'ana@email.com'),
    );
  });

  testWidgets('plano recorrente envia frequência, dias e data de início', (
    tester,
  ) async {
    final back = _BackFalso();

    await http.runWithClient(() async {
      await _abrir(tester);
      expect(
        find.text('Olá, Ana! Escolha o plano ideal para o seu pet.'),
        findsOneWidget,
      );

      await _tocar(tester, 'Agora não');
      expect(
        find.text('💰 Deseja ver a tabela de preços do Daycare?'),
        findsNothing,
      );

      await _tocar(tester, '🐶 Thor');
      await _tocar(tester, 'Mensal');
      await _tocar(tester, '2x por semana');
      expect(find.text('Dias da semana — selecione 2 dias'), findsOneWidget);

      await _tocar(tester, 'Seg');
      await _tocar(tester, 'Qua');
      expect(find.text('2/2 dias selecionados ✅'), findsOneWidget);

      // Com o limite atingido, os outros dias ficam bloqueados.
      final sexta = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Sex'),
      );
      expect(sexta.onSelected, isNull);

      expect(find.text(r'R$ 816,00'), findsOneWidget);

      await _escolherHoje(tester);
      await _tocar(tester, '🗓 Confirmar agendamento');
    }, () => back.client);

    final pedido = back.agendamento!;
    expect(pedido.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(pedido.body), {
      'petId': 7,
      'plano': 'mensal',
      'frequencia': '2x por semana',
      'diasSemana': [1, 3],
      'dataInicio': _hoje,
      'dataAvulso': null,
      'observacoes': '',
      'valorTotal': 816.0,
    });
    expect(
      find.text('Agendamento de Daycare criado com sucesso! 🎉'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(DaycarePage), findsNothing);
    expect(
      find.text('abrir'),
      findsOneWidget,
      reason: 'volta para a tela de baixo',
    );
  });

  testWidgets('avulso consulta as vagas e envia só a data do dia', (
    tester,
  ) async {
    final back = _BackFalso(
      vagas: {'ocupados': 7, 'disponivel': true, 'maximo': 10},
    );

    await http.runWithClient(() async {
      await _abrir(tester);
      await _tocar(tester, '🐶 Thor');
      await _tocar(tester, 'Dia Teste / Avulso');
      expect(find.text(r'R$ 160,00'), findsOneWidget);

      await _escolherHoje(tester);
      expect(find.text('✅ 3 vaga(s) disponível(eis)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Tem medo de trovão');
      await _tocar(tester, '🗓 Confirmar agendamento');
    }, () => back.client);

    final consulta = back.requisicoes.firstWhere(
      (r) => r.url.path == '/api/daycare/vagas',
    );
    expect(consulta.url.queryParameters['data'], _hoje);

    expect(jsonDecode(back.agendamento!.body), {
      'petId': 7,
      'plano': 'dayuse',
      'frequencia': null,
      'diasSemana': <int>[],
      'dataInicio': null,
      'dataAvulso': _hoje,
      'observacoes': 'Tem medo de trovão',
      'valorTotal': 160.0,
    });
  });

  testWidgets('avulso lotado não deixa confirmar', (tester) async {
    final back = _BackFalso(
      vagas: {'ocupados': 10, 'disponivel': false, 'maximo': 10},
    );

    await http.runWithClient(() async {
      await _abrir(tester);
      await _tocar(tester, '🐶 Thor');
      await _tocar(tester, 'Dia Teste / Avulso');
      await _escolherHoje(tester);
      expect(find.text('❌ Lotado — sem vagas nesta data'), findsOneWidget);

      await _tocar(tester, '🗓 Confirmar agendamento');
    }, () => back.client);

    expect(find.text('Não há vagas disponíveis nesta data.'), findsOneWidget);
    expect(back.agendamento, isNull);
  });

  testWidgets('valida os campos na mesma ordem do site', (tester) async {
    final back = _BackFalso();

    await http.runWithClient(() async {
      await _abrir(tester);

      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(find.text('Selecione o pet.'), findsOneWidget);

      await _tocar(tester, '🐶 Thor');
      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(find.text('Selecione um plano.'), findsOneWidget);

      await _tocar(tester, 'Trimestral (3 meses)');
      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(find.text('Selecione a frequência.'), findsOneWidget);

      await _tocar(tester, '3x por semana');
      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(find.text('Selecione os dias da semana.'), findsOneWidget);

      await _tocar(tester, 'Seg');
      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(
        find.text(
          'Selecione exatamente 3 dia(s) conforme a frequência escolhida.',
        ),
        findsOneWidget,
      );

      await _tocar(tester, 'Qua');
      await _tocar(tester, 'Sex');
      await _tocar(tester, '🗓 Confirmar agendamento');
      expect(find.text('Informe a data de início.'), findsOneWidget);
    }, () => back.client);

    expect(back.agendamento, isNull);
  });

  testWidgets('mostra a mensagem do back quando o dia lota', (tester) async {
    final back = _BackFalso(
      respostaAgendar: _json({
        'error': 'Limite de 10 pets atingido para o dia 20/11/2026.',
      }, 409),
    );

    await http.runWithClient(() async {
      await _abrir(tester);
      await _tocar(tester, '🐶 Thor');
      await _tocar(tester, 'Anual (12 meses)');
      await _tocar(tester, '1x por semana');
      await _tocar(tester, 'Ter');
      await _escolherHoje(tester);
      await _tocar(tester, '🗓 Confirmar agendamento');
    }, () => back.client);

    expect(
      find.text('Limite de 10 pets atingido para o dia 20/11/2026.'),
      findsOneWidget,
    );
  });

  testWidgets('"Ver preços" abre a tabela com os valores do site', (
    tester,
  ) async {
    final back = _BackFalso();

    await http.runWithClient(() async {
      await _abrir(tester);
      await _tocar(tester, 'Ver preços');
    }, () => back.client);

    expect(find.text('🏡 Tabela de Preços — Daycare'), findsOneWidget);
    expect(find.text(r'R$ 945,54'), findsOneWidget);

    await tester.tap(find.text('Entendido!'));
    await tester.pumpAndSettle();
    expect(find.text('🏡 Tabela de Preços — Daycare'), findsNothing);
    expect(
      find.text('💰 Deseja ver a tabela de preços do Daycare?'),
      findsNothing,
    );
  });
}
