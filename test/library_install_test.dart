// B05 — a tela sem biblioteca e a instalação de `.zywny`.
//
// O app não tem seletor de `.zywny`: o arquivo chega pelo "Abrir com…" do
// sistema (ou, na web, solto na página). O cartão de quando não há
// biblioteca só explica isso, sem botão.
import 'package:flutter/material.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/library_blob_store.dart';
import 'package:zywny/app/library_screen.dart';
import 'package:zywny_comum/incoming/incoming_packages.dart';
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
  late IncomingPackages incoming;

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
    incoming = IncomingPackages();
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
          incoming: incoming,
          scoreBuilder: (context, o) => const Scaffold(body: Text('x')),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('sem biblioteca: explica o "Abrir com…", sem botão de abrir', (
    tester,
  ) async {
    await pumpLibrary(tester);
    expect(find.text('Instale uma biblioteca de músicas'), findsOneWidget);
    expect(find.textContaining('.zywny'), findsOneWidget);
    expect(find.text('Abrir arquivo…'), findsNothing);
    expect(find.byTooltip('Instalar biblioteca (.zywny)…'), findsNothing);
    expect(find.text('COMECE POR AQUI'), findsNothing);
    // D-BIB-DIST: nenhuma menção a onde baixar.
    expect(find.textContaining('http'), findsNothing);
    expect(find.textContaining('baixar'), findsNothing);
  });

  testWidgets('em 360 dp o cartão não estoura', (tester) async {
    await pumpLibrary(tester, size: const Size(360, 640));
    expect(find.text('Instale uma biblioteca de músicas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
