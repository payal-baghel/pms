
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/loading/loading.dart';
import 'package:flutter_application_1/scanning/scanning.dart';
import 'package:flutter_application_1/l110/app_localizations.dart';
import 'package:flutter_application_1/pages/home/home_provider.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const Color appBarBlue = Color(0xFF1565C0);
  static const Color tileLabelBlue = Color(0xFF1565C0);

  static const String irLogoUrl =
      "https://cris.org.in/img/footer/redlogo.png";

  static const String loadingImageUrl =
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8p8KuW_cX-bGNhlCrqpaPV5UDpU0qPXwHwBON90RsLpgll1oRsWinP17K&s=10";

  static const String unloadingImageUrl =
      "https://www.facebook.com/easternrailwayheadquarter/posts/unloading-of-commodities-from-new-delhi-sealdah-parcel-express-train-after-arriv/3215576995133055/";

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<HomeProvider>().loadSyncStatus();
    });
  }

  Widget _infoLine(String label, String value) {
    return Text(
      "$label: $value",
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
        fontWeight: FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTile({
    required String title,
    required Widget? page,
    String? imageUrl,
    IconData? icon,
    Color? iconColor,
  }) {
    final Widget visual;

    if (imageUrl != null) {
      visual = ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.network(
          imageUrl,
          width: 88,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            icon ?? Icons.local_shipping,
            size: 42,
            color: iconColor ?? Colors.blueGrey,
          ),
        ),
      );
    } else {
      visual = Icon(
        icon,
        size: 46,
        color: iconColor ?? Colors.blueGrey,
      );
    }

    return GestureDetector(
      onTap: page != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => page,
                ),
              )
          : null,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            visual,
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: tileLabelBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Get HomeProvider data
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBlue,
        centerTitle: true,
        toolbarHeight: 56,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "PARCEL MANAGEMENT SYSTEM",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.network(
                irLogoUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(
                  Icons.train,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      // DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: appBarBlue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipOval(
                    child: Image.network(
                      irLogoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.train,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.dashboardTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: appBarBlue,
              ),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // BODY
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFEBEE),
              image: DecorationImage(
                image: NetworkImage(irLogoUrl),
                opacity: 0.06,
                fit: BoxFit.cover,
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

                  // USER INFORMATION FROM PROVIDER
                  _infoLine(
                    "User Id",
                    homeProvider.username,
                  ),

                  const SizedBox(height: 5),

                  _infoLine(
                    "Station Code",
                    homeProvider.station,
                  ),

                  const SizedBox(height: 5),

                  _infoLine(
                    "Loading Sync Pending",
                    "${homeProvider.loadingSyncPending}",
                  ),

                  const SizedBox(height: 5),

                  _infoLine(
                    "UnLoading Sync Pending",
                    "${homeProvider.unLoadingSyncPending}",
                  ),

                  const SizedBox(height: 20),

                  // FIRST ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTile(
                          title: loc.loading,
                          page:  LoadingPage(),
                          imageUrl: loadingImageUrl,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildTile(
                          title: loc.unloading,
                          page: const ScanningPage(),
                          imageUrl: unloadingImageUrl,
                          icon: Icons.local_shipping,
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
                        child: _buildTile(
                          title: loc.reports,
                          page: const ScanningPage(),
                          icon: Icons.bar_chart,
                          iconColor: const Color(0xFF37474F),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildTile(
                          title: loc.prrStatus,
                          page: const ScanningPage(),
                          icon: Icons.search,
                          iconColor: const Color(0xFF2E7D32),
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
    );
  }
}
