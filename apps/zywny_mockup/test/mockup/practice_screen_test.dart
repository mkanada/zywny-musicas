import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny_clock/zywny_clock.dart';
import 'package:zywny_mockup/mockup/options_panel.dart';
import 'package:zywny_mockup/mockup/practice_screen.dart';
import 'package:zywny_mockup/mockup/practice_state.dart';

const _args = PracticeArgs(
  title: 'Little bird, op. 43 nº 4',
  composer: 'Edvard Grieg',
  mode: PracticeMode.espera,
  hand: Hand.direita,
  tempoPercent: 80,
  measure: 4,
);

Future<void> _abrirEstudo(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PracticeScreen(
        clock: ManualClock(DateTime(2026, 11, 25, 10)),
        args: _args,
      ),
    ),
  );
  await tester.pump();
}

/// Desmonta a tela: o Cubit fecha e o "ao vivo" para antes do fim do teste.
Future<void> _fecharEstudo(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('Tocar troca o botão para Pausar e para de novo', (tester) async {
    await _abrirEstudo(tester);

    expect(find.byTooltip('Tocar'), findsOneWidget);

    await tester.tap(find.byTooltip('Tocar'));
    await tester.pump();
    expect(find.byTooltip('Pausar'), findsOneWidget);

    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(find.byTooltip('Tocar'), findsOneWidget);

    await _fecharEstudo(tester);
  });

  testWidgets('"Mais opções" abre o painel', (tester) async {
    await _abrirEstudo(tester);

    expect(find.byType(OptionsPanel), findsNothing);

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pump();

    expect(find.byType(OptionsPanel), findsOneWidget);

    await _fecharEstudo(tester);
  });

  testWidgets('"Ir" da folha de compasso leva ao compasso escolhido', (
    tester,
  ) async {
    await _abrirEstudo(tester);

    await tester.tap(find.byTooltip('Ir para compasso'));
    await tester.pumpAndSettle();
    expect(find.text('Ir para o compasso 4 de 41'), findsOneWidget);

    // O Cubit avisa a folha pelo stream: o quadro do `pump` vem antes do aviso,
    // então aqui é `pumpAndSettle`.
    tester.widget<Slider>(find.byType(Slider)).onChanged!(10);
    await tester.pumpAndSettle();
    expect(find.text('Ir para o compasso 10 de 41'), findsOneWidget);

    await tester.tap(find.text('Ir'));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);

    await _fecharEstudo(tester);
  });
}
