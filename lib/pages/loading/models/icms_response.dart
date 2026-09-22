class NtesRestServiceMessage {
  final String serviceDataFoundFlag;
  final String serviceInputValidFlag;
  final String serviceMessage;
  final String serviceDataResultFlag;
  final String serviceCallFlag;

  const NtesRestServiceMessage({
    this.serviceDataFoundFlag = "",
    this.serviceInputValidFlag = "",
    this.serviceMessage = "",
    this.serviceDataResultFlag = "",
    this.serviceCallFlag = "",
  });

  factory NtesRestServiceMessage.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    return NtesRestServiceMessage(
      serviceDataFoundFlag: value(json['serviceDataFoundFlag']),
      serviceInputValidFlag: value(json['serviceInputValidFlag']),
      serviceMessage: value(json['serviceMessage']),
      serviceDataResultFlag: value(json['serviceDataResultFlag']),
      serviceCallFlag: value(json['serviceCallFlag']),
    );
  }

  bool get inputValid => serviceInputValidFlag != "N";
}

class IcmStation {
  final String jsStation;
  final String jsPfNumber;
  final String dstn;
  final String startDate;
  final String trainName;
  final String jsStationName;
  final String jsETD;
  final String jsETA;
  final String jsSNo;

  const IcmStation({
    this.jsStation = "",
    this.jsPfNumber = "",
    this.dstn = "",
    this.startDate = "",
    this.trainName = "",
    this.jsStationName = "",
    this.jsETD = "",
    this.jsETA = "",
    this.jsSNo = "",
  });

  factory IcmStation.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    return IcmStation(
      jsStation: value(json['jsStation']),
      jsPfNumber: value(json['jsPfNumber']),
      dstn: value(json['dstn']),
      startDate: value(json['startDate']),
      trainName: value(json['trainName']),
      jsStationName: value(json['jsStationName']),
      jsETD: value(json['jsETD']),
      jsETA: value(json['jsETA']),
      jsSNo: value(json['jsSNo']),
    );
  }
}

class IcmsResponse {
  final NtesRestServiceMessage message;
  final List<dynamic> vStationList;
  final String? platform;
  final String? std;
  final String? etd;
  final String? pttStd;
  final String? atd;
  final String? trainStartDate;
  final String? validity;
  final String? decription;
  final List<IcmStation> stations;

  const IcmsResponse({
    this.message = const NtesRestServiceMessage(),
    this.vStationList = const [],
    this.platform,
    this.std,
    this.etd,
    this.pttStd,
    this.atd,
    this.trainStartDate,
    this.validity,
    this.decription,
    this.stations = const [],
  });

  factory IcmsResponse.fromJson(Map<String, dynamic> json) {
    String? value(Object? v) => v?.toString();

    final msgJson = json['restServiceMessage'];
    return IcmsResponse(
      message: msgJson is Map
          ? NtesRestServiceMessage.fromJson(
              Map<String, dynamic>.from(msgJson))
          : const NtesRestServiceMessage(),
      vStationList: json['vStationList'] is List
          ? (json['vStationList'] as List)
          : const [],
      platform: value(json['Platform']),
      std: value(json['STD']),
      etd: value(json['ETD']),
      pttStd: value(json['PTT_STD']),
      atd: value(json['ATD']),
      trainStartDate: value(json['TrainStartDate']),
      validity: value(json['validity']),
      decription: value(json['Decription']) ?? value(json['Description']),
      stations: _parseStations(json['vStationList']),
    );
  }

  static List<IcmStation> _parseStations(Object? list) {
    if (list is! List) return const [];
    final result = <IcmStation>[];
    for (final item in list) {
      if (item is Map) {
        result.add(IcmStation.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }

  bool get isValid => message.inputValid;

  String get trainName =>
      stations.isNotEmpty ? stations.first.trainName : "";

  String get platformNumber => stations.isNotEmpty
      ? (stations.firstWhere(
          (s) => s.jsPfNumber.isNotEmpty,
          orElse: () => const IcmStation(),
        ).jsPfNumber)
      : "";

  bool stopsAtStation(String stationCode) {
    final code = stationCode.toUpperCase();
    return stations.any((s) => s.jsStation.toUpperCase() == code);
  }
}