import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/model/voucher_model.dart';
import 'package:lelahanoi/public/widget/custom_toast.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:lelahanoi/utils/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/menu_model.dart';
import '../../../model/oder_model.dart';
import '../../../model/user_model.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color _primaryColor = const Color(0xFF557A58);
  final Color _bgMint = const Color(0xFFB4D3B6);

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  List<MenuModel> _cartItems = [];
  Map<String, int> _quantities = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  OrderType _orderType = OrderType.pickup;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime? _selectedTime;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadBootstrap();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBootstrap() async {
    await _loadUser();
    await _loadCart();
    _selectedTime ??= DateTime.now().add(const Duration(minutes: 30));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUser() async {
    _currentUser = await AuthService.getUserModel();
    _phoneController.text = _currentUser?.phone ?? '';
    _emailController.text = _currentUser?.email ?? AuthService.currentUser?.email ?? '';
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('shopping_cart');

    if (cartString != null && cartString.isNotEmpty) {
      final List<dynamic> decoded = json.decode(cartString);
      _cartItems = decoded.map((item) => MenuModel.fromMap(item as Map<String, dynamic>)).toList();
      _quantities = {
        for (final item in decoded) item['id'] as String: item['quantity'] as int? ?? 1,
      };
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = _cartItems.map((item) {
      final map = item.toFirestore();
      map['quantity'] = _quantities[item.id];
      return map;
    }).toList();
    await prefs.setString('shopping_cart', json.encode(data));
  }

  void _updateQty(int index, int delta) {
    setState(() {
      final id = _cartItems[index].id;
      final newQty = (_quantities[id] ?? 1) + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
        _quantities.remove(id);
      } else {
        _quantities[id] = newQty;
      }
    });
    _saveCart();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _selectedTime ?? DateTime.now().add(const Duration(minutes: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime ?? DateTime.now().add(const Duration(minutes: 30))),
    );
    if (time == null) return;

    setState(() {
      _selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _checkout() async {
    final t = context.read<LanguageProvider>().strings;
    if (_cartItems.isEmpty || _isSubmitting) return;

    if (_orderType == OrderType.ship && _addressController.text.trim().isEmpty) {
      ShowToast(t.deliveryAddress, false);
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ShowToast(t.phoneNumber, false);
      return;
    }

    if (_selectedTime == null) {
      ShowToast(t.chooseTime, false);
      return;
    }

    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: _primaryColor)),
    );

    try {
      final user = _currentUser ?? await AuthService.getUserModel();
      final userId = AuthService.currentUser?.uid ?? '';
      final spendBeforeOrder = user?.totalMoneySpend ?? 0;
      final userTier = UserModel.tierName(UserModel.tierFromSpend(spendBeforeOrder));
      final total = _cartItems.fold<int>(
        0,
        (sum, item) => sum + (item.price * (_quantities[item.id] ?? 1)),
      );

      final items = _cartItems
          .map(
            (item) => OrderItem(
              menuId: item.id,
              menuName: item.name,
              quantity: _quantities[item.id] ?? 1,
              price: item.price,
            ),
          )
          .toList();

      final order = OrderModel(
        id: '',
        userId: userId,
        userName: user?.name ?? 'Customer',
        userPhone: _phoneController.text.trim(),
        userEmail: _emailController.text.trim(),
        userTier: userTier,
        items: items,
        totalAmount: total,
        earnedPoints: (total / 1000).floor(),
        orderType: _orderType,
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
        paymentStatus: PaymentStatus.pending,
        shipAddress: _orderType == OrderType.ship ? _addressController.text.trim() : null,
        shipTime: _orderType == OrderType.ship ? _selectedTime : null,
        pickupTime: _orderType == OrderType.pickup ? _selectedTime : null,
      );

      await FirestoreService().createOrder(order);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shopping_cart');

      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _cartItems = [];
        _quantities = {};
      });
      await _showSuccess(total, spendBeforeOrder + total);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ShowToast("Có lỗi xảy ra: $e", false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccess(int total, int newSpend) async {
    final t = context.read<LanguageProvider>().strings;
    final tier = UserModel.tierFromSpend(newSpend);
    final vouchers = VoucherModel.forTier(UserModel.tierName(tier));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.orderSuccess, style: GoogleFonts.merriweather(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.orderSuccessMsg),
                const SizedBox(height: 12),
                Text("${t.total}: ${NumberFormat.decimalPattern().format(total)}đ"),
                const SizedBox(height: 12),
                Text("${t.memberTier}: ${UserModel.tierName(tier)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (vouchers.isNotEmpty) ...[
                  Text("${t.rewardsAvailable}:", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...vouchers.map(
                    (voucher) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text("• ${voucher.title} - ${voucher.description}"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(t.backToMenu, style: TextStyle(color: _primaryColor)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    final total = _cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.price * (_quantities[item.id] ?? 1)),
    );
    final suggestedVouchers = VoucherModel.forTier(
      UserModel.tierName(UserModel.tierFromSpend((_currentUser?.totalMoneySpend ?? 0) + total)),
    );

    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        title: Text(t.cart, style: GoogleFonts.merriweather(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _cartItems.isEmpty
          ? _buildEmptyState(t)
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildOrderTypeCard(t),
                          const SizedBox(height: 12),
                          if (suggestedVouchers.isNotEmpty) _buildVoucherCard(suggestedVouchers, t),
                          const SizedBox(height: 12),
                          ...List.generate(_cartItems.length, _buildCartItem),
                        ],
                      ),
                    ),
                          _buildBottomBar(total, t),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(dynamic t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 100, color: _primaryColor.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(t.emptyCart, style: GoogleFonts.merriweather(fontSize: 18, color: _primaryColor)),
        ],
      ),
    );
  }

  Widget _buildOrderTypeCard(dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.orderType, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SegmentedButton<OrderType>(
            segments: [
              ButtonSegment(value: OrderType.pickup, label: Text(t.pickup), icon: const Icon(Icons.store)),
              ButtonSegment(value: OrderType.ship, label: Text(t.ship), icon: const Icon(Icons.local_shipping)),
            ],
            selected: {_orderType},
            onSelectionChanged: (value) => setState(() => _orderType = value.first),
          ),
          const SizedBox(height: 16),
          if (_orderType == OrderType.pickup) _buildPickupInfo(t) else _buildShipFields(t),
          const SizedBox(height: 16),
          _buildField(
            controller: _phoneController,
            label: t.phoneNumber,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _emailController,
            label: t.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTimePicker(t),
          const SizedBox(height: 12),
          _buildPaymentMethod(t),
        ],
      ),
    );
  }

  Widget _buildPickupInfo(dynamic t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgMint.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${t.pickupAddress}: 369 Altstadt, 84028 Landshut"),
          SizedBox(height: 4),
          Text("${t.phoneNumber}: 015226673930"),
          SizedBox(height: 4),
          Text("${t.email}: manager@lelahanoi.de"),
        ],
      ),
    );
  }

  Widget _buildShipFields(dynamic t) {
    return Column(
      children: [
        _buildField(
          controller: _addressController,
          label: t.deliveryAddress,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("${t.deliveryAddress} / ${t.chooseTime}"),
          ),
      ],
    );
  }

  Widget _buildTimePicker(dynamic t) {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryColor.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: _primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime == null
                    ? "${t.chooseTime} ${_orderType == OrderType.pickup ? t.pickup : t.ship}"
                    : DateFormat('dd/MM/yyyy HH:mm').format(_selectedTime!),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(dynamic t) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<PaymentMethod>(
            contentPadding: EdgeInsets.zero,
            title: Text(t.cash),
            value: PaymentMethod.cash,
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value ?? PaymentMethod.cash),
          ),
        ),
        Expanded(
          child: RadioListTile<PaymentMethod>(
            contentPadding: EdgeInsets.zero,
            title: Text(t.transfer),
            value: PaymentMethod.transfer,
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value ?? PaymentMethod.cash),
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(List<VoucherModel> vouchers, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.rewardsAvailable, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...vouchers.take(3).map(
                (voucher) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("• ${voucher.title}: ${voucher.description}"),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    final qty = _quantities[item.id] ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              item.image,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 70),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                  "${NumberFormat.decimalPattern().format(item.price)}đ",
                  style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _bgMint.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => _updateQty(index, -1)),
                Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => _updateQty(index, 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(int total, dynamic t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(t.total, style: GoogleFonts.merriweather(fontSize: 18, color: Colors.grey[600])),
              Text(
                "${NumberFormat.decimalPattern().format(total)}đ",
                style: GoogleFonts.merriweather(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
              ),
              onPressed: _checkout,
              child: Text(
                t.confirmOrder,
                style: GoogleFonts.merriweather(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
