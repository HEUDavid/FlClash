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
