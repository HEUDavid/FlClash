import 'package:flutter/material.dart';

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

  MvpProfileItem copyWith({
    String? id,
    String? label,
    String? url,
    DateTime? lastUpdateDate,
    int? rulesCount,
    int? ruleProvidersCount,
    int? ruleProvidersTotalRules,
    List<int>? ruleProvidersCounts,
  }) {
    return MvpProfileItem(
      id: id ?? this.id,
      label: label ?? this.label,
      url: url ?? this.url,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      rulesCount: rulesCount ?? this.rulesCount,
      ruleProvidersCount: ruleProvidersCount ?? this.ruleProvidersCount,
      ruleProvidersTotalRules:
          ruleProvidersTotalRules ?? this.ruleProvidersTotalRules,
      ruleProvidersCounts: ruleProvidersCounts ?? this.ruleProvidersCounts,
    );
  }
}

enum MvpCoreStatus {
  disconnected,
  connecting,
  connected,
}

extension MvpDateTimeExtension on DateTime {
  String get formattedUpdateDate {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(this, now);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = DateUtils.isSameDay(this, yesterday);

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
}
