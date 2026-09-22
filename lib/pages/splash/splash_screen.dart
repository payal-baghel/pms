import 'package:flutter/material.dart';
import 'package:flutter_application_1/constant/app_color.dart';
import 'package:flutter_application_1/pages/login/login.dart';
import 'package:flutter_application_1/pages/splash/splash_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onLanguageToggle;
  final Locale currentLocale;

  const SplashScreen({
    super.key,
    required this.onLanguageToggle,
    required this.currentLocale,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<SplashViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isLoading) {
          return LoginPage(
            onLanguageToggle: widget.onLanguageToggle,
            currentLocale: widget.currentLocale,
          );
        }

        return const Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.train, size: 80, ),//color: AppColors.primary

              SizedBox(height: 20),

              Text(
                'PARCEL MANAGEMENT SYSTEM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  // color: AppColors.primaryBlue,
                ),
              ),

              SizedBox(height: 20),

              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }
}
