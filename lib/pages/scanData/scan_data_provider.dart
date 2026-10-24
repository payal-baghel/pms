import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/addPrr/add_prr_provider.dart';
import 'package:flutter_application_1/services/train_session.dart';

/// One saved ACT_LOADTLS_FALLBACK row shown in the Scan Data table.
/// Uses the same columns (and display names) as the Add PWB/PRR form.
class ScanDataRow {
  final Map<String, Object?> raw;

  const ScanDataRow(this.raw);

  String _v(String column) {
    final v = raw[column];
    if (v == null) return "";
    return v.toString().trim();
  }

  String get pwbltno => _v('PWBLTNO');
  String get itemNos => _v('ITEMNOS');
  String get pkgType => _v('PKGTYPE');
  String get bkgType => _v('BKTYPE');
  String get srcStn => _v('STNFROM').isEmpty ? _v('STNCODE') : _v('STNFROM');
  String get destStn => _v('DSTNSTN');
  String get bookingDate => _v('BOOK_DT');
  String get bkdPkg => _v('BKDPACKAGE');
  String get ldPkg => _v('NOOFITEMSLOADED');

  /// PKG column as "booked/loaded" (e.g. "16/1"), matching the earlier app.
  /// After CHECK ALL the loaded count equals the booked one ("16/16").
  String get pkgDisplay {
    final booked = bkdPkg.isEmpty ? "0" : bkdPkg;
    final loaded = ldPkg.isEmpty ? "0" : ldPkg;
    return "$booked/$loaded";
  }
  String get bkdWt => _v('TOTCHRGWT').isEmpty ? _v('BKWT') : _v('TOTCHRGWT');
  String get ldWt => _v('LDWT');
  String get comodityType => _v('MAJCOMMD');
  String get fare => _v('TOTCHRG');
  String get pkgCondn => _v('PKGCND');
  String get pkgDesc => _v('PKG_DESC');
  String get remarks => _v('REMARKS');
  String get rackNo => _v('RACKNO');

  /// True when the row reached the DB through a barcode scan (SCANALL = 1).
  /// Manually saved rows carry SCANALL = 0. Scanned rows can never be edited,
  /// only the data the user saved by hand may be updated later.
  bool get isScanned => (int.tryParse(_v('SCANALL')) ?? 0) == 1;

  /// Primary-key parts, needed to update / delete the row.
  String get actLoadNo => _v('ACT_LOADNO');
  int get pwbltnoInt => int.tryParse(_v('PWBLTNO')) ?? 0;

  // Display helpers (same conversions as the Add PWB/PRR form).
  String get pkgTypeLabel => AddPrrProvider.itemTypeLabel(pkgType);
  String get comodityLabel =>
      AddPrrProvider.comodityLabel(AddPrrProvider.comodityCodeFromShort(comodityType));
}

/// ViewModel (MVVM) for the "Scan Data" screen.
/// Reads the current loading session (train no, scale, loading time, vehicle)
/// that the Loading page stored, so it shows the real user-entered values,
/// plus every ACT_LOADTLS_FALLBACK row saved locally from the Add PWB/PRR form.
class ScanDataProvider extends ChangeNotifier {
  // ---------- Train information (from the current loading session) ----------
  String get trainNumber => TrainSession.trainNo;
  String get scale => TrainSession.scale;
  String get dateTime => TrainSession.loadDateTime;
  String get vehicle => TrainSession.vehicle;

  // ---------- Saved rows (ACT_LOADTLS_FALLBACK) ----------
  List<ScanDataRow> _rows = [];
  bool _loading = false;
  String _loadError = "";

  bool get isLoadingRows => _loading;
  String get loadError => _loadError;
  List<ScanDataRow> get rows => List.unmodifiable(_rows);

  /// Fetches every saved row from ACT_LOADTLS_FALLBACK (newest first).
  Future<void> refresh() async {
    _loading = true;
    _loadError = "";
    notifyListeners();
    try {
      _rows = (await DatabaseHelper.instance.getActLoadTlsFallbackRows())
          .map(ScanDataRow.new)
          .toList();
    } catch (e) {
      _loadError = "Error reading local DB: $e";
      _rows = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Deletes one saved row (by PWBLTNO + ACT_LOADNO) then reloads the table.
  // Update is locked for scanned rows, but a selected row can be deleted.
  Future<void> deleteRow(ScanDataRow row) async {
    await DatabaseHelper.instance.deleteActLoadTlsFallback(
      actLoadNo: row.actLoadNo,
      pwbltno: row.pwbltnoInt,
    );
    await refresh();
  }

  /// Marks every package of this PWB/PRR as loaded (Ld Pkg = Bkd Pkg) without
  /// deleting the row — the mentor's "CHECK ALL" (e.g. 10/1 -> 10/10).
  Future<void> checkAll(ScanDataRow row) async {
    final loaded = int.tryParse(row.bkdPkg) ?? 0;
    await DatabaseHelper.instance.updateActLoadTlsFallbackRow(
      origPwbltno: row.pwbltnoInt,
      actLoadNo: row.actLoadNo,
      values: {'NOOFITEMSLOADED': loaded, 'NOP_SCANNED': loaded},
    );
    await refresh();
  }

  // ---------- Left Over Pkg toggle (UI-only) ----------
  bool _leftOverPkgOff = true;

  bool get isLeftOverPkgOff => _leftOverPkgOff;

  void toggleLeftOverPkg() {
    _leftOverPkgOff = !_leftOverPkgOff;
    notifyListeners();
  }

  // ---------- Placeholder button actions (GUI only, no backend) ----------
  void onStartScanning() {}

  void onScanBarcode() {}

  void onAdd() {}

  void onEdit() {}

  void onNext() {}

  void onExit() {}
}