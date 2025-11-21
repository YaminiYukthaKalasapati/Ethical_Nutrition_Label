import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  final Battery _battery = Battery();

  // Get battery level
  Future<String> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return '$level%';
    } catch (e) {
      return 'N/A';
    }
  }

  // Get OS type
  String getOSType() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  // Get platform name
  String getPlatformName() {
    if (kIsWeb) return 'Web';
    return getOSType();
  }

  // Check if mobile
  bool isMobile() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // Check if desktop
  bool isDesktop() {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }
}
