import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/category.dart';
import 'package:lelahanoi/core/models/menu.dart';
import 'package:lelahanoi/features/menu/data/menu_repository.dart';

enum MenuStatus { loading, ready, failure }

class MenuState {
  const MenuState({
    required this.status,
    this.categories = const [],
    this.items = const [],
    this.searchQuery = '',
    this.error,
  });

  final MenuStatus status;
  final List<CategoryModel> categories;
  final List<MenuModel> items;
  final String searchQuery;
  final String? error;

  List<MenuModel> itemsFor(String categoryId) {
    return items.where((item) {
      final matchesCategory =
          categoryId == 'all' || item.categories == categoryId;
      final matchesSearch = item.name.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch && item.status == 'active';
    }).toList();
  }

  MenuState copyWith({
    MenuStatus? status,
    List<CategoryModel>? categories,
    List<MenuModel>? items,
    String? searchQuery,
    String? error,
  }) {
    return MenuState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}

class MenuCubit extends Cubit<MenuState> {
  MenuCubit({MenuRepository? repository})
      : _repository = repository ?? MenuRepository(),
        super(const MenuState(status: MenuStatus.loading)) {
    _categorySubscription =
        _repository.watchCategories().listen(_onCategories, onError: _onError);
    _menuSubscription =
        _repository.watchMenu().listen(_onMenu, onError: _onError);
  }

  final MenuRepository _repository;
  StreamSubscription<QuerySnapshot<CategoryModel>>? _categorySubscription;
  StreamSubscription<QuerySnapshot<MenuModel>>? _menuSubscription;

  void _onCategories(QuerySnapshot<CategoryModel> snapshot) {
    emit(state.copyWith(
        status: MenuStatus.ready,
        categories: snapshot.docs.map((doc) => doc.data()).toList()));
  }

  void _onMenu(QuerySnapshot<MenuModel> snapshot) {
    emit(state.copyWith(
        status: MenuStatus.ready,
        items: snapshot.docs.map((doc) => doc.data()).toList()));
  }

  void _onError(Object error) =>
      emit(state.copyWith(status: MenuStatus.failure, error: error.toString()));

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query.trim().toLowerCase()));

  Future<void> deleteItem(String id) => _repository.deleteMenuItem(id);
  Future<void> addCategory(String name) => _repository.addCategory(name);
  Future<void> deleteCategory(String id) => _repository.deleteCategory(id);
  Future<void> addMenu(Map<String, dynamic> payload) =>
      _repository.addMenu(payload);
  Future<void> updateMenu(String id, Map<String, dynamic> payload) =>
      _repository.updateMenu(id, payload);

  @override
  Future<void> close() async {
    await _categorySubscription?.cancel();
    await _menuSubscription?.cancel();
    return super.close();
  }
}
