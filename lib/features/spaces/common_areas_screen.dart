import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/ui.dart';
import 'common_areas_controller.dart';
import 'socialspaces_models.dart';

/// Browse the building's common areas and reserve a time slot.
class CommonAreasScreen extends ConsumerWidget {
  const CommonAreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialspacesControllerProvider);
    final controller = ref.read(socialspacesControllerProvider.notifier);

    ref.listen(socialspacesControllerProvider.select((s) => s.message), (_, message) {
      if (message == null) return;
      _showInfo(
        context,
        ref.tr('services.title'),
        message,
        ref.tr('services.understood'),
      );
      controller.dismissMessage();
    });

    if (state.loading) return const FullScreenLoading();
    if (state.error != null && state.spaces.isEmpty) {
      return ErrorState(
        state.error!,
        retryLabel: '↻',
        onRetry: () => controller.reload(),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          // `Expanded` constrains the list to the available space so a long
          // list can't overflow and collide with the reserve sheet.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  ref.tr('services.title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  ref.tr('services.subtitle'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const VerticalGap(16),
                Text(
                  ref.tr('services.availableTitle'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const VerticalGap(8),
                if (state.spaces.isEmpty)
                  EmptyState(ref.tr('services.empty'))
                else
                  for (final space in state.spaces)
                    _SpaceCard(
                      space: space,
                      selected: state.selectedSpace?.id == space.id,
                      onSelect: () => controller.selectSpace(space),
                    ),
              ],
            ),
          ),
          if (state.selectedSpace != null)
            _ReserveSheet(state: state),
          if (state.submitting)
            const ModalBarrier(dismissible: false, color: Colors.black26),
        ],
      ),
    );
  }

  Future<void> _showInfo(BuildContext context, String title, String message, String ack) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(ack)),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.selected,
    required this.onSelect,
  });

  final Space space;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      space.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: scheme.primary, size: 20),
                ],
              ),
              if (space.description.isNotEmpty) ...[
                const VerticalGap(8),
                Text(
                  space.description,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
              if (space.capacity != null) ...[
                const VerticalGap(8),
                StatusChip(label: 'services.capacity'.trFormat({'n': '${space.capacity}'}), color: scheme.primary),
              ],
              const VerticalGap(12),
              AppOutlinedActionButton(
                text: 'services.reserve'.trText(),
                enabled: !selected,
                onPressed: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReserveSheet extends ConsumerStatefulWidget {
  const _ReserveSheet({required this.state});

  final SpacesState state;

  @override
  ConsumerState<_ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends ConsumerState<_ReserveSheet> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(socialspacesControllerProvider.notifier);
    final space = state.selectedSpace!;
    final scheme = Theme.of(context).colorScheme;

    // Slots already taken for the selected date.
    final busy = state.spaceReservations
        .where((r) => r.date == state.date)
        .map((r) => '${r.startTime} – ${r.endTime}')
        .toList();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // Reserve room for the on-screen keyboard so the fields and the
        // confirm button are never covered while typing.
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
                      'services.reserveTitle'.trFormat({'name': space.name}),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.clearSelection,
                  ),
                ],
              ),
              const VerticalGap(12),
              _PickerField(
                icon: Icons.calendar_today_outlined,
                label: ref.tr('services.fieldDate'),
                value: Dates.dateLabel(state.date),
                onTap: () => _pickDate(),
              ),
              const VerticalGap(12),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      icon: Icons.schedule,
                      label: ref.tr('services.fieldStart'),
                      value: state.startTime.isEmpty
                          ? ref.tr('services.chooseTime')
                          : state.startTime,
                      placeholder: state.startTime.isEmpty,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      icon: Icons.schedule_outlined,
                      label: ref.tr('services.fieldEnd'),
                      value: state.endTime.isEmpty
                          ? ref.tr('services.chooseTime')
                          : state.endTime,
                      placeholder: state.endTime.isEmpty,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              if (busy.isNotEmpty) ...[
                const VerticalGap(12),
                Text(
                  ref.tr('services.reservedSlots'),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const VerticalGap(4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final slot in busy)
                      StatusChip(label: slot, color: bfWarning),
                  ],
                ),
              ],
              if (state.formError != null) ...[
                const VerticalGap(12),
                Text(state.formError!, style: TextStyle(color: scheme.error)),
              ],
              const VerticalGap(16),
              AppButton(
                text: ref.tr('services.confirmReserve'),
                loading: state.submitting,
                onPressed: controller.reserve,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final state = widget.state;
    final controller = ref.read(socialspacesControllerProvider.notifier);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = Dates.ymdOrNull(state.date);
    final safeInitial = (initial == null || initial.isBefore(today)) ? today : initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: today,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    controller.setDate(
      '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final state = widget.state;
    final controller = ref.read(socialspacesControllerProvider.notifier);
    final current = isStart ? state.startTime : state.endTime;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final formatted = Dates.timeLabel(picked.hour, picked.minute);
    if (isStart) {
      controller.setStartTime(formatted);
    } else {
      controller.setEndTime(formatted);
    }
  }
}

/// A read-only field that opens a date/time picker on tap.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: placeholder ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
