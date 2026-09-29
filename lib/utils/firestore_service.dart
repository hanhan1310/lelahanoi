import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/category_model.dart';
import '../model/menu_model.dart';
import '../model/oder_model.dart';
import '../model/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String storeAddress = '369 Altstadt, 84028 Landshut';
  static const String storePhone = '015226673930';
  static const String storeEmail = 'manager@lelahanoi.de';

  // --- QUẢN LÝ CATEGORIES ---
  CollectionReference<CategoryModel> get _catRef => _db.collection('categories').withConverter<CategoryModel>(
        fromFirestore: CategoryModel.fromFirestore,
        toFirestore: (cat, _) => cat.toFirestore(),
      );

  Future<void> addCategory(String name) => _catRef.add(CategoryModel(id: '', name: name));
  Future<void> updateCategory(String id, String newName) => _catRef.doc(id).update({'name': newName});
  Future<void> deleteCategory(String id) => _catRef.doc(id).update({'is_delete': true});

  // --- QUẢN LÝ MENU ---
  CollectionReference<MenuModel> get _menuRef => _db.collection('menu').withConverter<MenuModel>(
        fromFirestore: MenuModel.fromFirestore,
        toFirestore: (item, _) => item.toFirestore(),
      );

  Future<void> addMenuItem(MenuModel item) => _menuRef.add(item);
  Future<void> updateMenuItem(MenuModel item) => _menuRef.doc(item.id).set(item);
  // Xóa mềm: truyền is_delete = true (Lưu ý: Bạn yêu cầu menu truyền false nhưng thường xóa là true, tôi để biến linh hoạt)
  Future<void> deleteMenuItem(String id, bool status) => _menuRef.doc(id).update({'is_delete': status});

  // --- QUẢN LÝ USER ---
  CollectionReference<UserModel> get _userRef => _db.collection('user').withConverter<UserModel>(
        fromFirestore: UserModel.fromFirestore,
        toFirestore: (u, _) => u.toFirestore(),
      );

  Future<void> addUser(UserModel user) => _userRef.add(user);
  Future<void> updateUser(UserModel user) => _userRef.doc(user.id).set(user);
  Future<void> deleteUser(String id) => _userRef.doc(id).delete();

  // --- QUẢN LÝ ĐƠN HÀNG (ORDERS) ---
  Future<void> createOrder(OrderModel order) async {
    final orderDoc = await _db.collection('orders').add(order.toFirestore());
    // Cập nhật tích điểm cho User sau khi mua hàng
    final userRef = _db.collection('user').doc(order.userId);
    await userRef.set({
      'point': FieldValue.increment(order.earnedPoints),
      'total_money_spend': FieldValue.increment(order.totalAmount),
      'tier': order.userTier,
    }, SetOptions(merge: true));
    await orderDoc.update({'id': orderDoc.id});
  }

  // Lấy đơn hàng theo User ID
  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersByUser(String userId) {
    return _db.collection('orders').where('user_id', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamOrders() {
    return _db.collection('orders').orderBy('created_at', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() {
    return _db.collection('user').orderBy('total_money_spend', descending: true).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> managerSettingsStream() {
    return _db.collection('settings').doc('manager').snapshots();
  }

  Future<Map<String, dynamic>> getManagerSettings() async {
    final doc = await _db.collection('settings').doc('manager').get();
    return doc.data() ?? {};
  }

  Future<void> saveManagerSettings(Map<String, dynamic> data) {
    return _db.collection('settings').doc('manager').set(data, SetOptions(merge: true));
  }

  static Map<String, dynamic> buildCompletedOrderPayload(PaymentMethod paymentMethod) {
    return {
      'status': 'completed',
      'payment_status': 'paid',
      'payment_method': paymentMethod == PaymentMethod.transfer ? 'transfer' : 'cash',
    };
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> completeOrder(String orderId, PaymentMethod paymentMethod) {
    return _db.collection('orders').doc(orderId).update(buildCompletedOrderPayload(paymentMethod));
  }
}
