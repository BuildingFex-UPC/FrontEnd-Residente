import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/avatar.dart';
import '../../core/language_controller.dart';
import '../../core/session_repository.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/finance_screen.dart';
import '../incidents/incidents_screen.dart';
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
    final session = ref.watch(
      sessionRepositoryProvider.select((repo) => repo.current),
    );
    final language = ref.watch(languageControllerProvider);
    final selected =
        _items.firstWhere((item) => item.id == _selectedId, orElse: () => _items.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr(selected.titleKey)),
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
