import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/app_router.dart';
import 'config/constants.dart';
import 'config/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load session from SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    GlobalState.userId = prefs.getString('userId') ?? '';
    GlobalState.userName = prefs.getString('userName') ?? '';
    GlobalState.userRole = prefs.getString('userRole') ?? '';
    GlobalState.institution = prefs.getString('institution') ?? '';
    
    debugPrint('Loaded session: ${GlobalState.userId}, ${GlobalState.userRole}');
  } catch (e) {
    debugPrint('Error loading session: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Exam Invigilation',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.PRIMARY,
          primary: AppColors.PRIMARY,
          secondary: AppColors.SECONDARY,
          surface: AppColors.SURFACE,
          error: AppColors.ERROR,
        ),
        scaffoldBackgroundColor: AppColors.BACKGROUND,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.SURFACE,
          foregroundColor: AppColors.TEXT_PRIMARY,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.TEXT_PRIMARY),
          titleTextStyle: TextStyle(
            color: AppColors.TEXT_PRIMARY,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.SURFACE,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.SURFACE,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.PRIMARY, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.ERROR, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.TEXT_SECONDARY),
          prefixIconColor: AppColors.TEXT_SECONDARY,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AppColors.TEXT_PRIMARY, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AppColors.TEXT_PRIMARY, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: AppColors.TEXT_PRIMARY, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.TEXT_PRIMARY),
          bodyMedium: TextStyle(color: AppColors.TEXT_SECONDARY),
        ),
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
