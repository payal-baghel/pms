import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/splash/splash_provider.dart';
import 'package:flutter_application_1/scanning/scanning.dart';
import 'package:provider/provider.dart';

/// Shared navigation drawer used by the Welcome and Loading summary pages
/// so that the 3-line menu looks and behaves identically everywhere.
class PmsDrawer {
  PmsDrawer._();

  // Shared design system (single source of truth).
  static const Color _railBlueDark = const Color(0xFF0D2E5C);
  static const Color _railBlue = const Color(0xFF1565C0);
  static const Color _railBlueLight = const Color(0xFF1E88E5);
  static const String _irLogoUrl = "https://cris.org.in/img/footer/redlogo.png";

  static Widget build(
    BuildContext context, {
    required String username,
    required String station,
  }) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 132,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_railBlueLight, _railBlue, _railBlueDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipOval(
                  child: Image.network(
                    _irLogoUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.train, color: Colors.white, size: 44),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _drawerItem(Icons.home, "Home", () {
            Navigator.pop(context);
            // Welcome is the root screen; open pages stack on top of it.
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
          _drawerDivider(),
          _drawerItem(Icons.grid_view, "Mis Report", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanningPage()),
            );
          }),
          _drawerDivider(),
          _drawerItem(Icons.search, "PRR Status", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanningPage()),
            );
          }),
          _drawerDivider(),
          _drawerItem(Icons.qr_code, "Print Barcode", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanningPage()),
            );
          }),
          _drawerDivider(),
          _drawerItem(
            Icons.delete_outline,
            "Delete Old Data",
            () => Navigator.pop(context),
          ),
          _drawerDivider(),
          _drawerItem(
            Icons.star_border,
            "Reload Masters",
            () => Navigator.pop(context),
          ),
          _drawerDivider(),
          _drawerItem(Icons.logout, "Log Out", () {
            Navigator.pop(context); // drawer band
            context.read<SplashViewModel>().logout();
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              "PMS v2.0",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _drawerDivider() =>
      const Divider(height: 1, thickness: 1, color: const Color(0xFFE8EEF5));

  static Widget _drawerItem(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _railBlue),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: const Color(0xFF111111),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
