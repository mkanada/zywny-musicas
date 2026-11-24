// Na Web: soltar `.zywny` em qualquer ponto da página instala como se
// tivesse saído do "Abrir arquivo…" (a validação recusa o que não serve).
// O navegador navegaria para o arquivo sem o `preventDefault` no `dragover`.

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:zywny_bloc/zywny_bloc.dart';

import 'web_drop_cubit.dart';
import 'web_drop_stub.dart' show OnWebFiles;

/// Recebe os arquivos soltos na página; o destaque mostra onde soltar. O
/// contador do destaque é o [WebDropCubit], que fica acima dos ouvintes.
class WebDropZone extends StatelessWidget {
  const WebDropZone({super.key, required this.child, required this.onFiles});

  final Widget child;
  final OnWebFiles onFiles;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WebDropCubit(),
    child: _WebDropListeners(onFiles: onFiles, child: child),
  );
}

/// Os ouvintes de `dragenter`, `dragover`, `dragleave` e `drop` no documento.
/// É StatefulWidget só por eles: o registro no DOM se desfaz no dispose (como
/// o WidgetsBindingObserver). Não guarda estado: o destaque é do WebDropCubit.
class _WebDropListeners extends StatefulWidget {
  const _WebDropListeners({required this.child, required this.onFiles});

  final Widget child;
  final OnWebFiles onFiles;

  @override
  State<_WebDropListeners> createState() => _WebDropListenersState();
}

class _WebDropListenersState extends State<_WebDropListeners> {
  static bool _hasFiles(web.DragEvent event) =>
      event.dataTransfer?.types.toDart.any((type) => type.toDart == 'Files') ??
      false;

  late final JSFunction _onDragEnter = ((web.Event event) {
    if (_hasFiles(event as web.DragEvent)) {
      event.preventDefault();
      context.read<WebDropCubit>().entrou();
    }
  }).toJS;

  late final JSFunction _onDragOver = ((web.Event event) {
    event.preventDefault();
    final transfer = (event as web.DragEvent).dataTransfer;
    if (transfer != null) transfer.dropEffect = 'copy';
  }).toJS;

  // `dragenter`/`dragleave` disparam nos filhos também: só sem ninguém por
  // cima o destaque apaga (o WebDropCubit conta).
  late final JSFunction _onDragLeave = ((web.Event event) {
    if (mounted) context.read<WebDropCubit>().saiu();
  }).toJS;

  late final JSFunction _onDrop = ((web.Event event) {
    event.preventDefault();
    if (mounted) context.read<WebDropCubit>().soltou();
    final files = (event as web.DragEvent).dataTransfer?.files;
    if (files == null || files.length == 0) return;
    unawaited(_readAll(files));
  }).toJS;

  @override
  void initState() {
    super.initState();
    final element = web.document.documentElement;
    element?.addEventListener('dragenter', _onDragEnter);
    element?.addEventListener('dragover', _onDragOver);
    element?.addEventListener('dragleave', _onDragLeave);
    element?.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    final element = web.document.documentElement;
    element?.removeEventListener('dragenter', _onDragEnter);
    element?.removeEventListener('dragover', _onDragOver);
    element?.removeEventListener('dragleave', _onDragLeave);
    element?.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  Future<void> _readAll(web.FileList files) async {
    final read = <({String name, Uint8List bytes})>[];
    for (var i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null) continue;
      try {
        final jsBuffer = await file.arrayBuffer().toDart;
        final buffer = jsBuffer.toDart;
        read.add((name: file.name, bytes: buffer.asUint8List()));
      } on Object {
        // Um arquivo ilegível não impede os outros; a validação do pacote
        // explica na tela o que chegou vazio ou quebrado.
      }
    }
    if (read.isNotEmpty && mounted) widget.onFiles(read);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WebDropCubit, WebDropState, bool>(
      selector: (state) => state.arrastando,
      builder: (context, arrastando) => Stack(
        children: [
          widget.child,
          if (arrastando)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x99000000),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Solte para instalar a biblioteca',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
