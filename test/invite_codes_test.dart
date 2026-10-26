import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_residente/core/invite_codes.dart';

void main() {
  group('InviteCodes.extract', () {
    test('returns a bare code unchanged', () {
      expect(InviteCodes.extract('304-k7m2'), '304-k7m2');
    });

    test('extracts the code from a labeled message', () {
      expect(
        InviteCodes.extract('Código de invitación: 304-k7m2'),
        '304-k7m2',
      );
    });

    test('extracts a legacy plain department code', () {
      expect(InviteCodes.extract('304'), '304');
    });

    test('returns null for empty input', () {
      expect(InviteCodes.extract('   '), isNull);
    });
  });

  group('InviteCodes.looksLikeMessage', () {
    test('short bare codes are not messages', () {
      expect(InviteCodes.looksLikeMessage('304-k7m2'), isFalse);
    });

    test('multi-line text is a message', () {
      expect(InviteCodes.looksLikeMessage('hola\n304'), isTrue);
    });
  });

  group('InviteCodes.canAutoSearch', () {
    test('accepts complete department-suffix codes', () {
      expect(InviteCodes.canAutoSearch('304-k7m2'), isTrue);
    });

    test('rejects partial input', () {
      expect(InviteCodes.canAutoSearch('30'), isFalse);
    });
  });

  group('GuestInviteLink.build', () {
    test('points at the backend guest endpoint when no web origin is set', () {
      final link = GuestInviteLink.build('invite-abc');
      expect(link, contains('guestInviteToken=invite-abc'));
    });

    test('returns empty for a blank token', () {
      expect(GuestInviteLink.build('  '), '');
    });
  });
}
