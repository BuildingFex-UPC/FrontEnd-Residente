import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/features/finance/finance_models.dart';
import 'package:frontend_residente/features/finance/payment_webview.dart';

void main() {
  group('PaymentWebView URL Detection', () {
    test('isReturnUrl recognizes finance callback path', () {
      final uri = Uri.parse('https://buildingfex.web.app/app/resident/finance?payment=success&payment_id=123456&status=approved');
      expect(PaymentWebView.isReturnUrl(uri), isTrue);
    });

    test('isReturnUrl recognizes collection_status in query parameters', () {
      final uri = Uri.parse('https://example.com/callback?collection_status=approved&collection_id=998877');
      expect(PaymentWebView.isReturnUrl(uri), isTrue);
    });

    test('isReturnUrl recognizes payment_id with status in query parameters', () {
      final uri = Uri.parse('https://example.com/return?payment_id=123456&status=approved');
      expect(PaymentWebView.isReturnUrl(uri), isTrue);
    });

    test('isReturnUrl ignores internal Mercado Pago checkout URLs', () {
      final uri = Uri.parse('https://www.mercadopago.com.pe/checkout/v1/payment/redirect?pref_id=123');
      expect(PaymentWebView.isReturnUrl(uri), isFalse);
    });

    test('extractParams parses all outcome parameters', () {
      final uri = Uri.parse('https://buildingfex.web.app/app/resident/finance?collection_id=999&collection_status=approved&payment_id=999&status=approved&external_reference=MAINTENANCE:res-1:admin-1&preference_id=pref-123');
      final params = PaymentWebView.extractParams(uri);

      expect(params['collection_id'], equals('999'));
      expect(params['collection_status'], equals('approved'));
      expect(params['payment_id'], equals('999'));
      expect(params['status'], equals('approved'));
      expect(params['external_reference'], equals('MAINTENANCE:res-1:admin-1'));
      expect(params['preference_id'], equals('pref-123'));
    });
  });

  group('Finance Models & Calculation', () {
    test('FeeItem status and overdue flags calculate correctly', () {
      final paidItem = FeeItem(
        id: 'fee-F-1',
        originalId: 'F-1',
        type: 'fee',
        residentId: 'res-1',
        month: '2026-01',
        amount: 150.0,
        dueDate: '2026-01-20',
        status: 'Pagado',
        concept: 'Mantenimiento',
      );
      expect(paidItem.isPaid, isTrue);
      expect(paidItem.isOverdue, isFalse);

      final pendingItem = FeeItem(
        id: 'fee-F-2',
        originalId: 'F-2',
        type: 'fee',
        residentId: 'res-1',
        month: '2026-02',
        amount: 150.0,
        dueDate: '2026-02-20',
        status: 'Pendiente',
        concept: 'Mantenimiento',
      );
      expect(pendingItem.isPaid, isFalse);
    });

    test('ResidentAccount pendingAmount sums unpaid fees', () {
      final account = ResidentAccount(
        fees: [
          FeeItem(id: 'fee-F-1', originalId: 'F-1', type: 'fee', residentId: 'res-1', month: '2026-01', amount: 100.0, dueDate: '2026-01-20', status: 'Pagado', concept: 'Cuota 1'),
          FeeItem(id: 'fee-F-2', originalId: 'F-2', type: 'fee', residentId: 'res-1', month: '2026-02', amount: 150.0, dueDate: '2026-02-20', status: 'Pendiente', concept: 'Cuota 2'),
          FeeItem(id: 'fee-F-3', originalId: 'F-3', type: 'fee', residentId: 'res-1', month: '2026-03', amount: 50.0, dueDate: '2026-03-20', status: 'Pendiente', concept: 'Cuota 3'),
        ],
        payments: [
          Payment(id: 'P-1', residentId: 'res-1', amount: 100.0, paidAt: '2026-01-19', method: 'Mercado Pago'),
        ],
        settings: const FinanceSettings(),
      );

      expect(account.hasPending, isTrue);
      expect(account.pendingAmount, equals(200.0));
      expect(account.paidTotal, equals(100.0));
    });
  });
}
