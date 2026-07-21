class BarcodeDecoder {
  static Map<String, dynamic> decode(String scanData) {
    try {
      // 🔹 Weight
      int pktWt = int.parse(scanData.substring(0, 4));
      int pktDWt = int.parse(scanData.substring(4, 6));
      double weight = pktWt + (pktDWt / 100);

      // 🔹 PRR
      String prr = scanData.substring(6, 16);

      // 🔹 Total packets
      int totalPackets = int.parse(scanData.substring(16, 20));

      // 🔹 Item number
      int itemNo = int.parse(scanData.substring(20, 24));

      // 🔹 Destination (ASCII encoded)
      String destAscii = scanData.substring(24, 32);
      String destination = _decodeAscii(destAscii);

      // 🔹 Source (ASCII encoded)
      String srcAscii = scanData.substring(32, 40);
      String source = _decodeAscii(srcAscii);

      // 🔹 Booking date
      String bkDt = scanData.substring(46, 58);
      String formattedDate = _formatDate(bkDt);

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
      };
    } catch (e) {
      return {"error": "Invalid barcode format"};
    }
  }

  // 🔹 ASCII decoder
  static String _decodeAscii(String input) {
    String result = "";

    for (int i = 0; i < input.length; i += 2) {
      int charCode = int.parse(input.substring(i, i + 2));
      result += String.fromCharCode(charCode);
    }

    return result;
  }

  // 🔹 Date formatter
  static String _formatDate(String raw) {
    String day = raw.substring(0, 2);
    String month = raw.substring(2, 4);
    String year = raw.substring(4, 8);
    String hour = raw.substring(8, 10);
    String minute = raw.substring(10, 12);

    return "$day/$month/$year $hour:$minute";
  }
}
