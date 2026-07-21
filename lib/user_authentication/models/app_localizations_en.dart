// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get username => 'User ID';

  @override
  String get password => 'Password';

  @override
  String get stationCode => 'Station Code';

  @override
  String get submit => 'LOGIN';

  @override
  String get invalidLogin => 'Invalid Login Credentials';

  @override
  String get appVersion => 'App Version. 3.5';

  @override
  String get appType => 'AppType is Test';

  @override
  String deviceId(Object id) {
    return 'Device ID : $id';
  }

  @override
  String get dashboardTitle => 'PARCEL MANAGEMENT SYSTEM';

  @override
  String get loading => 'Loading';

  @override
  String get unloading => 'Unloading';

  @override
  String get reports => 'Reports';

  @override
  String get prrStatus => 'PRR Status';
}
