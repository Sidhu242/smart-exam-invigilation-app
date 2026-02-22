import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() => _instance;

  PermissionService._internal();

  /// Request camera and microphone permissions
  /// Returns true if both are granted
  Future<bool> requestExamPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  /// Request only camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request only microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// Check if both are granted
  Future<bool> areBothGranted() async {
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    return camera && microphone;
  }

  /// Open app settings to grant permissions manually
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
