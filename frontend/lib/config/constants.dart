import 'package:flutter/material.dart';

class AppConfig {
  // Server Configuration
  static const String SERVER_URL = "http://localhost:5000";
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
  static const String PUBLISH_EXAM = "/publish_exam";
  static const String DELETE_EXAM = "/delete_exam";
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
  static const Color PRIMARY = Color(0xFF673AB7);
  static const Color SECONDARY = Color(0xFF512DA8);
  static const Color BACKGROUND = Color(0xFFF3F0FA);
  static const Color SUCCESS = Color(0xFF4CAF50);
  static const Color ERROR = Color(0xFFF44336);
  static const Color WARNING = Color(0xFFFFC107);
}
