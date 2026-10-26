import '../../core/api_client.dart';
import '../../core/dates.dart';
import '../../core/session_repository.dart';

/// Incident statuses (ubiquitous language shared with the web app).
class IncidentStatus {
  static const String open = 'open';
  static const String inProgress = 'in-progress';
  static const String resolved = 'resolved';
}

class Incident {
  Incident({
    required this.id,
    this.residentId,
    this.residentName = '',
    this.description = '',
    this.status = IncidentStatus.open,
    this.createdAt,
    this.provider = '',
  });

  final String id;
  final String? residentId;
  final String residentName;
  final String description;
  final String status;
  final String? createdAt;
  final String provider;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id']?.toString() ?? '',
        residentId: json['residentId']?.toString(),
        residentName: json['residentName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: json['status']?.toString() ?? IncidentStatus.open,
        createdAt: json['createdAt']?.toString(),
        provider: json['provider']?.toString() ?? '',
      );
}

/// Incidents data access (resident side).
class IncidentsRepository {
  IncidentsRepository(this._api, this._session);

  final ApiClient _api;
  final SessionRepository _session;

  /// All incidents for this resident's building, newest first.
  Future<List<Incident>> listMine() => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'incidents',
          queryParameters: _api.ownerParams(),
        );
        final mine = _session.current?.profile.id;
        final all = (response.data ?? const [])
            .map((e) => Incident.fromJson((e as Map).cast<String, dynamic>()))
            .where((i) => mine == null || i.residentId == mine)
            .toList();
        all.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        return all;
      });

  /// Reports a new incident for the signed-in resident.
  Future<Incident> report(String description) => apiCall(() async {
        final profile = _session.current?.profile;
        final response = await _api.dio.post<dynamic>(
          'incidents',
          data: {
            'id': 'incident-${DateTime.now().millisecondsSinceEpoch}',
            'residentId': profile?.id,
            'residentName': profile?.name ?? '',
            'description': description.trim(),
            'status': IncidentStatus.open,
            'createdAt': Dates.nowIso(),
            'provider': '',
            'ownerAdminId': _session.activeDataOwnerId,
          },
        );
        return Incident.fromJson(
          (response.data as Map?)?.cast<String, dynamic>() ?? const {},
        );
      });

  /// Residents may only correct their own description (status/provider
  /// remain admin-owned).
  Future<void> updateDescription(String id, String description) =>
      apiCall(() async {
        await _api.dio.patch<dynamic>(
          'incidents/$id',
          data: {'description': description.trim()},
        );
      });

  Future<void> remove(String id) =>
      apiCall(() => _api.dio.delete<dynamic>('incidents/$id'));
}
