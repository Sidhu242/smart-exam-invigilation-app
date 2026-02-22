import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExamInstructionPage extends StatelessWidget {
  final String examId;
  final String examName;
  final String studentId;

  const ExamInstructionPage({
    required this.examId,
    required this.examName,
    required this.studentId,
  });

  Future<void> _startExam(BuildContext context) async {
    bool canStart = true;

    if (!kIsWeb) {
      final permissions = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      canStart = permissions[Permission.camera]?.isGranted ?? false;
    }

    if (context.mounted) {
      if (canStart) {
        context.go(
          '/take_exam/$examId?examName=${Uri.encodeComponent(examName)}&studentId=${Uri.encodeComponent(studentId)}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF673AB7),
        elevation: 2,
        title: const Text('Exam Instructions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with exam name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF673AB7),
                    const Color(0xFF512DA8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    examName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Instructions section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Important Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInstructionItem(
                    icon: Icons.videocam,
                    title: 'Camera Active',
                    description:
                        'Your face will be monitored during the entire exam',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    icon: Icons.mic,
                    title: 'Audio Monitored',
                    description:
                        'Suspicious sounds will be recorded and flagged',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    icon: Icons.fullscreen_exit,
                    title: 'Keep App in Focus',
                    description:
                        'Switching apps may result in exam termination',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    icon: Icons.person,
                    title: 'Solo Attempt Only',
                    description: 'Another person in view will flag a violation',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    icon: Icons.book,
                    title: 'No External Help',
                    description:
                        'Reference materials are not permitted during exam',
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    icon: Icons.timer,
                    title: 'Time Management',
                    description:
                        'Exam will auto-submit when time limit is reached',
                  ),
                  const SizedBox(height: 32),
                  // Warning box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Multiple violations may result in exam termination and academic penalties.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startExam(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'I Understand - Start Exam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF673AB7),
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF673AB7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
