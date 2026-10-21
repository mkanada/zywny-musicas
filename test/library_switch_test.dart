// Importação visível (.zywny) e troca de biblioteca só com mais de uma.
// B05 (instalar por arquivo), B06 (seção Bibliotecas), B11 (fila de entrada).
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
      await keys.package(
        id,
        name: name ?? id,
        version: version,
        pieces: pieces,
      ),
    );
  }

  group('sem seletor de .zywny no app', () {
    testWidgets('nem com biblioteca instalada, nem sem ela', (tester) async {
      await install('hinos', name: 'Hinário');
      await pumpLibrary(tester);
      expect(find.byTooltip('Instalar biblioteca (.zywny)…'), findsNothing);
      expect(find.text('Abrir arquivo…'), findsNothing);
    });

    testWidgets('o cartão vazio só explica o "Abrir com…"', (tester) async {
      await pumpLibrary(tester);
      expect(find.text('Instale uma biblioteca de músicas'), findsOneWidget);
      expect(find.textContaining('Abrir com'), findsOneWidget);
      expect(find.text('Abrir arquivo…'), findsNothing);
      expect(find.byTooltip('Instalar biblioteca (.zywny)…'), findsNothing);
    });
  });

  group('bibliotecas no cabeçalho', () {
    testWidgets('sempre visível, mesmo com uma só instalada', (tester) async {
      await install('hinos', name: 'Hinário');
      await pumpLibrary(tester);
      expect(find.byTooltip('Bibliotecas…'), findsOneWidget);
    });

    testWidgets('com uma só: sem seleção e sem instalar', (tester) async {
      await install('hinos', name: 'Hinário');
      await pumpLibrary(tester);
      await tester.tap(find.byTooltip('Bibliotecas…'));
      await tester.pumpAndSettle();
      expect(find.text('Bibliotecas'), findsWidgets);
      expect(find.text('Hinário'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      expect(find.text('Instalar outra…'), findsNothing);
    });

    testWidgets('remover a em uso passa para a que sobra', (tester) async {
      await install('hinos', name: 'Hinário', pieces: 3);
      await install('classicos', name: 'Clássicos', pieces: 2);
      await pumpLibrary(tester);
      await tester.tap(find.byTooltip('Bibliotecas…'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais sobre Clássicos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(store.activeId, 'hinos');
      expect(store.installed.map((e) => e.id), ['hinos']);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.text('T3'), findsOneWidget);
    });

    testWidgets('Sobre mostra os créditos', (tester) async {
      await install('hinos', name: 'Hinário', version: '2026.10.04', pieces: 3);
      await pumpLibrary(tester);
      await tester.tap(find.byTooltip('Bibliotecas…'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais sobre Hinário'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sobre esta biblioteca'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Versão 2026.10.04'), findsOneWidget);
      expect(find.textContaining('Créditos do teste.'), findsOneWidget);
    });

    testWidgets('abre o diálogo, troca e a lista acompanha', (tester) async {
      await install('hinos', name: 'Hinário', pieces: 3);
      await install('classicos', name: 'Clássicos', pieces: 2);
      expect(store.activeId, 'classicos');
      await pumpLibrary(tester);
      expect(find.textContaining('Clássicos'), findsOneWidget);

      await tester.tap(find.byTooltip('Bibliotecas…'));
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
      expect(find.byTooltip('Bibliotecas…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
