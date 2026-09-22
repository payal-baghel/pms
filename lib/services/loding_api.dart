import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/pages/loading/models/icms_response.dart';
import 'package:flutter_application_1/pages/loading/models/summarydetails.dart';
import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';
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
          "DETAIL": jsonEncode({"APPTYPE": "Online"}),
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Cookie Sent: ${LoginService.sessionCookie ?? "NONE"}");
      print(
          "Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}");

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
          .map((e) =>
              WagonMaster.fromJson(Map<String, dynamic>.from(e as Map)))
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

  static Future<TrainDetails?> getTrndtls({
    required String trainNo,
    required String tdate,
    String stnCode = "",
    String appType = "Online",
  }) async {
    try {
      final detail = jsonEncode({
        "trainNo": trainNo,
        "tdate": tdate,
        "stnCode": stnCode,
        "appType": appType,
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

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        return TrainDetails.fromJson(
            Map<String, dynamic>.from(decoded as Map));
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
          "strapptype": "Test",
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
