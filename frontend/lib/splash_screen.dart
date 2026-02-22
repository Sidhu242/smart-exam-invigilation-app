import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool('isLoggedIn') ?? false;

    final currentURL = Uri.base.path; // <-- MAGIC FIX

    // If already logged in, restore page by URL
    if (logged) {
      if (currentURL.startsWith("/student")) {
        Navigator.pushReplacementNamed(context, "/student");
        return;
      }
      if (currentURL.startsWith("/teacher")) {
        Navigator.pushReplacementNamed(context, "/teacher");
        return;
      }
    }

    // URLs without login
    if (currentURL.startsWith("/signup")) {
      Navigator.pushReplacementNamed(context, "/signup");
      return;
    }

    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 120),
      ),
    );
  }
}
