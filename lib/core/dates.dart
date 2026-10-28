/// Formatting helpers used across bounded contexts (formatting only:
/// business rules stay inside each feature's domain layer).
library;

const _monthNamesEs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const _monthNamesEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Two-digit padded number (e.g. 5 -> "05").
String _pad2(int n) => n.toString().padLeft(2, '0');

class Dates {
  /// Today as `yyyy-MM-dd` in the device timezone.
  static String todayYmd() {
    final now = DateTime.now();
    return '${now.year}-${_pad2(now.month)}-${_pad2(now.day)}';
  }

  /// Current timestamp in local ISO-8601 form.
  static String nowIso() => DateTime.now().toIso8601String();

  /// Parses the first 10 characters of [value] as `yyyy-MM-dd`, or null.
  static DateTime? ymdOrNull(String? value) {
    if (value == null || value.length < 10) return null;
    return DateTime.tryParse(value.substring(0, 10));
  }

  static String addDaysYmd(String value, int days) {
    final date = ymdOrNull(value) ?? DateTime.now();
    final shifted = date.add(Duration(days: days));
    return '${shifted.year}-${_pad2(shifted.month)}-${_pad2(shifted.day)}';
  }

  static int compareYmd(String a, String b) =>
      (ymdOrNull(a)?.millisecondsSinceEpoch ?? 0) -
      (ymdOrNull(b)?.millisecondsSinceEpoch ?? 0);

  /// True when [dueDate] is strictly before today.
  static bool isPastDue(String dueDate) {
    final due = ymdOrNull(dueDate);
    if (due == null) return false;
    return compareYmd(dueDate, todayYmd()) < 0;
  }

  /// "2025-03-05" -> "05 Mar 2025" (ES) / "05 Mar 2025" (EN).
  static String dateLabel(String? ymd, {String lang = 'es'}) {
    final date = ymdOrNull(ymd);
    if (date == null) return ymd ?? '—';
    final names = lang == 'en' ? _monthNamesEn : _monthNamesEs;
    return '${_pad2(date.day)} ${names[date.month - 1]} ${date.year}';
  }

  /// "2025-03-05" -> "Mar 2025" (used as the fee "month" label).
  static String monthYearLabel(String? ymd, {String lang = 'es'}) {
    final date = ymdOrNull(ymd);
    if (date == null) return '';
    final names = lang == 'en' ? _monthNamesEn : _monthNamesEs;
    return '${names[date.month - 1]} ${date.year}';
  }

  /// "14:05" style label for a 24h [hour]:[minute] pair.
  static String timeLabel(int hour, int minute) => '${_pad2(hour)}:${_pad2(minute)}';

  /// ISO timestamp formatted as a local date + time.
  static String dateTimeLabel(String? iso, {String lang = 'es'}) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return iso;
    return '${dateLabel(iso, lang: lang)} · ${_pad2(parsed.hour)}:${_pad2(parsed.minute)}';
  }
}

/// Formats an amount as Peruvian soles, e.g. `S/ 150.00`.
String formatSoles(num amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
  return 'S/ $whole.${parts[1]}';
}
