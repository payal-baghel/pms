class WagType {
  final String type;
  final String guage;
  final String detail;
  final String shortdet;

  WagType({
    required this.type,
    required this.guage,
    required this.detail,
    required this.shortdet,
  });

  factory WagType.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    // Case-insensitive lookup: live server sends PascalCase keys while
    // test responses may use camelCase.
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

    return WagType(
      type: pick(['type', 'wagType', 'wagtype']),
      guage: pick(['guage', 'gauge']),
      detail: pick(['detail', 'description', 'text']),
      shortdet: pick(['shortdet', 'shortDetail', 'short_detal']),
    );
  }

  factory WagType.fromMap(Map<String, dynamic> map) {
    return WagType(
      type: map['TYPE']?.toString() ?? "",
      guage: map['GUAGE']?.toString() ?? "",
      detail: map['DETAIL']?.toString() ?? "",
      shortdet: map['SHORTDET']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TYPE': type,
      'GUAGE': guage,
      'DETAIL': detail,
      'SHORTDET': shortdet,
    };
  }
}
