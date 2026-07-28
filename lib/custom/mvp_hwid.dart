import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MvpHwid {
  static String? _cachedHwid;

  /// 获取防重、幂等的设备硬件 ID (HWID)
  static Future<String> getHwid() async {
    if (_cachedHwid != null && _cachedHwid!.isNotEmpty) {
      return _cachedHwid!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHwid = prefs.getString('custom_device_hwid');
      if (storedHwid != null && storedHwid.isNotEmpty) {
        _cachedHwid = storedHwid;
        return storedHwid;
      }

      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
      bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 10
      
      final hwid = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      await prefs.setString('custom_device_hwid', hwid);
      _cachedHwid = hwid;
      return hwid;
    } catch (_) {
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
