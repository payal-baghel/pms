import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/applicationMode/application_mode_page.dart';
import 'package:flutter_application_1/pages/home/welcome.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // Dynamic pulsing effect on the logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoScale = _logoController.drive(Tween<double>(begin: 1.0, end: 1.10));

    Future.microtask(() {
      context.read<SplashViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isLoading) {
          if (viewModel.isLoggedIn) {
            return const WelcomePage();
          }
          return ApplicationModePage(
            onLanguageToggle: widget.onLanguageToggle,
            currentLocale: widget.currentLocale,
          );
        }

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFF5F7F8), Colors.white],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dynamic (pulsing) circular train logo — dark on light bg
                Center(
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1565C0),
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F006B5F),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.train,
                        size: 64,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main title — centre aligned, dark colour
                const Text(
                  'PARCEL MANAGEMENT SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle accent
                const Text(
                  'Indian Railway Parcel Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 32),

                // Theme-matching loader
                const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
