class TrainUser {
  final String? userid;
  final String? username;
  final String? stncode;
  final String? reglevel;

  const TrainUser({this.userid, this.username, this.stncode, this.reglevel});

  factory TrainUser.fromJson(Map<String, dynamic> json) {
    String? value(Object? v) => v?.toString();

    return TrainUser(
      userid: value(json['userid']),
      username: value(json['username']),
      stncode: value(json['stncode']),
      reglevel: value(json['reglevel']),
    );
  }
}

class TrainStop {
  final String? stnCode;
  final String? distance;
  final String? dayCnt;
  final String? fslrquota;
  final String? rslrquota;
  final String? ms1Rquota;
  final String? vp1Quota;
  final String? vp2Quota;
  final String? owningRly;
  final String? zone;
  final String? route;
  final String? arrTime;
  final String? depTime;
  final String? systemDt;
  final String? arrTimeTS;
  final String? depTimeTS;
  final String? valid;
  final String? trainVer;
  final String? stnDiv;
  final String? stnRly;
  final TrainUser? usrVo;

  const TrainStop({
    this.stnCode,
    this.distance,
    this.dayCnt,
    this.fslrquota,
    this.rslrquota,
    this.ms1Rquota,
    this.vp1Quota,
    this.vp2Quota,
    this.owningRly,
    this.zone,
    this.route,
    this.arrTime,
    this.depTime,
    this.systemDt,
    this.arrTimeTS,
    this.depTimeTS,
    this.valid,
    this.trainVer,
    this.stnDiv,
    this.stnRly,
    this.usrVo,
  });

  factory TrainStop.fromJson(Map<String, dynamic> json) {
    String? value(Object? v) => v?.toString();

    final usrJson = json['usrVO'];
    return TrainStop(
      stnCode: value(
        json['stnCode'] ??
            json['StnCode'] ??
            json['stn_code'] ??
            json['stncode'] ??
            json['STNCODE'],
      ),
      distance: value(json['distance']),
      dayCnt: value(json['dayCnt']),
      fslrquota: value(json['fslrquota']),
      rslrquota: value(json['rslrquota']),
      ms1Rquota: value(json['mslrquota'] ?? json['ms1rquota']),
      vp1Quota: value(json['vp1Quota'] ?? json['vp1quota']),
      vp2Quota: value(json['vp2Quota'] ?? json['vp2quota']),
      owningRly: value(json['owningRly']),
      zone: value(json['zone']),
      route: value(json['route']),
      arrTime: value(json['arrTime']),
      depTime: value(json['depTime']),
      systemDt: value(json['system_DT']),
      arrTimeTS: value(json['arrTimeTS']),
      depTimeTS: value(json['depTimeTS']),
      valid: value(json['valid']),
      trainVer: value(json['train_Ver']),
      stnDiv: value(json['stn_Div']),
      stnRly: value(json['stn_Rly']),
      usrVo: usrJson is Map
          ? TrainUser.fromJson(Map<String, dynamic>.from(usrJson))
          : null,
    );
  }
}

class TrainDetails {
  final String? trainNo;
  final String? trainName;
  final String? trainType;
  final String? trainDrctn;
  final String? otherDesc;
  final String? validity;
  final String? decription;

  final List<TrainStop> trnstpg;

  const TrainDetails({
    this.trainNo,
    this.trainName,
    this.trainType,
    this.trainDrctn,
    this.otherDesc,
    this.validity,
    this.decription,
    this.trnstpg = const [],
  });

  factory TrainDetails.fromJson(Map<String, dynamic> json) {
    String? value(Object? v) => v?.toString();

    List<TrainStop> parseStops(Object? raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) {
            // if it is a plain string list, treat each entry as a station code
            if (e is String) return TrainStop(stnCode: e);
            if (e is Map) {
              return TrainStop.fromJson(Map<String, dynamic>.from(e));
            }
            return null;
          })
          .whereType<TrainStop>()
          .toList();
    }

    return TrainDetails(
      trainNo: value(json['trainNo'] ?? json['trainno'] ?? json['train_no']),
      trainName: value(
        json['trainName'] ?? json['train_name'] ?? json['trainname'],
      ),
      trainType: value(json['trainType'] ?? json['train_type']),
      trainDrctn: value(json['trainDrctn'] ?? json['train_drctn']),
      otherDesc: value(json['other_desc']),
      validity: value(json['validity']),
      decription: value(
        json['decription'] ?? json['Decription'] ?? json['description'],
      ),
      trnstpg: parseStops(
        json['trnstpg'] ??
            json['trn_htpg'] ??
            json['trnHtpg'] ??
            json['halt_stn'] ??
            json['stations'],
      ),
    );
  }
}
