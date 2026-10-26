import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/repositories.dart';
import '../../core/session_repository.dart';
import 'support_repository.dart';

final supportControllerProvider =
    StateNotifierProvider<SupportController, SupportState>(
  (ref) => SupportController(ref),
);

class SupportState {
  const SupportState({
    this.loading = true,
    this.error,
    this.chats = const [],
    this.openingChatId,
    this.chat,
    this.loadingChat = false,
    this.newTopic = '',
    this.message = '',
    this.sending = false,
    this.creating = false,
    this.dialogMessage,
  });

  final bool loading;
  final String? error;
  final List<SupportChat> chats;

  /// Chat currently open in the conversation view (null = list view).
  final String? openingChatId;
  final SupportChat? chat;
  final bool loadingChat;

  final String newTopic;
  final String message;
  final bool sending;
  final bool creating;

  /// One-off dialog message (errors / confirmations).
  final String? dialogMessage;

  SupportState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<SupportChat>? chats,
    String? openingChatId,
    bool clearOpeningChatId = false,
    SupportChat? chat,
    bool clearChat = false,
    bool? loadingChat,
    String? newTopic,
    String? message,
    bool? sending,
    bool? creating,
    String? dialogMessage,
    bool clearDialogMessage = false,
  }) =>
      SupportState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        chats: chats ?? this.chats,
        openingChatId: clearOpeningChatId ? null : (openingChatId ?? this.openingChatId),
        chat: clearChat ? null : (chat ?? this.chat),
        loadingChat: loadingChat ?? this.loadingChat,
        newTopic: newTopic ?? this.newTopic,
        message: message ?? this.message,
        sending: sending ?? this.sending,
        creating: creating ?? this.creating,
        dialogMessage: clearDialogMessage ? null : (dialogMessage ?? this.dialogMessage),
      );
}

/// Resident support: FAQ catalog + own support chats.
class SupportController extends StateNotifier<SupportState> {
  SupportController(this._ref) : super(const SupportState()) {
    _load();
  }

  final Ref _ref;

  List<Faq> get faqs => faqCatalog;

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final residentId = _ref.read(sessionRepositoryProvider).current?.profile.id ?? '';
      final chats =
          await _ref.read(supportRepositoryProvider).listChatsForResident(residentId);
      state = state.copyWith(loading: false, chats: chats);
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageOf(e));
    }
  }

  void setNewTopic(String value) => state = state.copyWith(newTopic: value);

  void setMessage(String value) => state = state.copyWith(message: value);

  /// Creates a new support chat and opens it.
  Future<void> createChat() async {
    if (state.creating) return;
    state = state.copyWith(creating: true, clearDialogMessage: true);
    try {
      final profile = _ref.read(sessionRepositoryProvider).current?.profile;
      final chat = await _ref.read(supportRepositoryProvider).createChat(
            residentId: profile?.id ?? '',
            residentName: profile?.name ?? '',
            topic: state.newTopic,
          );
      state = state.copyWith(
        creating: false,
        newTopic: '',
        chats: [chat, ...state.chats],
        openingChatId: chat.id,
        chat: chat,
        loadingChat: false,
      );
    } catch (e) {
      state = state.copyWith(creating: false, dialogMessage: _messageOf(e));
    }
  }

  /// Opens the conversation view for [chatId].
  Future<void> openChat(String chatId) async {
    state = state.copyWith(openingChatId: chatId, loadingChat: true, clearChat: true);
    try {
      final chat = await _ref.read(supportRepositoryProvider).getChat(chatId);
      state = state.copyWith(loadingChat: false, chat: chat);
    } catch (e) {
      state = state.copyWith(loadingChat: false, dialogMessage: _messageOf(e));
    }
  }

  void closeChat() =>
      state = state.copyWith(clearOpeningChatId: true, clearChat: true, message: '');

  /// Appends the resident's message to the open chat.
  Future<void> sendMessage() async {
    final chat = state.chat;
    final body = state.message.trim();
    if (chat == null || body.isEmpty || state.sending) return;
    state = state.copyWith(sending: true, clearDialogMessage: true);
    try {
      final profile = _ref.read(sessionRepositoryProvider).current?.profile;
      final updated = await _ref.read(supportRepositoryProvider).appendMessage(
            chat.id,
            'resident',
            body,
            authorName: profile?.name,
          );
      state = state.copyWith(
        sending: false,
        message: '',
        chat: updated,
        chats: [
          for (final c in state.chats)
            if (c.id == updated.id) updated else c,
        ],
      );
    } catch (e) {
      state = state.copyWith(sending: false, dialogMessage: _messageOf(e));
    }
  }

  void dismissDialog() => state = state.copyWith(clearDialogMessage: true);
}

String _messageOf(Object e) =>
    e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage();
