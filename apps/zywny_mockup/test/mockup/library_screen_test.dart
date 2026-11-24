import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny_mockup/mockup/library_screen.dart';

Future<void> _abrirBiblioteca(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
  await tester.pump();
}

void main() {
  testWidgets('a busca filtra a lista e, sem resposta, diz que nada achou', (
    tester,
  ) async {
    await _abrirBiblioteca(tester);

    await tester.enterText(find.byType(TextField), 'chopin');
    await tester.pump();
    expect(find.textContaining('Chopin'), findsWidgets);
    expect(find.text('Nenhuma partitura encontrada'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz-nada');
    await tester.pump();
    expect(find.text('Nenhuma partitura encontrada'), findsOneWidget);
  });

  testWidgets('tocar numa chave de ordenação mostra a seta', (tester) async {
    await _abrirBiblioteca(tester);

    expect(find.text('Recentes↓'), findsOneWidget);

    await tester.tap(find.text('Nome'));
    await tester.pump();

    expect(find.text('Nome↓'), findsOneWidget);
    expect(find.text('Recentes↓'), findsNothing);
  });

  testWidgets('o indicador do teclado MIDI liga e desliga', (tester) async {
    await _abrirBiblioteca(tester);

    expect(find.byTooltip('Teclado MIDI conectado'), findsOneWidget);

    await tester.tap(find.byTooltip('Teclado MIDI conectado'));
    await tester.pump();

    expect(find.byTooltip('Teclado MIDI desconectado'), findsOneWidget);
  });
}
