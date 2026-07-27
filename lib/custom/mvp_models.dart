class MvpProfileItem {
  final String id;
  final String label;
  final String url;
  final DateTime? lastUpdateDate;

  const MvpProfileItem({
    required this.id,
    required this.label,
    required this.url,
    this.lastUpdateDate,
  });
}

enum MvpCoreStatus {
  disconnected,
  connecting,
  connected,
}
