// As gavetas e os painéis da tela da partitura (BL14b): a gaveta "⋯", a
// gaveta da trilha, o painel do layout, o das configurações gerais e o
// monitor do MIDI. Eram cinco `bool` do `_ScoreHomePageState`; agora o
// Cubit diz o que abrir fecha junto (o layout e o geral não ficam abertos ao
// mesmo tempo, e a gaveta ⋯ fecha ao abrir um painel).

import 'package:zywny_bloc/zywny_bloc.dart';

/// Quais gavetas e painéis estão abertos na partitura.
class HomePanelsState extends Equatable {
  const HomePanelsState({
    this.options = false,
    this.layout = false,
    this.general = false,
    this.midi = false,
    this.trailDrawer = false,
  });

  /// A gaveta "⋯" (opções de estudo).
  final bool options;

  /// O painel "Layout deste hino".
  final bool layout;

  /// O painel "Configurações gerais".
  final bool general;

  /// O monitor do MIDI.
  final bool midi;

  /// A gaveta da trilha (J06).
  final bool trailDrawer;

  /// Alguma gaveta ou painel aberto: com um deles, o "voltar" só fecha.
  bool get anyOpen => options || layout || general || midi || trailDrawer;

  HomePanelsState copyWith({
    bool? options,
    bool? layout,
    bool? general,
    bool? midi,
    bool? trailDrawer,
  }) => HomePanelsState(
    options: options ?? this.options,
    layout: layout ?? this.layout,
    general: general ?? this.general,
    midi: midi ?? this.midi,
    trailDrawer: trailDrawer ?? this.trailDrawer,
  );

  @override
  List<Object?> get props => [options, layout, general, midi, trailDrawer];
}

/// Abre e fecha as gavetas e os painéis da partitura.
class HomePanelsCubit extends Cubit<HomePanelsState> {
  HomePanelsCubit() : super(const HomePanelsState());

  void openOptions() => emit(state.copyWith(options: true));

  void closeOptions() => emit(state.copyWith(options: false));

  void openStageDrawer() => emit(state.copyWith(trailDrawer: true));

  void closeTrailDrawer() => emit(state.copyWith(trailDrawer: false));

  /// O layout abre no lugar da gaveta ⋯ e do painel geral.
  void openLayout() =>
      emit(state.copyWith(options: false, general: false, layout: true));

  void closeLayout() => emit(state.copyWith(layout: false));

  /// O geral abre no lugar da gaveta ⋯ e do layout.
  void openGeneral() =>
      emit(state.copyWith(options: false, layout: false, general: true));

  void closeGeneral() => emit(state.copyWith(general: false));

  /// O monitor do MIDI abre a partir do painel geral, que fecha.
  void openMidi() => emit(state.copyWith(general: false, midi: true));

  void closeMidi() => emit(state.copyWith(midi: false));

  /// O "voltar" do aparelho com algo aberto fecha tudo.
  void closeAll() => emit(const HomePanelsState());
}
