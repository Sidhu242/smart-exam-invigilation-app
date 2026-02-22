import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/exam_service.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';
import 'dart:math';

class ScheduleExamPage extends StatefulWidget {
  const ScheduleExamPage({super.key});

  @override
  State<ScheduleExamPage> createState() => _ScheduleExamPageState();
}

class _ScheduleExamPageState extends State<ScheduleExamPage> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _examService = ExamService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  String _generateExamId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[Random().nextInt(chars.length)])
        .join();
  }

  Future<void> _createExam() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _examService.createExam(
        id: _generateExamId(),
        name: _examNameController.text,
        dateTime: dateTime.toString().split('.')[0],
        institution: GlobalState.institution,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created!')),
        );
        context.go('/manage_exams');
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
        title: const Text('Schedule Exam'),
        backgroundColor: AppColors.PRIMARY,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _examNameController,
                decoration: const InputDecoration(labelText: 'Exam Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date'
                    : _selectedDate.toString()),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedTime == null
                    ? 'Select Time'
                    : _selectedTime.toString()),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.PRIMARY,
                  ),
                  child: const Text('Create Exam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
