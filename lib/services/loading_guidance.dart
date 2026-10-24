import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/services/loding_api.dart';
import 'package:flutter_application_1/services/train_session.dart';
import 'package:flutter_application_1/utils/barcode_decoder.dart';

/// Loads the "loading guidance" (actual load details) of the current train and
/// stores every row in the local ACT_LOADTLS_FALLBACK table, so the Scan Data
/// screen shows them right after the guidance is fetched.
class LoadingGuidance {
  LoadingGuidance._();

  /// Fetches the guidance for the train of the current loading session
  /// (train no, dates and vehicle type are taken from the session).
  static Future<({bool ok, int saved, String message})> loadForSession({
    String scheduledDate = "",
  }) async {
    return loadAndSave(
      trainNo: TrainSession.trainNo.trim(),
      stnCode: TrainSession.station.trim(),
      vclType: TrainSession.vehicle.trim(),
      schldDt: TrainSession.apiDate(scheduledDate),
      loadDt: TrainSession.loadDateForApi,
    );
  }

  /// Calls getActualLoadDtls and saves every returned row locally.
  ///
  /// Returns the number of saved rows and a message for the user.
  static Future<({bool ok, int saved, String message})> loadAndSave({
    required String trainNo,
    required String stnCode,
    required String vclType,
    required String schldDt,
    required String loadDt,
  }) async {
    final result = await LoadingService.getActualLoadDtls(
      trainNo: trainNo,
      stnCode: stnCode,
      vclType: vclType,
      schldDt: schldDt,
      loadDt: loadDt,
    );

    if (!result.ok) {
      return (
        ok: false,
        saved: 0,
        message: result.message.isEmpty
            ? "Guidance could not be fetched."
            : result.message,
      );
    }

    if (!result.hasRows) {
      return (
        ok: true,
        saved: 0,
        message: "No guidance records found for train $trainNo.",
      );
    }

    final actLoadNo = TrainSession.actLoadNo;
    var saved = 0;
    var skipped = 0;
    for (final row in result.rows) {
      final values = toDbValues(row, actLoadNo: actLoadNo);
      if (values == null) {
        skipped++;
        continue;
      }
      await DatabaseHelper.instance.insertActLoadTlsFallback(values);
      saved++;
    }

    print(
      "GUIDANCE saved -> $saved row(s), skipped $skipped | ACT_LOADNO: $actLoadNo",
    );

    return (
      ok: true,
      saved: saved,
      message: skipped > 0
          ? "$saved guidance record(s) loaded, $skipped skipped."
          : "$saved guidance record(s) loaded.",
    );
  }

  /// Maps one API row to the ACT_LOADTLS_FALLBACK columns.
  ///
  /// The column names of the service are not documented, so every key is
  /// matched case-insensitively (underscores / spaces ignored) and a few
  /// synonyms are tried as well. Returns null when the row carries no
  /// PWB/PRR number (such a row cannot be stored - it is the primary key).
  static Map<String, Object?>? toDbValues(
    Map<String, dynamic> row, {
    required String actLoadNo,
  }) {
    final norm = <String, dynamic>{};
    _flatten(row).forEach((key, value) => norm[_key(key)] = value);

    String text(List<String> aliases) {
      for (final alias in aliases) {
        final value = norm[_key(alias)];
        if (value == null) continue;
        final s = value.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return "";
    }

    String digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

    final prr = text([
      "PWBLTNO",
      "PWBPRRNO",
      "PWB_PRR_NO",
      "PRRNO",
      "PRR_NO",
      "PRR",
    ]);
    final pwbltno = int.tryParse(digits(prr)) ?? 0;
    if (pwbltno <= 0) return null;

    final itemNos = text(["ITEMNOS", "ITEM_NO", "ITEMNO"]);
    final stnFrom = text(["STNFROM", "FROMSTN", "FROM_STN", "ORIGIN"]);
    final stnCode = text(["STNCODE", "STN_CODE"]);
    final dest = text([
      "DSTNSTN",
      "DESTSTN",
      "DEST_STN",
      "TOSTN",
      "DESTINATION",
    ]);
    final destCba = text(["DESTNSTNCBA", "DSTNSTNCBA"]);
    final bookDt = text(["BOOK_DT", "BOOKING_DT", "BOOKING_DATE", "BOOKDT"]);
    final schldDt = text(["SCHLD_DT", "SCHEDULED_DT", "SCHLDDATE"]);
    final loadDt = text(["LOAD_DT", "LOADDATE", "ACTUALLD_DT"]);
    final bkdPkg = text([
      "BKDPACKAGE",
      "BKD_PACKAGE",
      "BKDPKG",
      "NOOFITEMSBOOKED",
      "NOOFITEMBOOKED",
    ]);
    final ldPkg = text([
      "NOOFITEMSLOADED",
      "NOOFITEMLOADED",
      "LDPKG",
      "LD_PKG",
      "LOADEDPACKAGE",
    ]);
    final bkdWt = text(["TOTCHRGWT", "BKDWT", "BKWT", "BOOKEDWEIGHT"]);
    final ldWt = text(["LDWT", "LD_WT", "ACTUALWT", "LOADEDWEIGHT"]);
    final majcommd = text(["MAJCOMMD", "MAJ_COMMD", "COMMODITY", "COMMO"]);
    final fare = text(["TOTCHRG", "FARE"]);
    final pkgType = text(["PKGTYPE", "PKG_TYPE", "ITEMTYPE"]);
    final bkType = text(["BKTYPE", "BK_TYPE", "BOOKINGTYPE"]);
    final pkgCnd = text(["PKGCND", "PKG_CONDITION"]);
    final pkgDesc = text(["PKG_DESC", "PKGDESC", "PKGDESCRIPTION"]);
    final remarks = text(["REMARKS", "REMARK"]);
    final rackNo = text(["RACKNO", "RACK_NO"]);
    final vehicleNo = text(["VEHICLE_NO", "VEHICLENO", "COACHNO"]);
    final scale = text(["SCALE", "LTSCALECODE", "SCALECODE"]);
    final nopScanned = text(["NOP_SCANNED", "NOPSCANNED"]);
    final serialNo = text(["SERIAL_NO", "SERIALNO"]);
    final consignorMobile = text(["CONSIGNOR_MOBILE_NO", "CONSIGNORMOBILENO"]);
    final consigneeMobile = text(["CONSIGNEE_MOBILE_NO", "CONSIGNEE_MOBILENO"]);

    // Booking type / item type: take the server value, otherwise derive them
    // from the first digit of the PWB/PRR (the same rule the barcode uses).
    final bookingType = bkType.isNotEmpty
        ? bkType
        : BarcodeDecoder.bookingTypeOf(prr);
    final itemType = pkgType.isNotEmpty
        ? pkgType
        : BarcodeDecoder.itemTypeOf(prr);

    return {
      "ACT_LOADNO": actLoadNo,
      "PWBLTNO": pwbltno,
      "ITEMNOS": itemNos,
      "STNFROM": stnFrom.isNotEmpty ? stnFrom : stnCode,
      "STNCODE": stnCode,
      "DSTNSTN": dest.isNotEmpty ? dest : destCba,
      "DESTNSTNCBA": destCba.isNotEmpty ? destCba : dest,
      "BOOK_DT": bookDt,
      "SCHLD_DT": schldDt,
      "LOAD_DT": loadDt,
      "BKDPACKAGE": bkdPkg,
      "NOOFITEMSLOADED": ldPkg,
      "TOTCHRGWT": bkdWt,
      "BKWT": bkdWt,
      "LDWT": ldWt,
      "MAJCOMMD": majcommd,
      "COMMO": majcommd,
      "TOTCHRG": fare,
      "PKGTYPE": itemType,
      "BKTYPE": bookingType,
      "PKGCND": pkgCnd,
      "PKG_DESC": pkgDesc,
      "REMARKS": remarks,
      "RACKNO": rackNo,
      "VEHICLE_NO": vehicleNo,
      "SCALE": scale,
      "NOP_SCANNED": nopScanned,
      "SERIAL_NO": int.tryParse(digits(serialNo)) ?? 0,
      "CONSIGNOR_MOBILE_NO": int.tryParse(digits(consignorMobile)) ?? 0,
      "CONSIGNEE_MOBILE_NO": int.tryParse(digits(consigneeMobile)) ?? 0,
      "SCANALL": 0,
      "SYSTEM_DT": DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// "PWBLTNO" and "pwb_ltno" both become "pwbltno".
  static String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Some services nest the real fields one level deep (e.g. a "bookVO"
  /// object inside the row), so the nested values are lifted up as well.
  static Map<String, dynamic> _flatten(Map<String, dynamic> row) {
    final flat = <String, dynamic>{...row};
    for (final value in row.values) {
      if (value is Map) {
        value.forEach((key, nested) {
          flat.putIfAbsent(key, () => nested);
        });
      }
    }
    return flat;
  }
}
