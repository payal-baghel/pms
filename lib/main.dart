import 'package:flutter/material.dart';
import 'package:flutter_application_1/user_authentication/models/app_localizations.dart';
import 'package:flutter_application_1/user_authentication/view/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParcelApp());
}

class ParcelApp extends StatefulWidget {
  const ParcelApp({super.key});

  @override
  State<ParcelApp> createState() => _ParcelAppState();
}

class _ParcelAppState extends State<ParcelApp> {
  Locale _currentLocale = const Locale('en');

  void switchLanguage() {
    setState(() {
      _currentLocale = _currentLocale.languageCode == 'en'
          ? const Locale('hi')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _currentLocale,
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginPage(
        onLanguageToggle: switchLanguage,
        currentLocale: _currentLocale,
      ),
    );
  }
}
