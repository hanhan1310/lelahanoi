import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/features/auth/data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated, failure }

class AuthState {
  const AuthState({
    required this.status,
    this.isManager = false,
    this.userId,
    this.errorCode,
    this.registrationCompleted = false,
  });

  final AuthStatus status;
  final bool isManager;
  final String? userId;
  final String? errorCode;
  final bool registrationCompleted;

  AuthState copyWith({
    AuthStatus? status,
    bool? isManager,
    String? userId,
    String? errorCode,
    bool clearError = false,
    bool? registrationCompleted,
  }) {
    return AuthState(
      status: status ?? this.status,
      isManager: isManager ?? this.isManager,
      userId: userId ?? this.userId,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      registrationCompleted:
          registrationCompleted ?? this.registrationCompleted,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository)
      : super(const AuthState(status: AuthStatus.checking)) {
    _authSubscription = _repository.authStateChanges.listen(_onAuthChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<bool>? _roleSubscription;

  Future<void> _onAuthChanged(User? user) async {
    await _roleSubscription?.cancel();

    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    emit(const AuthState(status: AuthStatus.checking));
    _roleSubscription = _repository.watchManagerRole(user.uid).listen(
          (isManager) => emit(AuthState(
            status: AuthStatus.authenticated,
            isManager: isManager,
            userId: user.uid,
          )),
          onError: (_) => emit(
              AuthState(status: AuthStatus.authenticated, userId: user.uid)),
        );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.checking, clearError: true));
    try {
      await _repository.login(email, password);
    } on FirebaseAuthException catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorCode: error.code));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.failure, errorCode: 'unknown'));
    }
  }

  Future<void> register(String name, String email, String password) async {
    emit(state.copyWith(status: AuthStatus.checking, clearError: true));
    try {
      await _repository.register(name, email, password);
      emit(state.copyWith(registrationCompleted: true));
    } on FirebaseAuthException catch (error) {
      emit(AuthState(status: AuthStatus.failure, errorCode: error.code));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.failure, errorCode: 'unknown'));
    }
  }

  Future<void> logout() => _repository.logout();

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _roleSubscription?.cancel();
    return super.close();
  }
}
