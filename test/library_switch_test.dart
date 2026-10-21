// Importação visível (.zywny) e troca de biblioteca só com mais de uma.
// B05 (instalar por arquivo), B06 (seção Bibliotecas), B11 (fila de entrada).
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny/app/library_screen.dart';
import 'package:zywny_library/library_store.dart';
import 'package:zywny_comum/ui/theme.dart';

import 'support/library_fixtures.dart';

class _NoDevicesMidiCommandPlatform extends MidiCommandPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<MidiDevice>?> get devices async => const <MidiDevice>[];

  @override
  Stream<MidiPacket>? get onMidiDataReceived => null;

  @override
  Stream<MidiSetupChange>? get onMidiSetupChanged => null;
}

void main() {
  late TestKeys keys;
  late MemoryLibraryBlobStore blobs;
  late LibraryStore store;
  Uint8List? picked;

  setUpAll(() async => keys = await TestKeys.generate());

  setUp(() {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    blobs = MemoryLibraryBlobStore();
    store = LibraryStore(
      blobs: blobs,
      prefs: SharedPreferencesAsync(),
      publicKey: keys.pub,
    );
    picked = null;
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Size size = const Size(760, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LibraryScreen(
          libraryStore: store,
          pickLibraryFile: () async => picked,
          scoreBuilder: (context, o) => const Scaffold(body: Text('x')),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> install(
    String id, {
    String? name,
    String version = '1',
    int pieces = 2,
  }) async {
    await store.load();
    await store.install(
      await keys.package(id, name: name ?? id, version: version, pieces: pieces),
    );
  }

  group('botão de instalar no cabeçalho', () {
    testWidgets('aparece sempre, mesmo com biblioteca instalada', (
      tester,
    ) async {
      await install('hinos', name: 'Hinário');
      await pumpLibrary(tester);
      expect(find.text('T1'), findsOneWidget);
      expect(
        find.byTooltip('Instalar biblioteca (.zywny)…'),
        findsOneWidget,
      );
    });

    testWidgets('instala pelo cabeçalho e vira a em uso', (tester) async {
      await pumpLibrary(tester);
      expect(find.text('Instale uma biblioteca de músicas'), findsOneWidget);
      picked = await keys.package('hinos', name: 'Hinário', pieces: 3);
      await tester.tap(find.byTooltip('Instalar biblioteca (.zywny)…'));
      await tester.pumpAndSettle();
      expect(find.text('Hinário instalada (3 hinos)'), findsOneWidget);
      expect(store.activeId, 'hinos');
      expect(find.text('T1'), findsOneWidget);
    });
  });

  group('troca de biblioteca no cabeçalho', () {
    testWidgets('só aparece com mais de uma instalada', (tester) async {
      await install('hinos', name: 'Hinário');
      await pumpLibrary(tester);
      expect(
        find.byTooltip('Trocar de biblioteca…'),
        findsNothing,
      );
    });

    testWidgets('abre o diálogo, troca e a lista acompanha', (tester) async {
      await install('hinos', name: 'Hinário', pieces: 3);
      await install('classicos', name: 'Clássicos', pieces: 2);
      expect(store.activeId, 'classicos');
      await pumpLibrary(tester);
      expect(find.textContaining('Clássicos'), findsOneWidget);

      await tester.tap(find.byTooltip('Trocar de biblioteca…'));
      await tester.pumpAndSettle();
      expect(find.text('Bibliotecas'), findsWidgets);
      expect(find.text('Hinário'), findsOneWidget);
      expect(find.textContaining('Clássicos'), findsWidgets);

      await tester.tap(find.text('Hinário'));
      await tester.pumpAndSettle();
      expect(store.activeId, 'hinos');

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hinário'), findsOneWidget);
      expect(find.textContaining('Clássicos'), findsNothing);
    });

    testWidgets('em 360 dp não estoura', (tester) async {
      await install('hinos', name: 'Hinário', pieces: 3);
      await install('classicos', name: 'Clássicos', pieces: 2);
      await pumpLibrary(tester, size: const Size(360, 640));
      expect(find.byTooltip('Trocar de biblioteca…'), findsOneWidget);
      expect(
        find.byTooltip('Instalar biblioteca (.zywny)…'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('uma só instalada (sem seleção)', () {
    testWidgets('nas configurações: sem rádio, com instalar e remover', (
      tester,
    ) async {
      await install('hinos', name: 'Hinário', pieces: 3);
      await pumpLibrary(tester);
      await tester.tap(find.byTooltip('Configurações gerais'));
      await tester.pumpAndSettle();

      expect(find.text('Bibliotecas'), findsOneWidget);
      expect(find.text('Hinário'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      expect(find.text('Instalar outra…'), findsOneWidget);

      await tester.tap(find.byTooltip('Mais sobre Hinário'));
      await tester.pumpAndSettle();
      expect(find.text('Sobre esta biblioteca'), findsOneWidget);
      expect(find.text('Remover…'), findsOneWidget);
    });
  });
}
