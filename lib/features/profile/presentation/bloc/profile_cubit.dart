import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/features/auth/data/auth_repository.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileState {
  const ProfileState(
      {required this.status,
      this.name = '',
      this.email = '',
      this.image = '',
      this.phone = '',
      this.error});

  final ProfileStatus status;
  final String name;
  final String email;
  final String image;
  final String phone;
  final String? error;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const ProfileState(status: ProfileStatus.loading));

  final AuthRepository _repository;

  Future<void> load() async {
    try {
      final data = await _repository.getUserData() ?? <String, dynamic>{};
      emit(ProfileState(
        status: ProfileStatus.ready,
        name: data['name']?.toString() ?? '',
        email:
            _repository.currentUser?.email ?? data['email']?.toString() ?? '',
        image: data['image']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
      ));
    } catch (error) {
      emit(
          ProfileState(status: ProfileStatus.failure, error: error.toString()));
    }
  }

  Future<void> updateProfile(
      {required String name, required String phone}) async {
    await _repository.updateCurrentUser({'name': name, 'phone': phone});
    emit(ProfileState(
        status: ProfileStatus.ready,
        name: name,
        email: state.email,
        image: state.image,
        phone: phone));
  }
}
