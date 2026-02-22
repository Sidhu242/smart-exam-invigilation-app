import 'package:go_router/go_router.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'student/student_home_page.dart';
import 'student/exam_instruction_page.dart';
import 'student/take_exam_page.dart';
import 'teacher/teacher_home_page.dart';
import 'teacher/schedule_exam_page.dart';
import 'teacher/manage_exams_page.dart';
import 'teacher/add_question_page.dart';
import 'teacher/exam_results_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),

      // Student Routes
      GoRoute(
        path: '/student_home',
        builder: (context, state) {
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          final studentName = state.uri.queryParameters['studentName'] ?? '';
          return StudentHomePage(
            studentId: studentId,
            studentName: studentName,
          );
        },
      ),
      GoRoute(
        path: '/exam_instruction/:examId',
        builder: (context, state) {
          final examId = state.pathParameters['examId'] ?? '';
          final examName = state.uri.queryParameters['examName'] ?? '';
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return ExamInstructionPage(
            examId: examId,
            examName: examName,
            studentId: studentId,
          );
        },
      ),
      GoRoute(
        path: '/take_exam/:examId',
        builder: (context, state) {
          final examId = state.pathParameters['examId'] ?? '';
          final examName = state.uri.queryParameters['examName'] ?? '';
          final studentId = state.uri.queryParameters['studentId'] ?? '';
          return TakeExamPage(
            examId: examId,
            examName: examName,
            studentId: studentId,
          );
        },
      ),

      // Teacher Routes
      GoRoute(
        path: '/teacher_home',
        builder: (context, state) {
          final teacherId = state.uri.queryParameters['teacherId'] ?? '';
          final teacherName = state.uri.queryParameters['teacherName'] ?? '';
          return TeacherHomePage(
            teacherId: teacherId,
            teacherName: teacherName,
          );
        },
      ),
      GoRoute(
        path: '/schedule_exam',
        builder: (context, state) => const ScheduleExamPage(),
      ),
      GoRoute(
        path: '/manage_exams',
        builder: (context, state) => const ManageExamsPage(),
      ),
      GoRoute(
        path: '/add_question/:examId',
        builder: (context, state) {
          final examId = state.pathParameters['examId'] ?? '';
          final examName = state.uri.queryParameters['examName'] ?? '';
          return AddQuestionPage(
            examId: examId,
            examName: examName,
          );
        },
      ),
      GoRoute(
        path: '/exam_results/:examId',
        builder: (context, state) {
          final examId = state.pathParameters['examId'] ?? '';
          return ExamResultsPage(examId: examId);
        },
      ),
    ],
  );
}
