import 'package:flutter/material.dart';
import 'package:zywny_comum/ui/side_panel.dart';

/// A folha "Ir para o compasso" (U07): devolve o compasso escolhido, ou `null`
/// se a pessoa desistiu. [target] é o compasso em que a folha abre e [total]
/// o número de compassos que o deslizador oferece.
Future<int?> pickMeasureJump(
  BuildContext context, {
  required int target,
  required int total,
}) {
  const sidePanel = true;
  var chosen = target;
  return showSheetOrSidePanel<int>(
    context,
    sidePanel: sidePanel,
    title: 'Ir para o compasso',
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => sheetBody(
        sidePanel: sidePanel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...measureJumpControls(
              chosen,
              total,
              (v) => setSheetState(() => chosen = v),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, chosen),
              child: const Text('Ir'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// O aviso "Ir para o compasso N de T" e o deslizador do compasso (o que o
/// botão "Ir" toca). [onChanged] recebe o compasso escolhido.
List<Widget> measureJumpControls(
  int target,
  int total,
  ValueChanged<int> onChanged,
) => [
  Text(
    'Ir para o compasso $target de $total',
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  ),
  Slider(
    value: target.toDouble(),
    min: 1,
    max: total.toDouble(),
    divisions: total > 1 ? total - 1 : null,
    onChanged: (v) => onChanged(v.round()),
  ),
];
