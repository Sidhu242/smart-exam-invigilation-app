import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService with ChangeNotifier {
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _flags = [];

  List<Map<String, dynamic>> get flags => _flags;

  void connect(int examId) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://sidhu2005-seis-backend.hf.space/ws/flags/$examId'),
    );
    _channel!.stream.listen((event) {
      final data = jsonDecode(event);
      _flags.add(data);
      notifyListeners();
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
