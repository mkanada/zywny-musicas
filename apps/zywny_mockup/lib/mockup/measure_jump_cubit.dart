// Estado da folha "Ir para o compasso" (`PracticeScreen`): o compasso que o
// slider mostra antes de o aluno confirmar. Só a folha o usa; fechá-la sem
// "Ir" descarta o valor.

import 'package:zywny_bloc/zywny_bloc.dart';

class MeasureJumpState extends Equatable {
  const MeasureJumpState({required this.target});

  /// O compasso escolhido no slider.
  final int target;

  MeasureJumpState copyWith({int? target}) =>
      MeasureJumpState(target: target ?? this.target);

  @override
  List<Object?> get props => [target];
}

class MeasureJumpCubit extends Cubit<MeasureJumpState> {
  MeasureJumpCubit(int inicial) : super(MeasureJumpState(target: inicial));

  /// O slider mexeu: o compasso passa a ser o escolhido.
  void escolher(int compasso) => emit(state.copyWith(target: compasso));
}
