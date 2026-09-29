import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartManager {
  // Tạo một StreamController để phát dữ liệu số lượng món ăn
  static final StreamController<int> _cartController = StreamController<int>.broadcast();

  // Getter để các Widget khác lắng nghe (listen)
  static Stream<int> get cartStream => _cartController.stream;

  // Hàm cập nhật và phát đi số lượng mới nhất
  static Future<void> refreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartString = prefs.getString('shopping_cart');
    int count = 0;
    if (cartString != null && cartString.isNotEmpty) {
      List<dynamic> cartList = json.decode(cartString);
      count = cartList.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
    }
    _cartController.add(count); // Phát số lượng mới vào Stream
  }
}
