import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar.dart';
import '../../core/language_controller.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/finance_screen.dart';
import '../incidents/incidents_screen.dart';
import '../notifications/notification_model.dart';
import '../notifications/notifications_controller.dart';
import '../reservations/my_reservations_screen.dart';
import '../settings/settings_screen.dart';
import '../spaces/common_areas_screen.dart';
import '../support/support_screen.dart';

class _NavItem {
  const _NavItem(this.id, this.titleKey, this.icon, this.screen);

  final String id;
  final String titleKey;
  final IconData icon;
  final Widget screen;
}

final _items = <_NavItem>[
  _NavItem('dashboard', 'shell.nav.dashboard', Icons.dashboard_outlined, const DashboardScreen()),
  _NavItem('finance', 'shell.nav.finances', Icons.account_balance_wallet_outlined, const FinanceScreen()),
  _NavItem('spaces', 'shell.nav.resident_services', Icons.dashboard_outlined, const CommonAreasScreen()),
  _NavItem('reservations', 'shell.nav.myReservations', Icons.calendar_month_outlined, const MyReservationsScreen()),
  _NavItem('incidents', 'shell.nav.incidents', Icons.flag_outlined, const IncidentsScreen()),
  _NavItem('support', 'shell.nav.support', Icons.support_agent_outlined, const SupportScreen()),
  _NavItem('settings', 'shell.nav.settings', Icons.settings_outlined, const SettingsScreen()),
];

/// Resident shell: a lateral drawer (like the web sidebar) + top bar.
class ResidentShell extends ConsumerStatefulWidget {
  const ResidentShell({super.key});

  @override
  ConsumerState<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends ConsumerState<ResidentShell> {
  String _selectedId = _items.first.id;

  @override
  Widget build(BuildContext context) {
    // Watch the auth controller (reactive) so the drawer reflects an edited
    // name/email/avatar immediately, without waiting for a screen change.
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final language = ref.watch(languageControllerProvider);
    final notifState = ref.watch(notificationsControllerProvider);
    final selected =
        _items.firstWhere((item) => item.id == _selectedId, orElse: () => _items.first);

    // Alert resident when an incident has been resolved
    ref.listen<NotificationItem?>(
      notificationsControllerProvider.select((s) => s.latestResolvedIncident),
      (previous, next) {
        if (next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ref.tr('notif.resolvedAlert')}: ${next.message}',
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: ref.tr('notif.view'),
                textColor: Colors.amberAccent,
                onPressed: () {
                  setState(() => _selectedId = 'incidents');
                  ref.read(notificationsControllerProvider.notifier).markAsRead(next.id);
                },
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          ref.read(notificationsControllerProvider.notifier).dismissResolvedAlert();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr(selected.titleKey)),
        actions: [
          IconButton(
            tooltip: ref.tr('notif.title'),
            icon: notifState.unreadCount > 0
                ? Badge.count(
                    count: notifState.unreadCount,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotificationsSheet(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerHeader(
                name: session?.profile.name ?? '',
                email: session?.profile.email ?? '',
                role: ref.tr('shell.role.resident'),
                avatar: session?.profile.avatar,
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in _items)
                      ListTile(
                        leading: Icon(item.icon),
                        title: Text(ref.tr(item.titleKey)),
                        selected: item.id == _selectedId,
                        onTap: () {
                          setState(() => _selectedId = item.id);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(ref.tr('shell.language')),
                trailing: Text(language == 'es' ? 'ES' : 'EN'),
                onTap: () => ref.read(languageControllerProvider.notifier).toggle(),
              ),
              ListTile(
                leading: Icon(Icons.logout_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  ref.tr('shell.logout'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
      body: selected.screen,
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    ref.read(notificationsControllerProvider.notifier).reload();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(notificationsControllerProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            const SizedBox(width: 8),
                            Text(
                              ref.tr('notif.title'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        if (state.notifications.any((n) => !n.isRead))
                          TextButton(
                            onPressed: () => ref
                                .read(notificationsControllerProvider.notifier)
                                .markAllAsRead(),
                            child: Text(ref.tr('notif.markAllRead')),
                          ),
                      ],
                    ),
                    const Divider(),
                    if (state.loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            ref.tr('notif.empty'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: state.notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final notif = state.notifications[index];
                            final isIncident = notif.type.startsWith('incident');
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: notif.type == 'incident_resolved'
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                child: Icon(
                                  notif.type == 'incident_resolved'
                                      ? Icons.check_circle_outline
                                      : Icons.flag_outlined,
                                  color: notif.type == 'incident_resolved'
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Nueva',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(notif.message),
                                  const SizedBox(height: 2),
                                  Text(
                                    notif.createdAt.length >= 16
                                        ? notif.createdAt
                                            .substring(0, 16)
                                            .replaceAll('T', ' ')
                                        : notif.createdAt,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (!notif.isRead) {
                                  ref
                                      .read(notificationsControllerProvider.notifier)
                                      .markAsRead(notif.id);
                                }
                                if (isIncident) {
                                  Navigator.of(context).pop();
                                  setState(() => _selectedId = 'incidents');
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
  });

  final String name;
  final String email;
  final String role;

  /// Profile icon: preset ("preset|😀|#FF5722") or a gallery photo data URL.
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AvatarView(avatar: avatar, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
