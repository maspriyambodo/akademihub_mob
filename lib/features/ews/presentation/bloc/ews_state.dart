part of 'ews_bloc.dart';

abstract class EwsState extends Equatable {
  final String? kategori;
  final int? level;
  final bool? onlyUnresolved;

  const EwsState({this.kategori, this.level, this.onlyUnresolved});

  @override
  List<Object?> get props => [kategori, level, onlyUnresolved];
}

class EwsInitial extends EwsState {
  const EwsInitial();
}

class EwsLoading extends EwsState {
  const EwsLoading({super.kategori, super.level, super.onlyUnresolved});
}

class EwsLoaded extends EwsState {
  final List<EwsAlertEntity> items;
  final String? actionMessage;

  const EwsLoaded({
    required this.items,
    super.kategori,
    super.level,
    super.onlyUnresolved,
    this.actionMessage,
  });

  @override
  List<Object?> get props => [items, kategori, level, onlyUnresolved, actionMessage];
}

class EwsError extends EwsState {
  final String message;
  const EwsError(this.message, {super.kategori, super.level, super.onlyUnresolved});

  @override
  List<Object?> get props => [message, kategori, level, onlyUnresolved];
}
