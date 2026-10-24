class CoachDetail {
  final String coachType;
  final String ownRly;
  final String coachNo;

  CoachDetail({
    required this.coachType,
    required this.ownRly,
    required this.coachNo,
  });

  // The Wagon-Rly-No. option text: COACHTYPE-OWNRLY-COACHNO.
  String get display => "$coachType-$ownRly-$coachNo";

  factory CoachDetail.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    // Case-insensitive lookup: the live server sends COACHTYPE / OWNRLY /
    // COACHNO while other responses may use camelCase.
    String pick(List<String> keys) {
      for (final k in keys) {
        for (final entry in json.entries) {
          if (entry.key.toLowerCase() == k.toLowerCase()) {
            final v = value(entry.value).trim();
            if (v.isNotEmpty) return v;
          }
        }
      }
      return "";
    }

    return CoachDetail(
      coachType: pick(['COACHTYPE', 'coachType', 'coachtype']),
      ownRly: pick(['OWNRLY', 'ownRly', 'ownrly']),
      coachNo: pick(['COACHNO', 'coachNo', 'coachno']),
    );
  }
}
