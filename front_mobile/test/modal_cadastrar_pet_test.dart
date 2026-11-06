import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_mobile/components/modal_cadastrar_pet.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('sugere raças enquanto digita e preenche ao tocar', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(750, 1624);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ModalCadastrarPet.abrir(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Raça'), 'bo');
    await tester.pump();

    // Como no site: só as raças que começam com o que foi digitado.
    expect(find.widgetWithText(ActionChip, 'Border Collie'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Boston Terrier'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Boxer'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Bichon Frisé'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'Boxer'));
    await tester.pump();

    expect(find.byType(ActionChip), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Boxer'), findsOneWidget);
  });
}
