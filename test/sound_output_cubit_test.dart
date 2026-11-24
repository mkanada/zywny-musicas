// O Cubit do som da partitura (BL12): as transições do estado, com blocTest.
// Os motores são falsos (como em sound_output_controller_test.dart, que
// cobre o comportamento); aqui o foco é o que o `stream` entrega.

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_midi_command_platform_interface/flutter_midi_command_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_midi/midi_device_manager.dart';
import 'package:zywny_midi/midi_out_sound_engine.dart';

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

class _Sender implements MidiSender {
  @override
  void send(Uint8List data, {String? deviceId}) {}
}

void main() {
  late SettingsCubit settings;
  late MidiDeviceManager devices;
  late FakeMidiInput input;
  late int attached;
  late int detached;
  // O motor que o último `novo()` abriu (o cubit o solta no `close`).
  FakeSoundEngine? motor;

  SoundOutputCubit novo() => SoundOutputCubit(
    settings: settings,
    devices: devices,
    input: input,
    monitorPitch: (r, {required midiKeyboard}) => r,
    playback: SoundOutputPlayback(
      hasTrack: () => true,
      attach: (_, {required always}) => attached++,
      detach: () => detached++,
      endPractice: () {},
    ),
    appEngineFactory: () async => motor = FakeSoundEngine(),
    midiSender: _Sender.new,
  );

  setUp(() async {
    MidiCommandPlatform.instance = _NoDevicesMidiCommandPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    settings = SettingsCubit();
    await settings.load();
    devices = MidiDeviceManager();
    // A primeira listagem (vazia) zeraria o `connected` que os testes põem.
    await pumpEventQueue();
    input = FakeMidiInput();
    attached = 0;
    detached = 0;
    motor = null;
  });

  tearDown(() {
    input.dispose();
    devices.close();
    settings.close();
  });

  group('SoundOutputState', () {
    test('copyWith troca só o campo pedido e é igual pelo conteúdo', () {
      const estado = SoundOutputState(output: SoundOutput.appSynth);

      expect(estado.copyWith(), estado);
      expect(estado.copyWith(soundOn: true).soundOn, isTrue);
      expect(estado.copyWith(soundOn: true).output, SoundOutput.appSynth);
      expect(
        const SoundOutputState(output: SoundOutput.midiKeyboard),
        isNot(estado),
      );
    });
  });

  group('SoundOutputCubit', () {
    blocTest<SoundOutputCubit, SoundOutputState>(
      'ligar o som abre o motor do app: carrega, termina e liga',
      build: novo,
      act: (cubit) => cubit.toggleSound(),
      expect: () => const [
        SoundOutputState(output: SoundOutput.appSynth, loadingSoundFont: true),
        SoundOutputState(output: SoundOutput.appSynth),
        SoundOutputState(output: SoundOutput.appSynth, soundOn: true),
      ],
    );

    blocTest<SoundOutputCubit, SoundOutputState>(
      'desligar o som volta ao mudo e silencia o motor',
      build: novo,
      act: (cubit) async {
        await cubit.toggleSound();
        await cubit.toggleSound();
      },
      expect: () => const [
        SoundOutputState(output: SoundOutput.appSynth, loadingSoundFont: true),
        SoundOutputState(output: SoundOutput.appSynth),
        SoundOutputState(output: SoundOutput.appSynth, soundOn: true),
        SoundOutputState(output: SoundOutput.appSynth),
      ],
      verify: (_) {
        expect(detached, 1);
        expect(motor!.allNotesOffCalls, 1);
      },
    );

    blocTest<SoundOutputCubit, SoundOutputState>(
      'markSoundOn emite uma vez, mesmo chamado de novo',
      build: novo,
      act: (cubit) {
        cubit.markSoundOn();
        cubit.markSoundOn();
      },
      expect: () => const [
        SoundOutputState(output: SoundOutput.appSynth, soundOn: true),
      ],
    );

    blocTest<SoundOutputCubit, SoundOutputState>(
      'trocar a saída nas configurações emite a saída nova (som desligado)',
      build: novo,
      act: (cubit) => settings.setOutput(SoundOutput.midiKeyboard),
      wait: const Duration(milliseconds: 10),
      expect: () => const [SoundOutputState(output: SoundOutput.midiKeyboard)],
    );

    test(
      'trocar de dispositivo MIDI refaz o monitor e sobe o serial',
      () async {
        final cubit = novo();
        addTearDown(cubit.close);
        expect(cubit.state.serial, 0);

        devices.simularConectado(
          MidiDevice('a', 'Teclado a', MidiDeviceType.serial, false),
        );
        await pumpEventQueue();

        expect(cubit.state.serial, 1);
        expect(cubit.midiMonitorOn, isFalse);
      },
    );
  });
}
