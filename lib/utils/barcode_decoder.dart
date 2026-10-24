class BarcodeDecoder {
  static Map<String, dynamic> decode(String scanData) {
    try {
      // 🔹 Weight of THIS packet (kg, 2 decimals)
      int pktWt = int.parse(scanData.substring(0, 4));
      int pktDWt = int.parse(scanData.substring(4, 6));
      double weight = pktWt + (pktDWt / 100);

      // 🔹 PRR
      String prr = scanData.substring(6, 16);

      // 🔹 Total booked packets
      int totalPackets = int.parse(scanData.substring(16, 20));

      // 🔹 Item number
      int itemNo = int.parse(scanData.substring(20, 24));

      // 🔹 Destination (ASCII encoded)
      String destAscii = scanData.substring(24, 32);
      String destination = _decodeAscii(destAscii);

      // 🔹 Source (ASCII encoded)
      String srcAscii = scanData.substring(32, 40);
      String source = _decodeAscii(srcAscii);

      // 🔹 Booking type + item type come from the FIRST digit of the PRR
      String bookingType = bookingTypeOf(prr);
      String itemType = itemTypeOf(prr);

      // 🔹 Commodity code (1 digit)
      String commodityCode = _part(scanData, 45, 46);

      // 🔹 Booking date
      String bkDt = scanData.substring(46, 58);
      String formattedDate = _formatDate(bkDt);

      // 🔹 The three 5-digit weight fields of the label
      int rawBookedWeight = _intOf(_part(scanData, 40, 45));
      int rawChargeableWeight = _intOf(_part(scanData, 58, 63));
      int rawTotalChargeableWeight = _intOf(_part(scanData, 63, 68));

      // The weight fields are stored in hundredths of a kg on some labels
      // (95928 = 959.28 kg) and in plain kg on others (00959 = 959 kg).
      // The unit is detected from the label itself, so the booked weight
      // used for the validation is always in kg.
      final double divisor = _weightDivisor(
        rawBookedWeight,
        totalPackets,
        weight,
      );
      double bookedWeight = rawBookedWeight / divisor;
      double chargeableWeight = rawChargeableWeight / divisor;
      double totalChargeableWeight = rawTotalChargeableWeight / divisor;

      // A chargeable weight far away from the booked weight means the label
      // uses another unit for it - the booked weight is used then.
      if (bookedWeight > 0) {
        if (chargeableWeight > bookedWeight * 10 ||
            chargeableWeight < bookedWeight / 10) {
          chargeableWeight = bookedWeight;
        }
        if (totalChargeableWeight > bookedWeight * 10 ||
            totalChargeableWeight < bookedWeight / 10) {
          totalChargeableWeight = bookedWeight;
        }
      }

      // 🔹 Package description (2 chars)
      String pkgDesc = _part(scanData, 68, 70);

      // 🔹 Scale (R / S), Rajdhani flag, estimated unloading time
      String scale = _part(scanData, 70, 71);
      String rajdhaniFlag = _part(scanData, 71, 72);
      int estUnloadingTime = _intOf(_part(scanData, 72, 74));

      // 🔹 Transit station (ASCII encoded)
      String transitStn = _decodeAscii(_part(scanData, 74, 82));

      return {
        "rawBarcode": scanData,
        "prr": prr,
        "weight": weight,
        "totalPackets": totalPackets,
        "scannedPackets": 1,
        "itemNo": itemNo.toString(),
        "source": source,
        "destination": destination,
        "bookingDate": formattedDate,
        // Booking type / item type (from the first digit of the PRR)
        "bookingType": bookingType,
        "itemType": itemType,
        // Booked values (used to validate the loaded packages and weight)
        "bookedWeight": bookedWeight,
        "chargeableWeight": chargeableWeight,
        "totalChargeableWeight": totalChargeableWeight,
        // True when the label stores the weights in plain kg (rounded), so a
        // loaded weight may be a fraction over the booked weight.
        "weightRounded": divisor <= 1,
        "commodityCode": commodityCode,
        "pkgDesc": pkgDesc,
        "scale": scale,
        "rajdhaniFlag": rajdhaniFlag,
        "estUnloadingTime": estUnloadingTime,
        "transitStn": transitStn,
      };
    } catch (e) {
      return {"error": "Invalid barcode format"};
    }
  }

  /// Booking type from the FIRST digit of the PWB/PRR (mentor's rule):
  /// 1, 2 -> PWB | 3, 4 -> LT | 5, 6 -> VPB | 9 -> PWB
  static String bookingTypeOf(String prr) {
    if (prr.isEmpty) return "";
    switch (prr.substring(0, 1)) {
      case "1":
      case "2":
        return "PWB";
      case "3":
      case "4":
        return "LT";
      case "5":
      case "6":
        return "VPB";
      case "9":
        return "PWB";
      default:
        return "";
    }
  }

  /// Item type from the FIRST digit of the PWB/PRR: 1-6 -> SYSTEM (S),
  /// 9 -> FSLA (our item type code for FSLA is "F").
  static String itemTypeOf(String prr) {
    if (prr.isEmpty) return "";
    final digit = prr.substring(0, 1);
    if (digit == "9") return "F";
    if (const {"1", "2", "3", "4", "5", "6"}.contains(digit)) return "S";
    return "";
  }

  /// Picks the unit of the 5-digit weight fields: 100 (hundredths of a kg)
  /// or 1 (plain kg). The parcel weight expected from the label itself
  /// (booked packages x weight of this packet) tells which one is used.
  static double _weightDivisor(
    int rawBookedWeight,
    int bookedPkgs,
    double packetWeight,
  ) {
    if (rawBookedWeight <= 0) return 100;
    if (bookedPkgs <= 0 || packetWeight <= 0) return 100;

    final expected = bookedPkgs * packetWeight;
    final asKg = rawBookedWeight.toDouble();
    final asCentiKg = rawBookedWeight / 100.0;
    return (asCentiKg - expected).abs() <= (asKg - expected).abs() ? 100 : 1;
  }

  /// Safe part read: a label that is too short gives an empty string instead
  /// of throwing, so the older (shorter) labels keep working.
  static String _part(String source, int start, int end) =>
      source.length >= end ? source.substring(start, end) : "";

  static int _intOf(String value) => int.tryParse(value.trim()) ?? 0;

  // 🔹 ASCII decoder (the label stores the ASCII code of every character as
  // a 2-digit decimal number, e.g. "65" = "A")
  static String _decodeAscii(String input) {
    String result = "";

    for (int i = 0; i + 1 < input.length; i += 2) {
      final code = int.tryParse(input.substring(i, i + 2));
      if (code == null) continue;
      result += String.fromCharCode(code);
    }

    return result.trim();
  }

  // 🔹 Date formatter -> dd-MMM-yyyy HH:mm (e.g. 15-Sep-2022 12:53)
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

  static String _formatDate(String raw) {
    String day = raw.substring(0, 2);
    String month = raw.substring(2, 4);
    String year = raw.substring(4, 8);
    String hour = raw.substring(8, 10);
    String minute = raw.substring(10, 12);

    final monthIndex = int.tryParse(month);
    final monthName =
        (monthIndex != null && monthIndex >= 1 && monthIndex <= 12)
        ? _months[monthIndex - 1]
        : month;

    return "$day-$monthName-$year $hour:$minute";
  }
}
