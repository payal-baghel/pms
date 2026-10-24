import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/loading/loading_db_helper.dart';
import 'package:flutter_application_1/pages/loading/models/icms_response.dart';
import 'package:flutter_application_1/pages/loading/models/summarydetails.dart';
import 'package:flutter_application_1/pages/loading/models/train_load_validation.dart';
import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/services/loding_api.dart' as loding_api;

class ValidateResult {
  final bool ok;
  final String title;
  final String message;
  final String scheduled;
  final String actual;

  // Server's Decription: empty -> proceed to next page,
  // otherwise the text to show as an alert (and stay on this page).
  final String decription;

  const ValidateResult({
    this.ok = true,
    this.title = "",
    this.message = "",
    this.scheduled = "",
    this.actual = "",
    this.decription = "",
  });
}

class LoadingProvider extends ChangeNotifier {
  bool _loadingTypes = false;
  List<WagonMaster> _wagonTypes = [];
  final List<String> _selectedWagonTypes = [];
  bool _trainValidating = false;
  ValidateTrainLoadResponse? _lastTrainValidation;
  ValidateResult? _lastValidateResult;
  bool _ntesLoading = false;
  IcmsResponse? _ntesDetail;
  TrainDetails? _trndtls;
  int _ntesSeq = 0;
  String _scale = "";

  bool get isLoadingTypes => _loadingTypes;
  List<WagonMaster> get wagonTypes => _wagonTypes;
  List<String> get selectedWagonTypes => _selectedWagonTypes;
  bool get isTrainValidating => _trainValidating;
  ValidateTrainLoadResponse? get lastTrainValidation => _lastTrainValidation;

  /// Last validateTrain outcome. Carries the `scheduled` date, which the
  /// Loading Summary page needs (NTES data is not always available there).
  ValidateResult? get lastValidateResult => _lastValidateResult;

  // ---------- Schedule date shared with the next screens ----------
  String _currentScheduledDate = "";

  /// The Scheduled Dep. currently shown on the Loading screen. ICMS/NTES data
  /// is often unavailable, so the Loading page hands its own date over here and
  /// the Loading Summary page reads it for GET_TRAIN_CONSIST.
  String get currentScheduledDate => _currentScheduledDate;

  void setCurrentScheduledDate(String value) {
    final trimmed = value.trim();
    if (trimmed == _currentScheduledDate) return;
    _currentScheduledDate = trimmed;
    notifyListeners();
  }

  bool get isNtesLoading => _ntesLoading;
  IcmsResponse? get ntesDetail => _ntesDetail;

  // jDate: Scheduled Dep. — Platform != null ? STD : PTT_STD
  String get fetchedJDate {
    if (_ntesDetail == null) return "";
    final raw = _ntesDetail!.platform != null
        ? _ntesDetail!.std
        : _ntesDetail!.pttStd;
    return _icmDateTime(raw);
  }

  // aDate: Actual Dep. — ETD/ATD, only if the train has already departed.
  String get fetchedADate {
    if (_ntesDetail == null || !_ntesDetail!.hasDeparted) return "";
    final raw = _ntesDetail!.platform != null
        ? _ntesDetail!.etd
        : _ntesDetail!.atd;
    return _icmDateTime(raw);
  }

  TrainDetails? get trndtls => _trndtls;

  /// Scale code from the getTrndtls payload (e.g. "R"), used by Scan Data.
  String get scale => _scale;

  // SETTER for the raw trndtls cache to store the scale.
  void _setScaleFromMap(Map<String, dynamic> map) {
    final raw = map['scaleCode'] ?? map['ltscalecode'] ?? map['SCALECODE'];
    _scale = (raw ?? "").toString().trim();
  }

  // TEMP DEBUG: last raw API responses (for on-screen display)
  String _rawIcms = "";
  String _rawTrndtls = "";
  String get rawIcmsDebug => _rawIcms;
  String get rawTrndtlsDebug => _rawTrndtls;

  // Route check (entry-card preview + shared helper): the loading station
  // must be on the train route and must NOT be the last stop (destination).
  // Missing data (trndtls null) is never a block.
  bool _routeAllowsStation(TrainDetails details, String station) {
    final stn = station.trim().toUpperCase();
    final stops = details.trnstpg
        .map((s) => s.stnCode?.trim().toUpperCase())
        .whereType<String>()
        .toList();
    if (stops.isEmpty) return true;
    return stops.contains(stn) && stops.last != stn;
  }

  // Mentor's flow (entry-card preview):
  //  STEP 1: loop i=0..stops.length — is the login station in the list?
  //  STEP 2: if found — last stop (destination) must be different.
  // Returns: (valid, title, message) — the preview shown to the user.
  (bool, String, String) get trainRouteVerdict {
    final details = _trndtls;
    if (details == null || details.trnstpg.isEmpty) {
      return (
        true,
        "",
        "",
      ); // no data — entry card handles the missing-data path
    }

    final stn = (LoginService.loggedInStation ?? "NDLS").trim().toUpperCase();
    final stops = details.trnstpg
        .map((s) => s.stnCode?.trim().toUpperCase())
        .whereType<String>()
        .toList();
    if (stops.isEmpty) return (true, "", "");

    // STEP 1: find the station with a loop
    var found = false;
    for (var i = 0; i < stops.length; i++) {
      if (stops[i] == stn) {
        found = true;
        break;
      }
    }
    if (!found) {
      return (
        false,
        "Invalid Train",
        "Loading station $stn is not on the route of this train.",
      );
    }

    // STEP 2: last stop (destination) must not be the loading station
    if (stops.last == stn) {
      return (
        false,
        "Invalid Train",
        "Loading station $stn is the last station (destination) of this "
            "train. Loading is not allowed at the destination.",
      );
    }

    return (
      true,
      "Valid Train",
      "Loading station $stn is on the train route and is not the "
          "destination. Loading is allowed.",
    );
  }

  // Mentor's approach (entry-time preview): the login station must be in
  // the train station list (trnstpg) and must NOT be the last stop
  // (destination).
  bool get isStationInRoute {
    final details = _trndtls;
    if (details == null || details.trnstpg.isEmpty) return false;
    return _routeAllowsStation(details, LoginService.loggedInStation ?? "NDLS");
  }

  String get selectedWagonTypesText => _selectedWagonTypes.join(", ");

  Future<void> loadWagonTypes() async {
    _loadingTypes = true;
    notifyListeners();

    final types = await loding_api.LoadingService.getWagonMaster();

    List<WagonMaster> toUse;
    if (types.isNotEmpty) {
      await LoadingDbHelper.instance.saveWagonMasters(types);
      toUse = await LoadingDbHelper.instance.getWagonMasters();
    } else {
      toUse = await LoadingDbHelper.instance.getWagonMasters();
    }

    _wagonTypes = toUse;
    _loadingTypes = false;
    notifyListeners();
  }

  void setSelectedWagonTypes(List<String> values) {
    _selectedWagonTypes
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void addWagonType(String value) {
    if (!_selectedWagonTypes.contains(value)) {
      _selectedWagonTypes.add(value);
      notifyListeners();
    }
  }

  void removeWagonType(String value) {
    if (_selectedWagonTypes.remove(value)) {
      notifyListeners();
    }
  }

  void clearForm() {
    _selectedWagonTypes.clear();
    _ntesDetail = null;
    _trndtls = null;
    _ntesLoading = false;
    _ntesSeq++;
    _scale = "";
    notifyListeners();
  }

  Future<void> fetchNtesDetail(String trainNo, {String? tdate}) async {
    final trimmed = trainNo.trim();

    // Fewer than 5 digits: not a valid train number, hide the card.
    if (trimmed.length < 5) {
      _ntesSeq++;
      if (_ntesDetail != null || _ntesLoading) {
        _ntesDetail = null;
        _ntesLoading = false;
        notifyListeners();
      }
      return;
    }

    final seq = ++_ntesSeq;
    _ntesLoading = true;
    _rawIcms = "";
    _rawTrndtls = "";
    notifyListeners();

    try {
      final userId = LoginService.loggedInUserId ?? "AT";
      final password = LoginService.loggedInPassword ?? "AT";
      final station = LoginService.loggedInStation ?? "NDLS";

      // Parallel: NTES (details) + getTrnDtls (route check).
      // Send stnCode as BLANK — same as the mentor's Postman hit (stnCode ""),
      // otherwise the server returns no route/data for special trains (02420).
      // tdate: use the user-selected journey date when available.
      final results = await Future.wait([
        loding_api.LoadingService.getIcmsData(
          trainNo: trimmed,
          jStation: station,
          jDate: _juourneyDateIcms(),
          userId: userId,
          password: password,
          onRaw: (raw) => _rawIcms = raw,
        ),
        loding_api.LoadingService.getTrndtls(
          trainNo: trimmed,
          tdate: tdate ?? _trainDateTrndtls(),
          onRaw: (raw) => _rawTrndtls = raw,
        ),
      ]);

      if (seq != _ntesSeq || !_ntesLoading)
        return; // request was cancelled/cleared

      _ntesDetail = results[0] as IcmsResponse;
      _trndtls = results[1] as TrainDetails?;
    } catch (e) {
      print("NTES detail error: $e");
      if (seq == _ntesSeq && _ntesLoading) {
        _ntesDetail = null;
        _trndtls = null;
      }
    }

    _ntesLoading = false;
    notifyListeners();
  }

  Future<ValidateResult> validateTrain(
    String trainNo, {
    String scheduledDep = "",
  }) async {
    final trimmed = trainNo.trim();
    if (trimmed.isEmpty) return const ValidateResult(ok: false);

    _trainValidating = true;
    notifyListeners();

    final station = LoginService.loggedInStation ?? "NDLS";
    final schldDt = _normalizeSchldDt(scheduledDep);

    final validation = await loding_api.LoadingService.validateTrainLoad(
      trainNo: trimmed,
      stnCode: station,
      vehicleNo: "",
      schldDt: schldDt,
      wagonOwnRly: "",
      vclType: _selectedWagonTypes.join(","),
    );

    _lastTrainValidation = validation;
    _trainValidating = false;
    notifyListeners();

    if (validation == null) {
      return const ValidateResult(
        ok: false,
        title: "Validation Failed",
        message:
            "No response received from the server.\n"
            "Please check the network / server connection.",
      );
    }

    if (!validation.isValid) {
      return ValidateResult(
        ok: false,
        title: "Invalid Journey input (Train/Station/Date) !!!",
        message: validation.message.isNotEmpty
            ? validation.message
            : "The entered train / station / date combination is not valid.",
      );
    }

    // Route check — for-loop over ALL stops that come inside the
    // validateTrainLoad response (Postman returns the same route):
    //  - the loading station must appear among the stops  (stopage mila -> valid)
    //  - the loading station must NOT be the last stop    (destination)
    final routeStation = station.trim().toUpperCase();
    final routeStops = validation.trnstpg
        .map((s) => s.stnCode?.trim().toUpperCase())
        .whereType<String>()
        .toList();

    if (routeStops.isNotEmpty) {
      var found = false;
      for (var i = 0; i < routeStops.length; i++) {
        if (routeStops[i] == routeStation) {
          found = true;
          break;
        }
      }
      if (!found) {
        return ValidateResult(
          ok: false,
          title: "Incorrect loading",
          message:
              "Loading station $station is not on the route of this train.",
        );
      }
      if (routeStops.last == routeStation) {
        return const ValidateResult(
          ok: false,
          title: "Incorrect loading",
          message: "Loading is not allowed at the last station (destination).",
        );
      }
    }

    // Background: auto-fill Scheduled/Actual dates from ICMS (best-effort)
    var sched = "";
    var actual = "";
    try {
      final userId = LoginService.loggedInUserId ?? "AT";
      final password = LoginService.loggedInPassword ?? "AT";
      final icms = await loding_api.LoadingService.getIcmsData(
        trainNo: trimmed,
        jStation: station,
        jDate: _juourneyDateIcms(),
        userId: userId,
        password: password,
      );
      if (icms.isValid) {
        sched = _icmDateTime(icms.std);
        actual = _icmDateTime(icms.etd);
      }

      loding_api.LoadingService.getTrndtls(
        trainNo: trimmed,
        tdate: _trainDateTrndtls(),
        onRaw: _cacheTrndtls,
      );
    } catch (e) {
      print("Background ICMS fill error: $e");
    }

    final via = validation.viastrn.trim();
    final type = validation.trainType.trim();
    final result = ValidateResult(
      ok: true,
      title: "Train Valid",
      decription: validation.decription,
      message:
          "Data Found !!! Train $trimmed"
          "${type.isNotEmpty ? " (Type: $type)" : ""} — loading allowed from $station."
          "${via.isNotEmpty ? "\nVia: $via" : ""}",
      scheduled: sched,
      actual: actual,
    );
    _lastValidateResult = result;
    return result;
  }

  // SCHLD_DT backend format: dd/MMM/yyyy HH:mm (e.g. 19/Sep/2026 21:02).
  // The UI date picker gives: dd/MMM/yyyy HH:mm -> convert, else today's time.
  String _normalizeSchldDt(String input) {
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
    const monthIndex = {
      "JAN": 1,
      "FEB": 2,
      "MAR": 3,
      "APR": 4,
      "MAY": 5,
      "JUN": 6,
      "JUL": 7,
      "AUG": 8,
      "SEP": 9,
      "OCT": 10,
      "NOV": 11,
      "DEC": 12,
    };

    // Field format (NTES auto-fill): dd-MMM-yyyy HH:mm -> dd/MMM/yyyy HH:mm
    // e.g. "18-Sep-2026 17:30" -> "18/Sep/2026 17:30"
    final monthNameMatch = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4})\s+(\d{1,2}):(\d{2})",
    ).firstMatch(input.trim());

    if (monthNameMatch != null) {
      final day = int.parse(monthNameMatch.group(1)!);
      final mon = monthNameMatch.group(2)!;
      final month = monthIndex[mon.toUpperCase()];
      if (day >= 1 && day <= 31 && month != null) {
        return "${day.toString().padLeft(2, '0')}/"
            "$mon/"
            "${monthNameMatch.group(3)} "
            "${monthNameMatch.group(4)!.padLeft(2, '0')}:"
            "${monthNameMatch.group(5)}";
      }
    }

    final match = RegExp(
      r"^(\d{1,2})[/-](\d{1,2})[/-](\d{4})\s+(\d{1,2}):(\d{2})",
    ).firstMatch(input.trim());

    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hh = match.group(4)!.padLeft(2, '0');
      final mm = match.group(5)!;

      if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        return "${day.toString().padLeft(2, '0')}/"
            "${months[month - 1]}/"
            "$year $hh:$mm";
      }
    }

    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/"
        "${months[now.month - 1]}/"
        "${now.year} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }

  String _juourneyDateIcms() {
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
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}";
  }

  String _trainDateTrndtls() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  DateTime? _parseIcmDateTime(String value) {
    final match = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4}) (\d{1,2}):(\d{2})(?::(\d{2}))?$",
    ).firstMatch(value);
    if (match == null) return null;

    const months = {
      "JAN": 1,
      "FEB": 2,
      "MAR": 3,
      "APR": 4,
      "MAY": 5,
      "JUN": 6,
      "JUL": 7,
      "AUG": 8,
      "SEP": 9,
      "OCT": 10,
      "NOV": 11,
      "DEC": 12,
    };
    final month = months[match.group(2)!.toUpperCase()];
    if (month == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      match.group(6) != null ? int.parse(match.group(6)!) : 0,
    );
  }

  String _formatIcmDateTime(DateTime dt) {
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
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year} $hh:$mm";
  }

  String _icmDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return "";

    final value = raw.trim();
    DateTime? parsed = DateTime.tryParse(value);

    if (parsed == null) {
      parsed = _parseIcmDateTime(value);
    }

    if (parsed == null) return "";

    return _formatIcmDateTime(parsed);
  }

  /// Called with the raw getTrndtls response body. Parses it and stores the
  /// train master (M_TRAIN) plus every route stop (M_TRNDTLS) so the Loading
  /// Summary screen can build the "Seal to Station" dropdown from the DB.
  void _cacheTrndtls(String raw) {
    try {
      if (raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final map = Map<String, dynamic>.from(decoded);
      final trainNo = (map['trainNo'] ?? "").toString().trim();
      if (trainNo.isEmpty) return;

      _setScaleFromMap(map);

      // ---- M_TRAIN: one row from the top-level fields ----
      final stopsRaw = map['trnstpg'];
      final stops = (stopsRaw is List)
          ? stopsRaw
                .whereType<Map>()
                .map((e) => TrainStop.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const <TrainStop>[];

      final train = <String, Object?>{
        'TRAIN_NO': trainNo,
        'TRAIN_NAME': map['trainName'],
        'TRAIN_TYPE': map['trainType'] ?? '',
        'TRAIN_DIRECTION': map['trainDrctn'],
        'TRAIN_GAUGE': map['guage'] ?? map['gauge'] ?? 'BG',
        'OWNNG_RLY': map['owningRly'],
        'PM_RLY': map['pmrly'],
        'TRAIN_VER': map['train_Ver'] ?? 1,
        'LTSCALECODE': map['ltscalecode'] ?? '',
        'SCALECODE': map['scaleCode'],
        'VALIDITY': map['validity'],
        'MON_FLAG': map['monFlag'],
        'TUE_FLAG': map['tueFlag'],
        'WED_FLAG': map['wedFlag'],
        'THU_FLAG': map['thuFlag'],
        'FRI_FLAG': map['friFlag'],
        'SAT_FLAG': map['satFlag'],
        'SUN_FLAG': map['sunFlag'],
        'PARCEL_BKNG_ALLWD': map['prclBkngAllwd'],
        'LUGG_BKNG_ALLWD': map['luggBkngAllwd'],
        'MAX_LOAD': map['maxload'],
        'CURRENT_LOAD': map['currentload'],
        'VIA_ROUTE': map['viastn'],
        'FCFSLRSTATUS': map['fcfslrstatus'],
        'FCRSLRSTATUS': map['fcrslrstatus'],
        'RCFSLRSTATUS': map['rcfslrstatus'],
        'FSLRTYPE': map['fslrtype'],
        'MSLRTYPE': map['mslrtype'],
        'RSLRTYPE': map['rslrtype'],
        'VALID_FROM': map['trnValidFrom'],
        'VALID_TO': map['trnValidTo'],
        'SYSTEM_DT': map['system_DT'],
        'FCFSLRCAP': map['fcfslrcapacity'],
      };

      DatabaseHelper.instance.saveTrainMaster(train);

      // ---- M_TRNDTLS: one row per stop ----
      if (stops.isNotEmpty) {
        DatabaseHelper.instance.saveTrnStops(trainNo, stops);
      }

      print(
        "TRNDTLS CACHED -> M_TRAIN: $trainNo | M_TRNDTLS: ${stops.length} stops",
      );
    } catch (e) {
      print("TRNDTLS cache error: $e");
    }
  }
}
