import 'package:flutter/material.dart';

import 'package:zywny_clock/zywny_clock.dart';
import 'package:zywny_comum/ui/theme.dart';

import 'mockup/library_screen.dart';
import 'mockup/practice_screen.dart';
import 'mockup/practice_state.dart';

/// O mockup de interface (`lib/mockup/`) — as telas de celular do artefato
/// "zywny — interface de estudo", sem o Verovio ligado (as imagens de
/// partitura vêm prontas de `assets/`, geradas por
/// `tool/build_mockup_images.sh`).
///
/// Um app à parte, membro do workspace da raiz (R12): `just run-mockup`.
/// Usa o tema e os widgets do app (`package:zywny`), mas nada do mockup
/// entra no app.
void main() {
  runApp(ZywnyMockupApp(clock: SystemClock()));
}

class ZywnyMockupApp extends StatelessWidget {
  const ZywnyMockupApp({super.key, required this.clock});

  /// O relógio do app (CT05f), que chega às telas pelo construtor.
  final AppClock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zywny — mockup',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Rotas nomeadas (`/estudo`, `/grande`, `/treino`, `/painel`) para abrir
  /// direto em cada um dos estados dos artboards `Celular*.dc.html` — usadas
  /// para tirar screenshot comparável ao artefato (`tool/capture_mockup_screens.sh`),
  /// além da navegação normal a partir da biblioteca.
  static const _littleBird = PracticeArgs(
    title: 'Little bird, op. 43 nº 4',
    composer: 'Edvard Grieg',
  );
  static const _littleBirdPracticing = PracticeArgs(
    title: 'Little bird, op. 43 nº 4',
    composer: 'Edvard Grieg',
    mode: PracticeMode.espera,
    hand: Hand.direita,
    tempoPercent: 80,
    measure: 4,
  );

  Route<Object?> _onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case '/estudo':
        page = PracticeScreen(clock: clock, args: _littleBird);
      case '/grande':
        page = PracticeScreen(
          clock: clock,
          args: PracticeArgs(
            title: 'Little bird, op. 43 nº 4',
            composer: 'Edvard Grieg',
            size: ScoreSize.grande,
          ),
        );
      case '/treino':
        page = PracticeScreen(clock: clock, args: _littleBirdPracticing);
      case '/painel':
        page = PracticeScreen(
          clock: clock,
          args: _littleBirdPracticing,
          startWithPanelOpen: true,
        );
      case '/':
      default:
        page = LibraryScreen(clock: clock);
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
