import 'summarydetails.dart';

class ValidateTrainLoadResponse {
  final String trainNo;
  final String trainType;
  final String srcStn;
  final String viastrn;
  final String divCode;
  final int? validity;
  final bool isError;
  final String message;

  // Mentor flow: empty Decription -> proceed to next page,
  // otherwise show its text as an alert and stay on this page.
  final String decription;

  // Route data comes inside the validateTrainLoad response itself.
  final String destStn;
  final List<TrainStop> trnstpg;

  const ValidateTrainLoadResponse({
    this.trainNo = "",
    this.trainType = "",
    this.srcStn = "",
    this.viastrn = "",
    this.divCode = "",
    this.validity,
    this.isError = false,
    this.message = "",
    this.decription = "",
    this.destStn = "",
    this.trnstpg = const [],
  });

  factory ValidateTrainLoadResponse.fromJson(Map<String, dynamic> json) {
    String value(Object? v) => v?.toString() ?? "";

    // Pick the first non-empty value among the given key variants.
    // The live server returns PascalCase keys (TrainNo / StnCode / Decription),
    // while the test DB returns camelCase ones.
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = value(json[k]).trim();
        if (v.isNotEmpty) return v;
      }
      return "";
    }

    final msg = pick(['message', 'msg', 'serviceMessage', 'MGS']);

    final errorFlag =
        json['error'] == true ||
        (json['error'] is String &&
            (json['error'] as String).toLowerCase() == 'true') ||
        value(json['status']).toLowerCase().contains('fail') ||
        msg.toLowerCase().contains('invalid') ||
        msg.toLowerCase().contains('not allowed') ||
        // "MGS" holds a server-side error/stack trace tail.
        (json.containsKey('MGS') && json['MGS'] != null);

    final rawStops = json['trnstpg'] ?? json['Trnstpg'] ?? json['stops'];
    final stops = <TrainStop>[];
    if (rawStops is List) {
      for (final e in rawStops) {
        if (e is Map) {
          stops.add(TrainStop.fromJson(Map<String, dynamic>.from(e)));
        } else if (e is String) {
          stops.add(TrainStop(stnCode: e));
        }
      }
    }

    return ValidateTrainLoadResponse(
      trainNo: pick(['trainNo', 'TrainNo', 'trainno']),
      trainType: pick(['trainType', 'TrainType', 'train_type']),
      srcStn: pick(['srcStn', 'SrcStn', 'srccode']),
      viastrn: pick(['viastrn', 'viastn', 'viaStn', 'via_stn']),
      divCode: pick(['divCode', 'DivCode', 'div_code']),
      validity: json['validity'] is num
          ? (json['validity'] as num).toInt()
          : int.tryParse(value(json['validity'])),
      isError: errorFlag,
      message: msg,
      decription: pick([
        'Decription',
        'decription',
        'Description',
        'description',
      ]),
      destStn: pick(['destStn', 'DestStn', 'dest_stn']),
      trnstpg: stops,
    );
  }

  bool get isValid =>
      !isError &&
      (trainNo.isNotEmpty || viastrn.isNotEmpty || trainType.isNotEmpty);
}
