import 'dart:async';
import 'package:flutter/material.dart';

class ExamTimer extends StatefulWidget {
  final int durationInSeconds;
  final VoidCallback onTimerEnd;

  const ExamTimer({
    super.key,
    required this.durationInSeconds,
    required this.onTimerEnd,
  });

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationInSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        widget.onTimerEnd();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _remainingSeconds < 300; // 5 minutes
    final isCritical = _remainingSeconds < 60; // 1 minute

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCritical
            ? Colors.red
            : isWarning
                ? Colors.orange
                : Colors.green,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatTime(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
