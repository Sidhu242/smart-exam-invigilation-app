import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../config/constants.dart';
import 'dart:math';

class AddQuestionPage extends StatefulWidget {
  final String examId;
  final String examName;

  const AddQuestionPage({
    required this.examId,
    required this.examName,
  });

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  final _examService = ExamService();

  String _questionType = 'mcq';
  int? _correctAnswer;
  bool _isSubmitting = false;

  String _generateQuestionId() {
    return 'Q${Random().nextInt(100000)}';
  }

  Future<void> _addQuestion() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_questionType == 'mcq' && _correctAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select correct answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final options = _optionControllers.map((c) => c.text).toList();
      await _examService.addQuestion(
        id: _generateQuestionId(),
        examId: widget.examId,
        text: _questionController.text,
        type: _questionType,
        options: _questionType == 'mcq' ? options : null,
        correctAnswer: _questionType == 'mcq' ? options[_correctAnswer!] : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added!')),
        );
        _formKey.currentState?.reset();
        _questionController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
        setState(() => _correctAnswer = null);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Question - ${widget.examName}'),
        backgroundColor: AppColors.PRIMARY,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: _questionType,
                onChanged: (v) => setState(() => _questionType = v ?? 'mcq'),
                items: const [
                  DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                  DropdownMenuItem(value: 'essay', child: Text('Essay')),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question Text'),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_questionType == 'mcq')
                Column(
                  children: [
                    ...List.generate(4, (idx) {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _optionControllers[idx],
                            decoration: InputDecoration(
                              labelText: 'Option ${idx + 1}',
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          RadioListTile<int>(
                            title: const Text('Correct Answer'),
                            value: idx,
                            groupValue: _correctAnswer,
                            onChanged: (v) =>
                                setState(() => _correctAnswer = v),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _addQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.PRIMARY,
                  ),
                  child: const Text('Add Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
