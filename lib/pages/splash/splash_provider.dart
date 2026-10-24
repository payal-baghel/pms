import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/login_api.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 3));

    _isLoading = false;
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  void logout() {
    LoginService.loggedInUserId = null;
    LoginService.loggedInPassword = null;
    LoginService.loggedInStation = null;
    LoginService.sessionCookie = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
