import 'package:flutter/material.dart';
import 'package:flutter_application_1/loading/loading_page.dart';
import 'package:flutter_application_1/user_authentication/models/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  String username;
  WelcomePage({super.key, required this.username});

  Widget buildTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget? page,
  ) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
      child: Container(
        width: 150,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 43, 138, 216),
                fontWeight: FontWeight.bold,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.dashboardTitle),
        backgroundColor: Colors.green,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Logout code
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Welcome , $username", style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 10),

            const SizedBox(height: 10),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildTile(
                  context,
                  loc.loading,
                  Icons.train,
                  const LoadingPage(),
                ),

                buildTile(
                  context,
                  loc.unloading,
                  Icons.inventory,
                  const LoadingPage(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildTile(
                  context,
                  loc.reports,
                  Icons.bar_chart,
                  const LoadingPage(),
                ),

                buildTile(
                  context,
                  loc.prrStatus,
                  Icons.search,
                  const LoadingPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
