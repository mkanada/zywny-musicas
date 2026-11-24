// R11: o andamento da trilha de estudo — montar a trilha, armar a etapa,
// contar, ouvir, avaliar, avançar, encerrar — e o treino livre, que divide
// com ela o mesmo `PracticeController`. Saiu de `_ScoreHomePageState`
// (achado 5 da revisão): a lógica pura da trilha é o [TrailCubit]; o
// que mora aqui é a cola entre ela, o player ([PlaybackCubit]), a
// prática e as marcas de erro na partitura. Os resumos e a conclusão são
// diálogos: a tela os mostra por [TrailRunnerHost].
//
// BL13: é um Cubit. O que a tela e as decisões leem (o N, o aviso de
// trilha indisponível, o ouvir, a latência, as marcas de erro e a revisão)
// está no estado; a trilha, o treino e os caches da pauta são objetos que
// o Cubit guarda. [TrailRunnerState.serial] sobe a cada aviso: a trilha ou o
// treino mudaram, e eles não estão no estado.

// Os parâmetros são públicos e os campos, privados (como no R08).
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:score_bridge/score_bridge.dart';
import 'package:zywny_bloc/zywny_bloc.dart';

import 'package:zywny_audio/score_audio_scheduler.dart';

import 'package:zywny_library/library_keys.dart' show progressIdFor;
import 'package:zywny_library/library_package.dart' show LibraryTerm;
import 'package:zywny_library/piece.dart';

import 'package:zywny_midi/midi_device_manager.dart';
import 'package:zywny_midi/midi_input_service.dart';

import 'package:zywny_audio/performance_track.dart';

import 'package:zywny_comum/practice/app_hand.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/practice/input_latency.dart';
import 'package:zywny_comum/practice/practice_colors.dart';
import 'package:zywny_comum/practice/practice_controller.dart';
import 'package:zywny_comum/practice/practice_report.dart';
import 'package:zywny_comum/practice/shift_detector.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/stage_result.dart'
    show StagePass, StageResult;
import 'package:zywny_comum/trail/trail_cubit.dart';
import 'package:zywny_comum/trail/trail_path.dart';
import 'package:zywny_comum/trail/trail_plan.dart';
import 'package:zywny_comum/trail/trail_progress.dart';
import 'package:zywny_comum/trail/trail_progress_cubit.dart';
import 'package:zywny_comum/trail/trail_stage.dart' show TrailPhase, TrailStage;
import 'package:zywny_comum/trail/trail_widgets.dart'
    show StageSummaryAction, TrailConclusionAction, trailStripTextFor;
import 'package:zywny_comum/ui/transpose_widgets.dart' show alsoStudiedText;
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/sound_output_controller.dart';

/// O resumo de uma etapa (ou de um bloco de reforço) que a tela mostra:
/// [blockCount] é o número de blocos de reforço que a reprovação abriu.
typedef StageSummaryDialog = Future<StageSummaryAction?> Function({
  required String stageRef,
  required StageResult result,
  required List<int> badLogical,
  required bool isLast,
  int? blockCount,
});

/// O que o runner pede à tela: os diálogos e a volta à biblioteca.
/// O começo de uma passada da trilha: a etapa, a trilha, o agendador, a faixa
/// e o player que ela usa.
typedef _PassStart = ({
  TrailCubit trail,
  TrailStage stage,
  ScoreAudioScheduler scheduler,
  PerformanceTrack track,
  ScorePlayer player,
});

/// O fim de uma passada da trilha: a etapa, o que o aluno fez nela e as marcas
/// de erro que ela deixou.
typedef _StageEnd = ({
  TrailCubit trail,
  TrailStage stage,
  StageResult result,
  List<WrongMark> wrongMarks,
});

class TrailRunnerHost {
  const TrailRunnerHost({
    required this.stageSummary,
    required this.conclusion,
    required this.backToLibrary,
    required this.practiceReport,
    this.pieceNChanged,
  });

  final StageSummaryDialog stageSummary;

  /// A trilha foi concluída (J07): biblioteca, treino livre ou ficar.
  final Future<TrailConclusionAction?> Function() conclusion;
  final VoidCallback backToLibrary;

  /// O treino livre com tempo acabou com algo avaliado (T03): a pontuação
  /// e o resumo.
  final void Function(PracticeReport report) practiceReport;

  /// O N deste hino mudou ([TrailRunnerCubit.setPieceN]): guardar.
  final void Function(int? n)? pieceNChanged;
}

/// O que a trilha do hino mostra e decide: o N, o aviso de trilha
/// indisponível, o ouvir, a latência calibrada, as marcas de erro na pauta e a
/// revisão das notas erradas. [serial] sobe a cada aviso (a trilha ou o treino
/// mudaram, e eles não estão aqui).
class TrailRunnerState extends Equatable {
  const TrailRunnerState({
    this.pieceN,
    this.unavailable,
    this.alsoStudied,
    this.listening = false,
    this.inputLatencyMs = 0,
    this.errorMeasureIds = const {},
    this.errorStageId,
    this.wrongMarks = const [],
    this.reviewing = false,
    this.serial = 0,
  });

  /// N da trilha deste hino (`null` = o geral).
  final int? pieceN;

  /// Por que não há trilha (explicação no lugar da faixa); `null` com trilha
  /// ou sem partitura.
  final String? unavailable;

  /// "Também estudada: original, 3 de 8 etapas" (Q04/Q08).
  final String? alsoStudied;

  /// Ouvindo o trecho da etapa (U03).
  final bool listening;

  /// Latência de entrada+saída calibrada para o teclado/saída correntes.
  final double inputLatencyMs;

  /// Compassos (ids da cena) com erro na última passagem.
  final Set<String> errorMeasureIds;

  /// A etapa a que as marcas de erro são (para descartá-las ao trocar).
  final String? errorStageId;

  /// As notas erradas do último treino que terminou (até o próximo treino, a
  /// troca de etapa ou a nova gravura).
  final List<WrongMark> wrongMarks;

  /// A revisão está aberta: as notas erradas fixas na partitura.
  final bool reviewing;

  final int serial;

  TrailRunnerState copyWith({
    int? Function()? pieceN,
    String? Function()? unavailable,
    String? Function()? alsoStudied,
    bool? listening,
    double? inputLatencyMs,
    Set<String>? errorMeasureIds,
    String? Function()? errorStageId,
    List<WrongMark>? wrongMarks,
    bool? reviewing,
    int? serial,
  }) => TrailRunnerState(
    pieceN: pieceN == null ? this.pieceN : pieceN(),
    unavailable: unavailable == null ? this.unavailable : unavailable(),
    alsoStudied: alsoStudied == null ? this.alsoStudied : alsoStudied(),
    listening: listening ?? this.listening,
    inputLatencyMs: inputLatencyMs ?? this.inputLatencyMs,
    errorMeasureIds: errorMeasureIds ?? this.errorMeasureIds,
    errorStageId: errorStageId == null ? this.errorStageId : errorStageId(),
    wrongMarks: wrongMarks ?? this.wrongMarks,
    reviewing: reviewing ?? this.reviewing,
    serial: serial ?? this.serial,
  );

  @override
  List<Object?> get props => [
    pieceN,
    unavailable,
    alsoStudied,
    listening,
    inputLatencyMs,
    errorMeasureIds,
    errorStageId,
    wrongMarks,
    reviewing,
    serial,
  ];
}

/// A trilha do hino aberto e o treino (da etapa ou livre) em curso.
///
/// Quem cria fecha ([close]): para o treino e solta a trilha. O store do
/// progresso é de fora (da biblioteca).
class TrailRunnerCubit extends Cubit<TrailRunnerState> {
  TrailRunnerCubit({
    required TrailProgressCubit store,
    required PlaybackCubit playback,
    required ScoreRenderCubit session,
    required SoundOutputCubit sound,
    required SettingsCubit settings,
    required MidiDeviceManager devices,
    required MidiInputService midiInput,
    required Piece piece,
    required LibraryTerm term,
    required this.scores,
    required this.ghosts,
    required this.shiftDetector,
    required this.onShift,
    required this.writtenFromReceived,
    required this.host,
    int? pieceN,
    Future<double> Function()? inputLatency,
  }) : _store = store,
       _playback = playback,
       _session = session,
       _sound = sound,
       _settings = settings,
       _devices = devices,
       _midiInput = midiInput,
       _piece = piece,
       _term = term,
       _inputLatency =
           inputLatency ??
           (() => calibratedInputLatency(devices, sound.output)),
       super(TrailRunnerState(pieceN: pieceN)) {
    _settingsSub = _settings.stream.listen((_) => _onSettingsChanged());
  }

  final TrailProgressCubit _store;
  final PlaybackCubit _playback;
  final ScoreRenderCubit _session;
  final SoundOutputCubit _sound;
  final SettingsCubit _settings;
  late final StreamSubscription<SettingsState> _settingsSub;
  final MidiDeviceManager _devices;
  final MidiInputService _midiInput;
  final Piece _piece;
  final LibraryTerm _term;
  final ScoreController scores;
  final GhostController ghosts;
  final ShiftDetector shiftDetector;
  final void Function(int d) onShift;

  /// A altura escrita para a nota que chegou do teclado (fase Q).
  final int Function(int received) writtenFromReceived;
  final TrailRunnerHost host;
  final Future<double> Function() _inputLatency;

  bool _disposed = false;

  TrailCubit? _trail;

  /// Escuta o estado da trilha; cancelada ao trocar ou soltar a trilha.
  StreamSubscription<TrailState>? _trailSub;
  PracticeController? _practice;
  Timer? _listenTimer;

  /// Etapas e andamentos com que o plano da trilha foi montado: mudou nas
  /// configurações, a trilha é remontada.
  List<TrailPhase> _planPhases = const [];
  Set<double> _planSpeeds = const {};

  /// Id da etapa para a qual a partitura já foi levada (U02). Cache do
  /// controlador, não é mostrado.
  String? _armedStageId;

  /// O cache de [markedIds]: vale para uma etapa **e** uma gravura. Cada
  /// gravura nova dá outros ids aos compassos (o Verovio continua o
  /// contador), e os da anterior não marcariam nada — o véu cobriria a
  /// pauta inteira, inclusive o trecho que se está tocando.
  String? _markedStageId;
  ScorePlayer? _markedPlayer;
  List<String> _markedIds = const [];
  Set<String> _markedSet = const {};

  /// Trilha de estudo (fase J): plano do hino, progresso e etapa
  /// selecionada. `null` sem trilha (caminho com saltos, ou partitura sem
  /// número de hino) — aí a tela fica no treino livre.
  TrailCubit? get trail => _trail;

  /// Por que não há trilha (explicação no lugar da faixa); `null` com trilha
  /// ou sem partitura.
  String? get unavailable => state.unavailable;

  /// "Também estudada: original, 3 de 8 etapas" (Q04/Q08): os outros tons
  /// em que este hino tem trilha. Lido a cada trilha montada.
  String? get alsoStudied => state.alsoStudied;

  /// N da trilha deste hino (`null` = o geral).
  int? get pieceN => state.pieceN;

  /// A trilha no comando (faixa), e não o treino livre.
  bool get trailMode => _trail != null && !_trail!.freeMode;

  /// O treino em curso (de uma etapa ou livre); `null` fora dele.
  PracticeController? get practice => _practice;

  /// Ouvindo o trecho da etapa (U03).
  bool get listening => state.listening;

  /// Latência de entrada+saída calibrada para o teclado/saída correntes.
  double get inputLatencyMs => state.inputLatencyMs;

  /// Compassos com erro na última passagem (ids da cena).
  Set<String> get errorMeasureIds => state.errorMeasureIds;

  /// As notas erradas do último treino que terminou; vazio se não houve
  /// nenhuma.
  List<WrongMark> get wrongMarks => state.wrongMarks;

  /// A revisão está aberta: as notas erradas fixas na partitura.
  bool get reviewing => state.reviewing;

  /// Compassos do trecho da etapa selecionada, para marcar na pauta (U02).
  /// Vazio no treino livre, sem trilha e na fase final.
  List<String> markedIds() {
    final trail = _trail;
    final player = _playback.player;
    final stage = trail?.selected;
    if (trail == null || trail.freeMode || player == null || stage == null) {
      return const [];
    }
    if (_markedStageId != stage.id || !identical(_markedPlayer, player)) {
      _markedStageId = stage.id;
      _markedPlayer = player;
      _markedIds = trailStageMeasureIds(trail.path, stage, player.measures);
      _markedSet = _markedIds.toSet();
    }
    return _markedIds;
  }

  /// [id] é de um compasso do trecho da etapa ([markedIds]).
  bool isMarked(String id) => markedIds().isNotEmpty && _markedSet.contains(id);

  /// Avisa a tela: a trilha, o treino ou a partitura mudaram. [mudar] troca os
  /// campos do estado (sem ele, só o [TrailRunnerState.serial] sobe); o aviso
  /// sai sempre, como o `notifyListeners` de antes.
  void _changed([TrailRunnerState Function(TrailRunnerState s)? mudar]) {
    if (_disposed) return;
    final novo = mudar == null ? state : mudar(state);
    emit(novo.copyWith(serial: novo.serial + 1));
  }

  /// As configurações mudaram: a trilha é remontada se o corte ou as etapas
  /// mudaram, e as cores do treino seguem as novas.
  void _onSettingsChanged() {
    // O N geral mudou e o hino usa o padrão: o corte muda junto (a trilha
    // antiga cai ao abrir, em [setup]).
    final trail = _trail;
    if (trail != null && !trail.running) {
      final effective = effectiveTrailMeasures(
        general: _settings.state.trailMeasures,
        piece: state.pieceN,
      );
      if (effective != trail.plan.n ||
          !listEquals(_planPhases, _settings.state.trailPlanPhases) ||
          !setEquals(_planSpeeds, _settings.state.trailSpeeds)) {
        unawaited(setup());
      }
    }
    // No treino o player destaca na cor de "esperado agora"; a cor da
    // reprodução volta em [endPractice].
    _playback.player?.highlightColor = _practice == null
        ? _settings.state.highlightColor
        : _settings.state.practicePendingColor;
    _practice
      ?..correctColor = _settings.state.highlightColor
      ..wrongColor = _settings.state.practiceWrongColor
      ..pendingColor = _settings.state.practicePendingColor;
  }

  /// Uma gravura nova: o treino da anterior acaba, o player é trocado e a
  /// trilha é montada de novo.
  void attachDocument(VsbDocument document, PerformanceTrack track) {
    _practice?.dispose();
    _practice = null;
    _trail?.setRunning(false);
    _playback.attach(document, track);
    unawaited(setup());
  }

  /// Solta a trilha atual: deixa de escutá-la e a fecha (BL10).
  void _soltaTrilha() {
    unawaited(_trailSub?.cancel());
    _trailSub = null;
    unawaited(_trail?.close());
    _trail = null;
  }

  /// [trail] ainda é a trilha montada e não foi fechada: depois de um `await`,
  /// só então ela recebe chamadas que emitem (BL10). Trocada ou fechada
  /// enquanto o runner esperava, não se mexe nela.
  bool _trilhaViva(TrailCubit trail) =>
      !_disposed && identical(_trail, trail) && !trail.isClosed;

  /// Monta a trilha depois de cada gravura: caminho sem repetições (J01),
  /// plano de etapas (J03) e progresso do hino. Sem plano (saltos) ou sem
  /// número de hino, explica e fica no livre.
  Future<void> setup() async {
    final document = _session.document;
    final track = _session.track;
    final player = _playback.player;
    _soltaTrilha();
    _changed((s) => s.copyWith(unavailable: () => null));
    clearErrorMarks();
    if (_disposed) return;
    if (document == null || track == null || player == null) return;
    // A trilha é do tom que está na tela (fase Q): cada tom tem a sua, e o
    // original guarda a de antes, sob o id da música.
    final pieceId = progressIdFor(_piece.id, _session.renderedTransposition);
    unawaited(_refreshAlsoStudied());
    final n = effectiveTrailMeasures(
      general: _settings.state.trailMeasures,
      piece: state.pieceN,
    );
    final path = TrailPath.fromTimeline(player.timeline);
    final plan = _planOf(path, track, n);
    if (plan.isEmpty) {
      _changed(
        (s) => s.copyWith(
          unavailable: () =>
              'Trilha indisponível ${_term.neste} ${_term.singular} — treino '
              'livre',
        ),
      );
      return;
    }
    var progress = await _store.ensureLoaded(pieceId);
    if (_disposed || !identical(_session.document, document)) return;
    // O N efetivo mudou desde o guardado (pelo geral): a trilha antiga é
    // de outro corte e é descartada ao abrir (J06).
    if (progress.total > 0 && progress.n != n) await _store.reset(pieceId);
    progress = _fittedProgress(progress, n, plan.stages.length);
    final trail = TrailCubit(
      path: path,
      plan: plan,
      progress: progress,
      store: _store,
      pieceId: pieceId,
    );
    _trailSub = trail.stream.listen((_) => _onTrailChanged());
    _armedStageId = null;
    _trail = trail;
    _changed();
    _armStage();
  }

  /// O plano de etapas de [path], com as fases e os andamentos de agora (que
  /// ficam guardados em `_planPhases` e `_planSpeeds`).
  TrailPlan _planOf(TrailPath path, PerformanceTrack track, int n) {
    _planPhases = _settings.state.trailPlanPhases;
    _planSpeeds = _settings.state.trailSpeeds;
    return TrailPlan.build(path, track, n: n, options: TrailPlanOptions(includeFinal: true, phases: _planPhases, speeds: _planSpeeds));
  }

  /// O progresso guardado, no corte [n] e com o total de etapas de agora
  /// ([total]). A trilha de outro corte já foi apagada pelo chamador; com outras
  /// etapas escolhidas nas configurações, o mesmo progresso fica com o total do
  /// plano de agora (para a biblioteca).
  static TrailProgress _fittedProgress(
    TrailProgress progress,
    int n,
    int total,
  ) {
    if (progress.total > 0 && progress.n != n) {
      return TrailProgress(n: n, total: total);
    }
    if (progress.total > 0 && progress.total != total) {
      return TrailProgress(
        n: progress.n,
        total: total,
        records: progress.records,
        resume: progress.resume,
      );
    }
    return progress;
  }

  /// Lê os outros tons em que este hino tem trilha ([alsoStudied]).
  Future<void> _refreshAlsoStudied() async {
    final tones = await _store.studiedTones(_piece.id);
    if (_disposed) return;
    final text = alsoStudiedText(
      tones,
      current: _session.renderedTransposition,
      fifths: _piece.fifths,
      naming: _settings.state.noteNaming,
    );
    if (text == state.alsoStudied) return;
    _changed((s) => s.copyWith(alsoStudied: () => text));
  }

  /// Reinicia a trilha do hino (gaveta, J06): zera o progresso e remonta.
  Future<void> restartTrail() async {
    if (_trail?.running ?? false) abandonStage();
    final id = _trail?.pieceId;
    if (id != null) await _store.reset(id);
    unawaited(setup());
  }

  /// Troca o N do hino (`null` = padrão geral). Mudar o N efetivo com
  /// progresso pede [confirm] e zera a trilha do hino (J06).
  Future<void> setPieceN(
    int? value, {
    required Future<bool> Function() confirm,
  }) async {
    final oldEffective = effectiveTrailMeasures(
      general: _settings.state.trailMeasures,
      piece: state.pieceN,
    );
    final newEffective = effectiveTrailMeasures(
      general: _settings.state.trailMeasures,
      piece: value,
    );
    if (newEffective != oldEffective &&
        _trail != null &&
        _trail!.progress.done > 0) {
      if (!await confirm()) return;
      await _store.reset(
        progressIdFor(_piece.id, _session.renderedTransposition),
      );
    }
    if (_disposed) return;
    _changed((s) => s.copyWith(pieceN: () => value));
    host.pieceNChanged?.call(value);
    if (newEffective != oldEffective) unawaited(setup());
  }

  void _onTrailChanged() {
    if (_disposed) return;
    // Trocou de etapa: as marcas de erro eram da anterior.
    if ((state.errorMeasureIds.isNotEmpty || state.wrongMarks.isNotEmpty) &&
        _trail?.selected?.id != state.errorStageId) {
      clearErrorMarks();
    }
    _changed();
    _armStage();
  }

  /// Marca na pauta os compassos (ocorrências) com erro.
  void markErrors(Iterable<int> occurrences) {
    final player = _playback.player;
    if (player == null) return;
    final ids = {
      for (final i in occurrences)
        if (i >= 0 && i < player.measures.length) player.measures[i].id,
    };
    _changed(
      (s) => s.copyWith(
        errorMeasureIds: ids,
        errorStageId: () => _trail?.selected?.id,
      ),
    );
  }

  void clearErrorMarks() {
    if (state.errorMeasureIds.isEmpty && state.wrongMarks.isEmpty) return;
    ghosts.clearReview();
    _changed(
      (s) => s.copyWith(
        errorMeasureIds: const {},
        errorStageId: () => null,
        wrongMarks: const [],
        reviewing: false,
      ),
    );
  }

  /// Guarda as notas erradas de um treino que acabou, para o aluno poder
  /// revê-las na partitura. Sem nenhuma, não oferece nada.
  void _keepWrongMarks(List<WrongMark> marks) {
    ghosts.clearReview();
    if (_disposed) return;
    if (marks.isEmpty) {
      _changed((s) => s.copyWith(wrongMarks: const [], reviewing: false));
      return;
    }
    _changed(
      (s) => s.copyWith(
        wrongMarks: marks,
        reviewing: false,
        errorStageId: () => _trail?.selected?.id,
      ),
    );
  }

  /// "Revisar": fixa na partitura as notas erradas do último treino — as
  /// tocadas antes do tempo à esquerda da nota, as depois à direita. A
  /// revisão é um estado da partitura, sem botão de fechar: dura o mesmo que
  /// as marcas de erro ([clearErrorMarks]) — até o próximo treino, o play, a
  /// troca de etapa ou uma gravura nova.
  void startReview() {
    if (state.wrongMarks.isEmpty || _practice != null || _disposed) return;
    ghosts.setReview([for (final m in state.wrongMarks) m.ghostRequest]);
    _changed((s) => s.copyWith(reviewing: true));
  }

  /// Com a etapa parada, a partitura mostra o primeiro compasso do trecho:
  /// ao abrir o hino e a cada troca de etapa. Não mexe com a etapa rodando,
  /// com treino em curso nem com a música tocando.
  void _armStage() {
    final trail = _trail;
    final player = _playback.player;
    if (trail == null || trail.freeMode || player == null) return;
    final stage = trail.selected;
    if (stage == null || stage.id == _armedStageId) return;
    if (trail.running ||
        _practice != null ||
        _playback.playing ||
        _session.busy) {
      return;
    }
    _armedStageId = stage.id;
    player.seek(Duration(microseconds: (stage.startMs * 1000).round()));
    // Parado: o seek acende a nota da partida na cor de reprodução (verde),
    // como se já tivesse sido tocada. Só a etapa em curso destaca notas.
    scores.clearHighlights();
    _playback.scheduler?.seek(stage.startMs);
  }

  /// Lê a latência calibrada do teclado/saída de agora.
  Future<void> loadInputLatency() async {
    final ms = await _inputLatency();
    if (_disposed) return;
    _changed((s) => s.copyWith(inputLatencyMs: ms));
  }

  /// A calibração acabou de medir [ms].
  void setInputLatency(double ms) {
    _changed((s) => s.copyWith(inputLatencyMs: ms));
  }

  /// Um treino novo: o agendador sobre o motor (que abre se preciso),
  /// `null` se não houver como.
  Future<ScoreAudioScheduler?> _ensureScheduler() async {
    final engine = await _sound.ensureEngine();
    if (engine == null || _disposed) return null;
    if (_playback.scheduler == null || !_sound.soundOn) {
      _playback.attachAudio(engine);
    }
    return _playback.scheduler;
  }

  /// Começa (ou para, se já está rodando) a etapa selecionada da trilha. A
  /// etapa manda nos controles enquanto roda — modo, mão, andamento,
  /// intervalo, contagem e metrônomo nas etapas com tempo — sem gravar nada:
  /// ao sair valem de novo os valores do aluno.
  Future<void> startStage() async {
    final trail = _trail;
    final track = _session.track;
    final player = _playback.player;
    if (trail == null || track == null || player == null) return;
    if (trail.running) {
      abandonStage();
      return;
    }
    final stage = trail.selected;
    if (stage == null) return;
    // Sem teclado quem chama é o ouvir ([listenStage]).
    if (_devices.state.connected == null) return;
    clearErrorMarks();
    stopListening();
    final scheduler = await _ensureScheduler();
    if (scheduler == null || !_trilhaViva(trail)) return;
    // O andamento da etapa vale só nela (sem gravar no hino).
    if ((stage.speed ?? _playback.speed) != scheduler.speed) {
      scheduler.setSpeed(stage.speed ?? _playback.speed);
    }
    scores.clearAll();
    // O instante de partida já acende na cor de "esperada" (e a mão do app
    // em cinza), não na da reprodução (U08).
    _paintForPractice(player, track, stage.phase.hand, stage.phase.mode);
    player.seek(Duration(microseconds: (stage.startMs * 1000).round()));
    await loadInputLatency();
    if (!_trilhaViva(trail)) return;
    final timed = stage.speed != null;
    shiftDetector.rearm();
    final practice = _practiceOf((
      trail: trail,
      stage: stage,
      scheduler: scheduler,
      track: track,
      player: player,
    ));
    if (timed) scheduler.metronomeOn = true;
    practice.start(countIn: timed);
    _playback.playPlayerAfterCount(stage.startMs);
    // No treino, o "esperado agora" acende na cor própria, como no modo
    // livre.
    player.highlightColor = _settings.state.practicePendingColor;
    trail.setRunning(true);
    trail.clearResult();
    _sound.markSoundOn();
    _practice = practice;
    _changed();
    _playback.setPlaying(true);
  }

  /// O controlador de avaliação da passada [pass]: o que ela toca e confere, e
  /// o que acontece nas bordas dela (o fim do trecho, os saltos e a espera).
  PracticeController _practiceOf(_PassStart pass) {
    final stage = pass.stage;
    final player = pass.player;
    return PracticeController(
      midiInput: _midiInput,
      track: pass.track,
      scheduler: pass.scheduler,
      controller: scores,
      hand: stage.phase.hand,
      ghosts: ghosts,
      inputLatencyMs: state.inputLatencyMs,
      writtenFromReceived: writtenFromReceived,
      shiftDetector: shiftDetector,
      onShift: onShift,
      mode: stage.phase.mode,
      measureIndexAt: player.timeline.measureIndexAt,
      passOf: (i) => player.measures[i].pass,
      range: (startMs: stage.startMs, endMs: stage.endMs),
      rangeJumps: trailStageGaps(pass.trail.path, stage),
      // No modo espera o aviso chega de dentro da notificação do passo
      // (`WaitModeSession.current`), e encerrar a etapa descarta esse mesmo
      // notificador: descartá-lo ali estoura (asserção no debug, RangeError
      // fora dele). O encerramento espera a notificação acabar.
      onRangeDone: () => scheduleMicrotask(() {
        final current = _practice;
        if (current != null) _onStageDone(current, stage);
      }),
      onRangeJump: (ms) =>
          player.seek(Duration(microseconds: (ms * 1000).round())),
      onWaitTarget: (ms) => player.waitTarget = ms,
      correctColor: _settings.state.highlightColor,
      wrongColor: _settings.state.practiceWrongColor,
      pendingColor: _settings.state.practicePendingColor,
      rhythmToleranceMs: _settings.state.rhythmToleranceMs,
    );
  }

  /// Ouvir o trecho da etapa (U03): as duas mãos, com som, no andamento da
  /// etapa (100% no modo espera), sem avaliar nada nem tocar no progresso.
  /// Para sozinho no fim e volta ao início do trecho.
  Future<void> listenStage() async {
    final trail = _trail;
    final player = _playback.player;
    if (trail == null || _session.track == null || player == null) return;
    if (state.listening) {
      stopListening();
      return;
    }
    final stage = trail.selected;
    if (stage == null) return;
    if (trail.running) abandonStage();
    clearErrorMarks();
    final scheduler = await _ensureScheduler();
    if (scheduler == null || !_trilhaViva(trail) || state.listening) return;
    _playback.cancelSilentCountIn();
    scores.clearAll();
    scheduler.setStaves(null);
    scheduler.setSpeed(stage.speed ?? 1.0);
    scheduler.metronomeOn = false;
    scheduler.setStopAt(stage.endMs - kRangeBoundaryToleranceMs);
    scheduler.setJumps(trailStageGaps(trail.path, stage));
    scheduler.onJump = (ms) =>
        player.seek(Duration(microseconds: (ms * 1000).round()));
    player.seek(Duration(microseconds: (stage.startMs * 1000).round()));
    player.play();
    scheduler.play(stage.startMs);
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (player.position.inMicroseconds / 1000 >= stage.endMs) {
        stopListening();
      }
    });
    _sound.markSoundOn();
    _changed((s) => s.copyWith(listening: true));
    _playback.setPlaying(true);
  }

  /// Fecha o ouvir: devolve ao agendador o que era do aluno e volta ao
  /// início do trecho. Sem efeito se não está ouvindo.
  void stopListening() {
    if (!state.listening) return;
    _listenTimer?.cancel();
    _listenTimer = null;
    _changed((s) => s.copyWith(listening: false));
    final scheduler = _playback.scheduler;
    if (scheduler != null) {
      scheduler.clearStopAt();
      scheduler.clearJumps();
      scheduler.onJump = null;
      scheduler.setSpeed(_playback.speed);
      scheduler.metronomeOn = _settings.state.metronomeOn;
      scheduler.pause();
    }
    _playback.player?.pause();
    scores.releaseAll();
    final start = _trail?.selected?.startMs;
    if (start != null) {
      _playback.player?.seek(Duration(microseconds: (start * 1000).round()));
      scheduler?.seek(start);
    }
    if (!_disposed) _playback.setPlaying(false);
  }

  /// O intervalo terminou por conta própria: grava, limpa e mostra o resumo
  /// da etapa (ou do bloco de reforço). Parar no meio não passa por aqui
  /// (abandono, sem registro).
  void _onStageDone(PracticeController practice, TrailStage stage) {
    if (_disposed || !identical(_practice, practice)) return;
    final trail = _trail;
    final result = practice.stageResult;
    final wrongMarks = practice.wrongMarks;
    _endRun();
    if (trail == null || result == null || _disposed) return;
    final end = (
      trail: trail,
      stage: stage,
      result: result,
      wrongMarks: wrongMarks,
    );
    final blockIndex = trail.blockIndexOf(stage);
    unawaited(() async {
      if (blockIndex != null) {
        await _onBlockDone(end, blockIndex);
        return;
      }
      await _onStageEnd(end);
    }());
  }

  /// Fim de uma etapa que não é de bloco: grava, limpa as marcas e mostra o
  /// resumo. A final aprovada conclui a trilha; a final reprovada com reforço
  /// útil treina os blocos.
  Future<void> _onStageEnd(_StageEnd end) async {
    final trail = end.trail;
    final stage = end.stage;
    final result = end.result;
    await trail.recordDone(result);
    if (!_trilhaViva(trail)) return;
    markErrors(result.badMeasures);
    _keepWrongMarks(end.wrongMarks);
    // Aprovou a final.100: concluiu a trilha (tela própria, J07).
    if (result.passed && stage.id == 'final.100') {
      await _onTrailConcluded(trail);
      return;
    }
    // Reprovou a final com reforço útil: treinar os blocos em vez de
    // tentar de novo.
    int? blocks;
    if (!result.passed &&
        stage.segment == null &&
        trail.startReinforcement(result)) {
      blocks = trail.blockViews.length;
    }
    final action = await host.stageSummary(
      stageRef: trailStripTextFor(
        trail.plan.segmentCount,
        stage.segment,
        stage.label,
      ),
      result: result,
      badLogical: _badLogical(trail, result),
      isLast: trail.progress.current(trail.plan) == null,
      blockCount: blocks,
    );
    if (!_trilhaViva(trail)) return;
    await _applyStageAction(trail, stage, action);
  }

  /// A trilha foi concluída pela final: a tela de conclusão decide (biblioteca
  /// ou modo livre).
  Future<void> _onTrailConcluded(TrailCubit trail) async {
    final action = await host.conclusion();
    if (!_trilhaViva(trail)) return;
    switch (action) {
      case TrailConclusionAction.library:
        host.backToLibrary();
      case TrailConclusionAction.free:
        trail.setFreeMode(true);
      case null:
        break;
    }
  }

  /// O que o resumo da etapa pediu, numa etapa que não é de bloco.
  Future<void> _applyStageAction(
    TrailCubit trail,
    TrailStage stage,
    StageSummaryAction? action,
  ) async {
    switch (action) {
      case StageSummaryAction.next:
        trail.next();
      case StageSummaryAction.retry:
        trail.repeat(stage);
        unawaited(startStage());
      case StageSummaryAction.skip:
        await trail.skipSelected();
        if (!_trilhaViva(trail)) return;
        trail.next();
      case StageSummaryAction.train:
        trail.next();
      // A revisão fica na etapa: quem a abre é a tela (vai à página).
      case StageSummaryAction.review:
      case null:
        break;
    }
  }

  /// Resultado de um bloco de reforço: guarda (sem tocar no plano) e mostra
  /// o resumo do bloco.
  Future<void> _onBlockDone(_StageEnd end, int blockIndex) async {
    final trail = end.trail;
    final stage = end.stage;
    final result = end.result;
    trail.recordBlockDone(blockIndex, result);
    if (_disposed) return;
    markErrors(result.badMeasures);
    _keepWrongMarks(end.wrongMarks);
    final action = await host.stageSummary(
      stageRef: stage.label,
      result: result,
      badLogical: _badLogical(trail, result),
      isLast: false,
    );
    if (!_trilhaViva(trail)) return;
    switch (action) {
      case StageSummaryAction.next:
      case StageSummaryAction.train:
        break;
      case StageSummaryAction.retry:
        trail.repeat(stage);
        unawaited(startStage());
      case StageSummaryAction.skip:
        trail.skipBlock(blockIndex);
        break;
      case StageSummaryAction.review:
      case null:
        break;
    }
  }

  /// Compassos lógicos com erro para o resumo.
  List<int> _badLogical(TrailCubit trail, StageResult result) {
    final numbers = <int>{};
    for (final occurrence in result.badMeasures) {
      final logical = trail.path.logicalOf(occurrence);
      if (logical != null) numbers.add(trail.path.logical[logical].number);
    }
    return numbers.toList()..sort();
  }

  /// Para a etapa no meio: sem registro e sem resumo.
  void abandonStage() {
    if (_practice == null || _trail == null) return;
    _endRun();
  }

  /// Solta o que a etapa prendeu e devolve os controles do aluno (andamento
  /// do agendador, metrônomo, cor de destaque).
  void _endRun() {
    final practice = _practice;
    if (practice == null) return;
    _releasePlayer();
    practice.stop();
    practice.dispose();
    _practice = null;
    _playback.scheduler?.setSpeed(_playback.speed);
    _playback.scheduler?.metronomeOn = _settings.state.metronomeOn;
    _playback.player?.pause();
    _playback.player?.cancelTurn();
    _trail?.setRunning(false);
    _changed();
    if (!_disposed) _playback.setPlaying(false);
  }

  /// Devolve a cor de destaque configurada (o treino usa o azul de
  /// "esperado agora") e desiste de soltar o player depois da contagem.
  void _releasePlayer() {
    final player = _playback.player;
    player?.highlightColor = _settings.state.highlightColor;
    player?.highlightColorOf = null;
    player?.skipHighlight = null;
    _playback.cancelPlayAfterCount();
  }

  /// "Praticar" (T02): o treino livre, com [hand] para o aluno e o app
  /// tocando a outra mão, a partir do loop (se houver). Precisa de som — o
  /// agendador que toca a mão do app é o mesmo do interruptor "som" — e
  /// abre o motor/pede um `.sf2` na primeira vez. Com treino em curso, para.
  Future<void> togglePractice({
    required Hand hand,
    required PracticeMode mode,
  }) async {
    if (_practice != null) {
      stopPractice();
      return;
    }
    final track = _session.track;
    final player = _playback.player;
    if (track == null || player == null) return;
    clearErrorMarks();
    final scheduler = await _ensureScheduler();
    if (scheduler == null) return;

    scores.clearAll();
    final range = _playback.loopRangeMs;
    final fromMs = range?.startMs ?? 0;
    _paintForPractice(player, track, hand, mode);
    player.seek(Duration(microseconds: (fromMs * 1000).round()));
    await loadInputLatency();
    if (_disposed) return;
    shiftDetector.rearm();
    final practice = PracticeController(
      midiInput: _midiInput,
      track: track,
      scheduler: scheduler,
      controller: scores,
      hand: hand,
      ghosts: ghosts,
      inputLatencyMs: state.inputLatencyMs,
      writtenFromReceived: writtenFromReceived,
      shiftDetector: shiftDetector,
      onShift: onShift,
      mode: mode,
      measureIndexAt: player.timeline.measureIndexAt,
      passOf: (i) => player.measures[i].pass,
      onLoopRestart: (ms) =>
          player.seek(Duration(microseconds: (ms * 1000).round())),
      onWaitTarget: (ms) => player.waitTarget = ms,
      correctColor: _settings.state.highlightColor,
      wrongColor: _settings.state.practiceWrongColor,
      pendingColor: _settings.state.practicePendingColor,
      rhythmToleranceMs: _settings.state.rhythmToleranceMs,
    );
    practice.start(fromMs: fromMs, countIn: mode != PracticeMode.wait);
    if (range != null) practice.setLoop(range.startMs, range.endMs);
    _playback.playPlayerAfterCount(fromMs);
    // No treino, o "esperado agora" acende na cor própria (azul por
    // padrão): o vermelho padrão do player confundia pendente com errada.
    player.highlightColor = _settings.state.practicePendingColor;
    _sound.markSoundOn();
    _practice = practice;
    _changed();
    _playback.setPlaying(true);
  }

  /// Cores do destaque durante o treino (U08), antes do `seek` que acende o
  /// instante de partida: "esperada" para as notas do aluno e cinza para as
  /// da mão que o app toca. No modo espera as notas do aluno são do
  /// `PracticeController` (esperada/certa em camadas): o player não as acende.
  void _paintForPractice(
    ScorePlayer player,
    PerformanceTrack track,
    Hand hand,
    PracticeMode mode,
  ) {
    player.highlightColor = _settings.state.practicePendingColor;
    final appNotes = appHandNoteIds(track, hand);
    player.highlightColorOf = appNotes.isEmpty
        ? null
        : (id) => appNotes.contains(id) ? kPracticeAppHandColor : null;
    if (mode == PracticeMode.wait) {
      final doc = player.document;
      final studentNotes = {
        for (final id in studentHandNoteIds(track, hand)) ...[
          id,
          doc.sceneIdOf(id) ?? id,
        ],
      };
      player.skipHighlight = studentNotes.contains;
    } else {
      player.skipHighlight = null;
    }
  }

  /// Encerra o treino: solta freio/filtro/destaques, descarta o controlador
  /// e — no tempo real, se algo foi avaliado — marca os compassos com erro
  /// e passa o relatório a [TrailRunnerHost.practiceReport] (T03).
  void endPractice() {
    final practice = _practice;
    if (practice == null) return;
    PracticeReport? report;
    _releasePlayer();
    _playback.player?.cancelTurn();
    if (practice.mode != PracticeMode.wait && practice.hasVerdicts) {
      practice.finish();
      report = practice.report;
    }
    final wrongMarks = practice.wrongMarks;
    practice.stop();
    practice.dispose();
    _practice = null;
    _changed();
    if (_disposed) return;
    if (report != null) {
      markErrors([
        for (final m in report.measures)
          if (m.errors + m.imprecise > 0) m.index,
      ]);
    }
    _keepWrongMarks(wrongMarks);
    if (report != null) host.practiceReport(report);
  }

  /// Para o treino em curso e volta ao estado pausado normal —
  /// [PracticeController.stop] já solta o freio/filtro do agendador e os
  /// destaques.
  void stopPractice() {
    if (_practice == null) return;
    endPractice();
    _playback.player?.pause();
    if (!_disposed) _playback.setPlaying(false);
  }

  @override
  Future<void> close() {
    _disposed = true;
    unawaited(_settingsSub.cancel());
    _listenTimer?.cancel();
    _practice?.dispose();
    _soltaTrilha();
    return super.close();
  }
}
