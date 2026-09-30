import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lelahanoi/core/l10n/app_strings.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';

Future<void> showOrderDetailSheet(
  BuildContext context, {
  required OrderModel order,
  required AppStrings t,
  bool isManager = false,
  Future<void> Function()? onConfirmCompleted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final typeText = order.orderType == OrderType.ship ? t.ship : t.pickup;
      final timeText = order.orderType == OrderType.ship
          ? (order.shipTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.shipTime!) : '-')
          : (order.pickupTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.pickupTime!) : '-');
      final addressText = order.orderType == OrderType.ship
          ? (order.shipAddress ?? '-')
          : '369 Altstadt, 84028 Landshut';

      return Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.orderInfo,
                        style: GoogleFonts.merriweather(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${t.orderCode}: #${order.id.substring(0, 10).toUpperCase()}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.status.name,
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(t.customerLabel, "${order.userName} (${order.userTier})"),
                  _buildInfoRow(t.phoneNumber, order.userPhone),
                  _buildInfoRow(t.orderType, typeText),
                  _buildInfoRow(t.orderDate, DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
                  _buildInfoRow(t.address, addressText),
                  _buildInfoRow(t.chooseTime, timeText),
                  _buildInfoRow(t.paymentMethod, order.paymentMethod == PaymentMethod.cash ? t.cash : t.transfer),
                  _buildInfoRow(t.status, order.paymentStatus == PaymentStatus.paid ? t.paid : t.unpaid),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: order.items.length,
                itemBuilder: (context, i) {
                  final item = order.items[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.fastfood_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.menuName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("x${item.quantity}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(
                          "${NumberFormat.decimalPattern().format(item.price * item.quantity)}đ",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.total, style: const TextStyle(color: Colors.grey)),
                      Text(
                        "${NumberFormat.decimalPattern().format(order.totalAmount)}đ",
                        style: GoogleFonts.merriweather(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              t.backToMenu,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      if (isManager && order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: onConfirmCompleted == null
                                  ? null
                                  : () async {
                                      await onConfirmCompleted();
                                      if (context.mounted) Navigator.pop(context);
                                    },
                              child: Text(
                                t.confirmCompleteOrder,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
