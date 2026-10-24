class PkgDesc {
  final int slNo;
  final String pkgDesc;
  final String userid;
  final String stncode;

  PkgDesc({
    required this.slNo,
    required this.pkgDesc,
    this.userid = "",
    this.stncode = "",
  });

  factory PkgDesc.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final k in keys) {
        for (final entry in json.entries) {
          if (entry.key.toLowerCase() == k.toLowerCase()) {
            final v = entry.value?.toString().trim() ?? "";
            if (v.isNotEmpty) return v;
          }
        }
      }
      return "";
    }

    return PkgDesc(
      slNo: int.tryParse(pick(['slNumber', 'slno', 'SL_NO'])) ?? 0,
      pkgDesc: pick(['pkgDesc', 'PKG_DESC', 'description', 'detail']),
      userid: pick(['userid', 'USERID']),
      stncode: pick(['stncode', 'STNCODE']),
    );
  }

  factory PkgDesc.fromMap(Map<String, dynamic> map) {
    return PkgDesc(
      slNo: int.tryParse(map['SL_NO']?.toString() ?? "") ?? 0,
      pkgDesc: map['PKG_DESC']?.toString() ?? "",
      userid: map['USERID']?.toString() ?? "",
      stncode: map['STNCODE']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'SL_NO': slNo,
      'PKG_DESC': pkgDesc,
      'USERID': userid,
      'STNCODE': stncode,
    };
  }
}