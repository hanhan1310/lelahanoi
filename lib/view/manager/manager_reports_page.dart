import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lelahanoi/model/oder_model.dart';
import 'package:lelahanoi/public/l10n/app_strings.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/public/widget/app_colors.dart';
import 'package:provider/provider.dart';

class ManagerReportsPage extends StatelessWidget {
  const ManagerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.strings;
    final localeCode = languageProvider.currentCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.reports,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final orders = (orderSnapshot.data?.docs ?? [])
              .map((doc) => OrderModel.fromMap(doc.data(), id: doc.id))
              .toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('user').snapshots(),
            builder: (context, userSnapshot) {
              final users = userSnapshot.data?.docs ?? [];
              final totalRevenue =
                  orders.fold<int>(0, (sum, order) => sum + order.totalAmount);
              final cash = orders
                  .where((o) => o.paymentMethod == PaymentMethod.cash)
                  .fold<int>(0, (sum, order) => sum + order.totalAmount);
              final transfer = orders
                  .where((o) => o.paymentMethod == PaymentMethod.transfer)
                  .fold<int>(0, (sum, order) => sum + order.totalAmount);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryGrid(totalRevenue, cash, transfer, orders.length,
                      users.length, t, localeCode),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        t.customersByRevenue,
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
                  ...users
                      .map((doc) => MapEntry(doc.id, doc.data()))
                      .toList()
                      .where((entry) =>
                          (entry.value['total_money_spend'] ?? 0) > 0)
                      .toList()
                      .reversed
                      .map((entry) => _buildCustomerCard(
                          entry.key, entry.value, orders, t, localeCode)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryGrid(
    int revenue,
    int cash,
    int transfer,
    int orderCount,
    int customerCount,
    AppStrings t,
    String localeCode,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _smallCard(
                t.revenue,
                _formatAmount(revenue, localeCode),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallCard(
                t.cash,
                _formatAmount(cash, localeCode),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallCard(
                t.transfer,
                _formatAmount(transfer, localeCode),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _smallCard(
                t.orders,
                "$orderCount",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallCard(
                t.customers,
                "$customerCount",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(String userId, Map<String, dynamic> data,
      List<OrderModel> orders, AppStrings t, String localeCode) {
    final userOrders = orders.where((order) => order.userId == userId).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['name'] ?? '',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("${t.memberTier}: ${data['tier'] ?? 'Bronze'}"),
          Text("${t.phoneNumber}: ${data['phone'] ?? ''}"),
          Text(
              "${t.totalPurchased}: ${_formatAmount(data['total_money_spend'] ?? 0, localeCode)}đ"),
          Text("${t.orders}: ${userOrders.length}"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: userOrders
                .take(5)
                .map(
                  (order) => Chip(
                    label: Text(
                        "${t.orderCode} #${order.id.substring(0, 6)} - ${_formatAmount(order.totalAmount, localeCode)}đ"),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount, String localeCode) {
    final normalizedLocale = switch (localeCode) {
      'vi' => 'vi',
      'de' => 'de',
      _ => 'en',
    };
    return NumberFormat.decimalPattern(normalizedLocale).format(amount);
  }
}
