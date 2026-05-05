import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../repositories/auth_repository.dart';
import '../../utils/api_failure.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

class AuthSignupEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  const AuthSignupEvent(
      {required this.email, required this.password, required this.name});
  @override
  List<Object?> get props => [email, password, name];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

class AuthAuthenticatedState extends AuthState {
  final UserModel user;
  const AuthAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthSignupEvent>(_onSignup);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onCheckStatus(
      AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticatedState(user));
      } else {
        emit(const AuthUnauthenticatedState());
      }
    } catch (_) {
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> _onSignup(
      AuthSignupEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      final result = await _authRepository.signup(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      emit(AuthAuthenticatedState(result.user));
    } on ApiFailure catch (e) {
      emit(AuthErrorState(e.message));
      // Re-emit unauthenticated so login screen shows the error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const AuthUnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> _onLogin(
      AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      final result = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticatedState(result.user));
    } on ApiFailure catch (e) {
      emit(AuthErrorState(e.message));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const AuthUnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> _onLogout(
      AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticatedState());
  }
}
