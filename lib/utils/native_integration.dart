import 'package:flutter/services.dart';

class NativeIntegration {
  static const MethodChannel _channel = MethodChannel('focus_flow/native');

  // Request Usage Stats Permission (Android)
  static Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'.");
    }
  }

  // Request Overlay Permission (Android) for jumping back to app
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print("Failed to request overlay permission: '${e.message}'.");
    }
  }

  // Get installed apps (Android)
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      return apps.map((e) => Map<String, String>.from(e)).toList();
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'.");
      return [];
    }
  }

  // Start the persistent service
  static Future<void> startPersistentService(List<String> blockedApps) async {
    try {
      await _channel.invokeMethod('startService', {'blockedApps': blockedApps});
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
    }
  }

  // Stop the persistent service
  static Future<void> stopPersistentService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print("Failed to stop service: '${e.message}'.");
    }
  }
}
