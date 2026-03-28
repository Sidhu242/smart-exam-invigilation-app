import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class TeacherDashboard extends StatelessWidget {
  final int examId;
  const TeacherDashboard({Key? key, required this.examId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final wsService = WebSocketService();
        wsService.connect(examId);
        return wsService;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Live Proctoring Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF673AB7),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildMonitoringSummary(),
            Expanded(
              child: Consumer<WebSocketService>(
                builder: (context, wsService, _) {
                  final flags = wsService.flags;
                  if (flags.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 80, color: Colors.green.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'Strict monitoring active.\nNo violations detected yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: flags.length,
                    itemBuilder: (context, index) {
                      final flag = flags[flags.length - 1 - index];
                      return _buildFlagCard(flag);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF673AB7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Monitoring", "ACTIVE", Icons.lens, Colors.greenAccent),
          _summaryItem("Integrity", "SECURE", Icons.verified_user, Colors.white),
          _summaryItem("Exam ID", "#$examId", Icons.tag, Colors.white70),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color valueColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildFlagCard(Map<String, dynamic> flag) {
    final violationType = flag['violation_type']?.toString().toUpperCase() ?? 'UNKNOWN';
    final timestamp = flag['timestamp'] ?? 'Just now';
    final confidence = (double.tryParse((flag['confidence'] ?? 1.0).toString()) ?? 1.0) * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Text(
                  violationType,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  timestamp,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 20,
                  child: Text(flag['student_name']?[0] ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag['student_name'] ?? 'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI Confidence: ${confidence.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View Proof', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
