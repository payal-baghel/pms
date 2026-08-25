// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get loginTitle => 'उपयोगकर्ता लॉगिन';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get stationCode => 'स्टेशन कोड';

  @override
  String get submit => 'जमा करें';

  @override
  String get invalidLogin => 'अमान्य लॉगिन जानकारी';

  @override
  String get appVersion => 'ऐप संस्करण. 3.0';

  @override
  String get appType => 'ऐप प्रकार ऑनलाइन है';

  @override
  String deviceId(Object id) {
    return 'डिवाइस आईडी : $id';
  }

  @override
  String get dashboardTitle => 'पार्सल प्रबंधन प्रणाली';

  @override
  String get loading => 'लोडिंग';

  @override
  String get unloading => 'अनलोडिंग';

  @override
  String get reports => 'रिपोर्ट्स';

  @override
  String get prrStatus => 'पीआरआर स्थिति';
}
