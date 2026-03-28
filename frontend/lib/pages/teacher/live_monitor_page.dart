import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/constants.dart';

class LiveMonitorPage extends StatefulWidget {
  final String examId;
  const LiveMonitorPage({super.key, required this.examId});

  @override
  State<LiveMonitorPage> createState() => _LiveMonitorPageState();
}

class _LiveMonitorPageState extends State<LiveMonitorPage> {
  WebSocketChannel? _feedChannel;
  WebSocketChannel? _flagsChannel;
  final Map<String, dynamic> _studentFeeds = {}; // {studentId: {name, frame, last_seen}}
  final List<Map<String, dynamic>> _violations = []; 
  bool _isFeedConnected = false;
  bool _isFlagsConnected = false;

  @override
  void initState() {
    super.initState();
    _connectWebSockets();
  }

  void _connectWebSockets() {
    _connectFeed();
    _connectFlags();
  }

  void _connectFeed() {
    final wsUrl = '${AppConfig.WS_URL}/ws/live_monitor/${widget.examId}';
    try {
      _feedChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _feedChannel!.stream.listen((message) {
        if (mounted) {
          final data = jsonDecode(message);
          setState(() {
            _studentFeeds[data['student_id']] = {
              'name': data['student_name'] ?? 'Unknown',
              'frame': data['frame'],
              'last_seen': DateTime.now(),
            };
          });
        }
      }, onDone: () {
        setState(() => _isFeedConnected = false);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _connectFeed();
        });
      }, onError: (err) {
        setState(() => _isFeedConnected = false);
      });
      setState(() => _isFeedConnected = true);
    } catch (e) {
      debugPrint('Feed WS Error: $e');
    }
  }

  void _connectFlags() {
    final wsUrl = '${AppConfig.WS_URL}/ws/flags/${widget.examId}';
    try {
      _flagsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _flagsChannel!.stream.listen((message) {
        if (mounted) {
          final data = jsonDecode(message);
          setState(() {
            _violations.insert(0, data);
            if (_violations.length > 50) _violations.removeLast(); // Keep latest 50
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Alert: ${data['student_name'] ?? data['student_id']} - ${data['violation_type']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }, onDone: () {
        setState(() => _isFlagsConnected = false);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _connectFlags();
        });
      }, onError: (err) {
        setState(() => _isFlagsConnected = false);
      });
      setState(() => _isFlagsConnected = true);
    } catch (e) {
      debugPrint('Flags WS Error: $e');
    }
  }

  @override
  void dispose() {
    _feedChannel?.sink.close();
    _flagsChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUND,
      appBar: AppBar(
        title: Text('Live Monitoring: ${widget.examId}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.circle,
              size: 12,
              color: (_isFeedConnected && _isFlagsConnected) ? Colors.green : Colors.red,
            ),
          ),
          Center(
              child: Text((_isFeedConnected && _isFlagsConnected) ? 'CONNECTED' : 'RECONNECTING',
                  style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: _studentFeeds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_outlined,
                            size: 64, color: AppColors.TEXT_MUTED.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Waiting for students to join...',
                            style: TextStyle(color: AppColors.TEXT_MUTED)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 4 / 3,
                    ),
                    itemCount: _studentFeeds.length,
                    itemBuilder: (context, index) {
                      final studentId = _studentFeeds.keys.elementAt(index);
                      final feed = _studentFeeds[studentId];
                      return _buildStudentCard(studentId, feed);
                    },
                  ),
          ),
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: AppColors.SURFACE,
              border: Border(left: BorderSide(color: AppColors.BORDER)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.BORDER)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Violations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_violations.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _violations.isEmpty
                      ? const Center(
                          child: Text(
                            'No violations detected',
                            style: TextStyle(color: AppColors.TEXT_MUTED),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _violations.length,
                          itemBuilder: (context, index) {
                            final alert = _violations[index];
                            return ListTile(
                              leading: const Icon(Icons.warning, color: Colors.red),
                              title: Text(alert['student_name'] ?? alert['student_id'] ?? 'Unknown'),
                              subtitle: Text(alert['violation_type'] ?? 'Unknown Alert'),
                              trailing: Text(
                                alert['timestamp']?.split(' ').last ?? '',
                                style: const TextStyle(fontSize: 10, color: AppColors.TEXT_MUTED),
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String id, Map<String, dynamic> feed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.BORDER),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: feed['frame'] != null
                ? Image.memory(
                    base64Decode(feed['frame']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    gaplessPlayback: true,
                  )
                : Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white54, size: 48),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.SURFACE,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: $id',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.TEXT_MUTED),
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(feed['last_seen']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(DateTime lastSeen) {
    final isStale = DateTime.now().difference(lastSeen).inSeconds > 5;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isStale ? Colors.grey : Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}
