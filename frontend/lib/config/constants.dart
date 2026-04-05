import 'package:flutter/material.dart';

class AppConfig {
  // Server Configuration
  static const String SERVER_URL = "https://sidhu2005-seis-backend.hf.space";
  static String get WS_URL => SERVER_URL.replaceFirst('http', 'ws');
  static const Duration CONNECT_TIMEOUT = Duration(seconds: 30);
  static const Duration RECEIVE_TIMEOUT = Duration(seconds: 30);

  // Exam Configuration
  static const int DEFAULT_EXAM_DURATION_MINUTES = 60;
  static const int EXAM_WARNING_THRESHOLD = 3;

  // API Endpoints
  static const String LOGIN = "/login";
  static const String SIGNUP = "/signup";
  static const String CREATE_EXAM = "/create_exam";
  static const String GET_EXAMS = "/get_exams";
  static const String GET_ALL_EXAMS = "/get_all_exams";
  static const String PUBLISH_EXAM = "/publish_exam";
  static const String DELETE_EXAM = "/delete_exam";
  static const String CLOSE_EXAM = "/close_exam";
  static const String ADD_QUESTION = "/add_question";
  static const String GET_QUESTIONS = "/get_questions";
  static const String SUBMIT_ANSWER = "/submit_answer";
  static const String SUBMIT_EXAM = "/submit_exam";
  static const String LOG_TAB_SWITCH = "/log_tab_switch";
  static const String GET_WARNINGS = "/get_warnings";
  static const String GET_EXAM_RESULTS = "/get_exam_results";
  static const String GET_SUMMARY = "/get_summary";
}

class AppStrings {
  // Errors
  static const String NETWORK_ERROR = "Network connection failed";
  static const String SERVER_ERROR = "Server error. Please try again later.";
  static const String INVALID_CREDENTIALS = "Invalid ID or password.";
  static const String EXAM_LOAD_FAILED = "Failed to load exam questions.";
  static const String SUBMISSION_FAILED = "Failed to submit exam.";
  static const String MISSING_FIELDS = "Please fill all required fields";

  // Success
  static const String EXAM_SUBMITTED = "Exam submitted successfully!";
  static const String LOGIN_SUCCESS = "Login successful!";
  static const String ANSWER_SAVED = "Answer saved";
}

class AppColors {
  // Primary & Secondary Brand Colors
  static const Color PRIMARY = Color(0xFF2563EB);     // SaaS Blue
  static const Color PRIMARY_DARK = Color(0xFF1D4ED8);
  static const Color PRIMARY_LIGHT = Color(0xFFDBEAFE);
  static const Color SECONDARY = Color(0xFF8B5CF6);   // Deep Purple
  static const Color SECONDARY_LIGHT = Color(0xFFEDE9FE);

  // Backgrounds & Surfaces
  static const Color BACKGROUND = Color(0xFFF3F4F6);  // Light Gray 
  static const Color SURFACE = Colors.white;          // White cards
  
  // Status Colors 
  static const Color SUCCESS = Color(0xFF10B981);     // Emerald green
  static const Color SUCCESS_LIGHT = Color(0xFFD1FAE5);
  static const Color ERROR = Color(0xFFEF4444);       // Red
  static const Color ERROR_LIGHT = Color(0xFFFEE2E2);
  static const Color WARNING = Color(0xFFF59E0B);     // Amber
  static const Color WARNING_LIGHT = Color(0xFFFEF3C7);
  static const Color INFO = Color(0xFF3B82F6);        // Blue
  static const Color INFO_LIGHT = Color(0xFFEFF6FF);

  // Typography 
  static const Color TEXT_PRIMARY = Color(0xFF111827);   // Almost black
  static const Color TEXT_SECONDARY = Color(0xFF6B7280); // Gray 500
  static const Color TEXT_MUTED = Color(0xFF9CA3AF);     // Gray 400

  // Borders
  static const Color BORDER = Color(0xFFE5E7EB);         // Gray 200

  static const LinearGradient PRIMARY_GRADIENT = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PRIMARY, PRIMARY_DARK],
  );
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.TEXT_SECONDARY,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.TEXT_MUTED,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
