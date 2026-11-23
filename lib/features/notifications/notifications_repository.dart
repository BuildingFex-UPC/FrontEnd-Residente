import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/session_repository.dart';
import 'notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionRepositoryProvider),
  ),
);

class NotificationsRepository {
  NotificationsRepository(this._api, this._session);

  final ApiClient _api;
  final SessionRepository _session;

  Future<List<NotificationItem>> listMine({bool? unreadOnly}) => apiCall(() async {
        final profileId = _session.current?.profile.id;
        final response = await _api.dio.get<List<dynamic>>(
          'notifications',
          queryParameters: {
            if (profileId != null) 'recipientId': profileId,
            'role': 'resident',
            if (unreadOnly != null) 'unreadOnly': unreadOnly.toString(),
          },
        );
        return (response.data ?? const [])
            .map((e) => NotificationItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });

  Future<int> unreadCount() => apiCall(() async {
        final profileId = _session.current?.profile.id;
        final response = await _api.dio.get<Map<String, dynamic>>(
          'notifications/unread-count',
          queryParameters: {
            if (profileId != null) 'recipientId': profileId,
            'role': 'resident',
          },
        );
        return (response.data?['count'] as num?)?.toInt() ?? 0;
      });

  Future<void> markAsRead(String id) =>
      apiCall(() => _api.dio.post<dynamic>('notifications/$id/read'));

  Future<void> markAllAsRead() => apiCall(() async {
        final profileId = _session.current?.profile.id;
        await _api.dio.post<dynamic>(
          'notifications/read-all',
          queryParameters: {
            if (profileId != null) 'recipientId': profileId,
            'role': 'resident',
          },
        );
      });
}

