class PkgCondn {
  final String code;
  final String detail;

  PkgCondn({required this.code, required this.detail});

  factory PkgCondn.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString().trim() ?? "";
    String pick(List<String> keys) {
      for (final k in keys) {
        for (final entry in json.entries) {
          if (entry.key.toLowerCase() == k.toLowerCase()) {
            final v = value(entry.value);
            if (v.isNotEmpty) return v;
          }
        }
      }
      return "";
    }

    return PkgCondn(
      code: pick(['code']),
      detail: pick(['detail', 'description', 'text']),
    );
  }

  factory PkgCondn.fromMap(Map<String, dynamic> map) {
    return PkgCondn(
      code: map['CODE']?.toString() ?? "",
      detail: map['DETAIL']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {'CODE': code, 'DETAIL': detail};
  }
}