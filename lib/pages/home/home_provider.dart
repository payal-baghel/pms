import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  // Logged-in user information
  String _username = "";
  String _station = "";

  // Sync pending counts
  int _loadingSyncPending = 0;
  int _unLoadingSyncPending = 0;

  // Getters
  String get username => _username;
  String get station => _station;

  int get loadingSyncPending => _loadingSyncPending;
  int get unLoadingSyncPending => _unLoadingSyncPending;

  // Save logged-in user information
  void setUserData({required String username, required String station}) {
    _username = username;
    _station = station;

    notifyListeners();
  }

  // Load sync status
  Future<void> loadSyncStatus() async {
    // API call will be added here later.

    _loadingSyncPending = 0;
    _unLoadingSyncPending = 0;

    notifyListeners();
  }
}
