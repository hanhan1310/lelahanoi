import 'dart:convert';

import 'package:lelahanoi/core/models/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartSnapshot {
  const CartSnapshot({required this.items, required this.quantities});

  final List<MenuModel> items;
  final Map<String, int> quantities;
}

class CartStorage {
  static const _key = 'shopping_cart';

  Future<CartSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null || value.isEmpty) {
      return const CartSnapshot(
          items: <MenuModel>[], quantities: <String, int>{});
    }

    final decoded =
        (json.decode(value) as List<dynamic>).cast<Map<String, dynamic>>();
    return CartSnapshot(
      items: decoded.map((item) => MenuModel.fromMap(item)).toList(),
      quantities: {
        for (final item in decoded)
          item['id'] as String: item['quantity'] as int? ?? 1,
      },
    );
  }

  Future<void> save(List<MenuModel> items, Map<String, int> quantities) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((item) {
      final map = item.toFirestore();
      map['quantity'] = quantities[item.id] ?? 1;
      return map;
    }).toList();
    await prefs.setString(_key, json.encode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
