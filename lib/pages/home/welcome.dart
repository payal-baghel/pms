import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/home/home_provider.dart';
import 'package:flutter_application_1/pages/home/pms_drawer.dart';
import 'package:flutter_application_1/pages/loading/loading.dart';
import 'package:flutter_application_1/scanning/scanning.dart';
import 'package:flutter_application_1/l110/app_localizations.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // ---------- Official railways-inspired palette ----------
  static const Color _railBlueDark = Color(0xFF0D2E5C);
  static const Color _railBlue = Color(0xFF1565C0);
  static const Color _accentRed = Color(0xFFD32F2F);
  static const Color _accentAmber = Color(0xFFFFA000);
  static const Color _bgTop = Color(0xFFEAF3FC);
  static const Color _bgBottom = Color(0xFFF7FAFD);

  // The app bar logo is supplied centrally by PMSAppBar.defaultLogoUrl.
  static const String _heroImageUrl =
      "https://commons.wikimedia.org/wiki/Special:FilePath/LHB_AC_2_tier_coach_of_Golden_Temple_Mail.jpg?width=1200";

  late final AnimationController _entrance;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<HomeProvider>().loadSyncStatus();
    });

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  // ---------- Hero banner (train image + animated sheen + user info) ----------

  Widget _infoChip(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            "$label: $value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSection(HomeProvider homeProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Railway image background
            Image.network(
              _heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_railBlue, _railBlueDark],
                  ),
                ),
                child: const Icon(
                  Icons.train,
                  color: Colors.white38,
                  size: 120,
                ),
              ),
            ),
            // Dark overlay for contrast
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black45, Color(0xD9133A6B)],
                ),
              ),
            ),
            // Animated moving sheen (dynamic effect)
            ClipRect(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  final width = MediaQuery.of(context).size.width;
                  final shift = (_shimmer.value * 2) - 1;
                  return Transform.translate(
                    offset: Offset(shift * width, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 90,
                        transform: Matrix4.rotationZ(0.4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Content on top
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.train, color: Colors.white70, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "INDIAN RAILWAYS • PARCELS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "Namaste, ${homeProvider.username}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Station: ${homeProvider.station}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _infoChip(
                          "Loading Sync",
                          "${homeProvider.loadingSyncPending}",
                          Icons.cloud_sync,
                          _accentAmber,
                        ),
                        _infoChip(
                          "Unloading Sync",
                          "${homeProvider.unLoadingSyncPending}",
                          Icons.cloud_off,
                          _accentRed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Service module card (animated) ----------

  Widget _moduleCard({
    required String title,
    required String caption,
    required IconData icon,
    required Color color,
    required int index,
    required Widget page,
  }) {
    final entrance = CurvedAnimation(
      parent: _entrance,
      curve: Interval(0.25 + (index * 0.15), 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(entrance),
        child: Material(
          color: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.09),
                    Colors.white,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated top accent bar
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.45)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, size: 26, color: color),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: color.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF607D8B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      appBar: const PMSAppBar(
        title: "Parcel Management System",
        showDrawer: true,
      ),

      drawer: PmsDrawer.build(
        context,
        username: homeProvider.username,
        station: homeProvider.station,
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgBottom],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _heroSection(homeProvider),
                  const SizedBox(height: 22),

                  // Section heading
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_railBlue, _accentAmber],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "SERVICE MODULES",
                        style: TextStyle(
                          fontSize: 16,
                          color: _railBlueDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // FIRST ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _moduleCard(
                          title: loc.loading,
                          caption: "Loading Summary",
                          icon: Icons.local_shipping,
                          color: const Color(0xFF1565C0),
                          index: 0,
                          page: const LoadingPage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _moduleCard(
                          title: loc.unloading,
                          caption: "Unloading Summary",
                          icon: Icons.unarchive_outlined,
                          color: const Color(0xFF2E7D32),
                          index: 1,
                          page: const ScanningPage(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // SECOND ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _moduleCard(
                          title: loc.reports,
                          caption: "Mis Report",
                          icon: Icons.bar_chart,
                          color: const Color(0xFFEF6C00),
                          index: 2,
                          page: const ScanningPage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _moduleCard(
                          title: loc.prrStatus,
                          caption: "Track Consignment",
                          icon: Icons.search,
                          color: const Color(0xFF6A1B9A),
                          index: 3,
                          page: const ScanningPage(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 2,
                          width: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_railBlue, _accentRed],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Powered by CRIS  •  Centre for Railway Information Systems",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78909C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
