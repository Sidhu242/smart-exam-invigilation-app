import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';
import '../../services/auth_service.dart';
import '../../utlis/exceptions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _authService.login(
        _idController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Save to global state
      GlobalState.userId = response['id'] ?? '';
      GlobalState.userName = response['name'] ?? '';
      GlobalState.userRole = response['role'] ?? '';
      GlobalState.institution = response['institution'] ?? '';

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', GlobalState.userId);
      await prefs.setString('userName', GlobalState.userName);
      await prefs.setString('userRole', GlobalState.userRole);
      await prefs.setString('institution', GlobalState.institution);

      // Navigate based on role
      if (response['role'] == 'student') {
        context.go(
          '/student_home?studentId=${Uri.encodeComponent(GlobalState.userId)}&studentName=${Uri.encodeComponent(GlobalState.userName)}',
        );
      } else if (response['role'] == 'teacher') {
        context.go(
          '/teacher_home?teacherId=${Uri.encodeComponent(GlobalState.userId)}&teacherName=${Uri.encodeComponent(GlobalState.userName)}',
        );
      }
    } on ValidationException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
             colors: [
               AppColors.PRIMARY,
               AppColors.PRIMARY_DARK,
             ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.PRIMARY.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 64,
              color: AppColors.PRIMARY,
            ),
          ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue to Smart Exam Invigilation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.TEXT_SECONDARY,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _idController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.ERROR.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.ERROR.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.ERROR, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: AppColors.ERROR, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage.isNotEmpty) const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.TEXT_SECONDARY),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/signup'),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.PRIMARY,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
