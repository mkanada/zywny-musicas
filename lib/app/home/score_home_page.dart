import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart' show MidiDevice;
import 'package:score_bridge/score_bridge.dart';
import 'package:zywny/app/home/score_measure_jump.dart';
import 'package:zywny/app/home/score_mode_cubit.dart';
import 'package:zywny/app/home/score_options_drawer.dart';
import 'package:zywny/app/home/score_overlays.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';
import 'package:zywny/app/home/score_phone_rail.dart';
import 'package:zywny/app/home/score_phone_title_bar.dart';
import 'package:zywny/app/home/score_shift_notice_cubit.dart';
import 'package:zywny/app/home/score_system_ui.dart';
import 'package:zywny/app/home/score_trail_drawer.dart';
import 'package:zywny/app/home/score_zoom.dart';
import 'package:zywny/app/library_screen.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny/tutorial/score_tour.dart';
import 'package:zywny/tutorial/tour.dart';
import 'package:zywny/tutorial/tour_store.dart';
import 'package:zywny_audio/performance_track.dart';
import 'package:zywny_audio/sound_engine.dart';
import 'package:zywny_auth/zywny_auth.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/app/general_settings_panel.dart';
import 'package:zywny_comum/app/layout_panel.dart';
import 'package:zywny_comum/audio/sound_engine_debug_panel.dart';
import 'package:zywny_comum/diag/diag_score_watch.dart';
import 'package:zywny_comum/diag/diag_screens.dart';
import 'package:zywny_comum/midi/midi_monitor_panel.dart';
import 'package:zywny_comum/practice/count_in_overlay.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/practice/practice_controller.dart';
import 'package:zywny_comum/practice/practice_report.dart';
import 'package:zywny_comum/practice/practice_tools.dart';
import 'package:zywny_comum/practice/shift_banner.dart';
import 'package:zywny_comum/practice/shift_detector.dart';
import 'package:zywny_comum/practice/study_mode.dart';
import 'package:zywny_comum/practice/transpose_check.dart';
import 'package:zywny_comum/render/score_renderer.dart';
import 'package:zywny_comum/render/score_size_log.dart';
import 'package:zywny_comum/settings/piece_settings.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/trail_progress_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart';
import 'package:zywny_comum/ui/device_kind.dart';
import 'package:zywny_comum/ui/score_paging.dart';
import 'package:zywny_comum/settings/effective_transposition.dart';
import 'package:zywny_comum/ui/side_panel.dart';
import 'package:zywny_comum/ui/theme.dart';
import 'package:zywny_comum/ui/transpose_widgets.dart';
import 'package:zywny_diag/diag_log.dart';
import 'package:zywny_library/library_package.dart' show LibraryTerm;
import 'package:zywny_library/piece.dart';
import 'package:zywny_midi/midi_device_manager.dart';
import 'package:zywny_midi/midi_input_service.dart';
import 'package:zywny_midi/midi_monitor.dart';
import 'package:zywny_midi/midi_out_sound_engine.dart';
import 'package:zywny_music/pitch_frame.dart';
import 'package:zywny_music/tone_choices.dart';

/// A tela da partitura de um hino: gravura, tocar, treino, trilha e as
/// gavetas. O estado vive em Cubits (BL14b): a gravura, o som, a reprodução,
/// a trilha e as configurações vêm da biblioteca ou são criados aqui; as
/// gavetas, o modo e o aviso da faixa são desta tela. O que fica no State é
/// o que é do framework (a vista, o zoom, o controlador da partitura).
class ScoreHomePage extends StatefulWidget {
  const ScoreHomePage({
    super.key,
    required this.opened,
    this.debugMode = false,
    this.renderer,
    this.tourStore,
    this.authStore,
  });

  /// O registro do tutorial de primeiro uso (`lib/tutorial/`); `null` (os
  /// testes) é sem passeio.
  final TourStore? tourStore;

  /// A sessão conectada (D02): o painel das configurações gerais mostra a
  /// seção "Conta" quando há uma.
  final AuthStore? authStore;

  /// Quem grava a partitura. Só os testes passam o seu; o app usa o da
  /// plataforma ([createScoreRenderer]).
  @visibleForTesting
  final ScoreRenderer? renderer;

  /// O hino que a biblioteca abriu, com os recursos que ela compartilha
  /// (configurações, trilha, MIDI): são dela, e é ela quem os descarta. Os
  /// testes passam um feito de fakes (`test/support/score_page_fakes.dart`).
  final OpenedPiece opened;

  /// `--debug` on the command line: asks Verovio to also embed the
  /// effective options and source document inside the rendered `.vsb`
  /// (`vsbDebug`, score_bridge's own debug mode), so a render can be
  /// reproduced from the `.vsb` alone.
  final bool debugMode;

  @override
  State<ScoreHomePage> createState() => _ScoreHomePageState();
}

/// A ponte entre o [ShiftNoticeCubit] e a faixa do comum (`ShiftBanner`), que
/// ainda pede um `ValueNotifier`: lê o aviso do Cubit e o escreve de volta
/// (a faixa zera o aviso ao fechar). Não guarda estado: o dono é o Cubit.
class _ShiftNoticeLink extends ValueNotifier<ShiftNotice?> {
  _ShiftNoticeLink(this._cubit) : super(null) {
    _sub = _cubit.stream.listen((_) => notifyListeners());
  }

  final ShiftNoticeCubit _cubit;
  late final StreamSubscription<ShiftNoticeState> _sub;

  @override
  ShiftNotice? get value => _cubit.state.notice;

  @override
  set value(ShiftNotice? novo) {
    if (novo == null) {
      _cubit.clear();
    } else {
      _cubit.show(novo);
    }
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

class _ScoreHomePageState extends State<ScoreHomePage> {
  /// Como a biblioteca chama a música.
  LibraryTerm get _term => widget.opened.term;

  Piece get _piece => widget.opened.piece;

  late final String _scoreName = _piece.number == null
      ? _piece.title
      : '${_piece.number} · ${_piece.title}';

  /// Gavetas e painéis abertos ([HomePanelsCubit]); o modo de treino e a mão
  /// ([ScoreModeCubit], a mão começa com a deste hino); o aviso da faixa
  /// ([ShiftNoticeCubit], e a ponte que o comum pede). Criados na
  /// `initState` e fechados no `dispose`.
  late final HomePanelsCubit _panels;
  late final ScoreModeCubit _mode;
  late final ShiftNoticeCubit _shift;
  late final _ShiftNoticeLink _shiftNotice;

  static const _kDefaultHand = Hand.direita;

  /// A gravura (R09): render, fila, caixa, layout e tom deste hino. A cada
  /// documento novo chama [_onDocument], que monta o player.
  late final ScoreRenderCubit _session;

  /// Configurações gerais (som, MIDI, cores…): as da biblioteca, já lidas
  /// por ela. Cada Cubit que as lê assina o seu.
  late final SettingsCubit _settings = widget.opened.appSettings;

  /// O que este hino tinha guardado ao abrir (andamento, mão, trilha, tom).
  late final PieceSettings _stored = widget.opened.pieceSettings;

  /// On-screen zoom and pan of the drawn page (framework: o `InteractiveViewer`
  /// usa este controlador).
  ///
  /// This lives above the score: it transforms the finished drawing and is
  /// never part of the render request, so changing it neither reflows the
  /// piece nor triggers a render. What does change the engraving is the
  /// `unit` option, in the panel.
  final TransformationController _view = TransformationController();
  Size _viewport = Size.zero;

  /// Note highlights. Repaints the page through its own listenable, so
  /// playback never rebuilds this widget.
  final ScoreCubit _controller = ScoreCubit();
  final GhostCubit _ghosts = GhostCubit();

  /// Page navigation and page-turn animation (sweep bar) of the [ScoreView].
  final ScoreViewCubit _viewController = ScoreViewCubit();

  /// Por onde sai o som (R08): os dois motores, a saída em uso, o `.sf2` e
  /// o monitor MIDI. Sobrevive a novas gravuras (só o agendador é
  /// recriado, um por `.vsb`).
  late final SoundOutputCubit _sound;

  /// Tocar a partitura (R10): player, agendador, contagem, loop, metrônomo
  /// e andamento. Um player por gravura ([_onDocument]).
  late final PlaybackCubit _playback;

  /// A trilha de estudo (fase J) e o treino em curso (R11): a etapa, o
  /// ouvir, o treino livre e as marcas na pauta.
  late final TrailRunnerCubit _runner;

  /// Espera (o tempo para até o aluno tocar), ou tempo real (T03) —
  /// configuração geral.
  PracticeMode get _practiceMode => _settings.state.practiceMode;
  set _practiceMode(PracticeMode value) => _settings.setPracticeMode(value);

  /// O progresso das trilhas é o da biblioteca (a linha do hino atualiza ao
  /// voltar sem reabrir nada — J09).
  late final TrailProgressCubit _trailStore = widget.opened.trailProgress;

  /// Entrada MIDI (M01): lista/conecta dispositivos e reconecta sozinho ao
  /// último escolhido; converte mensagens em [PlayedNote] para o monitor.
  /// Relógio de carimbo: o motor de áudio se já estiver ligado (mesmo
  /// instante que o áudio usa), senão este `Stopwatch`, que roda desde a
  /// abertura do app.
  final Stopwatch _appClock = Stopwatch()..start();

  /// O gerenciador de dispositivos é o da biblioteca (o teclado conectado
  /// lá continua conectado aqui).
  late final MidiDeviceManager _midiDeviceManager =
      widget.opened.midiDeviceManager;

  /// Ouve o gerenciador de teclados para a conferência da transposição: só a
  /// troca do teclado conectado ([_tecladoVisto]) chama [_maybeCheckTranspose].
  late final StreamSubscription<MidiDeviceState> _keyboardSub;
  MidiDevice? _tecladoVisto;
  late final MidiInputService _midiInput = FlutterMidiInputService(
    resubscribeOn: _midiDeviceManager.transportInstalled,
    nowSeconds: () =>
        _sound.engine?.nowSeconds ?? _appClock.elapsedMicroseconds / 1e6,
  );

  /// Appearance, from the general settings — pure paint-time, none of them
  /// reach Verovio or reflow the score.
  double get _haloWidth => _settings.state.haloWidth;
  Color get _barColor => _settings.state.barColor;

  // Haste fina: meia cabeça de nota (o padrão do `ScoreView` são duas). O
  // player e a vista precisam do mesmo valor. É só um memo da largura por
  // gravura (não é estado: não avisa ninguém).
  double _barWidthOf(VsbDocument document) {
    if (!identical(document, _barWidthDocument)) {
      _barWidthDocument = document;
      _barWidth = defaultBarWidth(document) / 4;
    }
    return _barWidth;
  }

  VsbDocument? _barWidthDocument;
  double _barWidth = 0;

  DiagScoreWatch? _diagScore;
  VoidCallback? _diagOffState;

  @override
  void initState() {
    super.initState();
    _diagScore = DiagScoreWatch(_viewController, label: _scoreName);
    _panels = HomePanelsCubit();
    _mode = ScoreModeCubit(hand: _stored.hand ?? _kDefaultHand);
    _shift = ShiftNoticeCubit();
    _shiftNotice = _ShiftNoticeLink(_shift);
    _diagOffState = DiagLog.retrato(
      'musica',
      () => {
        'musica': _scoreName,
        'id': _piece.id,
        'treino': _mode.state.trainingMode,
        'tocando': _playback.playing,
        'velocidade': _playback.speed,
        'metronomo': _playback.metronomeOn,
      },
    );
    _session = ScoreRenderCubit(
      renderer: widget.renderer ?? createScoreRenderer(),
      scoreXml: widget.opened.scoreXml,
      piece: _piece,
      settings: _settings,
      stored: _stored,
      name: _scoreName,
      kind: _kind,
      pixelRatio: currentPixelRatio,
      debugMode: widget.debugMode,
      onDocument: _onDocument,
    );
    _sound = _newSoundOutput();
    _playback = _newPlayback();
    _runner = _newTrailRunner();
    _tecladoVisto = _midiDeviceManager.state.connected;
    _keyboardSub = _midiDeviceManager.stream.listen(_onMidiState);
    applyScoreOrientation(_kind);
  }

  /// A saída de som desta tela: o motor, o monitor do MIDI e o que o player
  /// precisa dele.
  SoundOutputCubit _newSoundOutput() => SoundOutputCubit(
    settings: _settings,
    devices: _midiDeviceManager,
    input: _midiInput,
    monitorPitch: (r, {required midiKeyboard}) =>
        _pitchFrame.engineFromReceived(r, midiKeyboard: midiKeyboard),
    playback: SoundOutputPlayback(
      hasTrack: () => _playback.track != null,
      attach: (engine, {required always}) =>
          _playback.attachSound(engine, always: always),
      detach: () => _playback.detachSound(),
      endPractice: () => _runner.endPractice(),
    ),
    onMessage: _showMessage,
  );

  /// A reprodução da partitura, com o som desta tela e o zoom dela.
  PlaybackCubit _newPlayback() => PlaybackCubit(
    sound: _sound,
    settings: _settings,
    controller: _controller,
    view: _viewController,
    speed: _stored.speed ?? 1.0,
    barWidthOf: _barWidthOf,
    pitchOf: _enginePitchOf,
    onEnded: () => _runner.endPractice(),
    onLoopChanged: (range) => range == null
        ? _runner.practice?.clearLoop()
        : _runner.practice?.setLoop(range.startMs, range.endMs),
  );

  /// O treino da trilha deste hino, com a sessão, o som e a reprodução desta
  /// tela.
  TrailRunnerCubit _newTrailRunner() => TrailRunnerCubit(
    store: _trailStore,
    playback: _playback,
    session: _session,
    sound: _sound,
    settings: _settings,
    devices: _midiDeviceManager,
    midiInput: _midiInput,
    piece: _piece,
    term: _term,
    scores: _controller,
    ghosts: _ghosts,
    shiftDetector: _shiftDetector,
    onShift: _onShiftDetected,
    writtenFromReceived: (r) => _pitchFrame.writtenFromReceived(r),
    pieceN: _stored.trailMeasures,
    host: _trailHost(),
  );

  /// Os ganchos que a trilha usa nesta tela: o resumo de cada etapa (com a
  /// revisão), a conclusão, a volta à biblioteca, o registro do treino e o
  /// número de compassos do hino.
  TrailRunnerHost _trailHost() => TrailRunnerHost(
    stageSummary:
        ({
          required stageRef,
          required result,
          required badLogical,
          required isLast,
          blockCount,
        }) async {
          _showErrorsAtEnd();
          final action = await showStageSummary(
            context,
            StageSummaryInfo(
              stageRef: stageRef,
              result: result,
              badLogical: badLogical,
              isLast: isLast,
              blockCount: blockCount,
              reviewCount: _runner.wrongMarks.length,
              reviewHasSides: _runner.wrongMarks.any((m) => m.side != 0),
            ),
            sidePanel: true,
          );
          if (action == StageSummaryAction.review && mounted) {
            _startReview();
          }
          return action;
        },
    conclusion: () => showTrailConclusion(context, sidePanel: true),
    backToLibrary: _backToLibrary,
    practiceReport: _onPracticeReport,
    pieceNChanged: (n) => widget.opened.onPieceSettingsChanged(
      _pieceSettingsWith(trailMeasures: n),
    ),
  );

  /// Guarda o que é deste hino (andamento, mão, trilha, tom). Com um respiro:
  /// um slider arrastado chama isto a cada passo.
  void _savePieceSettings() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 400),
      _flushPieceSettings,
    );
  }

  Timer? _saveDebounce;

  PieceSettings _pieceSettingsWith({int? trailMeasures}) => PieceSettings(
    speed: _playback.speed == 1.0 ? null : _playback.speed,
    hand: _mode.state.hand == _kDefaultHand ? null : _mode.state.hand,
    trailMeasures: trailMeasures,
    transpose: _session.transposeChoice,
  );

  void _flushPieceSettings() {
    if (_saveDebounce == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = null;
    widget.opened.onPieceSettingsChanged(
      _pieceSettingsWith(trailMeasures: _runner.pieceN),
    );
  }

  /// Mudar o N efetivo com progresso reinicia a trilha do hino (J06).
  Future<bool> _confirmNewCut() => confirmTrailReset(
    context,
    title: 'Trocar o corte?',
    message: 'Isto reinicia a trilha ${_term.deste} ${_term.singular}.',
    confirmLabel: 'Trocar',
  );

  @override
  void dispose() {
    _diagScore?.dispose();
    _diagOffState?.call();
    restoreEdgeToEdge(_kind);
    unawaited(_session.close());
    _flushPieceSettings();
    _shiftNotice.dispose();
    unawaited(_shift.close());
    unawaited(_runner.close());
    unawaited(_keyboardSub.cancel());
    unawaited(_playback.close());
    unawaited(_sound.close());
    unawaited(_panels.close());
    unawaited(_mode.close());
    _midiInput.dispose();
    _viewController.close();
    unawaited(_controller.close());
    unawaited(_ghosts.close());
    _view.dispose();
    super.dispose();
  }

  /// Fecha a partitura e volta à biblioteca (o `dispose` para o que
  /// estiver tocando).
  void _backToLibrary() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  /// Troca o tom deste hino ("Transpor", Q06): [choice] é [kTransposeNone]
  /// ou um intervalo. Com trilha começada no tom de agora e nenhuma no novo,
  /// pergunta antes (Q04); guarda a escolha e grava a partitura de novo.
  Future<void> _chooseTranspose(String choice) async {
    final opened = widget.opened;
    final from = _session.transposition;
    final to = _session.transpositionFor(choice);
    if (to != from &&
        await _trailStore.toneChangeStartsOver(opened.piece.id, from, to)) {
      if (!mounted) return;
      final ok = await confirmTrailReset(
        context,
        title: 'Trocar de tom?',
        message: toneChangeMessage(
          opened.piece.fifths ?? 0,
          from: from,
          to: to,
          naming: _settings.state.noteNaming,
        ),
        confirmLabel: 'Trocar',
      );
      if (!ok || !mounted) return;
    }
    if (!_session.chooseTranspose(choice)) return;
    _panels.closeOptions();
    opened.onPieceSettingsChanged(
      _pieceSettingsWith(trailMeasures: _runner.pieceN),
    );
  }

  /// "Escolher…": a lista dos 12 tons.
  Future<void> _pickTone() async {
    final fifths = _piece.fifths;
    if (fifths == null) return;
    final range = _session.originalRange;
    final current = _session.transposition;
    final choice = await showToneList(
      context,
      choices: toneChoices(
        fifths,
        lowest: range?.lowest ?? kCatalogLowestMidi,
        highest: range?.highest ?? kCatalogHighestMidi,
        naming: _settings.state.noteNaming,
      ),
      currentFifths: fifths + (current?.fifthsDelta ?? 0),
    );
    if (choice == null || !mounted) return;
    await _chooseTranspose(choice.transposition?.interval ?? kTransposeNone);
  }

  /// Tocar no selo ([ScorePhoneTitleBar]) abre a conferência do teclado (Q06);
  /// sem teclado ou com o som só do app não há o que conferir, e a pessoa
  /// fica sabendo por quê.
  void _onSealTap() {
    final message = _midiDeviceManager.state.connected == null
        ? 'Conecte o teclado para conferir o TRANSPOSE.'
        : _sound.midiMonitorOn
        ? 'O som sai pelo app, no tom original: não há o que ajustar no '
              'teclado.'
        : null;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    unawaited(_openTransposeCheck());
  }

  /// As alturas da música aberta (fase Q): o que se lê, o que se ouve e o que
  /// chega do teclado. Montado a cada uso — o tom da gravura que está na tela,
  /// o que se sabe do teclado conectado e se o som é do app — então quem o usa
  /// por função (casador, agendador, monitor) sempre vê o estado de agora.
  PitchFrame get _pitchFrame {
    // O tom da gravura na tela (não o pedido, que ainda pode estar sendo
    // gravado): as alturas do `midi.json` são as dele.
    final k = _session.renderedTransposition?.semitones ?? 0;
    if (k == 0) return PitchFrame.identity;
    final behavior = _settings.state.keyboardTransposeOf(
      _midiDeviceManager.state.connected?.name,
    );
    return PitchFrame(
      k,
      keyboardShiftsOut: behavior.shiftsOut ?? false,
      keyboardShiftsIn: behavior.shiftsIn ?? false,
      appIsSound: _sound.midiMonitorOn,
    );
  }

  /// A altura que o [engine] deve receber para a nota escrita: o teclado MIDI
  /// lê o que mandamos pela regra dele; o sintetizador do app toca a soada.
  int Function(int) _enginePitchOf(SoundEngine engine) {
    final midiKeyboard = engine is MidiOutSoundEngine;
    return (w) => _pitchFrame.engineFromWritten(w, midiKeyboard: midiKeyboard);
  }

  /// Uma gravura nova ([ScoreRenderCubit.onDocument]): os ids (e talvez as
  /// páginas) mudaram, então o que tocava a anterior é desmontado e montado
  /// de novo sobre ela.
  void _onDocument(VsbDocument document, PerformanceTrack track) {
    if (!mounted) return;
    _runner.attachDocument(document, track);
    _sound.restoreSound();
    _maybeCheckTranspose();
    _maybeRemindTransposeReset();
    unawaited(_maybeStartTour());
  }

  /// Os botões que o tutorial aponta, e se ele já foi decidido nesta
  /// abertura da música.
  final ScoreTourKeys _tourKeys = ScoreTourKeys();
  bool _tourChecked = false;

  /// A primeira música aberta: o passeio pela tela, uma vez.
  Future<void> _maybeStartTour() async {
    final store = widget.tourStore;
    if (store == null || _tourChecked) return;
    _tourChecked = true;
    if (await store.seen(TourId.score)) return;
    await _runTour();
  }

  /// O passeio pela tela da partitura, sozinho ou por "Rever o tutorial".
  Future<void> _runTour() async {
    final store = widget.tourStore;
    if (store == null || !mounted) return;
    // Um quadro para a gaveta fechar e a barra assentar.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final end = await showTour(context, scoreTourSteps(_tourKeys, term: _term));
    if (end != null) await store.markSeen(TourId.score);
  }

  void _togglePlay() {
    _runner.clearErrorMarks();
    _playback.togglePlay();
  }

  /// Reiniciar: volta ao começo e segue como estava — tocando, recomeça de
  /// lá; parado, fica parado no começo. "Começo" é o da etapa na trilha, o
  /// do trecho em repetição no modo livre, ou o da música.
  Future<void> _restart() async {
    final player = _playback.player;
    if (player == null) return;
    if (_runner.trailMode) {
      final trail = _runner.trail!;
      if (trail.running) {
        _runner.abandonStage();
        await _runner.startStage();
        return;
      }
      final stage = trail.selected;
      if (stage != null) _playback.seekTo(stage.startMs);
      return;
    }
    if (_runner.practice != null) {
      _runner.stopPractice();
      await _runner.togglePractice(hand: _mode.state.hand, mode: _practiceMode);
      return;
    }
    if (_playback.playing) _runner.clearErrorMarks();
    _playback.restart();
  }

  /// Troca a mão do aluno (T02) — o seletor só aparece armado e sem sessão
  /// em andamento ([_runner.practice] existindo esconde o seletor).
  void _setHand(Hand hand) {
    _mode.setHand(hand);
    _savePieceSettings();
  }

  /// O treino livre com tempo acabou com algo avaliado (T03): a biblioteca
  /// guarda a melhor precisão do hino ("Pontuação") e o resumo abre.
  void _onPracticeReport(PracticeReport report) {
    widget.opened.onPracticeScore(
      (report.accuracy * 100).round(),
      _session.renderedTransposition,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showErrorsAtEnd();
      unawaited(_showSummary(report));
    });
  }

  Future<void> _showSummary(PracticeReport report) => showPracticeSummary(
    context,
    report,
    options: PracticeSummaryOptions(
      legend: _practiceLegend(),
      sidePanel: true,
      onRepeatWorst: _repeatWorst,
      wrongCount: _runner.wrongMarks.length,
      reviewHasSides: _runner.wrongMarks.any((m) => m.side != 0),
      onReview: _runner.wrongMarks.isEmpty ? null : _startReview,
    ),
  );

  /// Fim de uma etapa ou de um treino com notas erradas: a partitura já as
  /// mostra (na primeira página com erro), sem esperar o "Rever". O resumo só
  /// fica na frente, e "Rever na partitura" volta a essa página.
  void _showErrorsAtEnd() {
    if (_runner.wrongMarks.isNotEmpty) _startReview();
  }

  /// "Revisar" (fim do treino): as notas erradas ficam fixas na partitura e
  /// a primeira página com erro abre.
  void _startReview() {
    _runner.startReview();
    final pages = _reviewPages();
    if (pages.isNotEmpty) _viewController.goToPage(pages.first);
  }

  /// Páginas (índices) que têm nota errada fixa, em ordem.
  List<int> _reviewPages() =>
      ({for (final g in _ghosts.review) g.page.index}.toList()..sort());

  /// "Repetir os compassos com mais erros" (T03 + loop do T04): o intervalo
  /// que cobre os piores compassos se forem próximos (até 4 compassos);
  /// senão, só o pior.
  void _repeatWorst(List<MeasureStats> worst) {
    if (worst.isEmpty) return;
    var a = worst.map((m) => m.index).reduce(math.min);
    var b = worst.map((m) => m.index).reduce(math.max);
    if (b - a > 3) {
      a = b = worst.first.index;
    }
    _setLoop(a, b);
  }

  /// Tocar numa nota (E02c) move o player e o agendador.
  void _onScoreTap(String id) => _playback.seekToElement(id);

  void _setSpeed(double value) {
    _playback.setSpeed(value);
    _savePieceSettings();
  }

  Future<void> _openLoopSheet() async {
    final player = _playback.player;
    if (player == null || player.measures.isEmpty) return;
    final chosen = await showLoopSheet(
      context,
      (
        total: player.measures.length,
        current: player.state.measureIndex,
        initial: _playback.loop,
      ),
      sidePanel: true,
      onClear: _playback.clearLoop,
    );
    if (chosen == null || !mounted || !identical(player, _playback.player)) {
      return;
    }
    _setLoop(chosen.a, chosen.b);
  }

  /// "Repetir um trecho" e "repetir os piores compassos" (T03): liga o loop
  /// nos compassos `a..b` (ocorrências, 0-based) e vai ao início do trecho.
  void _setLoop(int a, int b) => _playback.setLoop(a, b);

  String get _outputKey =>
      _sound.output == SoundOutput.midiKeyboard ? 'midi' : 'app';

  Future<void> _openCalibration() async {
    final device = _midiDeviceManager.state.connected;
    if (device == null) return;
    final engine = await _sound.ensureEngine();
    if (engine == null || !mounted) return;
    final ms = await showCalibrationDialog(
      context,
      engine: engine,
      input: _midiInput,
      deviceName: device.name,
    );
    if (ms == null) return;
    await _midiDeviceManager.setInputLatencyMs(device.id, _outputKey, ms);
    if (mounted) _runner.setInputLatency(ms);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Teclados para os quais a conferência do TRANSPOSE (Q06) já foi oferecida
  /// nesta tela: quem a fechou não é incomodado a cada regravação.
  final Set<String> _transposeCheckAsked = {};
  bool _transposeCheckOpen = false;

  /// Q07: o aviso da faixa no topo da partitura (detector de deslocamento ou
  /// lembrete de voltar o TRANSPOSE a 0) e o detector, que vigia só onde o
  /// TRANSPOSE errado muda o número que chega: teclado que transpõe a saída
  /// (ou ainda não conferido) e som que sai do teclado, não do app.
  late final ShiftDetector _shiftDetector = ShiftDetector(
    enabled: () =>
        !_sound.midiMonitorOn &&
        _settings.state
                .keyboardTransposeOf(_midiDeviceManager.state.connected?.name)
                .shiftsOut !=
            false,
  );

  /// O detector disparou com a distância [d]: diz à pessoa o que ajustar e, num
  /// teclado ainda não conferido, guarda que ele transpõe a saída (só quem
  /// transpõe manda o número deslocado). Se o teclado já estava no valor
  /// pedido, só fica sabendo disso — não há o que avisar.
  void _onShiftDetected(int d) {
    if (!mounted) return;
    final frame = _pitchFrame;
    final frameShiftsOut = frame.keyboardShiftsOut && !frame.appIsSound;
    final name = _midiDeviceManager.state.connected?.name;
    final behavior = _settings.state.keyboardTransposeOf(name);
    if (name != null && !behavior.isChecked) {
      _settings.setKeyboardTranspose(
        name,
        KeyboardTransposeBehavior(shiftsOut: true, shiftsIn: behavior.shiftsIn),
      );
    }
    if (shiftIsAlreadyRight(d: d, k: frame.k, frameShiftsOut: frameShiftsOut)) {
      return;
    }
    _shift.show(
      shiftNoticeFor(d: d, k: frame.k, frameShiftsOut: frameShiftsOut),
    );
  }

  /// Lembra de voltar o TRANSPOSE a 0 ao passar de uma música transposta (nesta
  /// execução do app) a uma sem transposição, num teclado que não transpõe a
  /// saída: nele o detector não vê nada. Sair do app com a transposta aberta
  /// não avisa: no celular não há um momento confiável para isso.
  void _maybeRemindTransposeReset() {
    final now = (_session.renderedTransposition?.semitones ?? 0) != 0;
    final previous = _settings.lastPieceTransposed;
    _settings.lastPieceTransposed = now;
    final name = _midiDeviceManager.state.connected?.name;
    if (shouldRemindTransposeReset(
      state: ResetReminderState(
        previousWasTransposed: previous,
        nowTransposed: now,
        hasKeyboard: name != null,
        keyboardShiftsOut: _settings.state.keyboardTransposeOf(name).shiftsOut,
        appIsSound: _sound.midiMonitorOn,
      ),
    )) {
      _shift.show(const ShiftNotice(kShiftReminderMessage, hideOnPlay: false));
    }
  }

  /// Um estado novo do gerenciador de teclados: só a troca do teclado conectado
  /// chama [_maybeCheckTranspose].
  void _onMidiState(MidiDeviceState estado) {
    if (estado.connected == _tecladoVisto) return;
    _tecladoVisto = estado.connected;
    _maybeCheckTranspose();
  }

  /// Oferece a conferência sozinha quando há transposição, um teclado
  /// conectado e ainda não conferido ([shouldAutoCheckTranspose]).
  void _maybeCheckTranspose() {
    if (!mounted || _transposeCheckOpen) return;
    final name = _midiDeviceManager.state.connected?.name;
    if (!shouldAutoCheckTranspose(
      state: AutoCheckState(
        transposition: _session.renderedTransposition,
        deviceName: name,
        behavior: _settings.state.keyboardTransposeOf(name),
        appIsSound: _sound.midiMonitorOn,
        alreadyAsked: _transposeCheckAsked.contains(name),
      ),
    )) {
      return;
    }
    _transposeCheckAsked.add(name!);
    unawaited(_openTransposeCheck());
  }

  /// A conferência do TRANSPOSE (Q06): também é o que o selo da partitura
  /// abre (Q08). Sem teclado, sem transposição na tela ou com o som só do app
  /// não há o que ajustar, e não abre. O que se descobre fica guardado pelo
  /// nome do teclado.
  Future<void> _openTransposeCheck() async {
    final transposition = _session.renderedTransposition;
    final device = _midiDeviceManager.state.connected;
    if (transposition == null ||
        device == null ||
        _sound.midiMonitorOn ||
        _transposeCheckOpen ||
        !mounted) {
      return;
    }
    _transposeCheckOpen = true;
    try {
      final behavior = await showTransposeCheck(
        context,
        request: TransposeCheckRequest(
          transposition: transposition,
          deviceName: device.name,
          input: _midiInput,
          previous: _settings.state.keyboardTransposeOf(device.name),
          naming: _settings.state.noteNaming,
          playOwnSound: _playOwnTone,
          playOnKeyboard: _sound.output == SoundOutput.midiKeyboard
              ? _playKeyboardTone
              : null,
        ),
      );
      if (behavior != null) {
        _settings.setKeyboardTranspose(device.name, behavior);
      }
    } finally {
      _transposeCheckOpen = false;
    }
  }

  /// Toca [pitch] pelo sintetizador do app, para o teste de ouvido da
  /// conferência; `false` se ele não está aberto (então vale a palavra da
  /// pessoa). Pelo canal do monitor, que a partitura não usa.
  Future<bool> _playOwnTone(int pitch) async {
    final engine = _sound.appEngine;
    if (engine == null) return false;
    await _beep(engine, pitch, channel: kMidiMonitorChannel);
    return true;
  }

  /// Manda [pitch] cru ao teclado (M03), sem conversão: é o que a conferência
  /// da entrada compara.
  Future<void> _playKeyboardTone(int pitch) async {
    final engine = _sound.ensureMidiOutEngine();
    // Canal 1: alguns teclados só respondem nele.
    if (engine != null) await _beep(engine, pitch, channel: 0);
  }

  Future<void> _beep(
    SoundEngine engine,
    int pitch, {
    required int channel,
  }) async {
    engine.send([0x90 | channel, pitch, 100]);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    engine.send([0x80 | channel, pitch, 0]);
  }

  /// Só quem está ouvindo ou treinando vê a página virar com animação (a
  /// haste varre a pauta no compasso da música). Para só olhar, a página
  /// muda de uma vez.
  bool get _pageTurnAnimated => _playback.playing || _runner.practice != null;

  void _previousPage() {
    _viewController.previousPage(animate: _pageTurnAnimated);
  }

  void _nextPage() {
    _viewController.nextPage(animate: _pageTurnAnimated);
  }

  void _onPageChanged(int target) {
    if (mounted) _session.setPage(target);
  }

  /// A layout option settled (slider released, toggle flipped): keep it for
  /// every piece and re-engrave.
  void _commitLayout() {
    _session.saveLayout();
    unawaited(_session.render());
  }

  /// Back to the app's default layout — for every piece.
  void _resetLayout() {
    _session.resetLayout();
    _commitLayout();
  }

  Future<void> _copyOptions() async {
    final json = const JsonEncoder.withIndent('  ')
        .convert(_session.effectiveOptions);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Opções copiadas (JSON)')));
  }

  /// Modo da gaveta: `false` = Ouvir, `true` = Espera (modo treino, T02).
  /// Como no artefato, entrar em Espera pede uma mão só (Direita) e
  /// andamento 80%; voltar a Ouvir devolve Ambas e 100%.
  void _setTrainingFromDrawer(bool training) {
    if (training == _mode.state.trainingMode) return;
    if (!training && _runner.practice != null) _runner.stopPractice();
    _mode.setTraining(training);
    _setSpeed(training ? 0.8 : 1.0);
  }

  /// Escolha do seletor único de modos (U11). Entre os três modos de treino
  /// só troca o modo; de e para Ouvir valem os efeitos de carona de
  /// [_setTrainingFromDrawer] (mão e andamento).
  void _setStudyMode(StudyMode next) {
    final current = StudyMode.of(
      training: _mode.state.trainingMode,
      mode: _practiceMode,
    );
    if (next == current) return;
    final practiceMode = next.practiceMode;
    if (practiceMode != null) _practiceMode = practiceMode;
    if (next.isTraining != current.isTraining) {
      _setTrainingFromDrawer(next.isTraining);
    }
  }

  /// Compasso (base 1) e total para a barra lateral; `null` sem partitura.
  int? get _measureCount => scoreMeasureCountOf(_playback);

  Future<void> _openMeasureJump() async {
    final player = _playback.player;
    // Na trilha o compasso fala a numeração do caminho (a da gaveta e do
    // resumo), não a das ocorrências da música expandida (U07).
    final trail = _runner.trailMode ? _runner.trail : null;
    final path = trail != null && trail.path.measureCount > 0
        ? trail.path
        : null;
    final total = path?.measureCount ?? _measureCount;
    if (player == null || total == null) return;
    final current = player.state.measureIndex;
    final target = path != null ? (path.numberOf(current) ?? 1) : current + 1;
    final result = await pickMeasureJump(context, target: target, total: total);
    if (result == null || !mounted || !identical(player, _playback.player)) {
      return;
    }
    final ms =
        path?.startMsOfNumber(result) ??
        player.timeline.measures[result - 1].startMs;
    player.seek(Duration(milliseconds: ms.round()));
    _playback.scheduler?.seek(ms.toDouble());
  }

  /// Legenda das cores do treino, com as do aluno (U08).
  Widget _practiceLegend() => practiceLegendOf(_settings.state);

  /// Gaveta "⋯" ([ScoreOptionsDrawer]): as ações que dependem da tela
  /// (regravar, trocar de tom, o trecho em repetição) vêm daqui.
  Widget _buildOptionsDrawer() => ScoreOptionsDrawer(
    simplified: _piece.simplified,
    fifths: _piece.fifths,
    term: _term,
    chooseVersion: widget.opened.onChooseVersion,
    confirmNewCut: _confirmNewCut,
    onStudyChanged: _setStudyMode,
    onHandChanged: _setHand,
    onSpeedChanged: _setSpeed,
    onToggleTrailFree: _toggleTrailFree,
    onChooseTranspose: (choice) => unawaited(_chooseTranspose(choice)),
    onPickTone: () => unawaited(_pickTone()),
    onOpenLoopSheet: _openLoopFromDrawer,
    onCommitLayout: _commitLayout,
    onPreviousPage: _previousPage,
    onNextPage: _nextPage,
  );

  /// Liga ou desliga o treino livre da trilha; a gaveta de opções fecha junto.
  void _toggleTrailFree() {
    final trail = _runner.trail;
    if (trail == null) return;
    trail.setFreeMode(!trail.freeMode);
    _panels.closeOptions();
  }

  /// O "Repetir um trecho" da gaveta: fecha a gaveta e abre a folha do loop.
  void _openLoopFromDrawer() {
    _panels.closeOptions();
    unawaited(_openLoopSheet());
  }

  /// Corpo da partitura (desenhado para o celular — `CelularEstudo` /
  /// `CelularTreino` / `CelularPainel` / `CelularGrande` — e usado em
  /// qualquer largura): a partitura ocupa tudo, com a barra lateral de 84 px
  /// à direita; o resto (andamento, mão, modo, tamanho, som…) fica na
  /// gaveta ⋯.
  Widget _buildPhoneBody() => Stack(
    children: [
      SafeArea(
        child: Row(
          children: [
            Expanded(child: _phoneScoreColumn()),
            _phoneRailRegion(),
          ],
        ),
      ),
      BlocSelector<HomePanelsCubit, HomePanelsState, bool>(
        selector: (panels) => panels.options,
        builder: (context, open) =>
            open ? _buildOptionsDrawer() : const SizedBox.shrink(),
      ),
      BlocSelector<HomePanelsCubit, HomePanelsState, bool>(
        selector: (panels) => panels.trailDrawer,
        builder: (context, open) =>
            open ? const ScoreTrailDrawer() : const SizedBox.shrink(),
      ),
    ],
  );

  /// A coluna da partitura no celular: a barra de título, a caixa da partitura
  /// (com o tour) e, em debug, o painel do som.
  Widget _phoneScoreColumn() => ColoredBox(
    color: kSurface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScorePhoneTitleBar(
          piece: _piece,
          tourKeys: _tourKeys,
          midi: _midiDeviceManager,
          onBack: _backToLibrary,
          onSealTap: _onSealTap,
        ),
        Expanded(
          child: KeyedSubtree(key: _tourKeys.score, child: _buildScoreArea()),
        ),
        if (widget.debugMode) const SoundEngineDebugPanel(),
      ],
    ),
  );

  /// O trilho do celular ([ScorePhoneRail]). O compasso tocado vem do
  /// `ValueNotifier` do player, que muda com o player: por isso o trilho
  /// refaz a escuta quando a gravura muda ([PlaybackCubit]).
  Widget _phoneRailRegion() => BlocBuilder<PlaybackCubit, PlaybackState>(
    builder: (context, _) => BlocBuilder<MidiDeviceManager, MidiDeviceState>(
      bloc: _midiDeviceManager,
      builder: (context, _) {
        ScorePhoneRail rail(int index) => ScorePhoneRail(
          index: index,
          tourKeys: _tourKeys,
          midi: _midiDeviceManager,
          onTogglePlay: _togglePlay,
          onRestart: () => unawaited(_restart()),
          onOpenMeasureJump: () => unawaited(_openMeasureJump()),
        );
        // Sem player (ainda não há gravura), o trilho olha o compasso zero.
        final player = _playback.player;
        if (player == null) return rail(0);
        return BlocSelector<ScorePlayer, ScorePlayerState, int>(
          bloc: player,
          selector: (state) => state.measureIndex,
          builder: (context, index) => rail(index),
        );
      },
    ),
  );

  /// Celular, tablet ou desktop (pelo aparelho, não pela largura da janela):
  /// a orientação da partitura e o `unit` de partida dependem dele.
  final DeviceKind _kind = currentDeviceKind;

  /// Um painel da partitura (layout, configurações gerais, monitor MIDI):
  /// entra pela direita, na mesma casca das gavetas — o monitor também, que
  /// antes abria à esquerda (U18).
  Widget _scorePanel({
    required BoxConstraints constraints,
    required Widget child,
  }) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: math.min(kPhoneSidePanelWidth, constraints.maxWidth * 0.6),
      child: Material(
        color: kSurface,
        elevation: 8,
        child: SafeArea(left: false, child: ClipRect(child: child)),
      ),
    );
  }

  Widget _buildScoreArea() {
    // The page is engraved for this box, so its size has to be known before
    // the first render — hence measuring here rather than off the window.
    // Everything drawn over the score (zoom, panel) is a Stack child, so it
    // never changes this box and never re-engraves the piece.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        if (_session.setBox(constraints.biggest * dpr)) {
          // A primeira caixa: o painel, montado antes dela, ainda não mostra
          // o tamanho da página. Um aviso depois do quadro refaz o painel.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _session.boxSeen();
          });
        }
        _viewport = constraints.biggest;
        return BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
          builder: (context, _) {
            final document = _session.document;
            final hasPage = document != null && document.pages.isNotEmpty;
            return _scoreStack(
              constraints,
              hasPage: hasPage,
              content: _scoreContent(constraints, document),
            );
          },
        );
      },
    );
  }

  /// O que vai na caixa da partitura: a página, com a vista, ou (enquanto o
  /// hino não está gravado) o texto de espera ou o motivo de não ter aberto.
  Widget _scoreContent(BoxConstraints constraints, VsbDocument? document) {
    if (document == null || document.pages.isEmpty) return _scorePlaceholder();
    return BlocBuilder<PlaybackCubit, PlaybackState>(
      builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, _) => _scoreView(constraints, document),
        ),
      ),
    );
  }

  /// A vista da página ([ScoreView]), com a caixa dela fixa.
  Widget _scoreView(BoxConstraints constraints, VsbDocument document) {
    final turn = ScorePageTurn(
      barWidth: _barWidthOf(document),
      timed: _timedPractice,
      speed: _playback.scheduler?.speed ?? 1,
    );
    // InteractiveViewer gives its child unbounded room, so the
    // view is pinned to the score box.
    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: ScoreSizeLog(
        label: 'hino ${_piece.id}',
        document: document,
        child: ScoreView(
          document: document,
          controller: _controller,
          viewController: _viewController,
          curtain: _playback.player?.curtain,
          mode: ScorePageMode.pagedSweep,
          initialPage: _session.pageIndex.clamp(0, document.pages.length - 1),
          onPageChanged: _onPageChanged,
          onElementTap: _onScoreTap,
          ghosts: _ghosts,
          overlayIds:
              (_runner.markedIds().isEmpty &&
                      _runner.errorMeasureIds.isEmpty) ||
                  _playback.player == null
              ? const []
              : allMeasureIds(_playback.player!),
          overlayBuilder: (_, id, rect) => measureOverlay(_runner, id, rect),
          overlayUniformHeight: true,
          haloSigmaScale: _haloWidth,
          barColor: _barColor,
          barWidth: turn.barWidth,
          revealBlurSigma: turn.revealBlurSigma,
          maxSweepDuration: turn.maxSweepDuration,
        ),
      ),
    );
  }

  /// Só o treino com a música andando (tempo real, livre ou na trilha) é
  /// "timed": a virada de página entra com a haste.
  bool get _timedPractice => _runner.practice?.mode == PracticeMode.realtime;

  /// Sem página: a barra de progresso corre em cima enquanto o hino é gravado;
  /// se a gravação falhar, o motivo fica à vista.
  Widget _scorePlaceholder() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Text(
        switch (_session.error) {
          final error? =>
            'Não deu para abrir ${_term.o} ${_term.singular}: $error',
          null => _scoreName,
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, color: kInkCaption),
      ),
    ),
  );

  /// A pilha sobre a caixa da partitura: o zoom (onde ele existe), a contagem,
  /// a barra de carregamento, o passador de páginas, o aviso do teclado e os
  /// painéis abertos. Tudo isso fica por cima, sem mudar a caixa.
  Widget _scoreStack(
    BoxConstraints constraints, {
    required bool hasPage,
    required Widget content,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: !scoreZoomable
              ? content
              : InteractiveViewer(
                  transformationController: _view,
                  minScale: kZoomMin,
                  maxScale: kZoomMax,
                  boundaryMargin: EdgeInsets.all(
                    math.min(constraints.maxWidth, constraints.maxHeight) / 2,
                  ),
                  child: content,
                ),
        ),
        Positioned.fill(
          child: BlocBuilder<PlaybackCubit, PlaybackState>(
            builder: (context, _) => CountInOverlay(
              phone: true,
              active: _playback.playing,
              read: _playback.countIn,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: BlocSelector<ScoreRenderCubit, ScoreRenderState, bool>(
            selector: (session) => session.busy,
            builder: (context, busy) =>
                busy ? const LinearProgressIndicator() : const SizedBox.shrink(),
          ),
        ),
        if (hasPage)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _pagerRegion(),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ShiftBanner(notice: _shiftNotice, notes: _midiInput.notes),
        ),
        Positioned.fill(child: _panelsRegion(constraints)),
      ],
    );
  }

  /// O passador de páginas: a virada anima só quando se olha tocando ou
  /// treinando ([_pageTurnAnimated]).
  Widget _pagerRegion() => BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
    builder: (context, _) => BlocBuilder<PlaybackCubit, PlaybackState>(
      builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => ScorePager(
          controller: _viewController,
          pageCount: _session.pageCount,
          animated: _pageTurnAnimated,
          enabled: !_session.busy,
        ),
      ),
    ),
  );

  /// Os painéis abertos sobre a partitura: o monitor do MIDI e, um de cada vez,
  /// o do layout ou o geral. A pilha é a da região (um `Positioned` precisa
  /// ser filho direto de uma `Stack`).
  Widget _panelsRegion(BoxConstraints constraints) =>
      BlocBuilder<HomePanelsCubit, HomePanelsState>(
        builder: (context, panels) => Stack(
          children: [
            if (panels.midi) _midiPanel(constraints),
            if (panels.layout)
              _layoutPanel(constraints)
            else if (panels.general)
              _generalPanel(constraints),
          ],
        ),
      );

  Widget _midiPanel(BoxConstraints constraints) => _scorePanel(
    constraints: constraints,
    child: BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
      builder: (context, _) => MidiMonitorPanel(
        deviceManager: _midiDeviceManager,
        input: _midiInput,
        onClose: _panels.closeMidi,
        wrong: _runner.practice?.wrongPitches,
        heldPitchOf: (r) => _pitchFrame.writtenFromReceived(r),
      ),
    ),
  );

  Widget _layoutPanel(BoxConstraints constraints) => _scorePanel(
    constraints: constraints,
    child: BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
      builder: (context, _) => LayoutPanel(
        values: _session.layout,
        pageFitsBox: _session.pageFitsBox,
        fittedPage: _session.fittedPage,
        onChanged: _session.setLayoutValue,
        onCommit: _commitLayout,
        onFitChanged: (v) {
          _session.setPageFitsBox(v);
          _commitLayout();
        },
        onReset: _resetLayout,
        onCopy: _copyOptions,
        onClose: _panels.closeLayout,
        zoomSection: scoreZoomable ? zoomControls(_view, () => _viewport) : null,
      ),
    ),
  );

  Widget _generalPanel(BoxConstraints constraints) => _scorePanel(
    constraints: constraints,
    child: BlocBuilder<SoundOutputCubit, SoundOutputState>(
      builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => GeneralSettingsPanel(
          settings: _settings,
          midiDeviceManager: _midiDeviceManager,
          customSoundFont: _sound.customSoundFont,
          authStore: widget.authStore,
          onChooseSoundFont: () => unawaited(_sound.chooseSoundFont()),
          onResetSoundFont: () => unawaited(_sound.resetSoundFont()),
          onClose: _panels.closeGeneral,
          onTutorial: () {
            _panels.closeGeneral();
            unawaited(_runTour());
          },
          live: _liveSettingsActions(),
        ),
      ),
    ),
  );

  /// As ações ao vivo do painel geral (o som, o monitor, a calibração e o
  /// painel do MIDI), que valem sem fechar a tela.
  LiveSettingsActions _liveSettingsActions() => LiveSettingsActions(
    busy: _sound.loadingSoundFont,
    monitorOn: _sound.midiMonitorOn,
    onMonitorChanged: (_) => unawaited(_sound.toggleMidiMonitor()),
    inputLatencyMs: _runner.inputLatencyMs,
    onCalibrate: () {
      _panels.closeGeneral();
      unawaited(_openCalibration());
    },
    onOpenMidiPanel: _panels.openMidi,
  );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _session),
      BlocProvider.value(value: _settings),
      BlocProvider.value(value: _sound),
      BlocProvider.value(value: _playback),
      BlocProvider.value(value: _runner),
      BlocProvider.value(value: _panels),
      BlocProvider.value(value: _mode),
    ],
    child: DiagSessionScope(
      kind: 'musica',
      name: _scoreName,
      child: _buildScore(context),
    ),
  );

  Widget _buildScore(BuildContext context) =>
      BlocSelector<HomePanelsCubit, HomePanelsState, bool>(
        selector: (panels) => panels.anyOpen,
        builder: (context, anyOpen) => PopScope(
          // O "voltar" do aparelho fecha primeiro a gaveta aberta; só com todas
          // fechadas é que sai da partitura para a biblioteca.
          canPop: !anyOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _panels.closeAll();
          },
          child: Scaffold(backgroundColor: kSurface, body: _buildPhoneBody()),
        ),
      );
}
