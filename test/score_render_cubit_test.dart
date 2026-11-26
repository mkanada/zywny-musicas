// BL13: as transições do ScoreRenderCubit (lib/app/score_render_cubit.dart),
// com o renderer de mentira da tela de testes. A fila e o respiro da caixa
// ficam em `score_render_session_test.dart`.

import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny_comum/settings/piece_settings.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';

import 'support/score_page_fakes.dart';

import 'package:zywny_clock/zywny_clock.dart';

ScoreRenderCubit _gravura({RecordingRenderer? renderer}) => ScoreRenderCubit(
  clock: SystemClock(),
  renderer: renderer ?? RecordingRenderer(),
  scoreXml: Uint8List(1),
  piece: fakePiece(),
  settings: SettingsCubit(),
  stored: const PieceSettings(),
  name: '13 · Hino',
  resizeDebounce: const Duration(milliseconds: 20),
);

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'setLayoutValue guarda a mudança da pessoa no estado',
    build: _gravura,
    act: (c) => c.setLayoutValue('unit', 6.5),
    expect: () => [
      isA<ScoreRenderState>().having((s) => s.layoutOverrides, 'mudanças', {
        'unit': 6.5,
      }),
    ],
  );

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'layout: a mudança, a página fixa e o padrão de volta, um aviso cada',
    build: _gravura,
    act: (c) {
      c.setLayoutValue('unit', 6.5);
      c.setPageFitsBox(false);
      c.resetLayout();
    },
    expect: () => [
      isA<ScoreRenderState>().having((s) => s.layoutOverrides, 'mudanças', {
        'unit': 6.5,
      }),
      isA<ScoreRenderState>().having(
        (s) => s.pageFitsBox,
        'cabe na caixa',
        false,
      ),
      isA<ScoreRenderState>()
          .having((s) => s.layoutOverrides, 'mudanças', <String, Object>{})
          .having((s) => s.pageFitsBox, 'cabe na caixa', true),
    ],
  );

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'chooseTranspose: uma escolha nova avisa; a mesma escolha não',
    build: _gravura,
    act: (c) {
      c.chooseTranspose(kTransposeNone);
      c.chooseTranspose(kTransposeNone);
    },
    expect: () => [
      isA<ScoreRenderState>().having(
        (s) => s.transposeChoice,
        'tom',
        kTransposeNone,
      ),
    ],
  );

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'setPage sem gravura não muda nada',
    build: _gravura,
    act: (c) => c.setPage(2),
    expect: () => <ScoreRenderState>[],
  );

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'com caixa, a primeira gravura chega ao estado e o render acaba parado',
    build: () => _gravura()..setBox(const Size(1000, 700)),
    wait: const Duration(milliseconds: 60),
    verify: (c) {
      expect(c.document, isNotNull);
      expect(c.track, isNotNull);
      expect(c.busy, isFalse);
      expect(c.error, isNull);
    },
  );

  blocTest<ScoreRenderCubit, ScoreRenderState>(
    'gravura sem páginas: o erro vai ao estado e a página de antes fica',
    build: () {
      final renderer = RecordingRenderer()..next = RecordingRenderer().empty;
      return _gravura(renderer: renderer)..setBox(const Size(1000, 700));
    },
    wait: const Duration(milliseconds: 60),
    verify: (c) {
      expect(c.error, contains('sem páginas'));
      expect(c.document, isNull);
      expect(c.busy, isFalse);
    },
  );

  test('close fecha o estado e descarta a caixa', () async {
    final c = _gravura();
    await c.close();
    expect(c.isClosed, isTrue);
  });

  test('boxSeen avisa os ouvintes sem mudar nenhum campo (BL14b)', () async {
    final c = _gravura();
    final avisos = <ScoreRenderState>[];
    final sub = c.stream.listen(avisos.add);
    c.boxSeen();
    await Future<void>.delayed(Duration.zero);
    expect(avisos, hasLength(1));
    expect(avisos.single.serial, 1);
    expect(avisos.single.document, c.state.document);
    await sub.cancel();
    await c.close();
  });
}
