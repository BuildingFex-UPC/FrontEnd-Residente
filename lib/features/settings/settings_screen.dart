import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/language_controller.dart';
import '../../core/session_repository.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import 'edit_account_screen.dart';

/// Profile + language + session (settings).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(
      sessionRepositoryProvider.select((repo) => repo.current),
    );
    final language = ref.watch(languageControllerProvider);
    final profile = session?.profile;
    final scheme = Theme.of(context).colorScheme;

    if (profile == null) {
      return EmptyState(ref.tr('set.profile.loadFailed'));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ref.tr('set.title'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            ref.tr('set.subtitle'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const VerticalGap(16),
          SectionCard(
            title: ref.tr('set.profile.title'),
            child: Column(
              children: [
                KeyValue(label: ref.tr('set.profile.name'), value: profile.name),
                KeyValue(
                  label: ref.tr('set.profile.email'),
                  value: profile.email ?? '—',
                ),
                if (profile.dni?.isNotEmpty == true)
                  KeyValue(label: ref.tr('set.profile.dni'), value: profile.dni!),
                if (profile.address?.isNotEmpty == true)
                  KeyValue(label: ref.tr('set.profile.address'), value: profile.address!),
                if (profile.floor?.isNotEmpty == true)
                  KeyValue(label: ref.tr('set.profile.floor'), value: profile.floor!),
                if (profile.code?.isNotEmpty == true)
                  KeyValue(label: ref.tr('set.profile.department'), value: profile.code!),
              ],
            ),
          ),
          const VerticalGap(16),
          SectionCard(
            title: ref.tr('set.account.title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ref.tr('set.account.hint'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const VerticalGap(12),
                AppOutlinedActionButton(
                  text: ref.tr('set.account.edit'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditAccountScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalGap(16),
          SectionCard(
            title: ref.tr('shell.language'),
            child: Row(
              children: [
                Expanded(child: Text(ref.tr('shell.language'))),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'es', label: Text('ES')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {language},
                  onSelectionChanged: (selection) => ref
                      .read(languageControllerProvider.notifier)
                      .setLanguage(selection.first),
                ),
              ],
            ),
          ),
          const VerticalGap(16),
          SectionCard(
            title: ref.tr('set.session.title'),
            child: AppButton(
              text: ref.tr('set.session.logout'),
              destructive: true,
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
          const VerticalGap(24),
        ],
      ),
    );
  }
}
