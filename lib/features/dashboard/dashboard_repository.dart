import '../../core/api_client.dart';

/// An official announcement (comunicado). `duration` = days it stays active.
class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.priority = 'normal',
    this.authorName = '',
    required this.createdAt,
    this.duration = 7,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final String body;
  final String priority;
  final String authorName;
  final String createdAt;
  final int duration;
  final String expiresAt;

  bool get isActive {
    try {
      return DateTime.now().toUtc().isBefore(DateTime.parse(expiresAt).toUtc());
    } catch (_) {
      return true;
    }
  }

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'normal',
        authorName: json['authorName']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 7,
        expiresAt: json['expiresAt']?.toString() ?? json['createdAt']?.toString() ?? '',
      );
}

/// Announcements data access (resident side: read-only).
///
/// Queries are multi-tenant scoped via `ownerParams` on the shared client.
class AnnouncementsRepository {
  AnnouncementsRepository(this._api);

  final ApiClient _api;

  Future<List<Announcement>> list() => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'announcements',
          queryParameters: _api.ownerParams({'_sort': 'createdAt', '_order': 'desc'}),
        );
        return (response.data ?? const [])
            .map((e) => Announcement.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
}
