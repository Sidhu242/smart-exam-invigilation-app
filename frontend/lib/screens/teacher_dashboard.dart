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
        appBar: AppBar(title: Text('Teacher Dashboard')),
        body: Consumer<WebSocketService>(
          builder: (context, wsService, _) {
            final flags = wsService.flags;
            if (flags.isEmpty) {
              return Center(child: Text('No flags yet'));
            }
            return ListView.builder(
              itemCount: flags.length,
              itemBuilder: (context, index) {
                final flag = flags[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title:
                        Text('Student: ${flag['student_name'] ?? 'Unknown'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Violation: ${flag['violation_type']}'),
                        Text('Confidence: ${flag['confidence']}'),
                        Text('Timestamp: ${flag['timestamp']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
