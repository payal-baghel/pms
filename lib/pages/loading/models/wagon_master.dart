class WagonMaster {
  final String code;
  final String wagonType;
  final String codename;
  final String capicity;

  WagonMaster({
    required this.code,
    required this.wagonType,
    required this.codename,
    required this.capicity,
  });

  factory WagonMaster.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    return WagonMaster(
      code: value(json['code'] ?? json['wagonCode'] ?? json['wagon_code']),
      wagonType: value(json['wagon_type'] ?? json['wagonType']),
      codename: value(json['codename'] ?? json['codeName'] ?? json['code_name']),
      capicity: value(json['capicity'] ?? json['capacity']),
    );
  }

  factory WagonMaster.fromMap(Map<String, dynamic> map) {
    return WagonMaster(
      code: map['code']?.toString() ?? "",
      wagonType: map['wagon_type']?.toString() ?? "",
      codename: map['codename']?.toString() ?? "",
      capicity: map['capacity']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'wagon_type': wagonType,
      'codename': codename,
      'capacity': capicity,
    };
  }
}