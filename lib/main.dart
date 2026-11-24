import 'dart:async';

import 'package:flutter/material.dart';
import 'package:score_bridge/score_bridge.dart';
import 'package:zywny/app/zywny_app.dart';
import 'package:zywny/tutorial/tour_store.dart';
import 'package:zywny_auth/zywny_auth.dart';
import 'package:zywny_comum/about/licenses.dart';
import 'package:zywny_comum/diag/diag_screens.dart';
import 'package:zywny_comum/incoming/incoming_packages.dart';
import 'package:zywny_diag/diag_log.dart';

// O app e a tela de partitura moram em lib/app/; estes reexports são o que os
// testes e o roteiro de telas usam daqui.
export 'package:zywny/app/home/score_home_page.dart' show ScoreHomePage;
export 'package:zywny/app/zywny_app.dart' show MyApp;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await DiagLog.init();
  DiagScreens.registerState();
  // Liberation Serif (the `t` runs of the scene, §5.4) ships inside
  // score_bridge and has to be registered before the first paint —
  // otherwise the engine falls back to a system serif without warning.
  await loadScoreFonts();
  registerBundledLicenses();
  // B11: o `.zywny` que abriu o app (e os que chegarem depois) espera na fila
  // até a biblioteca estar na tela.
  final incoming = IncomingPackages();
  unawaited(listenForIncomingPackages(incoming, args: args));
  // D03: o store de autenticação da plataforma — o SDK do Firebase no Android
  // e na Web, o navegador do sistema no Linux e no Windows. Sem a
  // configuração do Firebase no build, ele é nulo e o app abre direto, sem o
  // portão da conta (é assim que os testes e o roteiro de telas rodam).
  final authStore = await createPlatformAuthStore();
  runApp(
    MyApp(
      debugMode: args.contains('--debug'),
      splash: true,
      tourStore: TourStore(),
      incoming: incoming,
      authStore: authStore,
      // Com conta, o primeiro acesso pergunta o apelido (D-NEG-PRIVACIDADE).
      requireNickname: authStore != null,
    ),
  );
}
