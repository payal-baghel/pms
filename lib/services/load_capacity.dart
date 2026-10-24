import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/loading/loading_db_helper.dart';
import 'package:flutter_application_1/services/train_session.dart';

/// Vehicle capacity and loaded-weight checks shared by the Scan Data screen,
/// the Add PWB/PRR form and the scanning screen.
///
/// The wagon master stores the capacity in TONNES ("3.9" for FCFSLR), while
/// the parcel data is in kg, so the capacity is converted: 3.9 T = 3900 kg.
class LoadCapacity {
  /// Vehicle capacity in kg for the vehicle type(s) of the current session.
  /// Returns null when the vehicle type is unknown or has no capacity
  /// (in that case the capacity check is skipped).
  static Future<double?> capacityKg() async {
    final typeText = TrainSession.vehicle.trim();
    if (typeText.isEmpty) return null;
    try {
      final wagons = await LoadingDbHelper.instance.getWagonMasters();
      final wanted = typeText
          .split(',')
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      double tonnes = 0;
      for (final w in wagons) {
        if (wanted.contains(w.wagonType.trim().toUpperCase())) {
          tonnes += _tonnes(w.capicity);
        }
      }
      return tonnes > 0 ? tonnes * 1000 : null;
    } catch (_) {
      return null;
    }
  }

  /// Total loaded weight (kg) already saved for the current loading session.
  static Future<double> loadedWeightKg() async {
    final rows = await DatabaseHelper.instance.getRowsByActLoadNo(
      TrainSession.actLoadNo,
    );
    double total = 0;
    for (final r in rows) {
      total += double.tryParse(r['LDWT']?.toString() ?? '') ?? 0;
    }
    return total;
  }

  /// Loaded weight (kg) of the current session WITHOUT one row (the row that
  /// is being edited), so the capacity check counts the other rows only.
  static Future<double> loadedWeightExcludingKg({
    required int pwbltno,
    required String actLoadNo,
  }) async {
    final rows = await DatabaseHelper.instance.getRowsByActLoadNo(
      TrainSession.actLoadNo,
    );
    double total = 0;
    for (final r in rows) {
      final rowPrr = int.tryParse(r['PWBLTNO']?.toString() ?? '') ?? 0;
      final rowAct = r['ACT_LOADNO']?.toString() ?? '';
      if (rowPrr == pwbltno && rowAct == actLoadNo) continue;
      total += double.tryParse(r['LDWT']?.toString() ?? '') ?? 0;
    }
    return total;
  }

  /// Loaded weight (kg) of one saved row; 0 when the row is not saved yet.
  static Future<double> rowWeightKg(int pwbltno) async {
    final row = await DatabaseHelper.instance.getActLoadTlsFallback(
      actLoadNo: TrainSession.actLoadNo,
      pwbltno: pwbltno,
    );
    if (row == null) return 0;
    return double.tryParse(row['LDWT']?.toString() ?? '') ?? 0;
  }

  /// Capacity written in the wagon master is in tonnes; it may also come as
  /// "3.9 T", so only the numeric part is read.
  static double _tonnes(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  /// Formal message used by every "capacity exceeded" alert.
  static String capacityMessage({
    required double totalKg,
    required double capacityKg,
  }) {
    final vehicle = TrainSession.vehicle.trim();
    return "Total loaded weight (${_fmt(totalKg)} kg) exceeds the vehicle "
        "capacity of $vehicle (${_fmt(capacityKg)} kg). "
        "The vehicle cannot be loaded beyond its capacity.";
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    var s = v.toStringAsFixed(3);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
