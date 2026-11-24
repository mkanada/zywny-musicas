import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zywny_comum/ui/device_kind.dart';
import 'package:zywny_comum/ui/orientation.dart';

/// A orientação e a barra de status da partitura. No desktop não valem.
void applyScoreOrientation(DeviceKind kind) {
  if (kind == DeviceKind.desktop) return;
  // A partitura é para ler em paisagem no celular (a biblioteca, em
  // retrato, volta a travar a orientação dela quando esta tela fecha); no
  // tablet ela segue o aparelho, em pé ou deitada.
  unawaited(
    SystemChrome.setPreferredOrientations(
      kind == DeviceKind.phone
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : kFollowDeviceOrientations,
    ),
  );
  // Modo imersivo (U10): a barra de status sai e a página é gravada,
  // desde a primeira vez, para a caixa inteira (pedido aqui para não
  // mudar a caixa e regravar o hino depois).
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
}

/// Ao sair da partitura, a barra de status volta (no desktop não vale).
void restoreEdgeToEdge(DeviceKind kind) {
  if (kind != DeviceKind.desktop) {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }
}
