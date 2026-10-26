import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/ui.dart';
import 'incidents_controller.dart';
import 'incidents_repository.dart';

/// Report and track the resident's incidents.
class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentsControllerProvider);
    final controller = ref.read(incidentsControllerProvider.notifier);

    ref.listen(incidentsControllerProvider.select((s) => s.message), (_, message) {
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      controller.dismissMessage();
    });

    if (state.loading && state.incidents.isEmpty) return const FullScreenLoading();
    if (state.error != null && state.incidents.isEmpty) {
      return ErrorState(
        state.error!,
        retryLabel: '↻',
        onRetry: () => controller.reload(),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => controller.reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  ref.tr('inc.resident.title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  ref.tr('inc.resident.subtitle'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const VerticalGap(16),
                SectionCard(
                  title: ref.tr('inc.resident.reportCard'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ControlledTextField(
                        label: ref.tr('inc.field.description'),
                        placeholder: ref.tr('inc.field.descriptionPlaceholder'),
                        value: state.description,
                        maxLines: 4,
                        onChanged: controller.setDescription,
                      ),
                      const VerticalGap(12),
                      AppButton(
                        text: state.submitting
                            ? ref.tr('inc.action.sending')
                            : ref.tr('inc.action.send'),
                        loading: state.submitting,
                        onPressed: controller.report,
                      ),
                    ],
                  ),
                ),
                const VerticalGap(16),
                SectionCard(
                  title: ref.tr('inc.resident.listCard'),
                  child: state.incidents.isEmpty
                      ? EmptyState(ref.tr('inc.resident.empty'))
                      : Column(
                          children: [
                            for (final incident in state.incidents)
                              _IncidentTile(incident: incident),
                          ],
                        ),
                ),
                const VerticalGap(24),
              ],
            ),
          ),
          if (state.editing != null) _EditDialog(state: state),
          if (state.deletingId != null) _DeleteDialog(state: state),
        ],
      ),
    );
  }
}

class _IncidentTile extends ConsumerWidget {
  const _IncidentTile({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(incidentsControllerProvider.notifier);

    final (statusKey, statusColor) = switch (incident.status) {
      IncidentStatus.inProgress => ('inc.status.in-progress', bfWarning),
      IncidentStatus.resolved => ('inc.status.resolved', bfSuccess),
      _ => ('inc.status.open', scheme.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              StatusChip(label: statusKey.trText(), color: statusColor),
            ],
          ),
          const VerticalGap(4),
          Row(
            children: [
              Text(
                Dates.dateTimeLabel(incident.createdAt),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => controller.openEditor(incident),
                child: Text(ref.tr('inc.action.edit')),
              ),
              TextButton(
                onPressed: () => controller.requestDelete(incident.id),
                child: Text(
                  ref.tr('inc.action.delete'),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _EditDialog extends ConsumerStatefulWidget {
  const _EditDialog({required this.state});

  final IncidentsState state;

  @override
  ConsumerState<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends ConsumerState<_EditDialog> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(incidentsControllerProvider.notifier);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ref.tr('inc.editor.editTitle'),
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
              const VerticalGap(12),
              ControlledTextField(
                label: ref.tr('inc.field.description'),
                placeholder: ref.tr('inc.field.descriptionPlaceholder'),
                value: state.editDescription,
                maxLines: 4,
                onChanged: controller.setEditDescription,
              ),
              const VerticalGap(16),
              AppButton(
                text: state.submitting
                    ? ref.tr('inc.action.saving')
                    : ref.tr('inc.action.save'),
                loading: state.submitting,
                onPressed: controller.saveEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialog extends ConsumerWidget {
  const _DeleteDialog({required this.state});

  final IncidentsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(incidentsControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ModalBarrier(dismissible: false, color: Colors.black38),
        Center(
          child: AlertDialog(
            title: Text(ref.tr('inc.delete.title')),
            content: Text(ref.tr('inc.delete.message')),
            actions: [
              TextButton(
                onPressed: controller.cancelDelete,
                child: Text(ref.tr('inc.action.cancel')),
              ),
              TextButton(
                onPressed: controller.confirmDelete,
                child: Text(
                  ref.tr('inc.action.delete'),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
