import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Range of the on-screen zoom. It scales the drawn page only — see
/// [_ScoreHomePageState._view] — so it has no bearing on the engraving.
const double kZoomMin = 0.5;
const double kZoomMax = 8.0;

/// Zoom na partitura: fora do celular (tablet, desktop, Web), onde a tela
/// grande e o mouse o tornam útil. No celular ela é fixa, sem arrastar nem
/// ampliar: o tamanho vem do `unit`.
bool get scoreZoomable =>
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

/// Zoom da partitura (fora do celular, onde a tela grande e o mouse o tornam útil).
void zoomBy(TransformationController view, Size viewport, double factor) =>
    zoomTo(view, viewport, view.value.getMaxScaleOnAxis() * factor);

/// Sets the on-screen zoom to [target], keeping the centre of the view
/// where it is.
void zoomTo(TransformationController view, Size viewport, double target) {
  final current = view.value.getMaxScaleOnAxis();
  final factor = target.clamp(kZoomMin, kZoomMax) / current;
  final cx = viewport.width / 2;
  final cy = viewport.height / 2;
  // All three axes, like InteractiveViewer does: getMaxScaleOnAxis() reads
  // the largest of them, so a Z left at 1 would pin the zoom at >= 100%.
  view.value =
      Matrix4.translationValues(cx, cy, 0) *
      Matrix4.diagonal3Values(factor, factor, factor) *
      Matrix4.translationValues(-cx, -cy, 0) *
      view.value;
}

/// Zoom control embedded in [LayoutPanel] (the "Opções" panel) — it used
/// to float over the score, but that hid the score under it on a small
/// window, so it moved in with the rest of the controls.
/// Zoom control embedded in [LayoutPanel] (the "Opções" panel) — it used
/// to float over the score, but that hid the score under it on a small
/// window, so it moved in with the rest of the controls.
Widget zoomControls(TransformationController view, Size Function() viewport) {
  return ValueListenableBuilder<Matrix4>(
    valueListenable: view,
    builder: (context, matrix, _) {
      final scale = matrix.getMaxScaleOnAxis();
      final untouched = matrix.isIdentity();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir zoom',
            onPressed: scale > kZoomMin
                ? () => zoomBy(view, viewport(), 1 / 1.25)
                : null,
            icon: const Icon(Icons.remove),
          ),
          // Logarithmic: equal steps are equal ratios, so 50%→100% takes
          // as much travel as 400%→800%.
          Expanded(
            child: Slider(
              min: math.log(kZoomMin) / math.ln2,
              max: math.log(kZoomMax) / math.ln2,
              value: (math.log(scale) / math.ln2).clamp(
                math.log(kZoomMin) / math.ln2,
                math.log(kZoomMax) / math.ln2,
              ),
              onChanged: (v) =>
                  zoomTo(view, viewport(), math.pow(2, v).toDouble()),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar zoom',
            onPressed: scale < kZoomMax
                ? () => zoomBy(view, viewport(), 1.25)
                : null,
            icon: const Icon(Icons.add),
          ),
          _zoomResetButton(view, scale: scale, untouched: untouched),
        ],
      );
    },
  );
}

/// "Voltar a 100%": a porcentagem atual, que desfaz o zoom quando há algum.
Widget _zoomResetButton(
  TransformationController view, {
  required double scale,
  required bool untouched,
}) {
  return Tooltip(
    message: 'Voltar a 100%',
    child: TextButton(
      onPressed: untouched ? null : () => view.value = Matrix4.identity(),
      child: SizedBox(
        width: 44,
        child: Text('${(scale * 100).round()}%', textAlign: TextAlign.center),
      ),
    ),
  );
}
