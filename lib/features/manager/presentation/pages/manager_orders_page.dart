import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/core/widgets/order_detail_sheet.dart';
import 'package:lelahanoi/features/manager/data/manager_reminder_service.dart';
import 'package:lelahanoi/features/order/presentation/bloc/order_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerOrdersPage extends StatelessWidget {
  const ManagerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.manageOrders,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state.status == OrderStatusState.loading) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state.status == OrderStatusState.failure) {
            return Center(child: Text("${t.errorSystem}: ${state.error}"));
          }

          final orders = state.orders;
          ManagerReminderService().sync(orders, t);

          final activeGroups = _groupByUser(
            orders
                .where((order) =>
                    order.status != OrderStatus.completed &&
                    order.status != OrderStatus.cancelled)
                .toList(),
          );
          final completedOrders = orders
              .where((order) => order.status == OrderStatus.completed)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryRow(orders, t),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    t.groupedOrders,
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (activeGroups.isEmpty)
                _buildEmptyCard(t.noActiveOrders)
              else
                ...activeGroups.values
                    .map((group) => _buildGroupCard(context, group, t)),
              const SizedBox(height: 20),
              Text(t.completedOrders,
                  style: GoogleFonts.merriweather(
                      color: Colors.black, fontSize: 18)),
              const SizedBox(height: 12),
              if (completedOrders.isEmpty)
                _buildEmptyCard(t.noCompletedOrders)
              else
                ...completedOrders
                    .map((order) => _buildOrderCard(context, order, t)),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<OrderModel>> _groupByUser(List<OrderModel> orders) {
    final map = <String, List<OrderModel>>{};
    for (final order in orders) {
      map.putIfAbsent(order.userId, () => []).add(order);
    }
    return map;
  }

  Widget _buildSummaryRow(List<OrderModel> orders, dynamic t) {
    final totalRevenue =
        orders.fold<int>(0, (sum, order) => sum + order.totalAmount);
    final cashTotal = orders
        .where((order) => order.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (sum, order) => sum + order.totalAmount);
    final transferTotal = orders
        .where((order) => order.paymentMethod == PaymentMethod.transfer)
        .fold<int>(0, (sum, order) => sum + order.totalAmount);

    return Row(
      children: [
        Expanded(child: _summaryCard(t.revenue, totalRevenue)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(t.cash, cashTotal)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(t.transfer, transferTotal)),
      ],
    );
  }

  Widget _summaryCard(String label, int amount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text("${NumberFormat.decimalPattern().format(amount)}đ",
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, List<OrderModel> group, dynamic t) {
    final customer = group.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${customer.userName} (${t.memberTier}: ${customer.userTier})",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("${t.phoneNumber}: ${customer.userPhone}"),
          const SizedBox(height: 12),
          ...group.map((order) => _buildOrderCard(context, order, t)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, dynamic t) {
    return GestureDetector(
      onTap: () => showOrderDetailSheet(
        context,
        order: order,
        t: t,
        isManager: true,
        onConfirmCompleted: () async {
          await context
              .read<OrderCubit>()
              .completeOrder(order.id, order.paymentMethod);
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "${t.orderCode}: #${order.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      "${t.orderDate}: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}"),
                  const SizedBox(height: 4),
                  Text(
                      "${t.orderType}: ${order.orderType == OrderType.ship ? t.ship : t.pickup}"),
                  const SizedBox(height: 4),
                  Text(
                      "${t.customerLabel}: ${order.userName} (${order.userTier})"),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  order.paymentStatus == PaymentStatus.paid ? t.paid : t.unpaid,
                  style: TextStyle(
                    color: order.paymentStatus == PaymentStatus.paid
                        ? Colors.green
                        : Colors.orange,
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

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}
