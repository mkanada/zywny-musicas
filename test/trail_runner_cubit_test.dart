// BL13: as transições do TrailRunnerCubit (lib/app/trail_runner_cubit.dart)
// sem partitura. A trilha e o treino de verdade (com o Gymnopédie e o aluno
// que toca) ficam em `trail_runner_test.dart`; aqui, o que o estado guarda:
// a latência, o N do hino, a revisão e as marcas de erro.

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:score_bridge/score_bridge.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_library/library_package.dart' show LibraryTerm;
import 'package:zywny_midi/midi_device_manager.dart';
import 'package:zywny_comum/practice/shift_detector.dart';
import 'package:zywny_comum/settings/piece_settings.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/stage_result.dart';
import 'package:zywny_comum/trail/trail_progress_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart' show StageSummaryAction;
import 'package:zywny_clock/zywny_clock.dart';

import 'support/practice_fakes.dart';
import 'support/score_page_fakes.dart';

class _NoDevicesMidiCommandPlatform extends MidiCommandPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<MidiDevice>?> get devices async => const <MidiDevice>[];

  @override
  Stream<MidiPacket>? get onMidiDataReceived => null;

  @override
  Stream<MidiSetupChange>? get onMidiSetupChanged => null;
}

Future<StageSummaryAction?> _semResumo({
  required String stageRef,
  required StageResult result,
  required List<int> badLogical,
  required bool isLast,
  int? blockCount,
}) async => null;

/// A trilha de um hino sem gravura: a sessão ainda não renderizou nada, então
/// [TrailRunnerCubit.setup] não monta trilha.
TrailRunnerCubit _trilha({int? pieceN}) {
  final settings = SettingsCubit();
  final devices = MidiDeviceManager();
  final input = FakeMidiInput();
  final scores = ScoreCubit();
  final piece = fakePiece();
  final session = ScoreRenderCubit(
    clock: SystemClock(),
    renderer: RecordingRenderer(),
    scoreXml: Uint8List(1),
    piece: piece,
    settings: settings,
    stored: const PieceSettings(),
    name: 'Hino',
  );
  late final PlaybackCubit playback;
  final sound = SoundOutputCubit(
    settings: settings,
    devices: devices,
    input: input,
    monitorPitch: (r, {required midiKeyboard}) => r,
    playback: SoundOutputPlayback(
      hasTrack: () => playback.track != null,
      attach: (engine, {required always}) =>
          playback.attachSound(engine, always: always),
      detach: () => playback.detachSound(),
      endPractice: () {},
    ),
  );
  playback = PlaybackCubit(
    clock: ManualClock(DateTime(2026)),
    sound: sound,
    settings: settings,
    controller: scores,
    wakelock: (_) {},
  );
  return TrailRunnerCubit(
    clock: ManualClock(DateTime(2026)),
    store: TrailProgressCubit(),
    playback: playback,
    session: session,
    sound: sound,
    settings: settings,
    devices: devices,
    midiInput: input,
    piece: piece,
    term: const LibraryTerm(singular: 'hino', plural: 'hinos', feminine: false),
    scores: scores,
    ghosts: GhostCubit(),
    shiftDetector: ShiftDetector(enabled: () => false),
    onShift: (_) {},
    writtenFromReceived: (r) => r,
    inputLatency: () async => 0,
    pieceN: pieceN,
    host: TrailRunnerHost(
      stageSummary: _semResumo,
      conclusion: () async => null,
      backToLibrary: () {},
      practiceReport: (_) {},
    ),
  );
}

void main() {
  setUpAll(() {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  blocTest<TrailRunnerCubit, TrailRunnerState>(
    'setInputLatency guarda a latência calibrada no estado',
    build: _trilha,
    act: (c) => c.setInputLatency(12.5),
    expect: () => [
      isA<TrailRunnerState>().having((s) => s.inputLatencyMs, 'latência', 12.5),
    ],
  );

  blocTest<TrailRunnerCubit, TrailRunnerState>(
    'a revisão sem notas erradas não abre e não avisa',
    build: _trilha,
    act: (c) => c.startReview(),
    expect: () => <TrailRunnerState>[],
  );

  blocTest<TrailRunnerCubit, TrailRunnerState>(
    'sem marcas de erro, limpar não avisa; sem gravura, marcar não faz nada',
    build: _trilha,
    act: (c) {
      c.clearErrorMarks();
      c.markErrors([0]);
    },
    expect: () => <TrailRunnerState>[],
  );

  blocTest<TrailRunnerCubit, TrailRunnerState>(
    'setPieceN troca o N do hino no estado e a trilha sem gravura fica vazia',
    build: _trilha,
    act: (c) => c.setPieceN(5, confirm: () async => true),
    wait: const Duration(milliseconds: 10),
    verify: (c) {
      expect(c.pieceN, 5);
      expect(c.trail, isNull);
      expect(c.unavailable, isNull);
    },
  );

  blocTest<TrailRunnerCubit, TrailRunnerState>(
    'o N guardado do hino já vem no estado desde o começo',
    build: () => _trilha(pieceN: 12),
    verify: (c) => expect(c.state.pieceN, 12),
  );

  test('close solta a trilha e fecha o estado', () async {
    final c = _trilha();
    await c.close();
    expect(c.isClosed, isTrue);
    expect(c.trail, isNull);
  });
}
