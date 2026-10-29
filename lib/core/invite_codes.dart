import 'api_config.dart';

/// Invitation codes are "304-k7m2" (department + random suffix; legacy codes
/// are plain departments like "304"), but admins share a whole message. These
/// helpers pull the real code out of whatever the resident pastes.
class InviteCodes {
  static final RegExp _labeled = RegExp(
    r'c[óo]digo(?:\s+de\s+invitaci[óo]n)?\s*[:#-]?\s*([A-Za-z0-9][A-Za-z0-9\-]{0,19})',
    caseSensitive: false,
  );

  static final RegExp _department = RegExp(
    r'(?:dept(?:o|artmento)?|departamento)\.?\s*([A-Za-z0-9][A-Za-z0-9\-]{0,19})',
    caseSensitive: false,
  );

  static final RegExp _digits = RegExp(r'\d{3,6}');
  static final RegExp _auto = RegExp(r'^\d{3,6}(?:-[A-Za-z0-9]{2,8})?$');

  /// True when the pasted value looks like a shared message rather than a code.
  static bool looksLikeMessage(String text) =>
      text.length > 12 ||
      text.contains('\n') ||
      text.contains('\r') ||
      _labeled.hasMatch(text) ||
      _department.hasMatch(text);

  /// Returns the code found in [raw], or null when nothing code-like is present.
  static String? extract(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final labeled = _labeled.firstMatch(text);
    if (labeled != null) return labeled.group(1);

    final department = _department.firstMatch(text);
    if (department != null) return department.group(1);

    if (!text.contains(RegExp(r'\s'))) return text;

    final digits = _digits.firstMatch(text);
    return digits?.group(0);
  }

  /// Codes worth searching automatically while the user types.
  static bool canAutoSearch(String code) => _auto.hasMatch(code);

  /// Department number of a code ("201-fewx" → "201"); legacy codes are
  /// already the plain department ("304" → "304").
  static String departmentOf(String? code) {
    final clean = (code ?? '').trim();
    if (clean.isEmpty) return '—';
    return clean.split('-').first;
  }
}

/// Builds the absolute URL shared with guests.
///
/// While the hosted web app has no domain, the link points to the backend's
/// public guest-invite endpoint (anonymous
/// `GET /reservations?guestInviteToken=...`), so scanning the QR always opens
/// the reservation details. Set [webOrigin] once the SPA is deployed and the
/// link switches to its `/invite/<token>` page automatically.
class GuestInviteLink {
  /// Origin of the hosted BuildingFex web app (no trailing slash).
  static const String webOrigin = '';

  static String build(String token) {
    final clean = token.trim();
    if (clean.isEmpty) return '';
    final encoded = Uri.encodeComponent(clean);
    final origin = webOrigin.trim();
    if (origin.isNotEmpty) {
      return '${origin.replaceAll(RegExp(r'/+$'), '')}/invite/$encoded';
    }
    return '${ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/reservations?guestInviteToken=$encoded';
  }
}
