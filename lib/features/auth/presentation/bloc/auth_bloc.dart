import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/notifications/push_notification_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final TokenStorage tokenStorage;
  final PushNotificationService pushNotifications;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.tokenStorage,
    required this.pushNotifications,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final hasToken = await tokenStorage.hasValidToken();
    if (!hasToken) return emit(AuthUnauthenticated());

    final result = await getCurrentUserUseCase();
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.requireData));
      unawaited(pushNotifications.syncToken());
    } else {
      emit(AuthError(result.requireFailure.message));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.identifier, event.password);
    if (result.isSuccess) {
      emit(AuthAuthenticated(result.requireData));
      unawaited(pushNotifications.syncToken());
    } else {
      emit(AuthError(result.requireFailure.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await pushNotifications.unregisterToken();
    await logoutUseCase();
    emit(AuthUnauthenticated());
  }
}
