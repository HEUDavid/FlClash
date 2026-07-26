import 'dart:convert';
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
      'package-name',
      defaultsTo: Platform.environment['PACKAGE_NAME'] ?? 'com.blockad.app',
      help: 'The Android Application ID / package name',
    )
    ..addOption(
      'scheme',
      help: 'Custom URL scheme (default: lowercased app-name)',
    );

  final results = parser.parse(args);
  final appName = results['app-name'] as String;
  final packageName = results['package-name'] as String;
  final customScheme = (results['scheme'] as String?) ??
      appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  stdout.writeln('Applying Branding Configuration:');
  stdout.writeln('  App Name:     $appName');
  stdout.writeln('  Package Name: $packageName');
  stdout.writeln('  Custom Scheme:$customScheme');
  stdout.writeln();

  _replaceInFile(
    path: 'android/app/build.gradle.kts',
    replacements: [
      (
        RegExp(r'applicationId\s*=\s*"[^"]+"'),
        'applicationId = "$packageName"',
      ),
    ],
  );

  _updateGoogleServicesJson('android/app/google-services.json', packageName);

  _replaceInFile(
    path: 'lib/common/constant.dart',
    replacements: [
      (
        RegExp(r"const appName\s*=\s*'[^']+'\s*;"),
        "const appName = '$appName';",
      ),
    ],
  );

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

  _replaceInFile(
    path: 'android/app/src/debug/AndroidManifest.xml',
    replacements: [
      (
        RegExp(r'android:label="[^"]+"'),
        'android:label="$appName Debug"',
      ),
    ],
  );

  _replaceInFile(
    path: 'android/common/src/main/res/values/strings.xml',
    replacements: [
      (
        RegExp(r'<string name="FlClash">.*?</string>'),
        '<string name="FlClash">$appName</string>',
      ),
    ],
  );

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

void _updateGoogleServicesJson(String path, String packageName) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln(
      'Warning: File not found: $path (skipping google-services.json)',
    );
    return;
  }
  try {
    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final clientList = json['client'] as List<dynamic>?;
    if (clientList != null && clientList.isNotEmpty) {
      bool changed = false;
      final existingNames = <String>{};

      for (final client in clientList) {
        if (client is Map<String, dynamic>) {
          final clientInfo = client['client_info'] as Map<String, dynamic>?;
          final androidClientInfo =
              clientInfo?['android_client_info'] as Map<String, dynamic>?;
          if (androidClientInfo != null) {
            final oldName = androidClientInfo['package_name'] as String?;
            if (oldName == 'com.follow.clash') {
              androidClientInfo['package_name'] = packageName;
              changed = true;
            } else if (oldName == 'com.follow.clash.debug') {
              androidClientInfo['package_name'] = '$packageName.debug';
              changed = true;
            } else if (oldName == 'com.follow.clash.dev') {
              androidClientInfo['package_name'] = '$packageName.dev';
              changed = true;
            }
            final currentName = androidClientInfo['package_name'] as String?;
            if (currentName != null) {
              existingNames.add(currentName);
            }
          }
        }
      }

      final neededNames = [
        packageName,
        '$packageName.debug',
        '$packageName.dev',
      ];
      for (final needed in neededNames) {
        if (!existingNames.contains(needed)) {
          final templateClient = clientList.first;
          final clonedClient =
              jsonDecode(jsonEncode(templateClient)) as Map<String, dynamic>;
          final clientInfo =
              clonedClient['client_info'] as Map<String, dynamic>?;
          final androidClientInfo =
              clientInfo?['android_client_info'] as Map<String, dynamic>?;
          if (androidClientInfo != null) {
            androidClientInfo['package_name'] = needed;
            clientList.add(clonedClient);
            existingNames.add(needed);
            changed = true;
          }
        }
      }

      if (changed) {
        const encoder = JsonEncoder.withIndent('  ');
        file.writeAsStringSync(encoder.convert(json));
        stdout.writeln('Updated: $path (injected required package names)');
      } else {
        stdout.writeln('No changes needed: $path');
      }
      return;
    }
  } catch (e) {
    stdout.writeln(
      'Warning: Failed to parse $path as JSON ($e), falling back to regex.',
    );
  }

  _replaceInFile(
    path: path,
    replacements: [
      (
        RegExp(r'"package_name":\s*"com\.follow\.clash"'),
        '"package_name": "$packageName"',
      ),
      (
        RegExp(r'"package_name":\s*"com\.follow\.clash\.debug"'),
        '"package_name": "$packageName.debug"',
      ),
      (
        RegExp(r'"package_name":\s*"com\.follow\.clash\.dev"'),
        '"package_name": "$packageName.dev"',
      ),
    ],
  );
}
