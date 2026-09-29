import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderType { pickup, ship }
enum PaymentMethod { cash, transfer }
enum PaymentStatus { pending, paid }
enum OrderStatus { pending, confirmed, ready, completed, cancelled }

class OrderItem {
  String menuId;
  String menuName;
  int quantity;
  int price;

  OrderItem({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
    'menu_id': menuId,
    'menu_name': menuName,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    menuId: m['menu_id'] ?? '',
    menuName: m['menu_name'] ?? '',
    quantity: m['quantity'] ?? 1,
    price: m['price'] ?? 0,
  );
}

class OrderModel {
  String id;
  String userId;
  String userName;
  String userPhone;
  String userEmail;
  String userTier;
  List<OrderItem> items;
  int totalAmount;
  int earnedPoints;
  OrderType orderType;
  PaymentMethod paymentMethod;
  PaymentStatus paymentStatus;
  OrderStatus status;
  // Ship fields
  String? shipAddress;
  DateTime? shipTime;
  // Pickup field
  DateTime? pickupTime;
  DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail = '',
    required this.userTier,
    required this.items,
    required this.totalAmount,
    required this.earnedPoints,
    required this.orderType,
    required this.paymentMethod,
    required this.createdAt,
    this.paymentStatus = PaymentStatus.pending,
    this.status = OrderStatus.pending,
    this.shipAddress,
    this.shipTime,
    this.pickupTime,
  });

  factory OrderModel.fromMap(Map<String, dynamic> d, {String id = ''}) {
    return OrderModel(
      id: id,
      userId: d['user_id'] ?? '',
      userName: d['user_name'] ?? '',
      userPhone: d['user_phone'] ?? '',
      userEmail: d['user_email'] ?? '',
      userTier: d['user_tier'] ?? 'Bronze',
      items: (d['items'] as List? ?? []).map((e) => OrderItem.fromMap(e)).toList(),
      totalAmount: d['total_amount'] ?? 0,
      earnedPoints: d['earned_points'] ?? 0,
      orderType: d['order_type'] == 'ship' ? OrderType.ship : OrderType.pickup,
      paymentMethod: d['payment_method'] == 'transfer' ? PaymentMethod.transfer : PaymentMethod.cash,
      paymentStatus: d['payment_status'] == 'paid' ? PaymentStatus.paid : PaymentStatus.pending,
      status: _parseStatus(d['status']),
      shipAddress: d['ship_address'],
      shipTime: _parseTime(d['ship_time']),
      pickupTime: _parseTime(d['pickup_time']),
      createdAt: _parseTime(d['created_at']) ?? DateTime.now(),
    );
  }

  static OrderStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed':  return OrderStatus.confirmed;
      case 'ready':      return OrderStatus.ready;
      case 'completed':  return OrderStatus.completed;
      case 'cancelled':  return OrderStatus.cancelled;
      default:           return OrderStatus.pending;
    }
  }

  static DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'user_name': userName,
    'user_phone': userPhone,
    'user_email': userEmail,
    'user_tier': userTier,
    'items': items.map((e) => e.toMap()).toList(),
    'total_amount': totalAmount,
    'earned_points': earnedPoints,
    'order_type': orderType == OrderType.ship ? 'ship' : 'pickup',
    'payment_method': paymentMethod == PaymentMethod.transfer ? 'transfer' : 'cash',
    'payment_status': paymentStatus == PaymentStatus.paid ? 'paid' : 'pending',
    'status': status.name,
    'ship_address': shipAddress,
    'ship_time': shipTime != null ? Timestamp.fromDate(shipTime!) : null,
    'pickup_time': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
    'created_at': FieldValue.serverTimestamp(),
  };
}
