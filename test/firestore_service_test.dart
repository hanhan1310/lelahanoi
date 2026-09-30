import 'package:flutter_test/flutter_test.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/data/firestore_data_source.dart';

void main() {
  group('FirestoreService completed order payload', () {
    test('marks completed orders as paid with cash payment method', () {
    final payload = FirestoreDataSource.buildCompletedOrderPayload(PaymentMethod.cash);

      expect(payload['status'], 'completed');
      expect(payload['payment_status'], 'paid');
      expect(payload['payment_method'], 'cash');
    });

    test('marks completed orders as paid with transfer payment method', () {
    final payload = FirestoreDataSource.buildCompletedOrderPayload(PaymentMethod.transfer);

      expect(payload['status'], 'completed');
      expect(payload['payment_status'], 'paid');
      expect(payload['payment_method'], 'transfer');
    });
  });
}
