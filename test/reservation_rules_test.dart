import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/features/spaces/socialspaces_models.dart';

Reservation _res(String date, String start, String end) => Reservation(
      spaceId: 'salon-1',
      date: date,
      startTime: start,
      endTime: end,
    );

void main() {
  group('ReservationRules.timeToMinutes', () {
    test('parses HH:mm into minutes after midnight', () {
      expect(ReservationRules.timeToMinutes('08:30'), 510);
      expect(ReservationRules.timeToMinutes('00:00'), 0);
      expect(ReservationRules.timeToMinutes('23:59'), 1439);
    });

    test('rejects malformed values', () {
      expect(ReservationRules.timeToMinutes('8'), isNull);
      expect(ReservationRules.timeToMinutes('24:00'), isNull);
      expect(ReservationRules.timeToMinutes('12:60'), isNull);
      expect(ReservationRules.timeToMinutes(null), isNull);
    });
  });

  group('ReservationRules.timeRangeValid', () {
    test('start must be strictly before end', () {
      expect(ReservationRules.timeRangeValid('08:00', '10:00'), isTrue);
      expect(ReservationRules.timeRangeValid('10:00', '10:00'), isFalse);
      expect(ReservationRules.timeRangeValid('12:00', '10:00'), isFalse);
    });
  });

  group('ReservationRules.overlaps', () {
    test('same slot on the same date overlaps', () {
      final a = _res('2026-03-05', '08:00', '10:00');
      final b = _res('2026-03-05', '09:00', '11:00');
      expect(ReservationRules.overlaps(a, b), isTrue);
    });

    test('adjacent slots do not overlap', () {
      final a = _res('2026-03-05', '08:00', '10:00');
      final b = _res('2026-03-05', '10:00', '12:00');
      expect(ReservationRules.overlaps(a, b), isFalse);
    });

    test('same slot on different dates does not overlap', () {
      final a = _res('2026-03-05', '08:00', '10:00');
      final b = _res('2026-03-06', '08:00', '10:00');
      expect(ReservationRules.overlaps(a, b), isFalse);
    });
  });

  group('ReservationRules invite expiry', () {
    test('expires 25 minutes after the start time', () {
      final expiry = ReservationRules.inviteExpiresAt('2026-03-05', '18:00');
      expect(expiry, DateTime(2026, 3, 5, 18, 25));
    });

    test('isInviteExpired compares against now', () {
      final before = DateTime(2026, 3, 5, 18, 10);
      final after = DateTime(2026, 3, 5, 19, 0);
      expect(
        ReservationRules.isInviteExpired('2026-03-05', '18:00', now: before),
        isFalse,
      );
      expect(
        ReservationRules.isInviteExpired('2026-03-05', '18:00', now: after),
        isTrue,
      );
    });

    test('invalid input counts as expired', () {
      expect(ReservationRules.isInviteExpired('', ''), isTrue);
    });
  });

  group('ReservationRules.maxGuests', () {
    test('is capped at 5 guests', () {
      expect(ReservationRules.maxGuests, 5);
    });
  });
}
