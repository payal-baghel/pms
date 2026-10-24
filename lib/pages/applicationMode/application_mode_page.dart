import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/login/login.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';

class ApplicationModePage extends StatefulWidget {
  final VoidCallback onLanguageToggle;
  final Locale currentLocale;

  const ApplicationModePage({
    super.key,
    required this.onLanguageToggle,
    required this.currentLocale,
  });

  @override
  State<ApplicationModePage> createState() => _ApplicationModePageState();
}

class _ApplicationModePageState extends State<ApplicationModePage> {
  static const String _crisLogoAsset = "assets/images/cris_logo.png";

  bool _showLogin = false;

  // Remember the selected mode ("Test" / "Online") so all API services
  // (getPlatformMaster, getWagonMaster, login, ...) send it as their APPTYPE.
  void _selectMode(String mode) {
    LoginService.appType = mode;
    setState(() => _showLogin = true);
  }

  @override
  Widget build(BuildContext context) {
    // From this selection screen the app opens the login page (splash keeps
    // the routing: after a successful login it swaps to the Welcome page).
    if (_showLogin) {
      return LoginPage(
        onLanguageToggle: widget.onLanguageToggle,
        currentLocale: widget.currentLocale,
      );
    }

    return Scaffold(
      // Shared app bar: same height, font, color and logo as every other page.
      appBar: const PMSAppBar(title: "Parcel Management System"),

      body: DecoratedBox(
        decoration: const BoxDecoration(
          // Neutral grey backdrop: the red/maroon gradient was replaced so it
          // stops competing with the blue app bar and the blue mode buttons.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)],
          ),
        ),
        // Forces the gradient to cover the whole screen, not just the
        // height of the (short) content column.
        child: SizedBox.expand(
          child: SafeArea(
            // SingleChildScrollView keeps the layout responsive: on small
            // screens the column scrolls instead of overflowing/overlapping.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CRIS logo kept rectangular (never stretched or
                          // cropped) on a white card.
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE8EEF5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              _crisLogoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.train,
                                    size: 60,
                                    color: const Color(0xFF1565C0),
                                  ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Test Application (pill button)
                          _pillButton(
                            "TEST APPLICATION",
                            () => _selectMode("Test"),
                          ),

                          const SizedBox(height: 16),

                          // Online Application (same pill styling, below TEST)
                          _pillButton(
                            "ONLINE APPLICATION",
                            () => _selectMode("Online"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ), // SizedBox.expand
        ),
      ),
    );
  }

  Widget _pillButton(String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1565C0),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 46,
          alignment: Alignment.center,
          // Pressed state colour comes from the shared palette.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
