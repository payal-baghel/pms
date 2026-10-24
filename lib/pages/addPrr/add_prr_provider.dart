import 'package:flutter/widgets.dart';

import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/addPrr/models/pwb_load_search_result.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_condn.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_desc.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/services/prr_api.dart';
import 'package:flutter_application_1/services/train_session.dart';
import 'package:flutter_application_1/utils/booking_date.dart';
import 'package:flutter_application_1/utils/booking_date.dart';
import 'package:flutter_application_1/utils/booking_date.dart';

/// ViewModel (MVVM) for the "Add PWB/PRR" screen.
/// GUI-only: static/mock values, no API/backend/database logic.
class AddPrrProvider extends ChangeNotifier {
  AddPrrProvider() {
    // The three SEARCH fields are the source of truth; whatever is typed
    // there is mirrored into the matching fields below the SEARCH button so
    // the user never has to type the same value twice.
    prrNoController.addListener(_syncSearchToForm);
    srcStnCodeController.addListener(_syncSearchToForm);
    destStnCodeController.addListener(_syncSearchToForm);

    // Pkg Condn dropdown source: M_PKGCONDN (synced after login).
    loadPkgCondnsFromDb();
    // Pkg Desc dropdown source: M_PKG_DESC (synced after login).
    loadPkgDescsFromDb();
  }

  // ---------- Mock/static values (UI display only) ----------
  String bookingType = "PWB";

  // ---------- Static dropdown option lists (manual selection) ----------
  static const List<String> itemTypes = ["S", "M", "N", "O", "F"];
  static const List<String> bookingTypes = ["PWB", "VPB", "LT"];

  /// Item Type options valid for a given PWB/PRR No. A 10-digit (or longer)
  /// number is a PWB (SYSTEM) booking, so MEMO ("M") must not be selectable.
  static List<String> itemTypesForPrr(String prr) {
    if (prr.trim().length >= 10) {
      return itemTypes.where((t) => t != "M").toList();
    }
    return itemTypes;
  }

  /// Display label for each Item Type code (S -> SYSTEM, M -> MEMO, etc).
  static String itemTypeLabel(String code) =>
      const {
        "S": "SYSTEM",
        "M": "MEMO",
        "N": "NIL",
        "O": "OUTAGENCY",
        "F": "FSLA",
      }[code] ??
      code;
  // ---------- Pkg Desc master (M_PKG_DESC, synced after login) ----------
  List<PkgDesc> _pkgDescMasters = [];

  /// The text values (PKG_DESC) for the Pkg Desc dropdown, from M_PKG_DESC.
  List<String> get pkgDescList => _pkgDescMasters.map((p) => p.pkgDesc).toList();

  /// The PKG_DESC text is shown as-is in the dropdown.
  String pkgDescLabel(String code) => code;

  /// Reads the Pkg Desc master list cached in the local DB.
  /// Called after login sync + at provider creation (offline fallback).
  Future<void> loadPkgDescsFromDb() async {
    try {
      _pkgDescMasters = await DatabaseHelper.instance.getPkgDescs();
    } catch (_) {
      _pkgDescMasters = [];
    }
    notifyListeners();
  }

  // ---------- Pkg Condn master (M_PKGCONDN, synced after login) ----------
  List<PkgCondn> _pkgCondnMasters = [];

  /// The codes (values) for the Pkg Condn dropdown, from M_PKGCONDN.
  List<String> get pkgCondnCodes => _pkgCondnMasters.map((p) => p.code).toList();

  /// Code -> Detail text ("code is your value and detail is text").
  String pkgCondnLabel(String code) {
    for (final p in _pkgCondnMasters) {
      if (p.code == code) return p.detail;
    }
    return code;
  }

  /// Reads the Pkg Condn master list cached in the local DB.
  /// Called after login sync + at provider creation (offline fallback).
  Future<void> loadPkgCondnsFromDb() async {
    try {
      _pkgCondnMasters = await DatabaseHelper.instance.getPkgCondns();
    } catch (_) {
      _pkgCondnMasters = [];
    }
    notifyListeners();
  }

  /// Maps a Pkg Desc SL_NO code (e.g. "17") to its master text (e.g. "NONE").
  /// Falls back to the raw input when no match is found or the list is empty.
  /// Also treats the literal "0" as empty so a server `pkg_desc=0` keeps the
  /// field blank instead of showing a bogus "-" entry.
  String _pkgDescTextFromCode(String code, {String fallback = ""}) {
    final c = code.trim();
    if (c.isEmpty || c == "0") return "";
    for (final p in _pkgDescMasters) {
      if (p.slNo.toString() == c && p.pkgDesc.isNotEmpty) return p.pkgDesc;
    }
    // Not a numeric code: already a text value.
    if (int.tryParse(c) == null) return c;
    return fallback;
  }

  /// Commodity codes shown in the dropdown, mapped to labels.
  static const List<String> comodityTypes = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];

  /// Display label for each Commodity code (1 -> HARD PARCEL, etc).
  static String comodityLabel(String code) =>
      const {
        "1": "HARD PARCEL",
        "2": "PERISHABLE PARCEL",
        "3": "NEWSPAPER MAGAZINE",
        "4": "SUBSIDIARY ITEM",
        "5": "HORSE DOG CATTLE BIRDS AND POULTRY",
        "6": "DANGEROUS GOODS",
        "7": "VALUABLE ITEM",
        "8": "ARMS AND AMMUNITION",
        "9": "MOTOR CAR/PLOUGH/BOAT (VP LOAD)",
      }[code] ??
      code;

  /// Short form for a Commodity code or full label (1 -> HP, 2 -> PP, etc).
  /// Non-code values are passed through unchanged.
  static String comodityShortForm(String value) {
    final code = comodityLabel(value) == value ? "" : value;
    final label = code.isEmpty ? value : comodityLabel(code);
    if (label != value && label.isNotEmpty) {
      final words =
          label.split(RegExp(r'[^A-Za-z]+')).where((w) => w.isNotEmpty);
      final acronym = words.map((w) => w[0].toUpperCase()).join();
      if (acronym.isNotEmpty) return acronym;
    }
    return value;
  }

  /// Reverse of [comodityShortForm]: HP -> 1, PP -> 2, etc. If the value is
  /// already a known code (or an unknown short form), it is returned as-is,
  /// so dropdowns that store codes keep working after a reload.
  static String comodityCodeFromShort(String value) {
    for (final code in comodityTypes) {
      if (comodityShortForm(code) == value) return code;
    }
    return value;
  }

  // ---------- Selected dropdown values (set by user or autofill) ----------
  String itemType = "";
  String comodityType = "";
  String pkgCondn = "";
  String pkgDesc = "";

  void setItemType(String v) {
    // A 10-digit (or longer) PWB/PRR No is a SYSTEM booking -> MEMO not allowed.
    if (v == "M" && pwbPrrNoController.text.trim().length >= 10) {
      v = "S";
    }
    itemType = v;
    notifyListeners();
  }

  void setBookingType(String v) {
    bookingType = v;
    notifyListeners();
  }

  void setComodityType(String v) {
    comodityType = v;
    comodityController.text = v;
    notifyListeners();
  }

  void setPkgCondn(String v) {
    pkgCondn = v;
    notifyListeners();
  }

  void setPkgDesc(String v) {
    pkgDesc = v;
    notifyListeners();
  }

  // ---------- Fields above the SEARCH button ----------
  final TextEditingController prrNoController = TextEditingController();
  final TextEditingController srcStnCodeController = TextEditingController();
  final TextEditingController destStnCodeController = TextEditingController();

  // ---------- Fields below the SEARCH button (auto-filled) ----------
  final TextEditingController pwbPrrNoController = TextEditingController();
  final TextEditingController srcStnController = TextEditingController();
  final TextEditingController destStnController = TextEditingController();

  // ---------- Remaining form fields ----------
  final TextEditingController bookingDateController = TextEditingController();
  final TextEditingController bkdPkgController = TextEditingController();
  final TextEditingController ldPkgController = TextEditingController();
  final TextEditingController bkdWtController = TextEditingController();
  final TextEditingController ldWtController = TextEditingController();
  final TextEditingController fareController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController rackNoController = TextEditingController();
  final TextEditingController comodityController = TextEditingController();

  /// PRR No. -> PWB/PRR No, Source Stn Code -> Src Stn,
  /// Dest Stn Code -> Dest Stn.
  void _syncSearchToForm() {
    var changed = false;
    changed |= _copy(pwbPrrNoController, prrNoController.text);
    changed |= _copy(srcStnController, srcStnCodeController.text);
    changed |= _copy(destStnController, destStnCodeController.text);

    // PRR number between 6 and 9 digits = a PRR (MEMO) booking, so
    // Item Type defaults to MEMO; >=10 digits is a PWB (SYSTEM).
    final prrLen = prrNoController.text.trim().length;
    if (prrLen >= 6 && prrLen < 10) {
      if (itemType != "M") {
        itemType = "M";
        changed = true;
      }
    } else if (prrLen >= 10) {
      if (itemType == "M") {
        itemType = "S";
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  /// Copies [value] into [target] while keeping the caret at the end.
  bool _copy(TextEditingController target, String value) {
    if (target.text == value) return false;
    target.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    return true;
  }

  /// Fills the three SEARCH fields and mirrors them into the form below.
  void applySearch({
    required String prrNo,
    required String src,
    required String dest,
  }) {
    prrNoController.text = prrNo;
    srcStnCodeController.text = src;
    destStnCodeController.text = dest;
    _syncSearchToForm();
  }

  // ---------- Search state ----------
  bool _searching = false;
  String _searchError = "";
  PwbLoadSearchResult? _searchResult;

  bool get isSearching => _searching;
  String get searchError => _searchError;
  PwbLoadSearchResult? get searchResult => _searchResult;

  // ---------- SAVE button state ----------
  bool _saving = false;
  // PWB/PRR for which the server replied WITHOUT any record. Such a PWB/PRR
  // is not auto-filled from the local DB and must not be saved either.
  String _noDataPrr = "";

  /// True when the last search for this PWB/PRR came back without a record.
  bool noDataForPrr(String prr) =>
      prr.isNotEmpty && _noDataPrr == prr.trim();
  bool get isSaving => _saving;

  /// Called by the SEARCH button. Validates the three SEARCH fields, then
  /// calls searchPwbLoad and stores the outcome for the View to display.
  ///
  /// Mentor's flow: the request input is PREPARED before the API call —
  /// ACT_LOADNO is built from the current session (flag + station + trainNo +
  /// vehicle + date), VEHICLE_TYPE / LOAD_DATE come from the Loading screen,
  /// and PKGTYPE stays empty (unknown before searching the RR). When the
  /// response arrives, the found row autofills every form field and is also
  /// saved into the ACT_LOADTLS_FALLBACK table.
  Future<PwbLoadSearchResult?> searchPwbLoad() async {
    if (_searching) return null;

    final prrNo = prrNoController.text.trim();
    final src = srcStnCodeController.text.trim();
    final dest = destStnCodeController.text.trim();

    String? invalid;
    if (prrNo.isEmpty) {
      invalid = "Enter PRR No.";
    } else if (src.isEmpty) {
      invalid = "Enter Source Stn Code.";
    } else if (dest.isEmpty) {
      invalid = "Enter Dest Stn Code.";
    }
    if (invalid != null) {
      _searchError = invalid;
      notifyListeners();
      return null;
    }

    _searching = true;
    _searchError = "";
    _searchResult = null;
    notifyListeners();

    final result = await PrrApi.searchPwbLoad(
      pwbLtNo: prrNo,
      srcStn: src,
      dstStn: dest,
      // Use the mode chosen on the Application Mode page (Test / Online) so
      // the request matches the login session cookie. Mentor's input: PKGTYPE
      // stays "PWB".
      pkgType: "PWB",
      actLoadNo: TrainSession.actLoadNo,
      vehicleType: TrainSession.vehicle,
      loadDate: TrainSession.loadDateForApi,
      stnCode: TrainSession.station.isEmpty ? src : TrainSession.station,
      appType: LoginService.appType,
    );

    _searchResult = result;
    if (!result.ok) {
      _searchError = result.message.isEmpty ? "Search failed." : result.message;
    } else if (result.message.isNotEmpty) {
      _searchError = result.message;
    }

    if (result.hasRows) {
      _noDataPrr = "";
      await _applyRowToForm(result.rows.first);
    } else {
      // Server replied without a record list: this PWB/PRR is NOT auto
      // filled (neither from the server nor from the local DB) and it can
      // not be saved either.
      _noDataPrr = prrNo;
      itemType = "";
      bookingType = "";
      _searchError = _searchError.isEmpty
          ? "Search done. Server replied without a record list."
          : _searchError;
      print("SEARCH no data -> PWB/PRR $prrNo not auto-filled, save blocked");
    }
    _searching = false;
    notifyListeners();

    return result;
  }

  /// Maps the searchPwbLoad response row into the form fields and saves it
  /// into ACT_LOADTLS_FALLBACK (mentor's requirement).
  Future<void> _applyRowToForm(Map<String, dynamic> row) async {
    final book = row['bookVO'];
    final bookMap = book is Map ? Map<String, dynamic>.from(book) : <String, dynamic>{};

    print(
      "AUTOFILL <- bookVO keys: ${bookMap.keys.toList()} | rows: ${row.keys.toList()}",
    );

    String read(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return "";
    }

    // ---- Collect values from the response, mapped to DB columns ----
    final pwbltno = read(bookMap, ['pwbltno', 'PWBLTNO']);
    final src = read(bookMap, ['stncode', 'STNCODE', 'STNFROM']);
    final dest = read(bookMap, ['dstnstn', 'DSTNSTN', 'destnstncba', 'DESTNSTNCBA']);
    final bkDate = read(bookMap, ['booking_dt_str', 'BOOK_DT']);
    final bkdPkg = read(bookMap, ['totpkgs', 'BKDPACKAGE']);
    final bkdWt = read(bookMap, ['totchrgwt', 'totactwt', 'TOTCHRGWT']);
    final ldPkg = read(row, ['noofitemsloaded', 'NOOFITEMSLOADED']);
    final ldWt = read(row, ['ldwt', 'LDWT']);
    // Commodity code lives in bookVO.majcommd (e.g. 1); the top-level
    // `majcommd` field is only the display name (e.g. HP).
    final commo = read(bookMap, ['MAJCOMMD', 'majcommd', 'COMMO']).isEmpty
        ? read(row, ['majcommd', 'MAJCOMMD', 'COMMO'])
        : read(bookMap, ['MAJCOMMD', 'majcommd', 'COMMO']);
    final fare = read(bookMap, ['totchrg', 'TOTCHRG']);
    final remarks = read(row, ['remarks', 'REMARKS']);
    final rack = read(row, ['rackno', 'RACKNO']);
    final itemTypeFromRow = read(bookMap, ['pkgtype', 'PKGTYPE', 'itemType']);
    // Search returns the Pkg Desc SL_NO code (e.g. "17"); the dropdown shows
    // the matching master text (e.g. "NONE"), so convert code -> text.
    final pkgCondnFromRow = read(row, ['pkgcnd', 'PKGCND', 'pkg_condn']);
    final pkgDescFromRow = _pkgDescTextFromCode(
      read(bookMap, ['pkg_desc', 'PKG_DESC', 'pkgDesc']),
      fallback: read(bookMap, ['pkg_desc', 'PKG_DESC', 'pkgDesc']),
    );

    // ---- Save: insert every detail into ACT_LOADTLS_FALLBACK ----
    try {
      final pwbltNoInt = int.tryParse(pwbltno) ?? 0;
      final fareFromServer = num.tryParse(fare) ?? 0;
      await DatabaseHelper.instance.insertActLoadTlsFallback({
        'ACT_LOADNO': TrainSession.actLoadNo,
        'PWBLTNO': pwbltNoInt,
        'CONSIGNOR_MOBILE_NO': int.tryParse(
                read(bookMap,
                    ['CONSIGNOR_MOBILE_NO', 'consignor_mobile_no'])) ??
            0,
        'CONSIGNEE_MOBILE_NO': int.tryParse(
                read(bookMap,
                    ['CONSIGNEE_MOBILE_NO', 'consignee_mobile_no'])) ??
            0,
        'MAJCOMMD': comodityShortForm(commo),
        // Only store the fare when the server really returned one (>0).
        // Otherwise keep the column empty until the SAVE button writes the
        // user's fare, so the DB does not show a misleading 0.
        ...(fareFromServer > 0 ? {'TOTCHRG': fareFromServer} : {}),
        'NOOFITEMSLOADED': int.tryParse(ldPkg) ?? 0,
        'PKGCND': pkgCondnFromRow,
        'LOAD_DT': TrainSession.loadDateTime,
        'STNCODE': src,
        'BKTYPE': read(bookMap, ['bktype', 'BKTYPE']),
        'STNFROM': src,
        'DSTNSTN': dest,
        'BOOK_DT': bkDate,
        'BKDPACKAGE': int.tryParse(bkdPkg) ?? 0,
        'PKGTYPE': itemTypeFromRow,
        // Server returns "0" / empty for pkg_desc; keep the column empty so
        // the SAVE button stores the real Pkg Desc the user selects.
        ...(pkgDescFromRow.isNotEmpty && pkgDescFromRow != "0"
            ? {'PKG_DESC': pkgDescFromRow}
            : {}),
        'VEHICLE_NO': TrainSession.vehicle,
        'BKWT': num.tryParse(read(row, ['bkwt', 'BKWT'])) ?? 0,
        'LDWT': num.tryParse(ldWt) ?? 0,
        'REMARKS': remarks,
        'RACKNO': rack,
        'SERIAL_NO': int.tryParse(read(row, ['serial_no', 'SERIAL_NO'])) ?? 0,
        'DESTNSTNCBA': read(bookMap, ['destnstncba', 'DESTNSTNCBA']),
        'SCALE': TrainSession.scale,
        'TOTCHRGWT': num.tryParse(bkdWt) ?? 0,
        'LDCHRGWT': read(row, ['ldchrgwt', 'LDCHRGWT']),
        'SCANALL': int.tryParse(read(row, ['scanall', 'SCANALL'])) ?? 0,
        'LOST_ITEMNO': read(row, ['lost_itemno', 'LOST_ITEMNO']),
        'SYSTEM_DT': DateTime.now().millisecondsSinceEpoch,
      });

      print(
        "ACT_LOADTLS_FALLBACK saved -> ACT_LOADNO: ${TrainSession.actLoadNo} "
        "| PWBLTNO: $pwbltno | PKGS: $bkdPkg | WT: $bkdWt",
      );
    } catch (e) {
      _searchError = "Could not save in local DB: $e";
      print("ACT_LOADTLS_FALLBACK insert error: $e");
      return;
    }

    // ---- Autofill: bind the form DIRECTLY from the server response ----
    // (not via the DB round-trip, so the form fills even if the insert or
    // read-back above hit some unrelated constraint issue).
    _bindFormFromSavedRow({
      'PWBLTNO': pwbltno,
      'STNFROM': src,
      'STNCODE': src,
      'DSTNSTN': dest,
      'DESTNSTNCBA': read(bookMap, ['destnstncba', 'DESTNSTNCBA']),
      'BOOK_DT': bkDate,
      'BKDPACKAGE': bkdPkg,
      'TOTCHRGWT': bkdWt,
      'NOOFITEMSLOADED': ldPkg,
      'LDWT': ldWt,
      'MAJCOMMD': commo,
      'PKGTYPE': itemTypeFromRow,
      'PKGCND': pkgCondnFromRow,
      'PKG_DESC': pkgDescFromRow,
      'BKTYPE': read(bookMap, ['bktype', 'BKTYPE']),
      'TOTCHRG': fare,
      'REMARKS': remarks,
      'RACKNO': rack,
      'SERIAL_NO': read(row, ['serial_no', 'SERIAL_NO']),
    });

    print(
      "ACT_LOADTLS_FALLBACK read-back -> PWBLTNO: $pwbltno "
      "| PKGS: $bkdPkg | WT: $bkdWt | DATE: $bkDate",
    );
  }

  /// Binds all form fields from a saved ACT_LOADTLS_FALLBACK row / the
  /// server response (used after a successful search).
  void _bindFormFromSavedRow(Map<String, Object?> saved) {
    String dbRow(String column) {
      final v = saved[column];
      return v == null ? "" : v.toString().trim();
    }

    final savedPwbltno = dbRow('PWBLTNO');
    if (savedPwbltno.isNotEmpty) {
      pwbPrrNoController.text = savedPwbltno;
    }
    final savedSrc = dbRow('STNFROM').isEmpty ? dbRow('STNCODE') : dbRow('STNFROM');
    if (savedSrc.isNotEmpty) {
      srcStnController.text = savedSrc;
    }
    final savedDest =
        dbRow('DSTNSTN').isEmpty ? dbRow('DESTNSTNCBA') : dbRow('DSTNSTN');
    if (savedDest.isNotEmpty) {
      destStnController.text = savedDest;
    }
    final savedBookDt = dbRow('BOOK_DT');
    if (savedBookDt.isNotEmpty) {
      bookingDateController.text = _uiBookingDate(savedBookDt);
    }
    final savedBkdPkg = dbRow('BKDPACKAGE');
    if (savedBkdPkg.isNotEmpty) {
      bkdPkgController.text = savedBkdPkg;
    }
    final savedBkdWt = dbRow('TOTCHRGWT');
    if (savedBkdWt.isNotEmpty) {
      bkdWtController.text = savedBkdWt;
    }
    final savedLdPkg = dbRow('NOOFITEMSLOADED');
    if (savedLdPkg.isNotEmpty) {
      ldPkgController.text = savedLdPkg;
    }
    final savedLdWt = dbRow('LDWT');
    if (savedLdWt.isNotEmpty) {
      ldWtController.text = savedLdWt;
    }
    final savedCommo = dbRow('MAJCOMMD').isEmpty ? dbRow('COMMO') : dbRow('MAJCOMMD');
    if (savedCommo.isNotEmpty) {
      // Convert the stored short form (e.g. HP) back to the dropdown code (1).
      comodityType = comodityCodeFromShort(savedCommo);
      comodityController.text = comodityType;
    }
    final savedItemType = dbRow('PKGTYPE');
    if (savedItemType.isNotEmpty) {
      itemType = savedItemType;
    }
    final savedPkgCondn = dbRow('PKGCND');
    if (savedPkgCondn.isNotEmpty) {
      pkgCondn = savedPkgCondn;
    }
    final savedPkgDesc = dbRow('PKG_DESC');
    if (savedPkgDesc.isNotEmpty && savedPkgDesc != "0") {
      pkgDesc = savedPkgDesc;
    } else {
      pkgDesc = "";
    }
    final savedBkType = dbRow('BKTYPE');
    if (savedBkType.isNotEmpty) {
      bookingType = savedBkType;
    }
    final savedFare = dbRow('TOTCHRG');
    if (savedFare.isNotEmpty) {
      fareController.text = savedFare;
    }
    final savedRemarks = dbRow('REMARKS');
    if (savedRemarks.isNotEmpty) {
      remarksController.text = savedRemarks;
    }
    final savedRack = dbRow('RACKNO');
    if (savedRack.isNotEmpty) {
      rackNoController.text = savedRack;
    }
  }

  /// Inserts the current form state into ACT_LOADTLS_FALLBACK when the SAVE
  /// button is pressed. Returns null on success, otherwise an error message.
  Future<String?> saveForm() async {
    if (_saving) return null;
    _saving = true;
    notifyListeners();

    final pwbltnoStr = pwbPrrNoController.text.trim().isEmpty
        ? prrNoController.text.trim()
        : pwbPrrNoController.text.trim();
    if (pwbltnoStr.isEmpty) {
      _saving = false;
      notifyListeners();
      return "Enter PWB/PRR No.";
    }
    final src = srcStnController.text.trim().isEmpty
        ? srcStnCodeController.text.trim()
        : srcStnController.text.trim();
    final dest = destStnController.text.trim().isEmpty
        ? destStnCodeController.text.trim()
        : destStnController.text.trim();
    if (src.isEmpty) {
      _saving = false;
      notifyListeners();
      return "Enter Source Station.";
    }
    if (dest.isEmpty) {
      _saving = false;
      notifyListeners();
      return "Enter Destination Station.";
    }

    // Whatever the user typed (22-10-2026 14:46, 22/Oct/2026 2:46 PM, ...)
    // is stored in the one UI format: 22-Oct-2026 14:46.
    normalizeBookingDate();

    Future<int> intOf(String value) async =>
        int.tryParse(value.trim()) ?? 0;
    Future<double> doubleOf(String value) async =>
        double.tryParse(value.trim()) ?? 0;
    final double bkdWt = await doubleOf(bkdWtController.text);
    final double fare = await doubleOf(fareController.text);
    final String pkgDescToSave = pkgDesc.trim();

    try {
      await DatabaseHelper.instance.insertActLoadTlsFallback({
        'ACT_LOADNO': TrainSession.actLoadNo,
        'PWBLTNO': await intOf(pwbltnoStr),
        // NOT NULL columns with no form field; 0 keeps the insert valid.
        'CONSIGNOR_MOBILE_NO': 0,
        'CONSIGNEE_MOBILE_NO': 0,
        'MAJCOMMD': comodityShortForm(
            comodityType.isEmpty ? comodityController.text.trim() : comodityType),
        'TOTCHRG': fare,
        'NOOFITEMSLOADED': await intOf(ldPkgController.text),
        'PKGCND': pkgCondn,
        'LOAD_DT': TrainSession.loadDateTime,
        'STNCODE': src,
        'BKTYPE': bookingType,
        'STNFROM': src,
        'DSTNSTN': dest,
        'BOOK_DT': bookingDateController.text.trim(),
        'BKDPACKAGE': await intOf(bkdPkgController.text),
        'PKGTYPE': itemType,
        'PKG_DESC': pkgDescToSave,
        'VEHICLE_NO': TrainSession.vehicle,
        'BKWT': bkdWt,
        'LDWT': await doubleOf(ldWtController.text),
        'REMARKS': remarksController.text.trim(),
        'RACKNO': rackNoController.text.trim(),
        'SCALE': TrainSession.scale,
        'TOTCHRGWT': bkdWt,
        'SYSTEM_DT': DateTime.now().millisecondsSinceEpoch,
        // 0 = this row was saved MANUALLY from the Add PWB/PRR form.
        'SCANALL': 0,
      });

      print(
        "ACT_LOADTLS_FALLBACK SAVED (SAVE btn) -> ACT_LOADNO: "
        "${TrainSession.actLoadNo} | PWBLTNO: $pwbltnoStr"
        " | PKGS: ${bkdPkgController.text} | WT: $bkdWt"
        " | Fare: $fare | PkgDesc: $pkgDescToSave",
      );

      // Print the exact DB file path + table, so the user knows where to look.
      print(
        "VERIFY -> DB file: ${await DatabaseHelper.instance.dbFilePath}"
        " | Table: ACT_LOADTLS_FALLBACK",
      );

      // Read-back: confirm the row really landed in the DB, and print every
      // stored column so the user can see what was saved (mentor's check).
      try {
        final saved = await DatabaseHelper.instance.getActLoadTlsFallback(
          actLoadNo: TrainSession.actLoadNo,
          pwbltno: int.tryParse(pwbltnoStr) ?? 0,
        );
        if (saved == null) {
          print("VERIFY RE-BACK: NO ROW FOUND in ACT_LOADTLS_FALLBACK!");
        } else {
          saved.forEach((k, v) => print("VERIFY -> $k = $v"));
        }
      } catch (e) {
        print("VERIFY READ-BACK error: $e");
      }

      _saving = false;
      notifyListeners();
      return null;
    } catch (e) {
      print("ACT_LOADTLS_FALLBACK SAVE(BTN) error: $e");
      _saving = false;
      notifyListeners();
      return "Could not save in local DB.";
    }
  }

  /// Rewrites the Booking Date field to the canonical `dd-MMM-yyyy HH:mm`
  /// format (e.g. `22-Oct-2026 14:46`). Called when the field is finished
  /// (keyboard "done") and right before saving.
  void normalizeBookingDate() {
    final raw = bookingDateController.text;
    final normalized = BookingDate.normalize(raw);
    if (normalized != raw) {
      bookingDateController.text = normalized;
    }
  }

  /// "19/09/2026/12/53" -> "19-Sep-2026 12:53" (UI booking date format).
  static String _uiBookingDate(String raw) => BookingDate.normalize(raw);

  /// Clears every field, dropdown and search state, so the RESET button
  /// brings the Add PWB/PRR page back to a fresh state.
  void resetForm() {
    prrNoController.clear();
    srcStnCodeController.clear();
    destStnCodeController.clear();

    pwbPrrNoController.clear();
    srcStnController.clear();
    destStnController.clear();

    bookingDateController.clear();
    bkdPkgController.clear();
    ldPkgController.clear();
    bkdWtController.clear();
    ldWtController.clear();
    fareController.clear();
    remarksController.clear();
    rackNoController.clear();
    comodityController.clear();

    // Dropdowns back to their initial values.
    itemType = "";
    comodityType = "";
    pkgCondn = "";
    pkgDesc = "";
    bookingType = "PWB";

    // Clear the search result / error banner too.
    _searchResult = null;
    _searchError = "";
    _noDataPrr = "";

    notifyListeners();
  }

  void clearSearchState() {
    _searchError = "";
    _searchResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    prrNoController.dispose();
    srcStnCodeController.dispose();
    destStnCodeController.dispose();
    pwbPrrNoController.dispose();
    srcStnController.dispose();
    destStnController.dispose();
    bookingDateController.dispose();
    bkdPkgController.dispose();
    ldPkgController.dispose();
    bkdWtController.dispose();
    ldWtController.dispose();
    fareController.dispose();
    remarksController.dispose();
    rackNoController.dispose();
    comodityController.dispose();
    super.dispose();
  }
}
