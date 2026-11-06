import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_mobile/main.dart';
import 'package:front_mobile/models/usuario.dart';
import 'package:front_mobile/services/sessao.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usuario = Usuario(id: 1, nome: 'Ana', email: 'ana@email.com');

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sessao.sair();
  });

  testWidgets('aba My Pet aparece ao entrar e some ao sair', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(750, 1624);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    // As abas carregam depoimentos ao abrir; sem rede elas só mostram erro.
    final client = MockClient((_) async => throw http.ClientException('sem rede'));

    await http.runWithClient(() async {
      await tester.pumpWidget(const AuventuraApp());
      await tester.pumpAndSettle();
      expect(find.text('My Pet'), findsNothing);

      await sessao.entrar('tok', _usuario);
      await tester.pumpAndSettle();
      expect(find.text('My Pet'), findsOneWidget);
      expect(find.text('Olá, Ana!'), findsOneWidget, reason: 'abre direto no My Pet');

      await sessao.sair();
      await tester.pumpAndSettle();
      expect(find.text('My Pet'), findsNothing);
      expect(find.text('Olá, Ana!'), findsNothing, reason: 'volta para a Home');
    }, () => client);
  });

  testWidgets(
    'login pelo "Agendar" volta ao formulário, sem pular para o My Pet',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      http.Response json(Object corpo) =>
          http.Response.bytes(utf8.encode(jsonEncode(corpo)), 200);
      final client = MockClient((req) async {
        switch (req.url.path) {
          case '/api/login':
            return json({
              'token': 'tok',
              'user': {'id': 1, 'nome': 'Ana', 'email': 'ana@email.com'},
            });
          case '/api/agendamentos':
            return json([]);
          case '/api/pets':
            return json([
              {
                'id': 7,
                'user_id': 1,
                'nome': 'Thor',
                'idade': 3,
                'peso': 12.5,
                'raca': 'Beagle',
              },
            ]);
        }
        throw http.ClientException('sem rede');
      });

      Future<void> tocar(Finder alvo) async {
        await tester.ensureVisible(alvo);
        await tester.pumpAndSettle();
        await tester.tap(alvo);
        await tester.pumpAndSettle();
      }

      await http.runWithClient(() async {
        await tester.pumpWidget(const AuventuraApp());
        await tester.pumpAndSettle();

        await tocar(find.text('Serviços'));
        await tocar(find.text('Banho').first);
        await tocar(find.text('🗓 Agendar já'));
        await tocar(find.text('Entrar'));
      }, () => client);

      expect(sessao.logado, isTrue);
      // A barra de abas fica embaixo do formulário, que abriu por cima dela.
      final abas = find.byType(NavigationBar, skipOffstage: false);
      expect(
        tester.widget<NavigationBar>(abas).selectedIndex,
        1,
        reason: 'continua na aba Serviços',
      );
      expect(find.text('Confirmar agendamento'), findsOneWidget);
      expect(
        find.text('🐶 Thor'),
        findsOneWidget,
        reason: 'carregou os pets do tutor',
      );
    },
  );
}
