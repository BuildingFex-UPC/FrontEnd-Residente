import 'dart:math';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/session_repository.dart';
import 'socialspaces_models.dart';

/// Social-spaces data access: the space catalog plus resident reservations.
class SocialSpacesRepository {
  SocialSpacesRepository(this._api, this._session);

  final ApiClient _api;
  final SessionRepository _session;

  String get _residentId => _session.current?.profile.id ?? '';

  /// `GET socialSpaces`
  Future<List<Space>> listSpaces() => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'socialSpaces',
          queryParameters: _api.ownerParams(),
        );
        return (response.data ?? const [])
            .map((e) => Space.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });

  /// `GET reservations?residentId=` (includes the guest invite token).
  Future<List<Reservation>> listByResident(String residentId) => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'reservations',
          queryParameters: _api.ownerParams({'residentId': residentId}),
        );
        return (response.data ?? const [])
            .map((e) => Reservation.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });

  /// `GET reservations?spaceId=` (invite token stripped).
  Future<List<Reservation>> listBySpace(String spaceId) => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'reservations',
          queryParameters: _api.ownerParams({'spaceId': spaceId}),
        );
        return (response.data ?? const [])
            .map((e) => Reservation.fromJson(
                  (e as Map).cast<String, dynamic>(),
                  includeInviteToken: false,
                ))
            .toList();
      });

  /// Client-side validated create (field/time/overlap), mirroring the web.
  Future<Reservation> add({
    required String spaceId,
    required String residentName,
    required String residentCode,
    required String date,
    required String startTime,
    required String endTime,
  }) =>
      apiCall(() async {
        final residentId = _residentId;
        final cleanSpace = spaceId.trim();
        final cleanDate = date.trim();
        final start = startTime.trim();
        final end = endTime.trim();
        if (cleanSpace.isEmpty ||
            residentId.isEmpty ||
            cleanDate.isEmpty ||
            start.isEmpty ||
            end.isEmpty) {
          throw AppException('RESERVATION_FIELDS_REQUIRED', '');
        }
        if (!ReservationRules.timeRangeValid(start, end)) {
          throw AppException('RESERVATION_TIME_INVALID', '');
        }

        final existingResponse = await _api.dio.get<List<dynamic>>(
          'reservations',
          queryParameters: _api.ownerParams({'spaceId': cleanSpace, 'date': cleanDate}),
        );
        final existing = (existingResponse.data ?? const [])
            .map((e) => Reservation.fromJson(
                  (e as Map).cast<String, dynamic>(),
                  includeInviteToken: false,
                ))
            .toList();
        final candidate = Reservation(
          spaceId: cleanSpace,
          date: cleanDate,
          startTime: start,
          endTime: end,
        );
        if (existing.any((r) => ReservationRules.overlaps(r, candidate))) {
          throw AppException('RESERVATION_OVERLAP', '');
        }

        final response = await _api.dio.post<dynamic>(
          'reservations',
          data: {
            'id': 'reservation-${DateTime.now().millisecondsSinceEpoch}',
            'spaceId': cleanSpace,
            'residentId': residentId,
            'residentName': residentName.trim(),
            'residentCode': residentCode.trim(),
            'date': cleanDate,
            'startTime': start,
            'endTime': end,
            'guests': <dynamic>[],
            'guestInviteToken': null,
            'ownerAdminId': _session.activeDataOwnerId,
          },
        );
        return Reservation.fromJson(
          (response.data as Map?)?.cast<String, dynamic>() ?? const {},
        );
      });

  /// Updates the guest list (max [ReservationRules.maxGuests]) and rotates the
  /// invite token only when guests are present.
  Future<Reservation> updateGuests(String reservationId, List<GuestInput> guests) =>
      apiCall(() async {
        final cleanId = reservationId.trim();
        if (cleanId.isEmpty) throw AppException('RESERVATION_NOT_FOUND', '');

        final currentResponse = await _api.dio.get<Map<dynamic, dynamic>>(
          'reservations/$cleanId',
          queryParameters: _api.ownerParams(),
        );
        final current = Reservation.fromJson(
          (currentResponse.data ?? const {}).cast<String, dynamic>(),
        );

        final normalized = <Map<String, dynamic>>[];
        for (var index = 0; index < guests.length; index++) {
          final input = guests[index];
          final name = input.name.trim();
          if (name.isEmpty) continue;
          final incomingId = input.id.trim();
          Guest? previous;
          for (final g in current.guests) {
            if (g.id == incomingId) {
              previous = g;
              break;
            }
          }
          normalized.add({
            'id': incomingId.isEmpty
                ? 'guest-${DateTime.now().millisecondsSinceEpoch}-$index'
                : incomingId,
            'name': name,
            'checkedIn': previous?.checkedIn ?? false,
            'checkedInAt': previous?.checkedInAt,
          });
          if (normalized.length >= ReservationRules.maxGuests) break;
        }

        final token = normalized.isNotEmpty
            ? (current.guestInviteToken?.trim().isNotEmpty == true
                ? current.guestInviteToken
                : 'invite-${_randomUuid()}')
            : null;

        final response = await _api.dio.patch<Map<dynamic, dynamic>>(
          'reservations/$cleanId',
          data: {'guests': normalized, 'guestInviteToken': token},
        );
        return Reservation.fromJson(
          (response.data ?? const {}).cast<String, dynamic>(),
        );
      });
}

String _randomUuid() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
