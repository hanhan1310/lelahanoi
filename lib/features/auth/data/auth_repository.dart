import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lelahanoi/core/models/user.dart';

/// Firebase adapter for authentication and the current user's profile.
///
/// The presentation layer talks to this repository through AuthCubit instead
/// of reaching Firebase directly.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? (Firebase.apps.isEmpty ? null : FirebaseAuth.instance),
        _db = firestore ??
            (Firebase.apps.isEmpty ? null : FirebaseFirestore.instance);

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream.value(null);

  Stream<bool> watchManagerRole(String uid) {
    return _db?.collection('user').doc(uid).snapshots().map(
              (snapshot) => snapshot.data()?['role']?.toString() == 'manager',
            ) ??
        Stream.value(false);
  }

  Future<UserCredential> login(String email, String password) {
    return (_auth ?? (throw StateError('Firebase is not initialized')))
        .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String name, String email, String password) async {
    final credential =
        await (_auth ?? (throw StateError('Firebase is not initialized')))
            .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      await (_db ?? (throw StateError('Firebase is not initialized')))
          .collection('user')
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': '',
        'image': '',
        'point': 0,
        'total_money_spend': 0,
        'role': 'customer',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Keep the original behavior: an auth account is still valid when the
      // profile document cannot be written.
    }
  }

  Future<void> logout() =>
      (_auth ?? (throw StateError('Firebase is not initialized'))).signOut();

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final document =
        await (_db ?? (throw StateError('Firebase is not initialized')))
            .collection('user')
            .doc(uid)
            .get();
    return document.data();
  }

  Future<UserModel?> getUserModel() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final document =
        await (_db ?? (throw StateError('Firebase is not initialized')))
            .collection('user')
            .doc(uid)
            .get();
    if (!document.exists) return null;
    return UserModel.fromMap(document.data() ?? <String, dynamic>{},
        id: document.id);
  }

  Future<void> updateCurrentUser(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await (_db ?? (throw StateError('Firebase is not initialized')))
        .collection('user')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}
