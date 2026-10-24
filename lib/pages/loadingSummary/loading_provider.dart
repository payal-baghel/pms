import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/loading/models/coach_detail.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_condn.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_desc.dart';
import 'package:flutter_application_1/pages/loading/models/platform_master.dart';
import 'package:flutter_application_1/pages/loading/models/railway_al.dart';
import 'package:flutter_application_1/pages/loading/models/wag_type.dart';
import 'package:flutter_application_1/services/loding_api.dart';

class LoadingSummaryProvider extends ChangeNotifier {
  bool _loadingPlatforms = false;
  List<PlatformMaster> _platformMasters = [];
  String _platformError = "";
  Future<void>? _platformLoadFuture;

  bool get isLoadingPlatforms => _loadingPlatforms;
  List<PlatformMaster> get platformMasters => _platformMasters;
  String get platformError => _platformError;

  // Mirror of LoadingProvider.loadWagonTypes(): fetch the platform master list
  // from the webservice, cache it into M_PLATFORM, then read it from the DB.
  // Concurrent calls share the same in-flight future.
  Future<void> loadPlatformMasters() {
    final inflight = _platformLoadFuture;
    if (inflight != null) return inflight;

    final future = _loadPlatformMasters();
    _platformLoadFuture = future;
    return future.whenComplete(() => _platformLoadFuture = null);
  }

  Future<void> _loadPlatformMasters() async {
    if (_loadingPlatforms) return;
    _loadingPlatforms = true;
    _platformError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getPlatformMaster();
      if (result.ok) {
        // Mentor's flow: on success ALWAYS sync M_PLATFORM (delete + insert),
        // even when the server returns an empty list.
        await DatabaseHelper.instance.savePlatformMasters(result.data);
      }
      // Dropdown source: read back from M_PLATFORM.
      final stored = await DatabaseHelper.instance.getPlatformMasters();
      _platformMasters = stored.isNotEmpty ? stored : result.data;
      if (_platformMasters.isEmpty) {
        _platformError = "server returned no data";
      }
    } catch (e) {
      print("PLATFORM-MASTER Load Error: $e");
      _platformError = "Error: $e";
      try {
        _platformMasters = await DatabaseHelper.instance.getPlatformMasters();
      } catch (_) {
        _platformMasters = [];
      }
    }

    _loadingPlatforms = false;
    notifyListeners();
  }

  // ================= Own Railway (M_RLY) =================
  bool _loadingRailways = false;
  List<RailwayAL> _railwayMasters = [];
  String _railwayError = "";
  Future<void>? _railwayLoadFuture;

  bool get isLoadingRailways => _loadingRailways;
  List<RailwayAL> get railwayMasters => _railwayMasters;
  String get railwayError => _railwayError;

  Future<void> loadRailwayMasters() {
    final inflight = _railwayLoadFuture;
    if (inflight != null) return inflight;

    final future = _loadRailwayMasters();
    _railwayLoadFuture = future;
    return future.whenComplete(() => _railwayLoadFuture = null);
  }

  Future<void> _loadRailwayMasters() async {
    if (_loadingRailways) return;
    _loadingRailways = true;
    _railwayError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getRailwayAL();
      if (result.ok) {
        await DatabaseHelper.instance.saveRailwayALs(result.data);
      }
      final stored = await DatabaseHelper.instance.getRailwayALs();
      _railwayMasters = stored.isNotEmpty ? stored : result.data;
      if (_railwayMasters.isEmpty) {
        _railwayError = "server returned no data";
      }
    } catch (e) {
      print("RAILWAY-AL Load Error: $e");
      _railwayError = "Error: $e";
      try {
        _railwayMasters = await DatabaseHelper.instance.getRailwayALs();
      } catch (_) {
        _railwayMasters = [];
      }
    }

    _loadingRailways = false;
    notifyListeners();
  }

  // ================= Coach Type (M_WAGTYPE) =================
  bool _loadingWagTypes = false;
  List<WagType> _wagTypeMasters = [];
  String _wagTypeError = "";
  Future<void>? _wagTypeLoadFuture;

  bool get isLoadingWagTypes => _loadingWagTypes;
  List<WagType> get wagTypeMasters => _wagTypeMasters;
  String get wagTypeError => _wagTypeError;

  Future<void> loadWagTypeMasters() {
    final inflight = _wagTypeLoadFuture;
    if (inflight != null) return inflight;

    final future = _loadWagTypeMasters();
    _wagTypeLoadFuture = future;
    return future.whenComplete(() => _wagTypeLoadFuture = null);
  }

  Future<void> _loadWagTypeMasters() async {
    if (_loadingWagTypes) return;
    _loadingWagTypes = true;
    _wagTypeError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getWagTypeAL();
      if (result.ok) {
        await DatabaseHelper.instance.saveWagTypes(result.data);
      }
      final stored = await DatabaseHelper.instance.getWagTypes();
      _wagTypeMasters = stored.isNotEmpty ? stored : result.data;
      if (_wagTypeMasters.isEmpty) {
        _wagTypeError = "server returned no data";
      }
    } catch (e) {
      print("WAGTYPE-AL Load Error: $e");
      _wagTypeError = "Error: $e";
      try {
        _wagTypeMasters = await DatabaseHelper.instance.getWagTypes();
      } catch (_) {
        _wagTypeMasters = [];
      }
    }

    _loadingWagTypes = false;
    notifyListeners();
  }

  // ================= Pkg Condn (M_PKGCONDN) =================
  bool _loadingPkgCondns = false;
  List<PkgCondn> _pkgCondnMasters = [];
  String _pkgCondnError = "";
  Future<void>? _pkgCondnLoadFuture;

  bool get isLoadingPkgCondns => _loadingPkgCondns;
  List<PkgCondn> get pkgCondnMasters => _pkgCondnMasters;
  String get pkgCondnError => _pkgCondnError;

  Future<void> loadPkgCondnMasters() {
    final inflight = _pkgCondnLoadFuture;
    if (inflight != null) return inflight;

    final future = _loadPkgCondnMasters();
    _pkgCondnLoadFuture = future;
    return future.whenComplete(() => _pkgCondnLoadFuture = null);
  }

  Future<void> _loadPkgCondnMasters() async {
    if (_loadingPkgCondns) return;
    _loadingPkgCondns = true;
    _pkgCondnError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getPkgCondnMaster();
      if (result.ok) {
        // Mentor's flow: on success ALWAYS sync M_PKGCONDN (delete + insert),
        // even when the server returns an empty list.
        await DatabaseHelper.instance.savePkgCondns(result.data);
      }
      // Dropdown source: read back from M_PKGCONDN.
      final stored = await DatabaseHelper.instance.getPkgCondns();
      _pkgCondnMasters = stored.isNotEmpty ? stored : result.data;
      if (_pkgCondnMasters.isEmpty) {
        _pkgCondnError = "server returned no data";
      }
    } catch (e) {
      print("PKG-CONDN-MASTER Load Error: $e");
      _pkgCondnError = "Error: $e";
      try {
        _pkgCondnMasters = await DatabaseHelper.instance.getPkgCondns();
      } catch (_) {
        _pkgCondnMasters = [];
      }
    }

    _loadingPkgCondns = false;
    notifyListeners();
  }

  // ================= Pkg Desc (M_PKG_DESC) =================
  bool _loadingPkgDescs = false;
  List<PkgDesc> _pkgDescMasters = [];
  String _pkgDescError = "";
  Future<void>? _pkgDescLoadFuture;

  bool get isLoadingPkgDescs => _loadingPkgDescs;
  List<PkgDesc> get pkgDescMasters => _pkgDescMasters;
  String get pkgDescError => _pkgDescError;

  Future<void> loadPkgDescMasters() {
    final inflight = _pkgDescLoadFuture;
    if (inflight != null) return inflight;

    final future = _loadPkgDescMasters();
    _pkgDescLoadFuture = future;
    return future.whenComplete(() => _pkgDescLoadFuture = null);
  }

  Future<void> _loadPkgDescMasters() async {
    if (_loadingPkgDescs) return;
    _loadingPkgDescs = true;
    _pkgDescError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getPkgDescMaster();
      if (result.ok) {
        // Mentor's flow: on success ALWAYS sync M_PKG_DESC (delete + insert),
        // even when the server returns an empty list.
        await DatabaseHelper.instance.savePkgDescs(result.data);
      }
      // Dropdown source: read back from M_PKG_DESC.
      final stored = await DatabaseHelper.instance.getPkgDescs();
      _pkgDescMasters = stored.isNotEmpty ? stored : result.data;
      if (_pkgDescMasters.isEmpty) {
        _pkgDescError = "server returned no data";
      }
    } catch (e) {
      print("PKG-DESC-MASTER Load Error: $e");
      _pkgDescError = "Error: $e";
      try {
        _pkgDescMasters = await DatabaseHelper.instance.getPkgDescs();
      } catch (_) {
        _pkgDescMasters = [];
      }
    }

    _loadingPkgDescs = false;
    notifyListeners();
  }

  // ================= Wagon-Rly-No. (train consist) =================
  bool _loadingConsist = false;
  List<CoachDetail> _coachDetails = [];
  String _consistError = "";
  String _consistTrainNo = "";
  String _consistForDate = "";

  bool get isLoadingConsist => _loadingConsist;
  List<CoachDetail> get coachDetails => _coachDetails;
  String get consistError => _consistError;

  /// Rebuilds the option list for the current train + schedule date.
  /// Never appends: the mentor's list is cleared and rebuilt every load.
  Future<void> loadCoachDetails(String trainNo, String scheduleDate) async {
    if (trainNo.trim().isEmpty) {
      _coachDetails = [];
      _consistError = "train number is empty";
      notifyListeners();
      return;
    }

    _loadingConsist = true;
    _consistError = "";
    notifyListeners();

    try {
      final result = await LoadingService.getTrainConsist(
        trainNo: trainNo.trim(),
        scheduleDate: scheduleDate.trim(),
      );
      _coachDetails = result.data;
      _consistTrainNo = trainNo.trim();
      _consistForDate = scheduleDate.trim();
      if (!result.ok) {
        // ok=false means the HTTP call itself failed (network/DNS/timeout) —
        // surface that, not a misleading "no coach found".
        _consistError =
            "could not fetch: ${result.error.isNotEmpty ? result.error : "HTTP/parse error"}";
      } else if (_coachDetails.isEmpty) {
        // Server answered 200 but with no coaches for this train/date. Show
        // the server's own text (if any) so the reason is visible.
        _consistError = result.message.isNotEmpty
            ? "no coach found for this train (${result.message})"
            : "no coach found for this train";
      }
    } catch (e) {
      print("TRAIN-CONSIST Load Error: $e");
      _coachDetails = [];
      _consistError = "Error: $e";
    }

    _loadingConsist = false;
    notifyListeners();
  }

  /// True when the cached consist belongs to [trainNo] + [scheduleDate].
  bool isConsistFor(String trainNo, String scheduleDate) {
    return _coachDetails.isNotEmpty &&
        _consistTrainNo == trainNo.trim() &&
        _consistForDate == scheduleDate.trim();
  }

  // ================= Seal to Station (M_TRNDTLS) =================
  bool _loadingSealStations = false;
  List<SealStation> _sealStations = [];
  String _sealStationsError = "";

  bool get isLoadingSealStations => _loadingSealStations;
  List<SealStation> get sealStations => _sealStations;
  String get sealStationsError => _sealStationsError;

  /// Reads the train's route stops from M_TRNDTLS. The dropdown shows
  /// STNCODE-DISTANCE-KM (e.g. "NDLS-0 KM", "ALJN-138.55 KM"), ordered by
  /// route. When [fromStation] (the user's login station) is given, only the
  /// login station and the stops after it on the route are shown.
  Future<void> loadSealStations(String trainNo, {String? fromStation}) async {
    if (trainNo.trim().isEmpty) {
      _sealStations = [];
      _sealStationsError = "train number is empty";
      notifyListeners();
      return;
    }

    _loadingSealStations = true;
    _sealStationsError = "";
    notifyListeners();

    try {
      final rows = await DatabaseHelper.instance.getTrnStops(trainNo.trim());
      List<SealStation> stops = rows.map(SealStation.fromMap).toList();

      // Only keep the stops AFTER the login station on the route. The login
      // station itself is not offered as a seal destination.
      final login = (fromStation ?? "").trim().toUpperCase();
      if (login.isNotEmpty) {
        final loginIndex = stops.indexWhere(
          (s) => s.stnCode.toUpperCase() == login,
        );
        if (loginIndex >= 0) {
          stops = stops.sublist(loginIndex + 1);
        }
      }

      _sealStations = stops;
      if (_sealStations.isEmpty) {
        _sealStationsError = "no stops cached for this train";
      }
    } catch (e) {
      print("SEAL-STATION Load Error: $e");
      _sealStations = [];
      _sealStationsError = "Error: $e";
    }

    _loadingSealStations = false;
    notifyListeners();
  }
}

/// One M_TRNDTLS row shown in the "Seal to Station" dropdown as
/// `STNCODE-DISTANCE`.
class SealStation {
  final String stnCode;
  final String stnDiv;
  final double distance;
  final int dayCount;
  final int arrTime;
  final int depTime;
  final String owningRly;

  const SealStation({
    required this.stnCode,
    required this.stnDiv,
    required this.distance,
    required this.dayCount,
    required this.arrTime,
    required this.depTime,
    required this.owningRly,
  });

  factory SealStation.fromMap(Map<String, Object?> map) {
    return SealStation(
      stnCode: (map['STNCODE'] ?? "").toString().trim(),
      stnDiv: (map['STN_CD'] ?? "").toString().trim(),
      distance:
          num.tryParse((map['DISTANCE'] ?? "0").toString())?.toDouble() ?? 0,
      dayCount: int.tryParse((map['DAYCOUNT'] ?? "0").toString()) ?? 0,
      arrTime: int.tryParse((map['ARRTIME'] ?? "0").toString()) ?? 0,
      depTime: int.tryParse((map['DEPTIME'] ?? "0").toString()) ?? 0,
      owningRly: (map['OWNNG_RLY'] ?? "").toString().trim(),
    );
  }

  /// "NDLS-0 KM" / "ALJN-156.73 KM" — the value shown in the dropdown.
  String get label {
    final dist = distance == distance.roundToDouble()
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(2);
    return "$stnCode-$dist KM";
  }
}
