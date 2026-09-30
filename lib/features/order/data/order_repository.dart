import 'package:lelahanoi/core/data/firestore_data_source.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/models/user.dart';

class OrderRepository {
  OrderRepository({FirestoreDataSource? dataSource})
      : _dataSource = dataSource ?? FirestoreDataSource();

  final FirestoreDataSource _dataSource;

  Stream<List<OrderModel>> watchOrders({String? userId}) {
    final stream = userId == null
        ? _dataSource.streamOrders()
        : _dataSource.getOrdersByUser(userId);
    return stream.map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  Stream<List<UserModel>> watchUsers() {
    return _dataSource.streamUsers().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
        .toList());
  }

  Future<void> completeOrder(String id, PaymentMethod method) =>
      _dataSource.completeOrder(id, method);
}
