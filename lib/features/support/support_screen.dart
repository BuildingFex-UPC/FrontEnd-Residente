import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/ui.dart';
import 'support_controller.dart';
import 'support_repository.dart';

/// FAQs + support chat for residents.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportControllerProvider);
    final controller = ref.read(supportControllerProvider.notifier);

    if (state.loading && state.chats.isEmpty) return const FullScreenLoading();
    if (state.error != null && state.chats.isEmpty) {
      return ErrorState(
        state.error!,
        retryLabel: '↻',
        onRetry: () => controller.reload(),
      );
    }

    // Conversation view takes over the screen while a chat is open.
    if (state.openingChatId != null) {
      return _ChatView(state: state);
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
                  ref.tr('sup.resident.title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  ref.tr('sup.resident.subtitle'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const VerticalGap(16),
                SectionCard(
                  title: ref.tr('sup.faqs.title'),
                  child: Column(
                    children: [
                      for (final faq in controller.faqs)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          title: Text(
                            faq.questionKey.trText(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq.answerKey.trText(),
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const VerticalGap(16),
                SectionCard(
                  title: ref.tr('sup.chats.title'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.chats.isEmpty)
                        EmptyState(ref.tr('sup.resident.empty'))
                      else
                        for (final chat in state.chats) _ChatTile(chat: chat),
                      const VerticalGap(12),
                      ControlledTextField(
                        label: ref.tr('sup.field.topic'),
                        value: state.newTopic,
                        onChanged: controller.setNewTopic,
                      ),
                      const VerticalGap(12),
                      AppButton(
                        text: state.creating
                            ? ref.tr('sup.action.opening')
                            : ref.tr('sup.action.newTicket'),
                        loading: state.creating,
                        onPressed: controller.createChat,
                      ),
                    ],
                  ),
                ),
                const VerticalGap(24),
              ],
            ),
          ),
          if (state.dialogMessage != null)
            _SupportDialog(message: state.dialogMessage!),
        ],
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});

  final SupportChat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final last = chat.messages.isNotEmpty ? chat.messages.last : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.chat_bubble_outline, color: scheme.primary),
      title: Text(chat.topic, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        'sup.chat.lastActivity'.trFormat({
          'date': Dates.dateTimeLabel(chat.updatedAt),
          'n': '${chat.messages.length}',
        }),
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: last == null
          ? null
          : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: () => ref.read(supportControllerProvider.notifier).openChat(chat.id),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({required this.state});

  final SupportState state;

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = ref.read(supportControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final chat = state.chat;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.closeChat,
        ),
        title: Text(chat?.topic ?? ref.tr('sup.dialog.title')),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Expanded(
              child: state.loadingChat || chat == null
                  ? const FullScreenLoading()
                  : chat.messages.isEmpty
                      ? EmptyState(ref.tr('sup.chat.empty'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final message = chat.messages[index];
                            final isResident = message.authorRole == 'resident';
                            return Align(
                              alignment: isResident
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isResident
                                      ? scheme.primaryContainer
                                      : scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: isResident
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(message.body),
                                    const VerticalGap(4),
                                    Text(
                                      Dates.dateTimeLabel(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ControlledTextField(
                      label: ref.tr('sup.field.messagePlaceholder'),
                      value: state.message,
                      maxLines: 3,
                      onChanged: controller.setMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: state.sending ? null : controller.sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
          if (state.dialogMessage != null)
            _SupportDialog(message: state.dialogMessage!),
        ],
      ),
    );
  }
}

/// Overlay dialog for one-off messages; dismisses via the controller since it
/// renders inside a Stack rather than as a route.
class _SupportDialog extends ConsumerWidget {
  const _SupportDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(
        children: [
          ModalBarrier(dismissible: false, color: Colors.black38),
          Center(
            child: AlertDialog(
              title: Text(ref.tr('sup.dialog.title')),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(supportControllerProvider.notifier).dismissDialog(),
                  child: Text(ref.tr('sup.dialog.ack')),
                ),
              ],
            ),
          ),
        ],
      );
}
