import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  String id;
  String categories;
  String name;
  String image;
  int price;
  String status;
  bool isDelete;
  DateTime? createdAt;

  MenuModel({
    required this.id,
    required this.categories,
    required this.name,
    required this.image,
    required this.price,
    required this.status,
    this.isDelete = false,
    this.createdAt,
  });

  // 1. Dùng để đọc từ Firestore (DocumentSnapshot)
  factory MenuModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, _) {
    final data = snapshot.data();
    return MenuModel.fromMap(data ?? {}, id: snapshot.id);
  }

  // 2. Dùng để đọc từ Map (Dùng cho SharedPreferences / JSON)
  factory MenuModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MenuModel(
      id: id ?? map['id'] ?? '',
      categories: map['categories'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: map['price'] ?? 0,
      status: map['status'] ?? 'active',
      isDelete: map['is_delete'] ?? false,
      // Xử lý Timestamp từ Firestore hoặc String từ JSON
      createdAt: map['create_at'] is Timestamp
          ? (map['create_at'] as Timestamp).toDate()
          : (map['create_at'] != null ? DateTime.tryParse(map['create_at'].toString()) : null),
    );
  }

  // 3. Dùng để ghi lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "id": id, // Lưu ID vào map để khi decode từ JSON không bị mất
      "categories": categories,
      "name": name,
      "image": image,
      "price": price,
      "status": status,
      "is_delete": isDelete,
      "create_at": createdAt?.toIso8601String(), // Lưu dạng String khi lưu vào máy
    };
  }

  // --- HÀM ENCODE / DECODE CHO GIỎ HÀNG ---

  static String encode(List<MenuModel> items) {
    return json.encode(
      items.map<Map<String, dynamic>>((item) => item.toFirestore()).toList(),
    );
  }

  static List<MenuModel> decode(String items) {
    return (json.decode(items) as List<dynamic>)
        .map<MenuModel>((item) => MenuModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
