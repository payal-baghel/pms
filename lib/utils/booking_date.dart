/// Booking-date helpers for the PWB/PRR forms.
///
/// The app shows and stores booking dates as `dd-MMM-yyyy HH:mm`
/// (for example `22-Oct-2026 14:46`). Whenever the user types a date by
/// hand it is normalized to that single format, so the Add PWB/PRR page,
/// the Update window, the Scan Data table and the local DB stay consistent.
class BookingDate {
  BookingDate._();

  static const List<String> _months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  /// `DateTime` -> `22-Oct-2026 14:46`.
  static String format(DateTime dt) =>
      "${_two(dt.day)}-${_months[dt.month - 1]}-${dt.year} "
      "${_two(dt.hour)}:${_two(dt.minute)}";

  static String _two(int value) => value.toString().padLeft(2, "0");

  /// Normalizes any understood booking date to the UI format.
  ///
  /// Text that cannot be understood is returned trimmed but unchanged, so an
  /// unusual (but valid) server value is never destroyed.
  static String normalize(String raw) {
    final dt = tryParse(raw);
    return dt == null ? raw.trim() : format(dt);
  }

  /// Parses the formats the PMS server / the user can produce.
  ///
  /// Handles, with or without a time:
  ///  - `22-Oct-2026 14:46`, `22/Oct/2026 2:46 PM`, `22 Oct 2026`
  ///  - `22-10-2026 14:46`, `22.10.2026`
  ///  - `2026-10-22 14:46` (ISO)
  ///  - `19/09/2026/12/53` (the server's slash format)
  static DateTime? tryParse(String raw) {
    final text = raw.trim().replaceAll(RegExp(r"\s+"), " ");
    if (text.isEmpty) return null;

    // "19/09/2026/12/53" -> day/month/year/hour/minute.
    var m = RegExp(
      r"^(\d{1,2})/(\d{1,2})/(\d{4})/(\d{1,2})/(\d{1,2})$",
    ).firstMatch(text);
    if (m != null) {
      return _build(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
      );
    }

    // Day first: "22-Oct-2026 14:46", "22/10/2026", "22 Oct 2026 2:46 PM".
    m = RegExp(
      r"^(\d{1,2})[-/ .]([A-Za-z]{3,}|\d{1,2})[-/ .](\d{4})"
      r"(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?)?$",
    ).firstMatch(text);
    if (m != null) {
      final month = _monthOf(m.group(2)!);
      if (month == null) return null;
      return _withTime(
        m,
        day: int.parse(m.group(1)!),
        month: month,
        year: int.parse(m.group(3)!),
      );
    }

    // Year first: "2026-10-22 14:46".
    m = RegExp(
      r"^(\d{4})[-/ .](\d{1,2})[-/ .](\d{1,2})"
      r"(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?)?$",
    ).firstMatch(text);
    if (m != null) {
      return _withTime(
        m,
        day: int.parse(m.group(3)!),
        month: int.parse(m.group(2)!),
        year: int.parse(m.group(1)!),
      );
    }

    return null;
  }

  static DateTime? _withTime(
    RegExpMatch m, {
    required int day,
    required int month,
    required int year,
  }) {
    var hour = int.tryParse(m.group(4) ?? "") ?? 0;
    final minute = int.tryParse(m.group(5) ?? "") ?? 0;
    final meridiem = (m.group(6) ?? "").toUpperCase();
    if (meridiem == "PM" && hour < 12) hour += 12;
    if (meridiem == "AM" && hour == 12) hour = 0;
    return _build(day, month, year, hour, minute);
  }

  static DateTime? _build(int day, int month, int year, int hour, int minute) {
    if (month < 1 || month > 12) return null;
    if (hour > 23 || minute > 59) return null;
    final dt = DateTime(year, month, day, hour, minute);
    // Rejects impossible dates like 31-Feb (DateTime would roll them over).
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  /// `"Oct"`/`"october"`/`"10"` -> 10; `null` when not a month.
  static int? _monthOf(String token) {
    final t = token.trim().toLowerCase();
    if (t.isEmpty) return null;
    final asInt = int.tryParse(t);
    if (asInt != null) return (asInt >= 1 && asInt <= 12) ? asInt : null;
    if (t.length < 3) return null;
    final prefix = t.substring(0, 3);
    for (var i = 0; i < _months.length; i++) {
      if (_months[i].toLowerCase() == prefix) return i + 1;
    }
    return null;
  }
}
