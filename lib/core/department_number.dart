/// Department number encodes floor + unit: last 2 digits = unit, leading
/// digits = floor. Examples: 304 -> floor 3 unit 04, 1204 -> floor 12.
///
/// Mirrors `DepartmentNumber.kt` in the admin (Compose) app so both apps
/// derive the same floor from the same department number.
class DepartmentNumber {
  static final RegExp _pattern = RegExp(r'^\d{3,4}$');

  /// Keeps only the digits of [value], or null when empty.
  static String? normalize(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  static bool isValid(String? value) => parse(value) != null;

  /// Returns `department` + derived `floor`, or null when malformed.
  static ({String department, String floor})? parse(String? value) {
    final digits = normalize(value);
    if (digits == null || !_pattern.hasMatch(digits)) return null;
    final floorPart = int.tryParse(digits.substring(0, digits.length - 2));
    if (floorPart == null || floorPart <= 0) return null;
    return (department: digits, floor: floorPart.toString());
  }
}
