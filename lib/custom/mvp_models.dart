enum MvpToastType {
  info,
  success,
  error,
  warning,
}

class MvpProfileItem {
  final String id;
  final String label;
  final String url;
  final DateTime? lastUpdateDate;
  final int? rulesCount;
  final int? ruleProvidersCount;
  final int? ruleProvidersTotalRules;
  final List<int>? ruleProvidersCounts;

  const MvpProfileItem({
    required this.id,
    required this.label,
    required this.url,
    this.lastUpdateDate,
    this.rulesCount,
    this.ruleProvidersCount,
    this.ruleProvidersTotalRules,
    this.ruleProvidersCounts,
  });
}

enum MvpCoreStatus {
  disconnected,
  connecting,
  connected,
}

extension MvpDateTimeExtension on DateTime {
  String get formattedUpdateDate {
    final now = DateTime.now();
    final isToday = year == now.year && month == now.month && day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        year == yesterday.year && month == yesterday.month && day == yesterday.day;

    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    if (isToday) {
      return '今天 $hourStr:$minuteStr';
    } else if (isYesterday) {
      return '昨天 $hourStr:$minuteStr';
    } else {
      final monthStr = month.toString().padLeft(2, '0');
      final dayStr = day.toString().padLeft(2, '0');
      return '$monthStr-$dayStr $hourStr:$minuteStr';
    }
  }

  String getLastUpdateTimeDesc(dynamic context) {
    final difference = DateTime.now().difference(this);
    final days = difference.inDays;
    if (days >= 365) {
      return '${(days / 365).floor()}年前';
    }
    if (days >= 30) {
      return '${(days / 30).floor()}个月前';
    }
    if (days >= 1) {
      return '$days天前';
    }
    final hours = difference.inHours;
    if (hours >= 1) {
      return '$hours小时前';
    }
    final minutes = difference.inMinutes;
    if (minutes >= 1) {
      return '$minutes分钟前';
    }
    return '刚刚';
  }
}
