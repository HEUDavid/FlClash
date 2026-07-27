import 'dart:io';

void main(List<String> args) {
  final envAppName = Platform.environment['APP_NAME'];
  final appName = (args.isNotEmpty && args[0].trim().isNotEmpty)
      ? args[0].trim()
      : (envAppName != null && envAppName.trim().isNotEmpty
          ? envAppName.trim()
          : 'Block Ad');

  stdout.writeln(
      '=== Apply Branding: Setting Display App Name to "$appName" ===');

  // List of files and replacement pairs (target -> replacement)
  final replacements = <String, List<Map<String, String>>>{
    'lib/common/constant.dart': [
      {
        'target': "const appName = 'FlClash';",
        'replacement': "const appName = '$appName';",
      },
    ],
    'android/app/src/main/AndroidManifest.xml': [
      {
        'target': 'android:label="FlClash"',
        'replacement': 'android:label="$appName"',
      },
    ],
    'android/app/src/debug/AndroidManifest.xml': [
      {
        'target': 'android:label="FlClash Debug"',
        'replacement': 'android:label="$appName Debug"',
      },
    ],
    'android/common/src/main/res/values/strings.xml': [
      {
        'target': '<string name="FlClash">FlClash</string>',
        'replacement': '<string name="FlClash">$appName</string>',
      },
    ],
    'android/common/src/main/java/com/follow/clash/common/GlobalState.kt': [
      {
        'target': 'const val NOTIFICATION_CHANNEL = "FlClash"',
        'replacement': 'const val NOTIFICATION_CHANNEL = "$appName"',
      },
    ],
    'android/service/src/main/java/com/follow/clash/service/VpnService.kt': [
      {
        'target': 'setSession("FlClash")',
        'replacement': 'setSession("$appName")',
      },
    ],
    'android/service/src/main/java/com/follow/clash/service/modules/NotificationModule.kt':
        [
      {
        'target': 'setContentTitle("FlClash")',
        'replacement': 'setContentTitle("$appName")',
      },
    ],
    'android/service/src/main/java/com/follow/clash/service/models/NotificationParams.kt':
        [
      {
        'target': 'val title: String = "FlClash",',
        'replacement': 'val title: String = "$appName",',
      },
      {
        'target': 'title = parcel.readString() ?: "FlClash",',
        'replacement': 'title = parcel.readString() ?: "$appName",',
      },
    ],
    'android/service/src/main/java/com/follow/clash/service/FilesProvider.kt': [
      {
        'target': 'add(DocumentsContract.Root.COLUMN_TITLE, "FlClash")',
        'replacement': 'add(DocumentsContract.Root.COLUMN_TITLE, "$appName")',
      },
    ],
    'android/app/src/main/kotlin/com/follow/clash/models/State.kt': [
      {
        'target': 'val currentProfileName: String = "FlClash",',
        'replacement': 'val currentProfileName: String = "$appName",',
      },
    ],
  };

  var modifiedCount = 0;

  for (final entry in replacements.entries) {
    final filePath = entry.key;
    final file = File(filePath);

    if (!file.existsSync()) {
      stderr.writeln('Warning: File not found: $filePath');
      continue;
    }

    var content = file.readAsStringSync();
    var changed = false;

    for (final pair in entry.value) {
      final target = pair['target']!;
      final replacement = pair['replacement']!;

      if (content.contains(target)) {
        content = content.replaceAll(target, replacement);
        changed = true;
        stdout.writeln('  [Updated] $filePath: "$target" -> "$replacement"');
      } else if (content.contains(replacement)) {
        stdout.writeln('  [Already updated] $filePath contains "$replacement"');
      } else {
        stderr.writeln(
            '  [Warning] $filePath did not contain target string: "$target"');
      }
    }

    if (changed) {
      file.writeAsStringSync(content);
      modifiedCount++;
    }
  }

  stdout.writeln(
      '=== Apply Branding Finished: Modified $modifiedCount files ===');
}
