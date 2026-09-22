import 'package:flutter/material.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 3));

    _isLoading = false;
    notifyListeners();
  }
}