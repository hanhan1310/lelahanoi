import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/core/widgets/order_detail_sheet.dart';
import 'package:lelahanoi/features/order/presentation/bloc/order_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.orderHistory, style: GoogleFonts.merriweather(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state.status == OrderStatusState.failure) return _buildEmptyState(context, t.orderError, Icons.error_outline);
          if (state.status == OrderStatusState.loading) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state.orders.isEmpty) {
            return _buildEmptyState(context, t.noOrders, Icons.receipt_long_outlined);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, state.orders[index], t);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(fontSize: 16, color: AppColors.primary.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, dynamic t) {
    return GestureDetector(
      onTap: () => showOrderDetailSheet(context, order: order, t: t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${t.orderCode}: #${order.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${t.orderDate}: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}"),
                  const SizedBox(height: 4),
                  Text("${t.orderType}: ${order.orderType == OrderType.ship ? t.ship : t.pickup}"),
                  const SizedBox(height: 4),
                  Text("${t.customerLabel}: ${order.userName} (${order.userTier})"),
                  const SizedBox(height: 4),
                  Text("${t.phoneNumber}: ${order.userPhone}"),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${NumberFormat.decimalPattern().format(order.totalAmount)}đ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  order.paymentStatus == PaymentStatus.paid ? t.paid : t.unpaid,
                  style: TextStyle(
                    color: order.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
