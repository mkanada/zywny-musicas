// BL13: as transições do PlaybackCubit (lib/app/playback_cubit.dart) sem
// gravura. O player (ScorePlayer) precisa do quadro da tela e fica para
// `playback_controller_test.dart`; aqui, só o estado e o que o som e o
// metrônomo mudam.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:score_bridge/score_bridge.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_midi/midi_device_manager.dart';

import 'support/practice_fakes.dart';

class _NoDevicesMidiCommandPlatform extends MidiCommandPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<MidiDevice>?> get devices async => const <MidiDevice>[];

  @override
  Stream<MidiPacket>? get onMidiDataReceived => null;

  @override
  Stream<MidiSetupChange>? get onMidiSetupChanged => null;
}

/// Um transporte sem gravura, com o som desligado e sem relógio de parede.
PlaybackCubit _transporte() {
  final settings = SettingsCubit();
  final devices = MidiDeviceManager();
  final input = FakeMidiInput();
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
    sound: sound,
    settings: settings,
    controller: ScoreController(),
    wakelock: (_) {},
  );
  return playback;
}

void main() {
  setUpAll(() {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  blocTest<PlaybackCubit, PlaybackState>(
    'setPlaying liga e desliga; o mesmo valor não avisa de novo',
    build: _transporte,
    act: (c) {
      c.setPlaying(true);
      c.setPlaying(true);
      c.setPlaying(false);
    },
    expect: () => [
      isA<PlaybackState>().having((s) => s.playing, 'tocando', true),
      isA<PlaybackState>().having((s) => s.playing, 'tocando', false),
    ],
  );

  blocTest<PlaybackCubit, PlaybackState>(
    'setSpeed põe o andamento no estado',
    build: _transporte,
    act: (c) => c.setSpeed(0.75),
    expect: () => [
      isA<PlaybackState>().having((s) => s.speed, 'andamento', 0.75),
    ],
  );

  blocTest<PlaybackCubit, PlaybackState>(
    'toggleMetronome troca o metrônomo da configuração (o estado do transporte '
    'não muda: a tela ouve as configurações)',
    build: _transporte,
    act: (c) => c.toggleMetronome(),
    expect: () => <PlaybackState>[],
    verify: (c) => expect(c.metronomeOn, isTrue),
  );

  blocTest<PlaybackCubit, PlaybackState>(
    'sem gravura, o loop não muda nada: setLoop e clearLoop calam',
    build: _transporte,
    act: (c) {
      c.setLoop(0, 1);
      c.clearLoop();
    },
    expect: () => <PlaybackState>[],
  );

  test('close para de tocar e fecha o estado', () async {
    final playback = _transporte();
    playback.setPlaying(true);
    expect(playback.state.playing, isTrue);
    await playback.close();
    expect(playback.isClosed, isTrue);
    expect(playback.state.playing, isFalse);
  });
}
