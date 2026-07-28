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

