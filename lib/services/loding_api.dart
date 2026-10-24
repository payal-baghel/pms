import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/pages/loading/models/icms_response.dart';
import 'package:flutter_application_1/pages/loading/models/summarydetails.dart';
import 'package:flutter_application_1/pages/loading/models/train_load_validation.dart';
import 'package:flutter_application_1/pages/loading/models/platform_master.dart';
import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';
import 'package:flutter_application_1/pages/loading/models/railway_al.dart';
import 'package:flutter_application_1/pages/loading/models/wag_type.dart';
import 'package:flutter_application_1/pages/loading/models/coach_detail.dart';
import 'package:flutter_application_1/pages/loading/models/actual_load_dtls.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_condn.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_desc.dart';
import 'package:flutter_application_1/services/login_api.dart';

import 'http_client.dart';

class LoadingService {
  static final http.Client client = ApiClient.createClient();

  static const String icmsUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/ntesRestServices/";

  static const String getTrndtlsUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getTrndtls/";

  static const String loadingSummaryUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/DataFromICMSToPMSRest/";

  static const String validateTrainLoadUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/validateTrainLoad/";

  static const String railwayALUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getRailwayAL/";

  static const String wagonMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getWagonMaster/";

  static const String wagtypeALUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getWagTypeAL/";

  static const String plateformMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getPlatformMaster/";

  static const String pkgCondnMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getPkgCondnMaster/";

  static const String pkgDescMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getM_PKG_DESC/";

  static const String getActualLoadDtlsUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/getActualLoadDtls/";

  /// "Loading guidance" API: returns the actual load details of a train
  /// (one row per PWB/PRR). The request body is the mentor's shape:
  /// {"DETAIL":"{\"TRAINNO\":\"12566\",\"STNCODE\":\"NDLS\",\"VCLTYPE\":\"FCRSLR\",\"SCHLD_DT\":\"21/Sep/2026 12:45\",\"LOAD_DT\":\"21/Sep/2026 12:45\",\"APPTYPE\":\"Online\"}"}
  static Future<ActualLoadDtlsResult> getActualLoadDtls({
    required String trainNo,
    required String stnCode,
    required String vclType,
    required String schldDt,
    required String loadDt,
    String appType = "",
  }) async {
    try {
      final detail = jsonEncode({
        "TRAINNO": trainNo,
        "STNCODE": stnCode,
        "VCLTYPE": vclType,
        "SCHLD_DT": schldDt,
        "LOAD_DT": loadDt,
        "APPTYPE": appType.isEmpty ? LoginService.appType : appType,
      });
      final body = jsonEncode({"DETAIL": detail});

      final response = await client.post(
        Uri.parse(getActualLoadDtlsUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: body,
      );

      print("GETACTUALLOADDTLS URL: $getActualLoadDtlsUrl");
      print("GETACTUALLOADDTLS Body: $body");
      print("GETACTUALLOADDTLS Status: ${response.statusCode}");
      print(
        "GETACTUALLOADDTLS Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        return ActualLoadDtlsResult.fromBody(response.body);
      }

      return ActualLoadDtlsResult(
        ok: false,
        rawBody: response.body,
        message: "Server error (${response.statusCode})",
      );
    } catch (e) {
      print("GETACTUALLOADDTLS Error: $e");
      return ActualLoadDtlsResult(
        ok: false,
        rawBody: "",
        message: "Network error: $e",
      );
    }
  }

  // (ok: request succeeded & body parsed; data: the parsed master list).
  // Mimics the mentor's authService.getPlatformMaster(): on success the
  // caller always syncs M_PLATFORM (delete + insert) even if the list is empty.
  static Future<({bool ok, List<PlatformMaster> data})>
  getPlatformMaster() async {
    try {
      // Send the exact request body expected by the server.
      // {"DETAIL": "{\"APPTYPE\":\"Test\"}"}
      final response = await client.post(
        Uri.parse(plateformMasterUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("PLATFORM-MASTER Status: ${response.statusCode}");
      print(
        "PLATFORM-MASTER Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          return (
            ok: true,
            data: _parsePlatformList(jsonDecode(response.body)),
          );
        } catch (e) {
          print("PLATFORM-MASTER Parse Error: $e");
          return (ok: false, data: const <PlatformMaster>[]);
        }
      }

      return (ok: false, data: const <PlatformMaster>[]);
    } catch (e) {
      print("PLATFORM-MASTER Error: $e");
      return (ok: false, data: const <PlatformMaster>[]);
    }
  }

  static List<PlatformMaster> _parsePlatformList(dynamic data) {
    // Direct list of platform objects
    if (data is List) {
      return data
          .map(
            (e) => PlatformMaster.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    // Response wrapped inside a key (data / platformList / list / result / etc.)
    if (data is Map) {
      for (final key in [
        "data",
        "platformList",
        "platformMasterList",
        "pfList",
        "list",
        "result",
        "PLATFORMLIST",
        "M_PLATFORM",
        "PLATFORM",
        "table",
        "Table",
      ]) {
        if (data[key] is List) {
          return _parsePlatformList(data[key]);
        }
      }

      // Single platform object in the root
      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => PlatformMaster.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  static Future<({bool ok, List<PkgCondn> data})> getPkgCondnMaster() async {
    try {
      // Send the exact request body expected by the server.
      // {"DETAIL": "{\"APPTYPE\":\"Test\"}"}
      final response = await client.post(
        Uri.parse(pkgCondnMasterUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("PKG-CONDN-MASTER Status: ${response.statusCode}");
      print(
        "PKG-CONDN-MASTER Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          return (
            ok: true,
            data: _parsePkgCondnList(jsonDecode(response.body)),
          );
        } catch (e) {
          print("PKG-CONDN-MASTER Parse Error: $e");
          return (ok: false, data: const <PkgCondn>[]);
        }
      }

      return (ok: false, data: const <PkgCondn>[]);
    } catch (e) {
      print("PKG-CONDN-MASTER Error: $e");
      return (ok: false, data: const <PkgCondn>[]);
    }
  }

  static List<PkgCondn> _parsePkgCondnList(dynamic data) {
    // Direct list of {code, detail} objects
    if (data is List) {
      return data
          .map((e) => PkgCondn.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // Response wrapped inside a key (data / list / result / etc.)
    if (data is Map) {
      for (final key in [
        "data",
        "pkgCondnList",
        "condnList",
        "list",
        "result",
        "M_PKGCONDN",
        "table",
        "Table",
      ]) {
        if (data[key] is List) {
          return _parsePkgCondnList(data[key]);
        }
      }

      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => PkgCondn.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  static Future<({bool ok, List<PkgDesc> data})> getPkgDescMaster() async {
    try {
      // Send the exact request body expected by the server.
      // {"DETAIL": "{\"APPTYPE\":\"Test\"}"}
      final response = await client.post(
        Uri.parse(pkgDescMasterUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("PKG-DESC-MASTER Status: ${response.statusCode}");
      print(
        "PKG-DESC-MASTER Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          return (
            ok: true,
            data: _parsePkgDescList(jsonDecode(response.body)),
          );
        } catch (e) {
          print("PKG-DESC-MASTER Parse Error: $e");
          return (ok: false, data: const <PkgDesc>[]);
        }
      }

      return (ok: false, data: const <PkgDesc>[]);
    } catch (e) {
      print("PKG-DESC-MASTER Error: $e");
      return (ok: false, data: const <PkgDesc>[]);
    }
  }

  static List<PkgDesc> _parsePkgDescList(dynamic data) {
    // Direct list of {pkgDesc, slNumber} objects
    if (data is List) {
      return data
          .map((e) => PkgDesc.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // Response wrapped inside a key (data / list / result / etc.)
    if (data is Map) {
      for (final key in [
        "data",
        "pkgDescList",
        "descList",
        "list",
        "result",
        "M_PKG_DESC",
        "table",
        "Table",
      ]) {
        if (data[key] is List) {
          return _parsePkgDescList(data[key]);
        }
      }

      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => PkgDesc.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------
  // getRailwayAL(): Own Railway master (mentor's getRailwayAL()).
  // Response is a list of {zone, code}; cached into M_RLY by the caller.
  // ---------------------------------------------------------------------
  static Future<({bool ok, List<RailwayAL> data})> getRailwayAL() async {
    try {
      final response = await client.post(
        Uri.parse(railwayALUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("RAILWAY-AL Status: ${response.statusCode}");
      print(
        "RAILWAY-AL Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          return (ok: true, data: _parseRailwayList(jsonDecode(response.body)));
        } catch (e) {
          print("RAILWAY-AL Parse Error: $e");
          return (ok: false, data: const <RailwayAL>[]);
        }
      }

      return (ok: false, data: const <RailwayAL>[]);
    } catch (e) {
      print("RAILWAY-AL Error: $e");
      return (ok: false, data: const <RailwayAL>[]);
    }
  }

  static List<RailwayAL> _parseRailwayList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => RailwayAL.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (data is Map) {
      for (final key in [
        "data",
        "railwayList",
        "railwayAL",
        "railways",
        "list",
        "result",
        "M_RLY",
        "RAILWAY",
        "table",
        "Table",
      ]) {
        if (data[key] is List) {
          return _parseRailwayList(data[key]);
        }
      }
      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => RailwayAL.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------
  // getWagTypeAL(): Coach Type master (mentor's getWagTypeAL()).
  // Cached into M_WAGTYPE by the caller.
  // ---------------------------------------------------------------------
  static Future<({bool ok, List<WagType> data})> getWagTypeAL() async {
    try {
      final response = await client.post(
        Uri.parse(wagtypeALUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("WAGTYPE-AL Status: ${response.statusCode}");
      print(
        "WAGTYPE-AL Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          return (ok: true, data: _parseWagTypeList(jsonDecode(response.body)));
        } catch (e) {
          print("WAGTYPE-AL Parse Error: $e");
          return (ok: false, data: const <WagType>[]);
        }
      }

      return (ok: false, data: const <WagType>[]);
    } catch (e) {
      print("WAGTYPE-AL Error: $e");
      return (ok: false, data: const <WagType>[]);
    }
  }

  static List<WagType> _parseWagTypeList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => WagType.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (data is Map) {
      for (final key in [
        "data",
        "wagTypeList",
        "wagTypeAL",
        "wagTypes",
        "list",
        "result",
        "M_WAGTYPE",
        "WAGTYPE",
        "table",
        "Table",
      ]) {
        if (data[key] is List) {
          return _parseWagTypeList(data[key]);
        }
      }
      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => WagType.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------
  // getTrainConsist(): builds the Wagon-Rly-No. option list (mentor's
  // loadData()). The detail field carries a nested JSON action:
  //   {"action":"GET_TRAIN_CONSIST","trnno":"13151","stdate":"20-09-2026"}
  // and the response fills TRAININFO / COACHDETL.
  // ---------------------------------------------------------------------
  static Future<({bool ok, String error, String message, List<CoachDetail> data})>
  getTrainConsist({
    required String trainNo,
    required String scheduleDate,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(loadingSummaryUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "wagonNo": "",
          "detail": jsonEncode({
            "action": "GET_TRAIN_CONSIST",
            "trnno": trainNo,
            "stdate": scheduleDate,
          }),
          "nil_ld_uld": "",
          "remark": "",
          "changeSLR": "",
          "guardCharge": "",
          "coachTypeUser": "",
          "STATUS": "",
          "pfno": "",
          "coachnoUser": "",
          "sealed": "",
          "OWNRLY": "",
          "COACHNO": "",
          "rpf": "",
          "ownrlyUser": "",
          "TRAININFO": "",
          "COACHTYPE": "",
          "sealToStn1": "",
          "sealToStn": "",
          "sealToStn2": "",
          "guardName": "",
          "LINETYPE": "",
          "guardHqtr": "",
          "guard_mob_no": "",
          "insideLock": "",
          "rejectWagon": "",
          "COACHDETL": "",
        }),
      );

      print("TRAIN-CONSIST Status: ${response.statusCode}");
      print(
        "TRAIN-CONSIST Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          final coaches = _parseCoachList(decoded);
          return (
            ok: true,
            error: "",
            message: _responseMessage(decoded),
            data: coaches,
          );
        } catch (e) {
          print("TRAIN-CONSIST Parse Error: $e");
          return (
            ok: false,
            error: "could not read server response",
            message: "",
            data: const <CoachDetail>[],
          );
        }
      }

      return (
        ok: false,
        error:
            "HTTP ${response.statusCode}${response.body.isEmpty ? " (EMPTY BODY)" : ""}",
        message: "",
        data: const <CoachDetail>[],
      );
    } catch (e) {
      print("TRAIN-CONSIST Error: $e");
      return (ok: false, error: "$e", message: "", data: const <CoachDetail>[]);
    }
  }

  /// Server text (SERVICEMESSAGE / Decription / message) so the caller can
  /// tell the user why the consist list is empty instead of only "no data".
  static String _responseMessage(dynamic data) {
    if (data is String) {
      final text = data.trim();
      if (!text.startsWith("{") && !text.startsWith("[")) return "";
      try {
        return _responseMessage(jsonDecode(text));
      } on FormatException {
        return "";
      }
    }
    if (data is! Map) return "";

    for (final key in [
      "SERVICEMESSAGE",
      "serviceMessage",
      "Decription",
      "decription",
      "description",
      "message",
      "Message",
      "errorMessage",
    ]) {
      final v = data[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final info = data["TRAININFO"];
    if (info is Map) return _responseMessage(info);
    return "";
  }

  // COACHDETL can arrive as a real array or as an embedded JSON string,
  // so both shapes are handled.
  static List<CoachDetail> _parseCoachList(dynamic data) {
    dynamic node = data;

    if (node is String) {
      final text = node.trim();
      if (text.isEmpty) return [];
      // Only strings that actually carry a JSON container are decoded. Plain
      // server text (e.g. a status response like {"STATUS":"F"} whose values
      // are bare strings) is NOT JSON, so trying to decode it used to throw
      // and hide the real reason behind a "parse error".
      if (!text.startsWith("[") && !text.startsWith("{")) return [];
      try {
        node = jsonDecode(text);
      } on FormatException {
        return [];
      }
    }

    if (node is Map) {
      for (final key in [
        "COACHDETL",
        "coachDetl",
        "coachDetails",
        "TRAININFO",
      ]) {
        final v = node[key];
        if (v != null && v != "") {
          final found = _parseCoachList(v);
          if (found.isNotEmpty) return found;
        }
      }
      for (final v in node.values) {
        final found = _parseCoachList(v);
        if (found.isNotEmpty) return found;
      }
      return [];
    }

    if (node is List) {
      final result = <CoachDetail>[];
      for (final item in node) {
        if (item is String) {
          // An element may itself be a JSON string of coach objects.
          final inner = _parseCoachList(item);
          if (inner.isNotEmpty) {
            result.addAll(inner);
          }
          continue;
        }
        if (item is Map) {
          final coach = CoachDetail.fromJson(Map<String, dynamic>.from(item));
          if (coach.display.replaceAll("-", "").trim().isNotEmpty) {
            result.add(coach);
          }
        }
      }
      return result;
    }

    return [];
  }

  static Future<List<WagonMaster>> getWagonMaster() async {
    try {
      // Send the exact request body expected by the server.
      // {"DETAIL": "{\"APPTYPE\":\"Online\"}"}
      final response = await client.post(
        Uri.parse(wagonMasterUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({
          "DETAIL": jsonEncode({"APPTYPE": LoginService.appType}),
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Cookie Sent: ${LoginService.sessionCookie ?? "NONE"}");
      print(
        "Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        return _parseWagonList(decoded);
      }

      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static List<WagonMaster> _parseWagonList(dynamic data) {
    // Direct list of wagon objects
    if (data is List) {
      return data
          .map((e) => WagonMaster.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    // Response wrapped inside a key (data / wagonList / result / etc.)
    if (data is Map) {
      for (final key in [
        "data",
        "wagonList",
        "wagonMasterList",
        "wagon_type_list",
        "result",
      ]) {
        if (data[key] is List) {
          return _parseWagonList(data[key]);
        }
      }

      // Single wagon object in the root
      final values = data.values.whereType<Map>().toList();
      if (values.isNotEmpty) {
        return values
            .map((e) => WagonMaster.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  static Future<IcmsResponse> getIcmsData({
    required String trainNo,
    required String jStation,
    required String jDate,
    String jEvent = "A",
    required String userId,
    required String password,
    String ttType = "PTT",
    void Function(String raw)? onRaw,
  }) async {
    try {
      final detail = jsonEncode({
        "trainNo": trainNo,
        "jStation": jStation,
        "jDate": jDate,
        "jEvent": jEvent,
        "usrId": userId,
        "paswd": password,
        "ttType": ttType,
      });
      final body = jsonEncode({"detail": detail});

      final response = await client.post(
        Uri.parse(icmsUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("ICMS URL: $icmsUrl");
      print("ICMS Body: ${body.replaceAll(password, "***")}");
      print("ICMS Status: ${response.statusCode}");
      print("ICMS Response: ${response.body}");
      onRaw?.call(response.body);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        return IcmsResponse.fromJson(Map<String, dynamic>.from(decoded as Map));
      }

      return const IcmsResponse();
    } catch (e) {
      print("ICMS Error: $e");
      return const IcmsResponse();
    }
  }

  static Future<ValidateTrainLoadResponse?> validateTrainLoad({
    required String trainNo,
    required String stnCode,
    required String vehicleNo,
    required String schldDt,
    required String wagonOwnRly,
    required String vclType,
    String? appType,
  }) async {
    try {
      final detail = jsonEncode({
        "VEHICLENO": vehicleNo,
        "SCHLD_DT": schldDt,
        "WAGONOWNRLY": wagonOwnRly,
        "VCLTYPE": vclType,
        "APPTYPE": appType ?? LoginService.appType,
        "TRAINNO": trainNo,
        "STNCODE": stnCode,
      });
      final body = jsonEncode({"DETAIL": detail});

      final response = await client.post(
        Uri.parse(validateTrainLoadUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: body,
      );

      print("VALIDATE-TRAIN-LOAD URL: $validateTrainLoadUrl");
      print("VALIDATE-TRAIN-LOAD Body: $detail");
      print("VALIDATE-TRAIN-LOAD Status: ${response.statusCode}");
      print("VALIDATE-TRAIN-LOAD Response: ${response.body}");

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return ValidateTrainLoadResponse.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      return null;
    } catch (e) {
      print("VALIDATE-TRAIN-LOAD Error: $e");
      return null;
    }
  }

  static Future<TrainDetails?> getTrndtls({
    required String trainNo,
    required String tdate,
    String stnCode = "",
    String appType = "",
    void Function(String raw)? onRaw,
  }) async {
    try {
      final detail = jsonEncode({
        "trainNo": trainNo,
        "tdate": tdate,
        "stnCode": stnCode,
        "appType": appType.isEmpty ? LoginService.appType : appType,
      });
      final body = jsonEncode({"detail": detail});

      final response = await client.post(
        Uri.parse(getTrndtlsUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("GETTRNDTLS URL: $getTrndtlsUrl");
      print("GETTRNDTLS Body: $body");
      print("GETTRNDTLS Status: ${response.statusCode}");
      print("GETTRNDTLS Response: ${response.body}");
      onRaw?.call(response.body);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        return TrainDetails.fromJson(Map<String, dynamic>.from(decoded as Map));
      }

      return null;
    } catch (e) {
      print("GETTRNDTLS Error: $e");
      return null;
    }
  }

  static Future<bool> login(
    String username,
    String password,
    String station,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(wagonMasterUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userid": username,
          "password": password,
          "stncode": station,
          "strapptype": LoginService.appType,
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        return response.body.toLowerCase().contains("true");
      } else {
        return false;
      }
    } catch (e) {
      print("API Error: $e");
      return false;
    }
  }
}
