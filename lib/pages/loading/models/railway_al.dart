class RailwayAL {
  final String zone;
  final String code;

  RailwayAL({required this.zone, required this.code});

  factory RailwayAL.fromJson(Map<String, dynamic> json) {
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

    return RailwayAL(
      zone: pick(['zone', 'zoneName', 'zonename']),
      code: pick(['code', 'railwayCode', 'rlycode']),
    );
  }

  factory RailwayAL.fromMap(Map<String, dynamic> map) {
    return RailwayAL(
      zone: map['ZONE']?.toString() ?? "",
      code: map['CODE']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {'ZONE': zone, 'CODE': code};
  }
}
