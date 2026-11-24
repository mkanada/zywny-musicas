// O modo de treino e a mão do aluno nesta partitura (T02): o que a gaveta ⋯
// mostra e o que o Play faz. Eram `_trainingMode` e `_hand` do
// `_ScoreHomePageState`; o modo de estudo (ouvir ou esperar, tempo real) é
// a configuração geral, em `SettingsCubit`.

import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/practice/hand.dart';

/// Se o aluno treina (com teclado) e com que mão.
class ScoreModeState extends Equatable {
  const ScoreModeState({this.trainingMode = false, this.hand = Hand.direita});

  /// O modo treino está armado (só vale no Play com um teclado conectado).
  final bool trainingMode;

  /// A mão do aluno.
  final Hand hand;

  ScoreModeState copyWith({bool? trainingMode, Hand? hand}) => ScoreModeState(
    trainingMode: trainingMode ?? this.trainingMode,
    hand: hand ?? this.hand,
  );

  @override
  List<Object?> get props => [trainingMode, hand];
}

/// Troca a mão e liga ou desliga o modo treino.
class ScoreModeCubit extends Cubit<ScoreModeState> {
  ScoreModeCubit({required Hand hand})
    : super(ScoreModeState(hand: hand));

  /// Troca a mão do aluno (o seletor só aparece sem treino em andamento).
  void setHand(Hand hand) => emit(state.copyWith(hand: hand));

  /// Liga ou desliga o modo treino. Entrar pede uma mão só: se estavam as
  /// duas, fica a direita. Sair devolve as duas. Quem chama cuida do treino
  /// parado e do andamento (`_setTrainingFromDrawer`).
  void setTraining(bool training) {
    if (training == state.trainingMode) return;
    final hand = training
        ? (state.hand == Hand.ambas ? Hand.direita : state.hand)
        : Hand.ambas;
    emit(state.copyWith(trainingMode: training, hand: hand));
  }
}
