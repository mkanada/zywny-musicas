// D02 — o portão da autenticação: sem conta o app mostra só a tela de
// entrada (D-NEG-SEM-CONTA); com a sessão vencida (7 dias sem rede,
// D-NEG-OFFLINE) ele pede conexão; e a conta pode ser trocada ou apagada
// pelas configurações (a LGPD, D-NEG-PRIVACIDADE).
//
// O store é o de mentira do `zywny_auth` (D01): nenhum teste tem rede nem
// Firebase configurado.

import 'package:flutter/material.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:zywny/main.dart';
import 'package:zywny_auth/zywny_auth.dart';
import 'package:zywny_comum/auth/account_settings_section.dart';
import 'package:zywny_comum/auth/sign_in_screen.dart';
import 'package:zywny_comum/ui/theme.dart';
import 'package:zywny_library/piece.dart';

class _NoDevicesMidiCommandPlatform extends MidiCommandPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<MidiDevice>?> get devices async => const <MidiDevice>[];

  @override
  Stream<MidiPacket>? get onMidiDataReceived => null;

  @override
  Stream<MidiSetupChange>? get onMidiSetupChanged => null;
}

final _piece = Piece(
  number: 244,
  title: 'Ó Vem à Igreja Comigo',
  composer: 'William J. Pitts',
  titleKey: 'ovem a igreja comigo',
  composerKey: 'william j pits',
  searchKey: '244 o vem a igreja comigo william j pits',
);

Future<PieceCatalog> _loadCatalog() async => PieceCatalog([_piece]);

void main() {
  setUp(() {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  /// O app inteiro, com a sessão-connecteda dada.
  Future<void> pumpApp(
    WidgetTester tester,
    AuthStore store, {
    bool requireNickname = false,
  }) async {
    tester.view.physicalSize = const Size(760, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyApp(
        loadCatalog: _loadCatalog,
        authStore: store,
        requireNickname: requireNickname,
      ),
    );
    await tester.pump();
  }

  /// A biblioteca aberta (a engrenagem das configurações).
  Finder libraryButton() => find.byTooltip('Configurações gerais');

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(libraryButton());
    await tester.pumpAndSettle();
  }

  testWidgets('sem conta, o app mostra só a tela de entrada', (tester) async {
    await pumpApp(tester, FakeAuthStore.loggedOut());

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    // A biblioteca não abre: sem conta, o app não passa.
    expect(libraryButton(), findsNothing);
  });

  testWidgets('entrar com Google abre a biblioteca', (tester) async {
    final store = FakeAuthStore.loggedOut();
    await pumpApp(tester, store);

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(store.signInCalls, 1);
    expect(store.lastProvider, SocialProvider.google);
    expect(find.byType(SignInScreen), findsNothing);
    expect(libraryButton(), findsOneWidget);
  });

  testWidgets('passados 7 dias sem internet, o app pede conexão', (
    tester,
  ) async {
    final store = FakeAuthStore.offlineExpired();
    await pumpApp(tester, store);

    expect(
      find.textContaining('Faz mais de 7 dias sem conexão'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(libraryButton(), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(store.refreshCalls, 1);
    expect(find.byType(SignInScreen), findsNothing);
    expect(libraryButton(), findsOneWidget);
  });

  testWidgets('trocar de conta na reconexão volta para a entrada', (
    tester,
  ) async {
    final store = FakeAuthStore.offlineExpired();
    await pumpApp(tester, store);

    await tester.tap(find.text('Trocar de conta'));
    await tester.pumpAndSettle();

    expect(store.signOutCalls, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('no primeiro acesso o app pergunta o apelido', (tester) async {
    final store = FakeAuthStore.loggedIn();
    await pumpApp(tester, store, requireNickname: true);

    expect(find.text('Como você quer ser chamado?'), findsOneWidget);
    expect(libraryButton(), findsNothing);

    // Sem o aceite, o botão não anda.
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(store.lastNickname, 'Ana');
    expect(libraryButton(), findsOneWidget);
  });

  testWidgets('as configurações mostram a conta e o código do aluno', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthStore.loggedIn());
    await openSettings(tester);

    expect(find.text('Conta'), findsOneWidget);
    expect(find.text('Apelido'), findsOneWidget);
    expect(find.text('aluno@zywny.app'), findsOneWidget);
    // O código que o tutor digita para vincular a conta.
    expect(find.text('FAKE-UID0'), findsOneWidget);
  });

  testWidgets('o apelido pode ser trocado pelas configurações', (tester) async {
    final store = FakeAuthStore.loggedIn(nickname: 'Ana');
    await pumpApp(tester, store);
    await openSettings(tester);

    expect(find.text('Ana'), findsOneWidget);
    await tester.tap(find.text('Alterar'));
    await tester.pumpAndSettle();
    expect(find.text('Seu apelido'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bia');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(store.lastNickname, 'Bia');
    expect(find.text('Bia'), findsOneWidget);
  });

  testWidgets('sair da conta pelas configurações volta para a entrada', (
    tester,
  ) async {
    final store = FakeAuthStore.loggedIn();
    await pumpApp(tester, store);
    await openSettings(tester);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(store.signOutCalls, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(libraryButton(), findsNothing);
  });

  testWidgets('apagar a conta pelas configurações volta para a entrada', (
    tester,
  ) async {
    final store = FakeAuthStore.loggedIn();
    await pumpApp(tester, store);
    await openSettings(tester);

    await tester.tap(find.text('Apagar minha conta e meus dados'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar minha conta?'), findsOneWidget);

    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(store.deleteAccountCalls, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  test('o código do aluno sai do identificador da conta', () {
    expect(studentCodeFor('abcdefghijkl'), 'ABCD-EFGH');
    expect(studentCodeFor('abc'), 'ABC0-0000');
    // O mesmo uid dá sempre o mesmo código.
    expect(studentCodeFor('uid-1'), studentCodeFor('uid-1'));
  });

  testWidgets('a tela de entrada cabe no celular deitado e no desktop', (
    tester,
  ) async {
    for (final size in const [
      Size(640, 360), // celular deitado
      Size(360, 640), // celular em pé
      Size(1280, 800), // desktop
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: SignInScreen(store: FakeAuthStore.loggedOut()),
        ),
      );
      await tester.pump();
      expect(find.text('Entrar com Google'), findsOneWidget, reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
    addTearDown(tester.view.reset);
  });
}
