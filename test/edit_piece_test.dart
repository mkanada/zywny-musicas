// Editar os dados das músicas e importar MusicXML, na tela da biblioteca.
import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny_library/piece.dart';
import 'package:zywny_library/piece_progress.dart';
import 'package:zywny/app/imported_scores.dart';
import 'package:zywny/app/library_screen.dart';
import 'package:zywny/app/piece_metadata.dart';
import 'package:zywny_comum/ui/theme.dart';

class _NoDevicesMidiCommandPlatform extends MidiCommandPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<MidiDevice>?> get devices async => const <MidiDevice>[];

  @override
  Stream<MidiPacket>? get onMidiDataReceived => null;

  @override
  Stream<MidiSetupChange>? get onMidiSetupChanged => null;
}

Piece _piece(int n, String title) => Piece(
  number: n,
  title: title,
  composer: 'Autor',
  titleKey: foldForSearch(title),
  composerKey: 'autor',
  searchKey: foldForSearch('$n $title autor'),
);

const _xml = '''
<score-partwise version="3.1">
  <work><work-title>Nova Música</work-title></work>
  <identification><creator type="composer">Eu</creator></identification>
  <part-list><score-part id="P1"><part-name>Piano</part-name></score-part>
  </part-list>
</score-partwise>
''';

void main() {
  setUp(() {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Future<({String name, Uint8List bytes})?> Function()? pickMusicXml,
    List<Piece>? pieces,
  }) async {
    tester.view.physicalSize = const Size(760, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LibraryScreen(
          loadCatalog: () async =>
              PieceCatalog(pieces ?? [_piece(1, 'Hino Um')]),
          loadScore: (piece) async => Uint8List(0),
          progress: PieceProgressStore(),
          metadata: PieceMetadataStore(),
          imported: ImportedScoresStore(blobs: MemoryLibraryBlobStore()),
          pickMusicXml: pickMusicXml ?? (() async => null),
          scoreBuilder: (context, o) =>
              const Scaffold(body: Text('partitura')),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Finder dialogFields() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  Future<void> openEditDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Editar dados da música').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar dados da música'), findsOneWidget);
  }

  Future<void> saveDialog(WidgetTester tester) async {
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar dados da música'), findsNothing);
  }

  testWidgets('edita o nome e a lista mostra na hora', (tester) async {
    await pumpLibrary(tester);
    expect(find.text('Hino Um'), findsOneWidget);

    await openEditDialog(tester);
    await tester.enterText(dialogFields().first, 'Hino Novo');
    await saveDialog(tester);

    expect(find.text('Hino Novo'), findsOneWidget);
    expect(find.text('Hino Um'), findsNothing);
  });

  testWidgets('a correção sobrevive a reabrir a tela', (tester) async {
    await pumpLibrary(tester);
    await openEditDialog(tester);
    await tester.enterText(dialogFields().first, 'Hino Novo');
    await saveDialog(tester);

    final store = PieceMetadataStore();
    await store.load('hinos', ['001']);
    expect(store.get('hinos', '001')?.title, 'Hino Novo');
  });

  testWidgets('restaurar volta aos dados do pacote', (tester) async {
    final setup = PieceMetadataStore();
    await setup.save('hinos', '001', const PieceMetadata(title: 'Mudado'));
    await pumpLibrary(tester);
    expect(find.text('Mudado'), findsOneWidget);

    await openEditDialog(tester);
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(find.text('Hino Um'), findsOneWidget);
  });

  testWidgets('cancelar a importação não faz nada', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byTooltip('Importar MusicXML…'));
    await tester.pumpAndSettle();
    expect(find.text('Editar dados da música'), findsNothing);
    expect(find.text('Hino Um'), findsOneWidget);
  });

  testWidgets('arquivo inválido explica e não abre nada', (tester) async {
    await pumpLibrary(
      tester,
      pickMusicXml: () async => (
        name: 'letra.txt',
        bytes: Uint8List.fromList(utf8.encode('só uma letra')),
      ),
    );
    await tester.tap(find.byTooltip('Importar MusicXML…'));
    await tester.pumpAndSettle();
    expect(find.text('Não deu para abrir'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Hino Um'), findsOneWidget);
  });

  testWidgets('importa, confirma os dados e abre a partitura', (tester) async {
    await pumpLibrary(
      tester,
      pickMusicXml: () async => (
        name: 'nova.musicxml',
        bytes: Uint8List.fromList(utf8.encode(_xml)),
      ),
    );
    await tester.tap(find.byTooltip('Importar MusicXML…'));
    await tester.pumpAndSettle();

    // Pré-preenchido com o que veio do arquivo.
    expect(find.text('Editar dados da música'), findsOneWidget);
    expect(find.text('Nova Música'), findsWidgets);
    await saveDialog(tester);

    expect(find.text('partitura'), findsOneWidget);
  });

  testWidgets('a importada entra na lista com os dados editados', (
    tester,
  ) async {
    await pumpLibrary(
      tester,
      pickMusicXml: () async => (
        name: 'nova.musicxml',
        bytes: Uint8List.fromList(utf8.encode(_xml)),
      ),
    );
    await tester.tap(find.byTooltip('Importar MusicXML…'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogFields().first, 'Minha Versão');
    await saveDialog(tester);
    expect(find.text('partitura'), findsOneWidget);

    // Volta à biblioteca: a importada está na lista (e no "Continuar").
    Navigator.of(tester.element(find.text('partitura'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Minha Versão'), findsWidgets);
  });

  testWidgets('apaga a importada pelo diálogo', (tester) async {
    await pumpLibrary(
      tester,
      pickMusicXml: () async => (
        name: 'nova.musicxml',
        bytes: Uint8List.fromList(utf8.encode(_xml)),
      ),
    );
    await tester.tap(find.byTooltip('Importar MusicXML…'));
    await tester.pumpAndSettle();
    await saveDialog(tester);
    expect(find.text('partitura'), findsOneWidget);
    Navigator.of(tester.element(find.text('partitura'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Nova Música'), findsWidgets);

    // Só a importada tem "Apagar" (a importada ordena depois do hino
    // numerado, então é o último botão de editar).
    await tester.tap(find.byTooltip('Editar dados da música').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar importada?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Música'), findsNothing);
    expect(find.text('Hino Um'), findsOneWidget);
  });
}
