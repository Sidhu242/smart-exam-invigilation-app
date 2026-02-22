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
    try {
      final exams = await _examService.getExams(
        institution: GlobalState.institution,
        published: false,
      );
      setState(() {
        _exams = exams;
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
        title: const Text('Manage Exams'),
        backgroundColor: AppColors.PRIMARY,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _exams.length,
              itemBuilder: (context, idx) {
                final exam = _exams[idx];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(exam['name'] ?? 'Exam'),
                    subtitle: Text(exam['exam_datetime'] ?? 'TBD'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/add_question/${exam['id']}?examName=${Uri.encodeComponent(exam['name'] ?? '')}',
                        );
                      },
                      child: const Text('Add Q'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
