import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/features/notifications/notification_model.dart';
import 'package:frontend_residente/features/notifications/notifications_controller.dart';

void main() {
  group('NotificationItem model', () {
    test('fromJson parses full incident_resolved notification', () {
      final json = {
        'id': 'notif-100',
        'recipientId': 'res-123',
        'role': 'resident',
        'title': 'Incidente resuelto',
        'message': "Tu incidente 'Luz quemada' ha sido resuelto.",
        'type': 'incident_resolved',
        'relatedEntityId': 'inc-555',
        'isRead': false,
        'createdAt': '2026-11-23T12:00:00Z',
        'readAt': null,
      };

      final notif = NotificationItem.fromJson(json);

      expect(notif.id, 'notif-100');
      expect(notif.recipientId, 'res-123');
      expect(notif.role, 'resident');
      expect(notif.title, 'Incidente resuelto');
      expect(notif.message, "Tu incidente 'Luz quemada' ha sido resuelto.");
      expect(notif.type, 'incident_resolved');
      expect(notif.relatedEntityId, 'inc-555');
      expect(notif.isRead, false);
      expect(notif.createdAt, '2026-11-23T12:00:00Z');
      expect(notif.readAt, isNull);
    });

    test('fromJson defaults fallback values', () {
      final notif = NotificationItem.fromJson({});

      expect(notif.id, '');
      expect(notif.type, 'general');
      expect(notif.isRead, false);
      expect(notif.createdAt, '');
    });
  });

  group('NotificationsState', () {
    test('copyWith works correctly and handles clearLatestResolved', () {
      final notif = NotificationItem.fromJson({
        'id': 'notif-1',
        'title': 'Incidente resuelto',
        'message': 'Resuelto',
        'type': 'incident_resolved',
        'isRead': false,
      });

      final state = NotificationsState(
        loading: false,
        unreadCount: 1,
        notifications: [notif],
        latestResolvedIncident: notif,
      );

      expect(state.unreadCount, 1);
      expect(state.latestResolvedIncident, isNotNull);

      final cleared = state.copyWith(clearLatestResolved: true);
      expect(cleared.latestResolvedIncident, isNull);
      expect(cleared.unreadCount, 1);
    });
  });
}

