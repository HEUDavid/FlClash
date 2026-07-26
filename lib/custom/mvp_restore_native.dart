import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';

// Native implementation for Desktop/Mobile platform where FFI is available
Future<void> restoreBackupData() async {
  await globalState.container
      .read((backupActionProvider as dynamic).notifier)
      .restore(RestoreOption.all);
}
