import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_model.dart';
import 'notifications_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.loading = false,
    this.unreadCount = 0,
    this.notifications = const [],
    this.latestResolvedIncident,
  });

  final bool loading;
  final int unreadCount;
  final List<NotificationItem> notifications;
  final NotificationItem? latestResolvedIncident;

  NotificationsState copyWith({
    bool? loading,
    int? unreadCount,
    List<NotificationItem>? notifications,
    NotificationItem? latestResolvedIncident,
    bool clearLatestResolved = false,
  }) =>
      NotificationsState(
        loading: loading ?? this.loading,
        unreadCount: unreadCount ?? this.unreadCount,
        notifications: notifications ?? this.notifications,
        latestResolvedIncident: clearLatestResolved
            ? null
            : (latestResolvedIncident ?? this.latestResolvedIncident),
      );
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (ref) => NotificationsController(ref),
);

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._ref) : super(const NotificationsState()) {
    reload();
  }

  final Ref _ref;

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    try {
      final repo = _ref.read(notificationsRepositoryProvider);
      final list = await repo.listMine();
      final unread = list.where((n) => !n.isRead).length;

      // Detect unread resolved incident notification
      final resolved = list.firstWhere(
        (n) => !n.isRead && n.type == 'incident_resolved',
        orElse: () => NotificationItem(
          id: '',
          recipientId: '',
          role: '',
          title: '',
          message: '',
          type: '',
          isRead: true,
          createdAt: '',
        ),
      );

      state = state.copyWith(
        loading: false,
        unreadCount: unread,
        notifications: list,
        latestResolvedIncident: resolved.id.isNotEmpty ? resolved : null,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _ref.read(notificationsRepositoryProvider).markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationItem(
            id: n.id,
            recipientId: n.recipientId,
            role: n.role,
            title: n.title,
            message: n.message,
            type: n.type,
            relatedEntityId: n.relatedEntityId,
            isRead: true,
            createdAt: n.createdAt,
            readAt: DateTime.now().toIso8601String(),
          );
        }
        return n;
      }).toList();

      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _ref.read(notificationsRepositoryProvider).markAllAsRead();
      final updated = state.notifications
          .map((n) => NotificationItem(
                id: n.id,
                recipientId: n.recipientId,
                role: n.role,
                title: n.title,
                message: n.message,
                type: n.type,
                relatedEntityId: n.relatedEntityId,
                isRead: true,
                createdAt: n.createdAt,
                readAt: DateTime.now().toIso8601String(),
              ))
          .toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: 0,
        clearLatestResolved: true,
      );
    } catch (_) {}
  }

  void dismissResolvedAlert() {
    state = state.copyWith(clearLatestResolved: true);
  }
}

