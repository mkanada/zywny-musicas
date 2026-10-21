// Fora da Web: sem arrastar-e-soltar; só mostra o filho.

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/widgets.dart';

/// Recebe os arquivos soltos na página. Fora da Web nunca é chamado.
typedef OnWebFiles =
    void Function(List<({String name, Uint8List bytes})> files);

/// Na Web, `web_drop_web.dart` troca este pelo que escuta o `drop` de
/// verdade; aqui, só o filho.
class WebDropZone extends StatelessWidget {
  const WebDropZone({
    super.key,
    required this.child,
    required this.onFiles,
  });

  final Widget child;

  /// Nunca chamado fora da Web; mantido para a assinatura ser a mesma.
  final OnWebFiles onFiles;

  @override
  Widget build(BuildContext context) => child;
}
