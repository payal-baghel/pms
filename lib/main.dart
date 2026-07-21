import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/api_service.dart';
import 'l10n/view/loading_page.dart';

import 'database_helper.dart';
import 'package:flutter/services.dart';

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

// class LoginPage extends StatefulWidget {
//   final VoidCallback onLanguageToggle;
//   final Locale currentLocale;

//   const LoginPage({
//     super.key,
//     required this.onLanguageToggle,
//     required this.currentLocale,
//   });

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   final stationController = TextEditingController();

//   String deviceId = "Loading...";

//   @override
//   void initState() {
//     super.initState();
//     getDeviceId();
//   }

//   Future<void> getDeviceId() async {
//     final deviceInfo = DeviceInfoPlugin();

//     try {
//       final androidInfo = await deviceInfo.androidInfo;
//       setState(() {
//         deviceId = androidInfo.id;
//       });
//     } catch (e) {
//       setState(() {
//         deviceId = "Unknown";
//       });
//     }
//   }

//   Future<void> login() async {
//     final loc = AppLocalizations.of(context)!;

//     final username = usernameController.text.trim();
//     final password = passwordController.text.trim();
//     final station = stationController.text.trim();

//     final isValid = await ApiService.login(username, password, station);
//     if (!mounted) return;

//     if (isValid) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => DashboardPage(username: username),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(loc.invalidLogin)));
//     }
//   }

//   @override
//   void dispose() {
//     usernameController.dispose();
//     passwordController.dispose();
//     stationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;

//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 6, 133, 172),
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(36, 117, 136, 221),
//         title: const Text("Parcel Management System"),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 15),
//                   child: ElevatedButton(
//                     onPressed: widget.onLanguageToggle,
//                     child: Text(
//                       widget.currentLocale.languageCode == 'en'
//                           ? "हिंदी"
//                           : "English",
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: const EdgeInsets.only(left: 20.0),
//                   child: Text(
//                     loc.loginTitle,
//                     style: const TextStyle(
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromARGB(255, 17, 13, 13),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 25),
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   color: Colors.white,
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: usernameController,
//                         textCapitalization: TextCapitalization.sentences,
//                         inputFormatters: [
//                           TextInputFormatter.withFunction((oldValue, newValue) {
//                             return newValue.copyWith(
//                               text: newValue.text.toUpperCase(),
//                               selection: newValue.selection,
//                             );
//                           }),
//                         ],
//                         decoration: InputDecoration(
//                           hintText: loc.username,
//                           fillColor: Color(0xFFFFFFFF),
//                           suffixIcon: const Icon(Icons.person),
//                           border: InputBorder.none,
//                         ),
//                       ),
//                       const Divider(),
//                       TextField(
//                         controller: passwordController,
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           hintText: loc.password,
//                           suffixIcon: const Icon(Icons.visibility),
//                           border: InputBorder.none,
//                         ),
//                       ),
//                       const Divider(),
//                       TextField(
//                         controller: stationController,
//                         decoration: InputDecoration(
//                           hintText: loc.stationCode,
//                           suffixIcon: const Icon(Icons.train),
//                           border: InputBorder.none,
//                         ),
//                       ),
//                       const Divider(),
//                       const SizedBox(height: 30),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 25),
//                         child: Column(
//                           children: [
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color.fromARGB(
//                                     255,
//                                     6,
//                                     133,
//                                     172,
//                                   ),
//                                   foregroundColor: Colors.white,
//                                 ),
//                                 onPressed: login,
//                                 child: Text(loc.submit),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             SizedBox(width: double.infinity),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 150),
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 20),
//                 child: Column(
//                   children: [
//                     Text(
//                       loc.appType,
//                       style: const TextStyle(fontSize: 20, color: Colors.black),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       loc.appVersion,
//                       style: const TextStyle(fontSize: 20, color: Colors.black),
//                     ),
//                     Text(
//                       loc.deviceId(deviceId),
//                       style: const TextStyle(fontSize: 20, color: Colors.black),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// } **/

class DashboardPage extends StatelessWidget {
  String username;
  DashboardPage({super.key, required this.username});

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
                  const Scaffold(),
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
                  const Scaffold(),
                ),

                buildTile(
                  context,
                  loc.prrStatus,
                  Icons.search,
                  const Scaffold(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
