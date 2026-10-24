/// Shared in-memory session for the current loading operation.
///
/// The Loading screen is the source of truth: whenever the user validates a
/// train, the train no., scale, loading time and vehicle type are stored here.
/// The Scan Data and Add PWB/PRR screens read this session instead of keeping
/// their own hard-coded copy, so every change the user makes on the Loading
/// screen is reflected on the following screens.
library;

/// Mirrors the server's ACT_LOADNO dummy loading number:
///   load_unload_flag + stncode + trainNo + vechType + date
/// e.g. "LNDLS12554FCRSLR280926" (L + NDLS + 12554 + FCRSLR + 280926).
class TrainSession {
  TrainSession._();

  /// "L"; Unloading screens can switch this to "U" later.
  static String loadUnloadFlag = "L";

  static String trainNo = "";
  static String scale = "";
  static String vehicle = "";

  /// Actual loading date/time in the UI format: dd-MMM-yyyy HH:mm.
  static String loadDateTime = "";

  /// Loading station code (login station).
  static String station = "";

  /// Dummy ACT_LOADNO built from the session fields:
  /// flag + station + trainNo + vechType + ddMMyy.
  static String get actLoadNo {
    final flag = loadUnloadFlag.trim().toUpperCase();
    final stn = station.trim().toUpperCase();
    final no = trainNo.trim();
    final veh = vehicle.trim().toUpperCase();
    final ddmyy = _ddmmyy(loadDateTime);
    var result = "$flag$stn$no$veh";
    if (ddmyy.isNotEmpty) result += ddmyy;
    return result;
  }

  /// LOAD_DATE in the backend format: dd/MMM/yyyy HH:mm
  /// (e.g. "28/Sep/2026 17:00"), built from the session's loadDateTime.
  static String get loadDateForApi => _apiDate(loadDateTime);

  /// Same conversion for any other date the UI holds
  /// ("dd-MMM-yyyy HH:mm" -> "dd/MMM/yyyy HH:mm").
  static String apiDate(String uiDateTime) => _apiDate(uiDateTime);

  /// DDMMYY part of the ACT_LOADNO date (e.g. 28/09/2026 -> "280926").
  static String _ddmmyy(String uiDateTime) {
    final dt = _parseUi(uiDateTime);
    if (dt == null) return "";
    return "${dt.day.toString().padLeft(2, '0')}"
        "${dt.month.toString().padLeft(2, '0')}"
        "${dt.year.toString().substring(2)}";
  }

  /// dd-MMM-yyyy HH:mm (UI) -> dd/MMM/yyyy HH:mm (backend).
  static String _apiDate(String uiDateTime) {
    const months = [
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
    final dt = _parseUi(uiDateTime);
    if (dt == null) return uiDateTime.trim();
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${months[dt.month - 1]}/"
        "${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  /// Parses "dd-MMM-yyyy HH:mm" (the format the Loading screen uses).
  static DateTime? _parseUi(String value) {
    const monthIndex = {
      "jan": 1,
      "feb": 2,
      "mar": 3,
      "apr": 4,
      "may": 5,
      "jun": 6,
      "jul": 7,
      "aug": 8,
      "sep": 9,
      "oct": 10,
      "nov": 11,
      "dec": 12,
    };
    final match = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4})\s+(\d{1,2}):(\d{2})",
    ).firstMatch(value.trim());
    if (match == null) return null;
    final month = monthIndex[match.group(2)!.toLowerCase()];
    if (month == null) return null;
    try {
      return DateTime(
        int.parse(match.group(3)!),
        month,
        int.parse(match.group(1)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
      );
    } catch (_) {
      return null;
    }
  }
}