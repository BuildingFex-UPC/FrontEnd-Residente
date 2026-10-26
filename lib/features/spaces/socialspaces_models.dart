import '../../core/dates.dart';

/// Common areas published by admins and time-bounded reservations residents
/// create against them.
class Space {
  Space({this.id, required this.name, this.description = '', this.capacity, this.imageUrl = ''});

  final String? id;
  final String name;
  final String description;
  final int? capacity;
  final String imageUrl;

  factory Space.fromJson(Map<String, dynamic> json) => Space(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        capacity: (json['capacity'] as num?)?.toInt(),
        imageUrl: json['imageUrl']?.toString() ?? '',
      );
}

class Guest {
  Guest({required this.id, required this.name, this.checkedIn = false, this.checkedInAt});

  final String id;
  final String name;
  final bool checkedIn;
  final String? checkedInAt;
}

/// Editable row of the guest-list dialog (id may be blank for new guests).
class GuestInput {
  GuestInput({this.id = '', this.name = ''});

  final String id;
  final String name;
}

class Reservation {
  Reservation({
    this.id,
    required this.spaceId,
    this.residentId = '',
    this.residentName = '',
    this.residentCode = '',
    required this.date,
    required this.startTime,
    required this.endTime,
    this.guests = const [],
    this.guestInviteToken,
  });

  final String? id;
  final String spaceId;
  final String residentId;
  final String residentName;
  final String residentCode;
  final String date;
  final String startTime;
  final String endTime;
  final List<Guest> guests;
  final String? guestInviteToken;

  factory Reservation.fromJson(Map<String, dynamic> json, {bool includeInviteToken = true}) {
    final guests = (json['guests'] as List? ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .map((m) => Guest(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              checkedIn: m['checkedIn'] as bool? ?? false,
              checkedInAt: m['checkedInAt']?.toString(),
            ))
        .where((g) => g.name.trim().isNotEmpty)
        .toList();
    return Reservation(
      id: json['id']?.toString(),
      spaceId: json['spaceId']?.toString() ?? '',
      residentId: json['residentId']?.toString() ?? '',
      residentName: json['residentName']?.toString() ?? '',
      residentCode: json['residentCode']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      guests: guests,
      guestInviteToken: includeInviteToken ? json['guestInviteToken']?.toString() : null,
    );
  }
}

/// Validation and scheduling rules shared by reservations (ported from the
/// web utils).
class ReservationRules {
  static const int maxGuests = 5;

  /// Minutes after the reservation start when the guest invite stops working.
  static const int inviteExpiresMinutesAfterStart = 25;

  /// Returns minutes after midnight, or null when the value is not `HH:mm`.
  static int? timeToMinutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  static bool timeRangeValid(String startTime, String endTime) {
    final start = timeToMinutes(startTime);
    final end = timeToMinutes(endTime);
    if (start == null || end == null) return false;
    return start < end;
  }

  static bool overlaps(Reservation a, Reservation b) {
    if (a.date != b.date) return false;
    final aStart = timeToMinutes(a.startTime);
    final aEnd = timeToMinutes(a.endTime);
    final bStart = timeToMinutes(b.startTime);
    final bEnd = timeToMinutes(b.endTime);
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) return false;
    return aStart < bEnd && bStart < aEnd;
  }

  /// Expiry instant of the guest invite, or null on invalid input.
  static DateTime? inviteExpiresAt(String? date, String? startTime) {
    final day = Dates.ymdOrNull(date);
    if (day == null) return null;
    final minutes = timeToMinutes(startTime);
    if (minutes == null) return null;
    final start = DateTime(day.year, day.month, day.day).add(Duration(minutes: minutes));
    return start.add(const Duration(minutes: inviteExpiresMinutesAfterStart));
  }

  static bool isInviteExpired(String? date, String? startTime, {DateTime? now}) {
    final expiry = inviteExpiresAt(date, startTime);
    if (expiry == null) return true;
    return (now ?? DateTime.now()).isAfter(expiry);
  }
}
