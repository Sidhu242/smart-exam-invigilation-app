import 'package:flutter/material.dart';

class ViolationCard extends StatelessWidget {
  final String studentName;
  final String violationType;
  final String severity; // 'low', 'medium', 'high'
  final String timestamp;
  final String description;
  final int violationCount;

  const ViolationCard({
    Key? key,
    required this.studentName,
    required this.violationType,
    required this.severity,
    required this.timestamp,
    required this.description,
    required this.violationCount,
  }) : super(key: key);

  Color _getSeverityColor() {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.amber;
    }
  }

  IconData _getViolationIcon() {
    switch (violationType.toLowerCase()) {
      case 'face_not_detected':
        return Icons.face;
      case 'multiple_faces':
        return Icons.group;
      case 'app_switch':
        return Icons.switch_account;
      case 'suspicious_audio':
        return Icons.mic;
      case 'copy_paste':
        return Icons.content_copy;
      case 'tab_switch':
        return Icons.tab;
      default:
        return Icons.warning;
    }
  }

  String _getViolationLabel() {
    switch (violationType.toLowerCase()) {
      case 'face_not_detected':
        return 'Face Not Detected';
      case 'multiple_faces':
        return 'Multiple Faces';
      case 'app_switch':
        return 'App Switch';
      case 'suspicious_audio':
        return 'Suspicious Audio';
      case 'copy_paste':
        return 'Copy/Paste Activity';
      case 'tab_switch':
        return 'Tab Switch';
      default:
        return violationType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: _getSeverityColor(),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getSeverityColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getViolationIcon(),
                    color: _getSeverityColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getViolationLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSeverityColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSeverityColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${severity[0].toUpperCase()}${severity.substring(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getSeverityColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                // Violation count badge
                if (violationCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: violationCount >= 3
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Violation ${violationCount}/3',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: violationCount >= 3 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            if (violationCount >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Exam auto-submitted due to multiple violations',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Summary stats widget
class ViolationStats extends StatelessWidget {
  final int totalViolations;
  final int highSeverity;
  final int mediumSeverity;
  final int lowSeverity;

  const ViolationStats({
    Key? key,
    required this.totalViolations,
    required this.highSeverity,
    required this.mediumSeverity,
    required this.lowSeverity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            label: 'Total',
            value: totalViolations.toString(),
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.2),
          ),
          _buildStatItem(
            label: 'High',
            value: highSeverity.toString(),
            color: Colors.red,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.2),
          ),
          _buildStatItem(
            label: 'Medium',
            value: mediumSeverity.toString(),
            color: Colors.orange,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.2),
          ),
          _buildStatItem(
            label: 'Low',
            value: lowSeverity.toString(),
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
