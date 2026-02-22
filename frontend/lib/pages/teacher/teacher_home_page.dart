import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';

class TeacherHomePage extends StatelessWidget {
  final String teacherId;
  final String teacherName;

  const TeacherHomePage({
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: AppColors.PRIMARY,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              GlobalState.clear();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $teacherName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildOption(
              context,
              icon: Icons.add_circle,
              title: 'Schedule Exam',
              subtitle: 'Create and schedule a new exam',
              onTap: () => context.go('/schedule_exam'),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.manage_accounts,
              title: 'Manage Exams',
              subtitle: 'View, edit, and manage exams',
              onTap: () => context.go('/manage_exams'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.PRIMARY),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}
