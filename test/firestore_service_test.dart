import 'package:flutter_test/flutter_test.dart';
import 'package:lelahanoi/model/oder_model.dart';
import 'package:lelahanoi/utils/firestore_service.dart';

void main() {
  group('FirestoreService completed order payload', () {
    test('marks completed orders as paid with cash payment method', () {
      final payload = FirestoreService.buildCompletedOrderPayload(PaymentMethod.cash);

      expect(payload['status'], 'completed');
      expect(payload['payment_status'], 'paid');
      expect(payload['payment_method'], 'cash');
    });

    test('marks completed orders as paid with transfer payment method', () {
      final payload = FirestoreService.buildCompletedOrderPayload(PaymentMethod.transfer);

      expect(payload['status'], 'completed');
      expect(payload['payment_status'], 'paid');
      expect(payload['payment_method'], 'transfer');
    });
  });
}
