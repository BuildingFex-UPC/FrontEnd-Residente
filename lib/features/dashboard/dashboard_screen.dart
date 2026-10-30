import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import '../spaces/socialspaces_models.dart';
import 'dashboard_controller.dart';

/// Resident dashboard: greeting, finance KPIs, announcements, incidents and
/// upcoming reservations.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    // Watch the auth controller (reactive) so the greeting reflects an edited
    // name immediately, without waiting for a screen change.
    final name = ref.watch(
      authControllerProvider.select((s) => s.session?.profile.name ?? ''),
    );

    if (state.loading && state.fees.isEmpty && state.reservations.isEmpty) {
      return const FullScreenLoading();
    }
    if (state.error != null && state.fees.isEmpty) {
      return ErrorState(
        state.error!,
        retryLabel: '↻',
        onRetry: () => ref.read(dashboardControllerProvider.notifier).load(),
      );
    }

    final summary = state.financeSummary;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                ref.tr('dash.greeting', {'name': name.isEmpty ? ref.tr('dash.residentFallback') : name}),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(ref.tr('dash.residentSubtitle'),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const VerticalGap(16),
              _KpiCard(
                label: ref.tr('dash.pendingBalance'),
                value: formatSoles(summary.pending),
                color: summary.pending > 0 ? bfWarning : bfSuccess,
              ),
              if (summary.overdue > 0) ...[
                const VerticalGap(8),
                _NoticeChip(
                  text: ref.tr('dash.overdueNotice', {'amount': formatSoles(summary.overdue)}),
                  color: bfWarning,
                ),
              ],
              const VerticalGap(16),
              _CountRow(
                items: [
                  _CountItem(ref.tr('dash.chipOpen', {'n': '${state.openIncidents}'}), scheme.error),
                  _CountItem(ref.tr('dash.chipInProgress', {'n': '${state.inProgressIncidents}'}), bfWarning),
                  _CountItem(ref.tr('dash.chipResolved', {'n': '${state.resolvedIncidents}'}), bfSuccess),
                ],
                title: ref.tr('dash.incidentsTitle'),
              ),
              const VerticalGap(16),
              _ReservationsCard(
                title: ref.tr('dash.todayReservations'),
                reservations: state.todayReservations,
                spacesById: state.spacesById,
                emptyText: ref.tr('dash.noUpcomingReservations'),
                fallbackSpace: ref.tr('dash.defaultSpace'),
              ),
              const VerticalGap(16),
              _ReservationsCard(
                title: ref.tr('dash.upcomingReservations'),
                reservations: state.upcomingReservations,
                spacesById: state.spacesById,
                emptyText: ref.tr('dash.noUpcomingReservations'),
                fallbackSpace: ref.tr('dash.defaultSpace'),
              ),
              const VerticalGap(16),
              SectionCard(
                title: ref.tr('dash.announcementsTitle'),
                child: state.activeAnnouncements.isEmpty
                    ? EmptyState(ref.tr('dash.noFees'))
                    : Column(
                        children: [
                          for (final ann in state.activeAnnouncements)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.campaign_outlined, color: scheme.primary),
                              title: Text(ann.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(ann.body),
                            ),
                        ],
                      ),
              ),
              const VerticalGap(24),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.color});

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
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );
}

class _NoticeChip extends StatelessWidget {
  const _NoticeChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => StatusChip(label: text, color: color);
}

class _CountItem {
  const _CountItem(this.label, this.color);

  final String label;
  final Color color;
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.title, required this.items});

  final String title;
  final List<_CountItem> items;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: title,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final item in items) StatusChip(label: item.label, color: item.color)],
        ),
      );
}

class _ReservationsCard extends StatelessWidget {
  const _ReservationsCard({
    required this.title,
    required this.reservations,
    required this.spacesById,
    required this.emptyText,
    required this.fallbackSpace,
  });

  final String title;
  final List<Reservation> reservations;
  final Map<String, Space> spacesById;
  final String emptyText;
  final String fallbackSpace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      title: title,
      child: reservations.isEmpty
          ? EmptyState(emptyText)
          : Column(
              children: [
                for (final r in reservations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_outlined, color: scheme.primary),
                    title: Text(spacesById[r.spaceId]?.name ?? fallbackSpace,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${Dates.dateLabel(r.date)} · ${r.startTime} – ${r.endTime}'),
                  ),
              ],
            ),
    );
  }
}
