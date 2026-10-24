class PlatformMaster {
  final String code;
  final String detail;

  PlatformMaster({required this.code, required this.detail});

  factory PlatformMaster.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    // Case-insensitive lookup — live server sends PascalCase keys while
    // test responses may use camelCase (same fix as train route validation).
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

    return PlatformMaster(
      code: pick(['code', 'pfno', 'platform_no', 'pfNo']),
      detail: pick(['detail', 'text', 'detailDesc', 'description']),
    );
  }

  factory PlatformMaster.fromMap(Map<String, dynamic> map) {
    return PlatformMaster(
      code: map['CODE']?.toString() ?? "",
      detail: map['DETAIL']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {'CODE': code, 'DETAIL': detail};
  }
}
