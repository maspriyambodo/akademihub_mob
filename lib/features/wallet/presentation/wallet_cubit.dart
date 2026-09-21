import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/wallet_repository.dart';

class WalletState {
  final bool busy;
  final String? error;
  final WalletPageData? page;
  const WalletState({this.busy = false, this.error, this.page});
}

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;
  WalletCubit(this.repository) : super(const WalletState());
  Future<void> load(String path, {int page = 1, WalletRecord? query}) async {
    if (state.busy) return;
    emit(WalletState(busy: true, page: state.page));
    try {
      final result = await repository.list(path, page: page, query: query);
      if (!isClosed) emit(WalletState(page: result));
    } catch (e) {
      if (!isClosed) emit(WalletState(error: walletError(e)));
    }
  }
}
