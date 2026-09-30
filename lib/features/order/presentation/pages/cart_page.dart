import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/models/user.dart';
import 'package:lelahanoi/core/models/voucher.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:lelahanoi/features/order/presentation/bloc/cart_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _primaryColor = Color(0xFF557A58);
  static const _bgMint = Color(0xFFB4D3B6);

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<CartCubit>().state.user;
    _phoneController.text = user?.phone ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final state = context.read<CartCubit>().state;
    final selected =
        state.selectedTime ?? DateTime.now().add(const Duration(minutes: 30));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: selected,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selected),
    );
    if (time == null) return;
    context.read<CartCubit>().setSelectedTime(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _checkout(CartState state) async {
    final t = context.read<LanguageCubit>().strings;
    if (state.items.isEmpty || state.status == CartStatus.submitting) return;
    if (state.orderType == OrderType.ship &&
        _addressController.text.trim().isEmpty) {
      showToast(t.deliveryAddress, false);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      showToast(t.phoneNumber, false);
      return;
    }
    if (state.selectedTime == null) {
      showToast(t.chooseTime, false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primaryColor)),
    );
    final cart = context.read<CartCubit>();
    await cart.checkout(
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    final result = cart.state;
    if (result.status == CartStatus.success) {
      await _showSuccess(result.submittedTotal ?? 0, result.newSpend ?? 0);
      cart.clearResult();
    } else if (result.status == CartStatus.failure) {
      showToast('Có lỗi xảy ra: ${result.error}', false);
    }
  }

  Future<void> _showSuccess(int total, int newSpend) async {
    final t = context.read<LanguageCubit>().strings;
    final tier = UserModel.tierFromSpend(newSpend);
    final vouchers = VoucherModel.forTier(UserModel.tierName(tier));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.orderSuccess,
            style: GoogleFonts.merriweather(
                color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.orderSuccessMsg),
            const SizedBox(height: 12),
            Text('${t.total}: ${NumberFormat.decimalPattern().format(total)}đ'),
            const SizedBox(height: 12),
            Text('${t.memberTier}: ${UserModel.tierName(tier)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (vouchers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${t.rewardsAvailable}:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ...vouchers.map((voucher) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('• ${voucher.title} - ${voucher.description}'))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(t.backToMenu,
                style: const TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          previous.status == CartStatus.loading &&
          current.status == CartStatus.ready,
      listener: (context, state) {
        _phoneController.text = state.user?.phone ?? '';
        _emailController.text = state.user?.email ?? '';
      },
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          final suggestedVouchers = VoucherModel.forTier(
            UserModel.tierName(UserModel.tierFromSpend(
                (state.user?.totalMoneySpend ?? 0) + state.total)),
          );
          return Scaffold(
            backgroundColor: _bgMint,
            appBar: AppBar(
              title: Text(t.cart,
                  style: GoogleFonts.merriweather(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: state.status == CartStatus.loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor))
                : state.items.isEmpty
                    ? _buildEmptyState(t)
                    : Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                _buildOrderTypeCard(state, t),
                                const SizedBox(height: 12),
                                if (suggestedVouchers.isNotEmpty)
                                  _buildVoucherCard(suggestedVouchers, t),
                                const SizedBox(height: 12),
                                ...List.generate(state.items.length,
                                    (index) => _buildCartItem(state, index)),
                              ],
                            ),
                          ),
                          _buildBottomBar(state, t),
                        ],
                      ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(dynamic t) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 100, color: _primaryColor.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(t.emptyCart,
                style: GoogleFonts.merriweather(
                    fontSize: 18, color: _primaryColor)),
          ],
        ),
      );

  Widget _buildOrderTypeCard(CartState state, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.orderType,
              style: GoogleFonts.merriweather(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SegmentedButton<OrderType>(
            segments: [
              ButtonSegment(
                  value: OrderType.pickup,
                  label: Text(t.pickup),
                  icon: const Icon(Icons.store)),
              ButtonSegment(
                  value: OrderType.ship,
                  label: Text(t.ship),
                  icon: const Icon(Icons.local_shipping)),
            ],
            selected: {state.orderType},
            onSelectionChanged: (value) =>
                context.read<CartCubit>().setOrderType(value.first),
          ),
          const SizedBox(height: 16),
          if (state.orderType == OrderType.pickup)
            _buildPickupInfo(t)
          else
            _buildField(
                controller: _addressController,
                label: t.deliveryAddress,
                icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildField(
              controller: _phoneController,
              label: t.phoneNumber,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildField(
              controller: _emailController,
              label: t.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTimePicker(state, t),
          const SizedBox(height: 12),
          _buildPaymentMethod(state, t),
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
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${t.pickupAddress}: 369 Altstadt, 84028 Landshut'),
        const SizedBox(height: 4),
        Text('${t.phoneNumber}: 015226673930'),
        const SizedBox(height: 4),
        Text('${t.email}: manager@lelahanoi.de'),
      ]),
    );
  }

  Widget _buildTimePicker(CartState state, dynamic t) {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withOpacity(0.08))),
        child: Row(children: [
          const Icon(Icons.schedule, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(state.selectedTime == null
                  ? '${t.chooseTime} ${state.orderType == OrderType.pickup ? t.pickup : t.ship}'
                  : DateFormat('dd/MM/yyyy HH:mm')
                      .format(state.selectedTime!))),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  Widget _buildPaymentMethod(CartState state, dynamic t) {
    return Row(children: [
      Expanded(
          child: RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              title: Text(t.cash),
              value: PaymentMethod.cash,
              groupValue: state.paymentMethod,
              onChanged: (value) => context
                  .read<CartCubit>()
                  .setPaymentMethod(value ?? PaymentMethod.cash))),
      Expanded(
          child: RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              title: Text(t.transfer),
              value: PaymentMethod.transfer,
              groupValue: state.paymentMethod,
              onChanged: (value) => context
                  .read<CartCubit>()
                  .setPaymentMethod(value ?? PaymentMethod.cash))),
    ]);
  }

  Widget _buildVoucherCard(List<VoucherModel> vouchers, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.rewardsAvailable,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...vouchers.take(3).map((voucher) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• ${voucher.title}: ${voucher.description}'))),
      ]),
    );
  }

  Widget _buildCartItem(CartState state, int index) {
    final item = state.items[index];
    final quantity = state.quantities[item.id] ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(item.image,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 70))),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: GoogleFonts.merriweather(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text('${NumberFormat.decimalPattern().format(item.price)}đ',
              style: const TextStyle(
                  color: _primaryColor, fontWeight: FontWeight.w600)),
        ])),
        Container(
          decoration: BoxDecoration(
              color: _bgMint.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: () =>
                    context.read<CartCubit>().updateQuantity(index, -1)),
            Text('$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () =>
                    context.read<CartCubit>().updateQuantity(index, 1)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBottomBar(CartState state, dynamic t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t.total,
              style: GoogleFonts.merriweather(
                  fontSize: 18, color: Colors.grey[600])),
          Text('${NumberFormat.decimalPattern().format(state.total)}đ',
              style: GoogleFonts.merriweather(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: state.status == CartStatus.submitting
                    ? null
                    : () => _checkout(state),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text(t.checkout,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)))),
      ]),
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text}) {
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
              borderSide: BorderSide.none)),
    );
  }
}
