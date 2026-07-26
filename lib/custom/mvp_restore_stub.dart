// Web 平台存根：隔离所有 FFI/sqlite3/win32 依赖，实现 100% 网页端预览兼容
Future<void> downloadAndRestoreBackup(String url) async {
  // Web 预览模式：模拟下载与恢复延迟
  await Future.delayed(const Duration(milliseconds: 500));
}

Future<void> updateSubscriptionOrBackup(String url) async {
  // Web 预览模式：模拟更新订阅与备份
  await Future.delayed(const Duration(milliseconds: 600));
}
