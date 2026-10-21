// As configurações gerais não gerenciam mais bibliotecas: a seção saiu
// daqui para o diálogo "Bibliotecas…" do cabeçalho. Fica o que é do painel
// (som, MIDI, cores, conta, tutorial).
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
import 'package:zywny_library/piece.dart';
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

  setUp(() async {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    blobs = MemoryLibraryBlobStore();
    store = LibraryStore(
      blobs: blobs,
      prefs: SharedPreferencesAsync(),
      publicKey: keys.pub,
    );
    await store.load();
    await store.install(
      await keys.package('hinos', name: 'Hinário', pieces: 2),
    );
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Configurações gerais'));
    await tester.pumpAndSettle();
  }

  Future<void> closeSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
  }

  testWidgets('sem seção Bibliotecas: gerência fica no diálogo do cabeçalho', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 1400);
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
    await tester.pumpAndSettle();
    await openSettings(tester);
    expect(find.text('Bibliotecas'), findsNothing);
    expect(find.text('Instalar outra…'), findsNothing);
    // O diálogo do cabeçalho continua com a lista (sem seletor de arquivo).
    await closeSettings(tester);
    await tester.tap(find.byTooltip('Bibliotecas…'));
    await tester.pumpAndSettle();
    expect(find.text('Bibliotecas'), findsWidgets);
    expect(find.text('Hinário'), findsOneWidget);
    expect(find.text('Instalar outra…'), findsNothing);
  });

  testWidgets('sem trocar nada, fechar o painel não recarrega', (tester) async {
    var loads = 0;
    tester.view.physicalSize = const Size(760, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LibraryScreen(
          libraryStore: store,
          loadCatalog: () async {
            loads++;
            return const PieceCatalog([]);
          },
          scoreBuilder: (context, o) => const Scaffold(body: Text('x')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openSettings(tester);
    await closeSettings(tester);
    expect(loads, 1);
  });
}
