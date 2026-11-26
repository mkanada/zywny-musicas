// R09: a gravura da partitura aberta — pedir o render, a fila de renders,
// a transposição com que foi gravada, o tamanho da caixa e o layout do
// hino. Saiu de `_ScoreHomePageState` (achado 5 da revisão); a tela ouve o
// Cubit e, a cada documento novo ([ScoreRenderCubit.onDocument]), monta o
// que toca.
//
// BL13: é um Cubit. A gravura, a página, o tom, o layout e o andamento do
// render estão no estado; a caixa (`_box`) e a fila de renders ficam fora
// dele de propósito: [setBox] é chamado do `build` e não avisa a tela.

// Os parâmetros são públicos e os campos, privados (como no R09).
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:score_bridge/score_bridge.dart' show VsbDocument;
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_clock/zywny_clock.dart';

import 'package:zywny_library/piece.dart';

import 'package:zywny_audio/performance_track.dart';

import 'package:zywny_music/transposition.dart';

import 'package:zywny_comum/render/layout_options.dart';
import 'package:zywny_comum/ui/device_kind.dart';
import 'package:zywny_comum/render/score_renderer.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/settings/effective_transposition.dart';
import 'package:zywny_comum/settings/piece_settings.dart';

/// Uma gravura nova chegou: [document] e a [track] tocável dela. O Cubit
/// já trocou o seu estado (documento, transposição, página) quando chama.
typedef ScoreDocumentCallback = void Function(
  VsbDocument document,
  PerformanceTrack track,
);

/// Quanto o celular espera a caixa deitada antes de gravar a partitura na
/// caixa em pé (ver `ScoreRenderCubit.setBox`).
const kRotationGrace = Duration(milliseconds: 1200);

/// O que a gravura mostra e o que a pessoa mudou nela (o tamanho da página, o
/// layout deste hino e o tom, fase Q).
class ScoreRenderState extends Equatable {
  const ScoreRenderState({
    this.document,
    this.track,
    this.pageIndex = 0,
    this.status = 'nenhuma partitura',
    this.error,
    this.busy = false,
    this.renderedTransposition,
    this.originalRange,
    this.transposeChoice,
    this.layoutOverrides = const {},
    this.pageFitsBox = true,
    this.serial = 0,
  });

  /// A gravura na tela; `null` até a primeira.
  final VsbDocument? document;

  /// As notas tocáveis de [document].
  final PerformanceTrack? track;

  final int pageIndex;
  final String status;

  /// A última gravação falhou — o celular não tem linha de status, então o
  /// motivo aparece no lugar da partitura.
  final String? error;

  /// Um render em curso.
  final bool busy;

  /// A transposição com que [document] foi gravado (`null` = no tom
  /// original).
  final Transposition? renderedTransposition;

  /// A faixa da música **original** lida do `midi.json` da última gravura.
  final ({int lowest, int highest})? originalRange;

  /// A escolha de transposição deste hino: `null` = a pessoa não escolheu,
  /// [kTransposeNone] = "Não", ou um intervalo.
  final String? transposeChoice;

  /// Só o que a pessoa mudou: é isto que [ScoreRenderCubit.saveLayout] guarda
  /// para todos os hinos. O resto é o padrão do aparelho.
  final Map<String, Object> layoutOverrides;

  /// Se a página sai da caixa da partitura ou de `pageWidth`/`pageHeight`.
  final bool pageFitsBox;

  /// Sobe a cada [ScoreRenderCubit.boxSeen]: o aviso da primeira caixa é
  /// uma renotificação do mesmo valor, e o Cubit só avisa se algo muda.
  final int serial;

  ScoreRenderState copyWith({
    VsbDocument? document,
    PerformanceTrack? track,
    int? pageIndex,
    String? status,
    String? Function()? error,
    bool? busy,
    Transposition? Function()? renderedTransposition,
    ({int lowest, int highest})? originalRange,
    String? transposeChoice,
    Map<String, Object>? layoutOverrides,
    bool? pageFitsBox,
    int? serial,
  }) => ScoreRenderState(
    document: document ?? this.document,
    track: track ?? this.track,
    pageIndex: pageIndex ?? this.pageIndex,
    status: status ?? this.status,
    error: error == null ? this.error : error(),
    busy: busy ?? this.busy,
    renderedTransposition: renderedTransposition == null
        ? this.renderedTransposition
        : renderedTransposition(),
    originalRange: originalRange ?? this.originalRange,
    transposeChoice: transposeChoice ?? this.transposeChoice,
    layoutOverrides: layoutOverrides ?? this.layoutOverrides,
    pageFitsBox: pageFitsBox ?? this.pageFitsBox,
    serial: serial ?? this.serial,
  );

  @override
  List<Object?> get props => [
    document,
    track,
    pageIndex,
    status,
    error,
    busy,
    renderedTransposition,
    originalRange,
    transposeChoice,
    layoutOverrides,
    pageFitsBox,
    serial,
  ];
}

/// A gravura da partitura aberta e o que muda nela: o tamanho da caixa
/// ([setBox]), o layout deste hino e o tom (fase Q).
///
/// Um render por vez: o que for pedido durante um fica na fila e sai, um
/// só, quando ele acaba, com as opções da hora. A página anterior continua
/// na tela enquanto isso.
class ScoreRenderCubit extends Cubit<ScoreRenderState> {
  ScoreRenderCubit({
    required ScoreRenderer renderer,
    required Uint8List scoreXml,
    required Piece piece,
    required SettingsCubit settings,
    required PieceSettings stored,
    required this.clock,
    required this.name,
    this.kind = DeviceKind.desktop,
    this.pixelRatio = 1,
    this.debugMode = false,
    this.onDocument,
    this.resizeDebounce = const Duration(milliseconds: 400),
    this.rotationGrace = kRotationGrace,
  }) : _renderer = renderer,
       _scoreXml = scoreXml,
       _piece = piece,
       _settings = settings,
       super(
         ScoreRenderState(
           transposeChoice: stored.transpose,
           layoutOverrides: layoutOverridesFrom(settings.state.scoreLayout),
           pageFitsBox: settings.state.scorePageFitsBox,
         ),
       ) {
    _settingsSub = _settings.stream.listen((_) => _onSettingsChanged());
  }

  final ScoreRenderer _renderer;
  final Uint8List _scoreXml;

  /// O relógio do app (CT05f): o respiro entre a caixa mudar e a gravura.
  final AppClock clock;
  final Piece _piece;
  final SettingsCubit _settings;
  late final StreamSubscription<SettingsState> _settingsSub;

  /// Como a partitura é chamada no status ("13 · Hino").
  final String name;

  /// O aparelho: no celular o layout começa com [kPhoneUnit] e uma caixa em
  /// pé é, de início, o aparelho ainda girando (ver [setBox]); no tablet,
  /// com [tabletUnit].
  final DeviceKind kind;

  /// Densidade da tela: no tablet e no desktop o `unit` padrão a acompanha
  /// ([tabletUnit], [screenUnit]).
  final double pixelRatio;

  /// `--debug`: pede ao Verovio o `.vsb` com as opções e a fonte embutidas.
  final bool debugMode;

  /// Chamado a cada gravura nova; ver [ScoreDocumentCallback].
  ScoreDocumentCallback? onDocument;

  /// O respiro entre a caixa mudar e a partitura ser gravada de novo.
  final Duration resizeDebounce;

  /// Quanto o celular espera a caixa deitada ([kRotationGrace]).
  final Duration rotationGrace;

  bool _disposed = false;

  /// A caixa da partitura (pixels do aparelho). Fica fora do estado: a tela a
  /// informa no `build`, e isso não pode avisar a tela de novo.
  Size? _box;
  AppTimer? _resizeTimer;

  /// Um pedido chegou durante um render: sai quando ele acabar.
  bool _renderQueued = false;

  VsbDocument? get document => state.document;

  /// As notas tocáveis de [document].
  PerformanceTrack? get track => state.track;

  int get pageIndex => state.pageIndex;
  int get pageCount => state.document?.pages.length ?? 0;
  String get status => state.status;

  /// A última gravação falhou — o celular não tem linha de status, então
  /// o motivo aparece no lugar da partitura.
  String? get error => state.error;

  /// Um render em curso.
  bool get busy => state.busy;

  /// A transposição com que [document] foi gravado (`null` = no tom
  /// original).
  Transposition? get renderedTransposition => state.renderedTransposition;

  /// A faixa da música **original** lida do `midi.json` da última gravura,
  /// em MIDI. Antes da primeira gravura é `null` e vale a do catálogo; com
  /// ela, a direção da transposição é conferida contra o teclado (Q03).
  ({int lowest, int highest})? get originalRange => state.originalRange;

  /// A escolha de transposição deste hino: `null` = a pessoa não escolheu
  /// (vale a chave geral), [kTransposeNone] = "Não", ou um intervalo.
  String? get transposeChoice => state.transposeChoice;

  /// Opções do Verovio, por nome (ver `layout_options.dart`): as que a pessoa
  /// mudou, para todos os hinos, sobre o padrão do aparelho.
  Map<String, Object> get layout => {
    ...layoutDefaults,
    ...state.layoutOverrides,
  };

  /// O layout deste aparelho sem nenhuma mudança da pessoa.
  Map<String, Object> get layoutDefaults => initialLayoutValues(
    phone: kind == DeviceKind.phone,
    tablet: kind == DeviceKind.tablet,
    pixelRatio: pixelRatio,
  );

  /// Se a página sai da caixa da partitura ou de `pageWidth`/`pageHeight`.
  bool get pageFitsBox => state.pageFitsBox;

  /// A transposição com que este hino abre agora: a escolha dele, ou a
  /// chave geral. `null` = o tom original.
  Transposition? get transposition => transpositionFor(state.transposeChoice);

  /// A transposição que [choice] daria a este hino.
  Transposition? transpositionFor(String? choice) {
    return effectiveTransposition(
      _piece,
      PieceSettings(transpose: choice),
      _settings,
      range: state.originalRange,
    );
  }

  /// "Sem acidentes" para este hino; `null` sem armadura ou já em Dó.
  Transposition? get noAccidentals {
    final fifths = _piece.fifths;
    if (fifths == null) return null;
    final range = state.originalRange;
    return Transposition.toNoAccidentals(
      fifths,
      range: (
        lowest: range?.lowest ?? kCatalogLowestMidi,
        highest: range?.highest ?? kCatalogHighestMidi,
      ),
    );
  }

  /// Paper size, in tenths of a millimetre, that makes one device pixel one
  /// unit — i.e. the page is engraved at 254 dpi and drawn 1:1, which is the
  /// configuration `compare` measured against the reference SVG. Anything
  /// larger would show the notation shrunk, pushing stroke widths below a
  /// pixel (a 0.13 mm staff line needs ~7.7 px/mm to survive).
  Size? get fittedPage {
    final box = _box;
    if (box == null) return null;
    return Size(
      box.width
          .round()
          .clamp(kVerovioMinPageWidth, kVerovioMaxPageWidth)
          .toDouble(),
      box.height
          .round()
          .clamp(kVerovioMinPageHeight, kVerovioMaxPageHeight)
          .toDouble(),
    );
  }

  int get _pageWidth => state.pageFitsBox
      ? fittedPage!.width.round()
      : layout['pageWidth'] as int;

  int get _pageHeight => state.pageFitsBox
      ? fittedPage!.height.round()
      : layout['pageHeight'] as int;

  /// Every option that reaches Verovio for the current state: the page size
  /// plus whatever differs from Verovio's defaults.
  Map<String, Object> get effectiveOptions => {
    'pageWidth': _pageWidth,
    'pageHeight': _pageHeight,
    ...layoutOptionsToSend(layout),
    'transpose': ?transposition?.interval,
    if (debugMode) 'vsbDebug': true,
  };

  /// Records the score box (device pixels) and re-engraves when it really
  /// changed. Devolve `true` na primeira caixa (o painel de layout, montado
  /// antes dela, ainda não mostra o tamanho da página).
  ///
  /// Chamado do `build` da tela, então nunca avisa os ouvintes na hora: o
  /// render passa por um respiro, também porque arrastar a janela muda a
  /// caixa a cada quadro, e cada uma é um render pela FFI.
  bool setBox(Size devicePx) {
    final previous = _box;
    if (previous == devicePx) return false;
    _box = devicePx;
    // No celular a tela é travada em paisagem, mas abre a partir da
    // biblioteca em retrato: uma caixa mais alta que larga é, de início, só
    // o aparelho ainda girando, e gravar a partitura para ela seria trabalho
    // jogado fora (a caixa em paisagem chega logo depois). Se ela não vier —
    // o sistema pode ignorar a trava, como o Android 16 em tela grande —, a
    // caixa em pé é gravada assim mesmo, depois de [rotationGrace]: nunca
    // uma tela em branco.
    // Com a partitura já gravada deitada, uma caixa em pé é o aparelho
    // voltando à biblioteca: nada a gravar, como sempre.
    if (kind == DeviceKind.phone && devicePx.height > devicePx.width) {
      if (state.document == null && !state.busy) {
        _resizeTimer?.cancel();
        _resizeTimer = clock.timer(rotationGrace, render);
      }
      return previous == null;
    }
    if (state.document == null && !state.busy) {
      // Nada gravado ainda: a primeira gravura sai assim que há caixa.
      _resizeTimer?.cancel();
      _resizeTimer = clock.timer(Duration.zero, render);
      return previous == null;
    }
    // A fixed page size does not depend on the box, so a resize has nothing
    // to re-engrave.
    if (previous == null || !state.pageFitsBox) return previous == null;
    // 2% of slack: a one-pixel wobble is not worth re-engraving the piece.
    final changed =
        (previous.width - devicePx.width).abs() / previous.width > 0.02 ||
        (previous.height - devicePx.height).abs() / previous.height > 0.02;
    if (!changed) return false;
    _resizeTimer?.cancel();
    _resizeTimer = clock.timer(resizeDebounce, render);
    return false;
  }

  /// A página que a vista mostra mudou.
  void setPage(int target) {
    if (pageCount == 0) return;
    emit(
      state.copyWith(
        pageIndex: target,
        status: pageCount > 1
            ? 'página ${target + 1} de $pageCount'
            : 'pronto ✓',
      ),
    );
  }

  /// Uma opção de layout mudou (o slider andando): só o valor; a partitura
  /// é gravada de novo em [render], quando a mudança assenta, e o valor vai
  /// para todos os hinos em [saveLayout].
  void setLayoutValue(String key, Object value) {
    emit(
      state.copyWith(layoutOverrides: {...state.layoutOverrides, key: value}),
    );
  }

  void setPageFitsBox(bool value) => emit(state.copyWith(pageFitsBox: value));

  /// A primeira caixa foi medida e o painel do layout precisa mostrar o
  /// tamanho da página: avisa os ouvintes mesmo sem mudança de campo.
  void boxSeen() => emit(state.copyWith(serial: state.serial + 1));

  /// Guarda o layout e a página para todos os hinos. Quem chama grava a
  /// partitura de novo ([render]) logo depois.
  void saveLayout() {
    _settings
      ..setScoreLayout(state.layoutOverrides)
      ..setScorePageFitsBox(state.pageFitsBox);
  }

  /// Volta ao layout padrão do app, para todos os hinos. Não guarda nem grava
  /// de novo: quem chama faz isso ([saveLayout] e [render]).
  void resetLayout() {
    emit(state.copyWith(layoutOverrides: const {}, pageFitsBox: true));
  }

  /// Guarda a escolha de tom ([transposeChoice]) e grava a partitura de
  /// novo se o tom mudou. Devolve `false` se a escolha já era essa.
  bool chooseTranspose(String choice) {
    if (choice == state.transposeChoice) return false;
    emit(state.copyWith(transposeChoice: choice));
    // Mesmo tom (ex.: "Não" quando a chave geral já está desligada): só
    // guarda a escolha, a partitura é a mesma.
    if (transposition != state.renderedTransposition) unawaited(render());
    return true;
  }

  /// "Abrir as músicas já sem acidentes" mudou e este hino não tem escolha
  /// própria: a partitura é gravada de novo no outro tom.
  void _onSettingsChanged() {
    if (_disposed) return;
    if (state.document != null &&
        transposition != state.renderedTransposition) {
      unawaited(render());
    }
  }

  /// Grava a partitura com as opções de agora e a mostra. A página anterior
  /// fica na tela enquanto isso, para comparar o efeito de uma opção no
  /// mesmo zoom. Com um render em curso, entra na fila.
  Future<void> render() async {
    if (_box == null || _disposed) return;
    if (state.busy) {
      _renderQueued = true;
      return;
    }

    final pageWidth = _pageWidth;
    final pageHeight = _pageHeight;
    final transposition = this.transposition;
    // A página vai à parte, em ScoreRenderRequest.
    final options = effectiveOptions
      ..remove('pageWidth')
      ..remove('pageHeight');

    emit(
      state.copyWith(
        busy: true,
        error: () => null,
        status: 'renderizando $name ($pageWidth×$pageHeight)…',
      ),
    );

    var wrongDirection = false;
    try {
      final watch = Stopwatch()..start(); // relógio: medida de desenho
      final rendered = await _renderer.render(
        ScoreRenderRequest(
          source: _scoreXml,
          fileName: '${_piece.id}.musicxml',
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          options: options,
        ),
      );
      final document = rendered.document;
      debugPrint(
        'ScoreRenderCubit: render($name) levou '
        '${watch.elapsedMilliseconds}ms',
      );
      if (_disposed) return;
      // Recusa antes de trocar o estado: daqui em diante ele é trocado de uma
      // vez e precisa de ao menos uma página.
      if (document.pages.isEmpty) {
        throw StateError('a gravura veio sem páginas');
      }
      final track = PerformanceTrack.fromDocument(document);
      wrongDirection = _adopt(rendered, track, transposition);
      onDocument?.call(document, track);
    } catch (e) {
      _failRender(e);
    }

    if (!_disposed && (_renderQueued || wrongDirection)) {
      _renderQueued = false;
      unawaited(render());
    }
  }

  /// Põe a gravura [rendered], com a faixa [track] e a [transposition] com que
  /// foi feita, no lugar da anterior. Devolve `true` se a direção da
  /// transposição mudou enquanto ela gravava (a faixa real pede outra).
  bool _adopt(
    RenderedScore rendered,
    PerformanceTrack track,
    Transposition? transposition,
  ) {
    final document = rendered.document;
    // Com a faixa real da música, a direção da transposição pode mudar (o
    // hino passaria do teclado): nesse caso grava de novo, no fim. A faixa
    // vai ao estado antes da conta, que a lê.
    final range = _rangeOf(document, transposition) ?? state.originalRange;
    emit(state.copyWith(originalRange: range));
    final wrongDirection = this.transposition != transposition;
    // New options reflow the score: the page we were on may not exist
    // any more.
    final page = state.pageIndex.clamp(0, document.pages.length - 1);
    var status = document.pages.length > 1
        ? 'página ${page + 1} de ${document.pages.length}'
        : 'carregada ✓';
    if (rendered.debugCopyPath case final path?) {
      status = '$status — .vsb salvo em $path';
    }
    emit(
      state.copyWith(
        document: document,
        track: track,
        busy: false,
        renderedTransposition: () => transposition,
        pageIndex: page,
        status: status,
      ),
    );
    return wrongDirection;
  }

  /// A gravura de [error] falhou: a página anterior fica na tela, com o erro
  /// na barra de status.
  void _failRender(Object error) {
    if (_disposed) return;
    emit(
      state.copyWith(
        status: 'erro: $error',
        error: () => '$error',
        busy: false,
      ),
    );
  }

  /// A nota mais grave e a mais aguda da música **original** em [document],
  /// que foi gravado com [transposition] (as alturas do `midi.json` já saem
  /// transpostas). `null` sem notas.
  static ({int lowest, int highest})? _rangeOf(
    VsbDocument document,
    Transposition? transposition,
  ) {
    final notes = document.midi?.notes;
    if (notes == null || notes.isEmpty) return null;
    final shift = transposition?.semitones ?? 0;
    return (
      lowest: notes.map((n) => n.pitch).reduce(math.min) - shift,
      highest: notes.map((n) => n.pitch).reduce(math.max) - shift,
    );
  }

  @override
  Future<void> close() {
    _disposed = true;
    _resizeTimer?.cancel();
    unawaited(_settingsSub.cancel());
    return super.close();
  }
}
