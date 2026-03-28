import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/exam_service.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';

class ManageExamsPage extends StatefulWidget {
  const ManageExamsPage({super.key});

  @override
  State<ManageExamsPage> createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends State<ManageExamsPage> {
  final _examService = ExamService();
  bool _isLoading = true;
  List<dynamic> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      // Fetch ALL exams (published + unpublished) for this institution
      final exams = await _examService.getAllExams(
        institution: GlobalState.institution,
      );
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exams: $e')),
        );
      }
    }
  }

  Future<void> _publishExam(String examId) async {
    try {
      await _examService.publishExam(examId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam published! Students can now see it.'),
            backgroundColor: AppColors.SUCCESS,
          ),
        );
        _loadExams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exams'),
        backgroundColor: AppColors.PRIMARY,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExams,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No exams yet. Create one from the dashboard.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _exams.length,
                  itemBuilder: (context, idx) {
                    final exam = _exams[idx];
                    final isPublished = exam['published'] == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPublished
                              ? AppColors.SUCCESS.withOpacity(0.1)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exam['name'] ?? 'Untitled Exam',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPublished
                                        ? AppColors.SUCCESS.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPublished
                                          ? AppColors.SUCCESS
                                          : Colors.orange,
                                    ),
                                  ),
                                  child: Text(
                                    isPublished ? 'Published' : 'Draft',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPublished
                                          ? AppColors.SUCCESS
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 14, color: AppColors.TEXT_SECONDARY),
                                const SizedBox(width: 4),
                                Text(
                                  exam['exam_datetime'] ?? 'No time set',
                                  style: const TextStyle(
                                      color: AppColors.TEXT_SECONDARY,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      '/add_question/${exam['id']}?examName=${Uri.encodeComponent(exam['name'] ?? '')}',
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Q'),
                                ),
                                const SizedBox(width: 8),
                                if (!isPublished)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _publishExam(exam['id'].toString()),
                                    icon: const Icon(Icons.publish, size: 16),
                                    label: const Text('Publish'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.SUCCESS,
                                      foregroundColor: Colors.white,
                                    ),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.check_circle,
                                        size: 16, color: AppColors.SUCCESS),
                                    label: const Text('Published',
                                        style: TextStyle(
                                            color: AppColors.SUCCESS)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
