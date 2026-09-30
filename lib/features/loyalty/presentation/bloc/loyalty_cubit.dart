import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/user.dart';
import 'package:lelahanoi/features/auth/data/auth_repository.dart';

enum LoyaltyStatus { loading, ready, failure }

class LoyaltyState {
  const LoyaltyState({required this.status, this.user, this.error});

  final LoyaltyStatus status;
  final UserModel? user;
  final String? error;
}

class LoyaltyCubit extends Cubit<LoyaltyState> {
  LoyaltyCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const LoyaltyState(status: LoyaltyStatus.loading));

  final AuthRepository _repository;

  Future<void> load() async {
    try {
      emit(LoyaltyState(
          status: LoyaltyStatus.ready, user: await _repository.getUserModel()));
    } catch (error) {
      emit(
          LoyaltyState(status: LoyaltyStatus.failure, error: error.toString()));
    }
  }
}
