import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_model.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    try {
      await _db.collection('user').doc(cred.user!.uid).set({
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
      // Auth đã tạo thành công, bỏ qua lỗi Firestore
    }
  }

  static Future<void> logout() => _auth.signOut();

  static Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('user').doc(uid).get();
    return doc.data();
  }

  static Future<UserModel?> getUserModel() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('user').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  static Future<void> updateCurrentUser(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('user').doc(uid).set(data, SetOptions(merge: true));
  }
}
