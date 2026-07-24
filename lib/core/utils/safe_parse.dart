/// Small helpers for defensively parsing API JSON (backend fields are
/// sometimes null/missing depending on content type).
class SafeParse {
  SafeParse._();

  static String string(dynamic value, [String fallback = '']) =>
      value == null ? fallback : value.toString();

  static int intVal(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool boolVal(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    return value.toString() == 'true';
  }

  static DateTime? dateVal(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> stringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
