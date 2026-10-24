import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_application_1/pages/addPrr/models/pwb_load_search_result.dart';
import 'package:flutter_application_1/services/http_client.dart';
import 'package:flutter_application_1/services/login_api.dart';

/// Service for the "Add PWB/PRR" screen (the loading search).
class PrrApi {
  static final http.Client client = ApiClient.createClient();

  static const String searchPwbLoadUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/searchPwbLoad/";

  /// POST /searchPwbLoad/
  ///
  /// Body: {"DETAIL":"{\"PWBLTNO\":...,\"PKGTYPE\":\"\",\"ACT_LOADNO\":...,
  ///               \"VEHICLE_TYPE\":...,\"STNFROM\":...,\"DSTNSTN\":...,
  ///               \"LOAD_DATE\":...,\"STNCODE\":...,\"PRR\":\"PRR\",
  ///               \"APPTYPE\":\"Test/Online\"}"}
  ///
  /// Mentor's flow: before calling the API the input is prepared from the
  /// current session — ACT_LOADNO is a dummy loading number built as
  /// (flag + station + trainNo + vehicle + date), VEHICLE_TYPE/LODE_DATE come
  /// from the Loading screen, and PKGTYPE is empty (unknown before search).
  static Future<PwbLoadSearchResult> searchPwbLoad({
    required String pwbLtNo,
    required String srcStn,
    required String dstStn,
    String pkgType = "",
    String actLoadNo = "",
    String vehicleType = "",
    String loadDate = "",
    String stnCode = "",
    String prr = "PRR",
    String appType = "Online",
  }) async {
    try {
      final detail = <String, String>{
        "PWBLTNO": pwbLtNo,
        "PKGTYPE": pkgType,
        "ACT_LOADNO": actLoadNo,
        "VEHICLE_TYPE": vehicleType,
        "STNFROM": srcStn,
        "DSTNSTN": dstStn,
        "LOAD_DATE": loadDate,
        "STNCODE": stnCode.isEmpty ? srcStn : stnCode,
        "PRR": prr,
        "APPTYPE": appType,
      };

      final response = await client.post(
        Uri.parse(searchPwbLoadUrl),
        headers: {
          "Content-Type": "application/json",
          if (LoginService.sessionCookie != null)
            "cookie": LoginService.sessionCookie!,
        },
        body: jsonEncode({"DETAIL": jsonEncode(detail)}),
      );

      print("SEARCH-PWBLOAD Status: ${response.statusCode}");
      print(
        "SEARCH-PWBLOAD Response: ${response.body.isEmpty ? "(EMPTY BODY)" : response.body}",
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return PwbLoadSearchResult.fromBody(response.body);
      }

      return PwbLoadSearchResult(
        ok: false,
        rawBody: response.body,
        message: "Server returned status ${response.statusCode}",
      );
    } catch (e) {
      print("SEARCH-PWBLOAD Error: $e");
      return PwbLoadSearchResult(ok: false, rawBody: "", message: "Error: $e");
    }
  }
}
