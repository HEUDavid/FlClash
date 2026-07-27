import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_clash/common/common.dart';
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

      String rawId = '';
      final deviceInfo = DeviceInfoPlugin();

      if (system.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        rawId =
            '${androidInfo.brand}_${androidInfo.model}_${androidInfo.hardware}_${androidInfo.id}';
      } else if (system.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        rawId = windowsInfo.deviceId;
      } else if (system.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        rawId = macInfo.systemGUID ?? macInfo.computerName;
      } else if (system.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        rawId = linuxInfo.machineId ?? linuxInfo.id;
      } else {
        rawId = DateTime.now().microsecondsSinceEpoch.toString();
      }

      final digest = sha256.convert(utf8.encode('BlockAd_$rawId'));
      final hwid = digest.toString();

      await prefs.setString('custom_device_hwid', hwid);
      _cachedHwid = hwid;
      return hwid;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      var fallbackHwid = prefs.getString('custom_device_hwid');
      if (fallbackHwid == null || fallbackHwid.isEmpty) {
        final digest = sha256.convert(
          utf8.encode(
            'BlockAd_fallback_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        fallbackHwid = digest.toString();
        await prefs.setString('custom_device_hwid', fallbackHwid);
      }
      _cachedHwid = fallbackHwid;
      return fallbackHwid;
    }
  }
}
