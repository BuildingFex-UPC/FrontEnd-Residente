import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/invite_codes.dart';
import '../../core/ui.dart';
import '../spaces/socialspaces_models.dart';
import 'my_reservations_controller.dart';

/// The resident's own reservations: guest list editing + invite QR.
class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    // The controller is cached (non-autoDispose), so its constructor only runs
    // once. Reload every time this tab is shown so a reservation created in
    // another tab (Espacios comunes) shows up here immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(myReservationsControllerProvider.notifier).reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myReservationsControllerProvider);
    final controller = ref.read(myReservationsControllerProvider.notifier);

    ref.listen(myReservationsControllerProvider.select((s) => s.message), (_, message) {
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      controller.dismissMessage();
    });

    if (state.loading && state.reservations.isEmpty) return const FullScreenLoading();
    if (state.error != null && state.reservations.isEmpty) {
      return ErrorState(
        state.error!,
        retryLabel: '↻',
        onRetry: () => controller.reload(),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          // `Expanded` constrains the list so it can't overflow into the editor.
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    ref.tr('resv.title'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    ref.tr('resv.subtitle'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const VerticalGap(16),
                  if (state.reservations.isEmpty)
                    EmptyState(ref.tr('resv.empty'))
                  else
                    for (final reservation in state.reservations)
                      _ReservationCard(
                        reservation: reservation,
                        spaceName: state.spacesById[reservation.spaceId]?.name,
                        onEditGuests: () => controller.openEditor(reservation),
                      ),
                ],
              ),
            ),
          ),
          if (state.editing != null)
            _GuestsEditor(state: state),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.spaceName,
    required this.onEditGuests,
  });

  final Reservation reservation;
  final String? spaceName;
  final VoidCallback onEditGuests;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasGuests = reservation.guests.isNotEmpty;
    final expired =
        ReservationRules.isInviteExpired(reservation.date, reservation.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    spaceName ?? 'resv.spaceFallback'.trText(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
            const VerticalGap(8),
            Text(
              '${Dates.dateLabel(reservation.date)} · ${reservation.startTime} – ${reservation.endTime}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const VerticalGap(12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${'resv.guests'.trText()}: ${reservation.guests.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton(onPressed: onEditGuests, child: Text('resv.editGuests'.trText())),
              ],
            ),
            if (hasGuests) ...[
              const VerticalGap(8),
              for (final guest in reservation.guests)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(child: Text(guest.name, style: const TextStyle(fontSize: 14))),
                      StatusChip(
                        label: guest.checkedIn
                            ? 'resv.checkedIn'.trText()
                            : 'resv.notCheckedIn'.trText(),
                        color: guest.checkedIn ? bfSuccess : bfWarning,
                      ),
                    ],
                  ),
                ),
              const VerticalGap(12),
              if (expired)
                Text(
                  'resv.inviteExpired'.trText(),
                  style: TextStyle(color: scheme.error, fontSize: 12),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_2, size: 18),
                        label: Text('resv.inviteTitle'.trText()),
                        onPressed: () => _showInviteSheet(context, reservation),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteSheet(BuildContext context, Reservation reservation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InviteSheet(reservation: reservation),
    );
  }
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final token = reservation.guestInviteToken ?? '';
    final link = GuestInviteLink.build(token);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'resv.inviteTitle'.trText(),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const VerticalGap(16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: QrImageView(
                data: link.isEmpty ? token : link,
                size: 220,
                semanticsLabel: 'resv.inviteQrDesc'.trText(),
              ),
            ),
          ),
          const VerticalGap(16),
          if (link.isNotEmpty)
            SelectableText(
              link,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          const VerticalGap(16),
          AppButton(
            text: 'resv.shareQr'.trText(),
            onPressed: () => _share(context),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final token = reservation.guestInviteToken ?? '';
    final link = GuestInviteLink.build(token);
    final text = link.isNotEmpty
        ? 'resv.shareUrl'.trFormat({'url': link})
        : 'resv.shareToken'.trFormat({'token': token});
    await SharePlus.instance.share(ShareParams(text: text));
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _GuestsEditor extends ConsumerStatefulWidget {
  const _GuestsEditor({required this.state});

  final MyReservationsState state;

  @override
  ConsumerState<_GuestsEditor> createState() => _GuestsEditorState();
}

class _GuestsEditorState extends ConsumerState<_GuestsEditor> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(myReservationsControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // Reserve room for the on-screen keyboard so the guest fields and the
        // save button are never covered while typing.
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'resv.editGuests'.trText(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.closeEditor,
                  ),
                ],
              ),
              const VerticalGap(8),
              Text(
                'resv.guestsHint'.trFormat({'n': '${ReservationRules.maxGuests}'}),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const VerticalGap(12),
              for (var index = 0; index < state.guestInputs.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ControlledTextField(
                    label: 'resv.guestLabel'.trFormat({'n': '${index + 1}'}),
                    value: state.guestInputs[index].name,
                    onChanged: (value) => controller.setGuestName(index, value),
                  ),
                ),
              if (state.guestInputs.length < ReservationRules.maxGuests)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('resv.guests'.trText()),
                  onPressed: controller.addGuestRow,
                ),
              if (state.formError != null) ...[
                const VerticalGap(8),
                Text(state.formError!, style: TextStyle(color: scheme.error)),
              ],
              const VerticalGap(16),
              AppButton(
                text: 'resv.save'.trText(),
                loading: state.saving,
                onPressed: controller.saveGuests,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
