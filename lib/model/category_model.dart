import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String id;
  String name;
  bool isDelete;

  CategoryModel({required this.id, required this.name, this.isDelete = false});

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, _) {
    final data = snapshot.data();
    return CategoryModel(
      id: snapshot.id,
      name: data?['name'] ?? '',
      isDelete: data?['is_delete'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        "name": name,
        "is_delete": isDelete,
      };
}
