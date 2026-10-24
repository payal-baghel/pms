import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/login_api.dart';

class LoginProvider extends ChangeNotifier {
  String _deviceId = "Loading...";
  bool _isLoading = false;

  String get deviceId => _deviceId;
  bool get isLoading => _isLoading;

  Future<void> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
      notifyListeners();
    } catch (e) {
      _deviceId = "Unknown";
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, String station) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isValid = await LoginService.login(username, password, station);
      return isValid;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
