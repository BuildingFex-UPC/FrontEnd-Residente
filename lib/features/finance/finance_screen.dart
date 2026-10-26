import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/language_controller.dart';
import '../../core/session_repository.dart';
import '../../core/ui.dart';
import 'finance_controller.dart';
import 'finance_models.dart';
import 'payment_webview.dart';

/// Resident finances: pending balance, Mercado Pago checkout, fees and history.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final language = ref.watch(languageControllerProvider);

    // React to a checkout being started: open Mercado Pago in a WebView and
    // feed the redirect params back into the controller.
    ref.listen(financeControllerProvider.select((s) => s.checkoutUrl), (prev, next) {
      if (next != null && next.isNotEmpty) _openCheckout(context, ref, next);
    });

    return Scaffold(
      body: SafeArea(
        child: _buildBody(context, ref, state, language),
      ),
      // Confirmation / status dialogs.
      floatingActionButton: null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FinanceState state, String language) {
    if (state.loading && state.account == null) return const FullScreenLoading();
    if (state.error != null && state.account == null) {
      return ErrorState(state.error!, retryLabel: '↻', onRetry: () => ref.read(financeControllerProvider.notifier).load());
    }
    final account = state.account;
    if (account == null) return const FullScreenLoading();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(financeControllerProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(ref.tr('rfin.title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(ref.tr('rfin.subtitle'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const VerticalGap(16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: ref.tr('rfin.pending'),
                      value: formatSoles(account.pendingAmount),
                      color: bfWarning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: ref.tr('rfin.paidTotal'),
                      value: formatSoles(account.paidTotal),
                      color: bfSuccess,
                    ),
                  ),
                ],
              ),
              if (account.hasPending) ...[
                const VerticalGap(16),
                SectionCard(
                  title: ref.tr('rfin.checkout.title'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.tr('rfin.checkout.subtitle'),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const VerticalGap(12),
                      AppButton(
                        text: state.startingCheckout || state.confirming
                            ? ref.tr('rfin.checkout.opening')
                            : ref.tr('rfin.checkout.pay'),
                        loading: state.startingCheckout || state.confirming,
                        onPressed: () => ref
                            .read(financeControllerProvider.notifier)
                            .startCheckout(
                              payerEmail: ref.read(sessionRepositoryProvider).current?.profile.email,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const VerticalGap(16),
              SectionCard(
                title: ref.tr('rfin.fees.title'),
                child: account.fees.isEmpty
                    ? EmptyState(ref.tr('rfin.fees.empty'))
                    : Column(
                        children: [
                          for (final fee in account.fees) _FeeRow(fee: fee, language: language),
                        ],
                      ),
              ),
              const VerticalGap(16),
              SectionCard(
                title: ref.tr('rfin.history.title'),
                child: account.payments.isEmpty
                    ? EmptyState(ref.tr('rfin.history.empty'))
                    : Column(
                        children: [
                          for (final payment in account.payments)
                            _PaymentRow(payment: payment, language: language),
                        ],
                      ),
              ),
              const VerticalGap(24),
            ],
          ),
        ),
        if (state.message != null)
          _MessageDialog(
            message: state.message!,
            ackText: ref.tr('rfin.understood'),
            onAck: () => ref.read(financeControllerProvider.notifier).dismissMessage(),
          ),
      ],
    );
  }

  Future<void> _openCheckout(BuildContext context, WidgetRef ref, String url) async {
    final controller = ref.read(financeControllerProvider.notifier);
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => PaymentWebView(url: url, title: ref.read(financeRepositoryTitleProvider)),
      ),
    );
    if (result != null) {
      await controller.handlePaymentReturn(result);
    } else {
      controller.clearCheckoutUrl();
    }
  }
}

final financeRepositoryTitleProvider = Provider<String>((_) => 'Mercado Pago');

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const VerticalGap(4),
              Text(value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.fee, required this.language});

  final FeeItem fee;
  final String language;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fee.concept, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'rfin.fees.row'
                      .trFormat({'month': fee.month, 'date': Dates.dateLabel(fee.dueDate, lang: language)}),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatSoles(fee.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
              StatusChip(
                label: fee.isPaid ? 'rfin.status.paid'.trText() : 'rfin.status.pending'.trText(),
                color: fee.isPaid ? bfSuccess : bfWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.language});

  final Payment payment;
  final String language;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final concept = (payment.concept == null || payment.concept!.trim().isEmpty)
        ? 'rfin.payment.fallbackConcept'.trText()
        : payment.concept!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concept, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  Dates.dateTimeLabel(payment.paidAt, lang: language),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(formatSoles(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.w600, color: bfSuccess)),
        ],
      ),
    );
  }
}

class _MessageDialog extends StatelessWidget {
  const _MessageDialog({required this.message, required this.ackText, required this.onAck});

  final String message;
  final String ackText;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ModalBarrier(dismissible: false, color: Colors.black.withValues(alpha: 0.3)),
          Center(
            child: ConfirmDialog(
              title: 'rfin.title'.trText(),
              message: message,
              confirmText: ackText,
              onConfirm: onAck,
              onDismiss: onAck,
            ),
          ),
        ],
      );
}
