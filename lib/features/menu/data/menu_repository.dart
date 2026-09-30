import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lelahanoi/core/data/firestore_data_source.dart';
import 'package:lelahanoi/core/models/category.dart';
import 'package:lelahanoi/core/models/menu.dart';

class MenuRepository {
  MenuRepository({FirestoreDataSource? dataSource})
      : _dataSource = dataSource ?? FirestoreDataSource();

  final FirestoreDataSource _dataSource;

  Stream<QuerySnapshot<CategoryModel>> watchCategories() =>
      _dataSource.streamCategories();
  Stream<QuerySnapshot<MenuModel>> watchMenu() => _dataSource.streamMenu();
  Future<void> deleteMenuItem(String id) =>
      _dataSource.deleteMenuItem(id, true);
  Future<void> addCategory(String name) => _dataSource.addCategory(name);
  Future<void> updateCategory(String id, String name) =>
      _dataSource.updateCategory(id, name);
  Future<void> deleteCategory(String id) => _dataSource.deleteCategory(id);
  Future<void> addMenu(Map<String, dynamic> payload) =>
      _dataSource.addMenuPayload(payload);
  Future<void> updateMenu(String id, Map<String, dynamic> payload) =>
      _dataSource.updateMenuPayload(id, payload);
}
