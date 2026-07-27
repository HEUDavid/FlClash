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
    );

  final results = parser.parse(args);
  final appName = results['app-name'] as String;
  final customScheme = (results['scheme'] as String?) ??
      appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  stdout.writeln('Applying Branding Configuration:');
  stdout.writeln('  App Name:     $appName');
  stdout.writeln('  Package Name: (unchanged, keeping original com.follow.clash)');
  stdout.writeln('  Custom Scheme:$customScheme');
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

  // 2. 替换桌面端 URL Protocol 注册 Scheme
  if (customScheme != 'flclash') {
    _replaceInFile(
      path: 'lib/common/window.dart',
      replacements: [
        (
          RegExp(r"protocol\.register\('flclash'\);"),
          "protocol.register('$customScheme');",
        ),
      ],
    );
  }

  // 3. 替换 Android 主 Application 与 Tile 开关 Label 以及添加 DeepLink Scheme
  _replaceInFile(
    path: 'android/app/src/main/AndroidManifest.xml',
    replacements: [
      (
        RegExp(r'android:label="[^"]+"'),
        'android:label="$appName"',
      ),
      if (customScheme != 'flclash')
        (
          RegExp(
              r'<data android:scheme="flclash"\s*/>(?!\s*<data android:scheme=)'),
          '<data android:scheme="flclash" />\n                <data android:scheme="$customScheme" />',
        ),
    ],
  );

  // 4. 替换 Android Debug 模式 Label
  _replaceInFile(
    path: 'android/app/src/debug/AndroidManifest.xml',
    replacements: [
      (
        RegExp(r'android:label="[^"]+"'),
        'android:label="$appName Debug"',
      ),
    ],
  );

  // 5. 替换 Android 原生字符串资源
  _replaceInFile(
    path: 'android/common/src/main/res/values/strings.xml',
    replacements: [
      (
        RegExp(r'<string name="FlClash">.*?</string>'),
        '<string name="FlClash">$appName</string>',
      ),
    ],
  );

  // 6. 替换前台通知服务标题
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

  // 7. 替换通知默认参数标题与序列化读取默认值
  _replaceInFile(
    path:
        'android/service/src/main/java/com/follow/clash/service/models/NotificationParams.kt',
    replacements: [
      (
        RegExp(r'val title:\s*String\s*=\s*"[^"]+"'),
        'val title: String = "$appName"',
      ),
      (
        RegExp(r'title\s*=\s*parcel\.readString\(\)\s*\?:\s*"[^"]+"'),
        'title = parcel.readString() ?: "$appName"',
      ),
    ],
  );

  // 8. 替换 VPN 连接会话 Session 名称
  _replaceInFile(
    path:
        'android/service/src/main/java/com/follow/clash/service/VpnService.kt',
    replacements: [
      (
        RegExp(r'setSession\("[^"]+"\)'),
        'setSession("$appName")',
      ),
    ],
  );

  // 9. 替换全局原生状态常量与日志 Prefix
  _replaceInFile(
    path: 'android/common/src/main/java/com/follow/clash/common/GlobalState.kt',
    replacements: [
      (
        RegExp(r'const val NOTIFICATION_CHANNEL\s*=\s*"[^"]+"'),
        'const val NOTIFICATION_CHANNEL = "$appName"',
      ),
      (
        RegExp(r'Log\.d\("\[FlClash\]"'),
        'Log.d("[$appName]"',
      ),
    ],
  );

  // 10. 替换文件选择器提供者标题
  _replaceInFile(
    path:
        'android/service/src/main/java/com/follow/clash/service/FilesProvider.kt',
    replacements: [
      (
        RegExp(r'add\(DocumentsContract\.Root\.COLUMN_TITLE,\s*"[^"]+"\)'),
        'add(DocumentsContract.Root.COLUMN_TITLE, "$appName")',
      ),
    ],
  );

  // 11. 替换原生 State 默认配置名称
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


