import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lelahanoi/core/l10n/app_strings.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/models/user.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/features/order/presentation/bloc/order_cubit.dart';

class ManagerReportsPage extends StatelessWidget {
  const ManagerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>();
    final t = language.strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(t.reports,
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state.status == OrderStatusState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == OrderStatusState.failure) {
            return Center(child: Text('${t.errorSystem}: ${state.error}'));
          }
          final orders = state.orders;
          final users = state.users
              .where((user) => user.totalMoneySpend > 0)
              .toList()
              .reversed
              .toList();
          final revenue =
              orders.fold<int>(0, (sum, order) => sum + order.totalAmount);
          final cash = orders
              .where((order) => order.paymentMethod == PaymentMethod.cash)
              .fold<int>(0, (sum, order) => sum + order.totalAmount);
          final transfer = orders
              .where((order) => order.paymentMethod == PaymentMethod.transfer)
              .fold<int>(0, (sum, order) => sum + order.totalAmount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryGrid(revenue, cash, transfer, orders.length,
                  state.users.length, t, language.currentCode),
              const SizedBox(height: 18),
              Row(children: [
                Text(t.customersByRevenue,
                    style: GoogleFonts.merriweather(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                const Expanded(
                    child: Divider(thickness: 1, color: Colors.black)),
              ]),
              const SizedBox(height: 12),
              ...users.map((user) =>
                  _customerCard(user, orders, t, language.currentCode)),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryGrid(int revenue, int cash, int transfer, int orderCount,
      int customerCount, AppStrings t, String locale) {
    return Column(children: [
      Row(children: [
        Expanded(child: _smallCard(t.revenue, _format(revenue, locale))),
        const SizedBox(width: 10),
        Expanded(child: _smallCard(t.cash, _format(cash, locale))),
        const SizedBox(width: 10),
        Expanded(child: _smallCard(t.transfer, _format(transfer, locale))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _smallCard(t.orders, '$orderCount')),
        const SizedBox(width: 10),
        Expanded(child: _smallCard(t.customers, '$customerCount')),
      ]),
    ]);
  }

  Widget _smallCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _customerCard(
      UserModel user, List<OrderModel> orders, AppStrings t, String locale) {
    final userOrders =
        orders.where((order) => order.userId == user.id).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('${t.memberTier}: ${UserModel.tierName(user.tier)}'),
        Text('${t.phoneNumber}: ${user.phone}'),
        Text('${t.totalPurchased}: ${_format(user.totalMoneySpend, locale)}đ'),
        Text('${t.orders}: ${userOrders.length}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: userOrders
              .take(5)
              .map((order) => Chip(
                  label: Text(
                      '${t.orderCode} #${order.id.substring(0, order.id.length < 6 ? order.id.length : 6)} - ${_format(order.totalAmount, locale)}đ')))
              .toList(),
        ),
      ]),
    );
  }

  String _format(int amount, String locale) {
    return NumberFormat.decimalPattern(
            locale == 'vi' || locale == 'de' ? locale : 'en')
        .format(amount);
  }
}
