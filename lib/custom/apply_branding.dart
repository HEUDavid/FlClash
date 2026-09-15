// ignore_for_file: depend_on_referenced_packages, require_trailing_commas

import 'dart:io';

import 'package:args/args.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'app-name',
      defaultsTo: Platform.environment['APP_NAME'] ?? 'BlockAd',
      help: 'The display name of the application',
    )
    ..addOption(
      'scheme',
      help: 'Custom URL scheme (default: lowercased app-name)',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    );

  final results = parser.parse(args);
  if (results['help'] as bool) {
    stdout.writeln('Usage: dart lib/custom/apply_branding.dart [options]');
    stdout.writeln(parser.usage);
    return;
  }
  final appName = results['app-name'] as String;
  final customScheme = (results['scheme'] as String?) ??
      appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  stdout.writeln('Applying Branding Configuration:');
  stdout.writeln('  App Name:      $appName');
  stdout.writeln(
      '  Package Name:  (unchanged, keeping original com.follow.clash)',
  );
  stdout.writeln('  Custom Scheme: $customScheme');
  stdout.writeln();

  // 1. 替换 Flutter 侧应用名称常量
  _replaceInFile(
    path: 'lib/common/constant.dart',
    replacements: [
      (
        RegExp(r"const appName\s*=\s*'[^']+'\s*;"),
        "const appName = '$appName';",
      ),
    ],
  );

  // 2. 添加 Android 主清单 DeepLink Scheme (保持 android:label="@string/app_name" 规范资源引用)
  if (customScheme != 'flclash') {
    _replaceInFile(
      path: 'android/app/src/main/AndroidManifest.xml',
      replacements: [
        (
          RegExp(
              r'<data android:scheme="flclash"\s*/>(?!\s*<data android:scheme=)'),
          '<data android:scheme="flclash" />\n                <data android:scheme="$customScheme" />',
        ),
      ],
    );
  }

  // 3. 替换 Android Debug 模式 Label
  _replaceInFile(
    path: 'android/app/src/debug/AndroidManifest.xml',
    replacements: [
      (
        RegExp(r'android:label="[^"]+"'),
        'android:label="$appName Debug"',
      ),
    ],
  );

  // 4. 替换 Android 原生字符串资源
  _replaceInFile(
    path: 'android/common/src/main/res/values/strings.xml',
    replacements: [
      (
        RegExp(r'<string name="app_name">.*?</string>'),
        '<string name="app_name">$appName</string>',
      ),
      (
        RegExp(r'<string name="service_channel_name">.*?</string>'),
        '<string name="service_channel_name">$appName Service</string>',
      ),
    ],
  );

  // 5. 替换前台通知服务标题
  _replaceInFile(
    path:
        'android/service/src/main/java/com/follow/clash/service/modules/NotificationModule.kt',
    replacements: [
      (
        RegExp(r'setContentTitle\("[^"]+"\)'),
        'setContentTitle("$appName")',
      ),
    ],
  );

  // 6. 替换通知默认参数标题
  _replaceInFile(
    path:
        'android/service/src/main/java/com/follow/clash/service/models/NotificationParams.kt',
    replacements: [
      (
        RegExp(r'val title:\s*String\s*=\s*"[^"]+"'),
        'val title: String = "$appName"',
      ),
    ],
  );

  // 7. 替换全局原生状态常量与日志 Prefix
  _replaceInFile(
    path: 'android/common/src/main/java/com/follow/clash/common/GlobalState.kt',
    replacements: [
      (
        RegExp(r'const val NOTIFICATION_CHANNEL\s*=\s*"[^"]+"'),
        'const val NOTIFICATION_CHANNEL = "$appName"',
      ),
      (
        RegExp(r'Log\.d\("FlClash"'),
        'Log.d("$appName"',
      ),
    ],
  );

  // 8. 替换原生 State 默认配置名称
  _replaceInFile(
    path: 'android/app/src/main/kotlin/com/follow/clash/models/State.kt',
    replacements: [
      (
        RegExp(r'val currentProfileName:\s*String\s*=\s*"[^"]+"'),
        'val currentProfileName: String = "$appName"',
      ),
    ],
  );

  stdout.writeln('Successfully applied branding changes!');
}

void _replaceInFile({
  required String path,
  required List<(RegExp pattern, String replacement)> replacements,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('Warning: File not found: $path');
    return;
  }

  var content = file.readAsStringSync();
  var modified = false;

  for (final (pattern, replacement) in replacements) {
    if (pattern.hasMatch(content)) {
      content = content.replaceAll(pattern, replacement);
      modified = true;
    }
  }

  if (modified) {
    file.writeAsStringSync(content);
    stdout.writeln('Updated: $path');
  } else {
    stdout.writeln('No changes needed: $path');
  }
}
