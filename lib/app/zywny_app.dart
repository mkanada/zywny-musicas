import 'package:flutter/material.dart';
import 'package:zywny/app/home/score_home_page.dart';
import 'package:zywny/app/library_screen.dart';
import 'package:zywny/tutorial/tour_store.dart';
import 'package:zywny_auth/zywny_auth.dart';
import 'package:zywny_comum/app/splash_screen.dart';
import 'package:zywny_comum/auth/auth_gate.dart';
import 'package:zywny_comum/diag/bug_report_scope.dart';
import 'package:zywny_comum/diag/diag_screens.dart';
import 'package:zywny_comum/incoming/incoming_packages.dart';
import 'package:zywny_comum/ui/theme.dart';
import 'package:zywny_clock/zywny_clock.dart';
import 'package:zywny_library/library_term_scope.dart';
import 'package:zywny_library/piece.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.clock,
    this.debugMode = false,
    this.splash = false,
    this.loadCatalog,
    this.tourStore,
    this.incoming,
    this.authStore,
    this.requireNickname = false,
  });

  /// O relógio do app (CT05b): a raiz o passa às telas que criam motores e
  /// cubits de tempo. O `main` passa o do aparelho; os testes, o que pedirem.
  final AppClock clock;

  final bool debugMode;

  /// Splash de abertura (`lib/app/splash_screen.dart`); os testes ficam sem ela.
  final bool splash;

  /// De onde vêm as músicas da biblioteca; sem isto, a biblioteca instalada
  /// e em uso. Os testes trocam por uma lista própria.
  final Future<PieceCatalog> Function()? loadCatalog;

  /// O registro do tutorial de primeiro uso; os testes ficam sem ele (e, com
  /// isso, sem o passeio).
  final TourStore? tourStore;

  /// Os `.zywny` que o sistema entrega ao app (B11); os testes ficam sem.
  final IncomingPackages? incoming;

  /// A sessão conectada (D02): sem ela, o app abre direto (é o caso dos
  /// testes); com ela, o [AuthGate] segura o app até haver conta.
  final AuthStore? authStore;

  /// Perguntar o apelido no primeiro acesso (D-NEG-PRIVACIDADE).
  final bool requireNickname;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zywny',
      navigatorObservers: [DiagScreens.observer],
      // O botão e o gesto de "Reportar bug", em todas as telas.
      builder: (context, child) =>
          BugReportScope(appName: 'musicas', child: child!),
      theme: buildAppTheme(),
      // A tela inicial é a biblioteca de hinos embutidos; a partitura
      // (ScoreHomePage) abre por cima dela, um hino por vez.
      home: SplashOverlay(
        enabled: splash,
        // Sem conta, o app mostra só a tela de entrada (D-NEG-SEM-CONTA).
        child: AuthGate(
          store: authStore,
          requireNickname: requireNickname,
          child: LibraryScreen(
            loadCatalog: loadCatalog,
            tourStore: tourStore,
            authStore: authStore,
            // A abertura (1,8 s mais o esmaecer) cobre a biblioteca: o passeio
            // espera ela sair.
            tourDelay: splash
                ? const Duration(milliseconds: 2400)
                : Duration.zero,
            incoming: incoming,
            incomingDelay: splash
                ? const Duration(milliseconds: 2400)
                : Duration.zero,
            scoreBuilder: (context, opened) => LibraryTermScope(
              term: opened.term,
              numbered: opened.numbered,
              child: ScoreHomePage(
                clock: clock,
                debugMode: debugMode,
                opened: opened,
                tourStore: tourStore,
                authStore: authStore,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
