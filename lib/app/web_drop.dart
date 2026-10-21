// Arrastar e soltar arquivos da biblioteca na página (só Web).
//
// `export` condicional, no modelo do `LibraryBlobStore`: na Web vale o
// [WebDropZone] de verdade (`web_drop_web.dart`); nas outras plataformas, um
// que só mostra o filho (`web_drop_stub.dart`).

export 'web_drop_stub.dart'
    if (dart.library.js_interop) 'web_drop_web.dart';
