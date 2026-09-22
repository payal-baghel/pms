import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/home/home_provider.dart';
import 'package:flutter_application_1/pages/login/login_provider.dart';
import 'package:flutter_application_1/pages/splash/splash_provider.dart';
import 'package:flutter_application_1/pages/splash/splash_screen.dart';
import 'package:flutter_application_1/l110/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const ParcelApp(),
    ),
  );
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
      home: SplashScreen(
        onLanguageToggle: switchLanguage,
        currentLocale: _currentLocale,
      ),
    );
  }
}
