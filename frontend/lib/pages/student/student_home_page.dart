import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';

class StudentHomePage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentHomePage({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _examService = ExamService();
  final _submissionService = SubmissionService();

  bool _isLoading = true;
  List<dynamic> _exams = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final exams = await _examService.getExams(
        institution: GlobalState.institution,
        published: true,
      );
      final summary = await _submissionService.getSummary(widget.studentId);

      setState(() {
        _exams = exams;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.studentName}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('Completed'),
                                Text(
                                  '${_summary['completed_exams'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('Accuracy'),
                                Text(
                                  '${_summary['accuracy'] ?? 'N/A'}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Available Exams',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._exams.map((exam) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(exam['name'] ?? 'Exam'),
                        subtitle: Text(exam['exam_datetime'] ?? 'TBD'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            context.push(
                              '/exam_instruction/${exam['id']}?examName=${Uri.encodeComponent(exam['name'] ?? '')}&studentId=${Uri.encodeComponent(widget.studentId)}',
                            );
                          },
                          child: const Text('Start'),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
