import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MvpHwid {
  static String? _cachedHwid;

  /// 获取防重、幂等的设备硬件 ID (HWID)
  /// 优先从 SharedPreferences 中读取；首次启动生成高熵 UUID 并持久化，
  /// 应用覆盖升级时 SharedPreferences 自动完整保留，确保 HWID 绝对幂等且无设备冲突。
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

      // 生成安全的 128 位 UUID (Hex 格式)
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
      bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 10

      final hwid =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      await prefs.setString('custom_device_hwid', hwid);
      _cachedHwid = hwid;
      return hwid;
    } catch (_) {
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

