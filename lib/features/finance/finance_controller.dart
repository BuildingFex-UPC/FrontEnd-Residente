import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/i18n.dart';
import '../../core/session_repository.dart';
import 'finance_models.dart';
import 'finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(apiClientProvider), ref.watch(sessionRepositoryProvider)),
);

class FinanceState {
  const FinanceState({
    this.loading = true,
    this.error,
    this.account,
    this.startingCheckout = false,
    this.confirming = false,
    this.checkoutUrl,
    this.message,
  });

  final bool loading;
  final String? error;
  final ResidentAccount? account;
  final bool startingCheckout;
  final bool confirming;

  /// Non-null when a real Mercado Pago checkout must be opened in a WebView.
  final String? checkoutUrl;
  final String? message;

  FinanceState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    ResidentAccount? account,
    bool? startingCheckout,
    bool? confirming,
    String? checkoutUrl,
    bool clearCheckoutUrl = false,
    String? message,
    bool clearMessage = false,
  }) =>
      FinanceState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        account: account ?? this.account,
        startingCheckout: startingCheckout ?? this.startingCheckout,
        confirming: confirming ?? this.confirming,
        checkoutUrl: clearCheckoutUrl ? null : (checkoutUrl ?? this.checkoutUrl),
        message: clearMessage ? null : (message ?? this.message),
      );
}

class FinanceController extends Notifier<FinanceState> {
  @override
  FinanceState build() {
    Future.microtask(load);
    return const FinanceState();
  }

  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      // Apply automatic late fees (mora) first, but never let that side effect
      // block the account from loading (mirrors the web/Compose `runCatching`).
      try {
        await _repo.autoApplyLateFees();
      } catch (_) {
        // Best-effort: ignore and still show the current account state.
      }
      final fees = await _repo.listFees();
      final payments = await _repo.listPayments();
      final settings = await _repo.getSettings();
      state = state.copyWith(
        loading: false,
        account: ResidentAccount(fees: fees, payments: payments, settings: settings),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageOf(e));
    }
  }

  /// Starts the Mercado Pago checkout. Demo mode completes immediately;
  /// otherwise [FinanceState.checkoutUrl] is set so the UI opens a WebView.
  Future<void> startCheckout({String? payerEmail}) async {
    if (state.startingCheckout) return;
    state = state.copyWith(startingCheckout: true, clearMessage: true);
    try {
      final checkout = await _repo.checkout(payerEmail: payerEmail);
      if (checkout.demo) {
        await _repo.confirm(demo: true);
        await _repo.recordPayment(reference: checkout.preferenceId);
        await load();
        state = state.copyWith(
          startingCheckout: false,
          message: AppTexts.translate('rfin.msg.demoConfirmed'),
        );
        return;
      }
      final initPoint = checkout.initPoint;
      if (initPoint == null || initPoint.isEmpty) {
        state = state.copyWith(
          startingCheckout: false,
          message: AppTexts.translate('rfin.msg.checkoutFailed'),
        );
        return;
      }
      state = state.copyWith(startingCheckout: false, checkoutUrl: initPoint);
    } catch (e) {
      state = state.copyWith(
        startingCheckout: false,
        message: AppTexts.translate('rfin.msg.checkoutFailed'),
      );
    }
  }

  void clearCheckoutUrl() => state = state.copyWith(clearCheckoutUrl: true);

  void dismissMessage() => state = state.copyWith(clearMessage: true);

  /// Confirms a payment after the WebView returns Mercado Pago redirect
  /// params (`payment`, `status`, `payment_id`, `collection_id`).
  Future<void> handlePaymentReturn(Map<String, String> params) async {
    state = state.copyWith(clearCheckoutUrl: true, confirming: true);
    final paymentId = params['payment_id'] ??
        params['collection_id'] ??
        params['payment'];
    final status = params['status'] ?? '';
    try {
      final confirmation = await _repo.confirm(paymentId: paymentId);
      if (confirmation.reconciled) {
        await _repo.recordPayment(reference: paymentId, paidAt: confirmation.paidAt);
        await load();
        final suffix = confirmation.itemsPaid > 0
            ? AppTexts.format('rfin.msg.itemsReconciled', {'n': '${confirmation.itemsPaid}'})
            : '';
        state = state.copyWith(
          confirming: false,
          message: AppTexts.format('rfin.msg.paymentConfirmed', {'suffix': suffix}),
        );
      } else if (status == 'pending' || status == 'in_process') {
        await load();
        state = state.copyWith(
          confirming: false,
          message: AppTexts.translate('rfin.msg.paymentUnderReview'),
        );
      } else {
        await load();
        state = state.copyWith(
          confirming: false,
          message: AppTexts.translate('rfin.msg.paymentFailed'),
        );
      }
    } catch (e) {
      state = state.copyWith(confirming: false, message: _messageOf(e));
    }
  }
}

final financeControllerProvider =
    NotifierProvider<FinanceController, FinanceState>(FinanceController.new);

String _messageOf(Object e) =>
    e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage();
