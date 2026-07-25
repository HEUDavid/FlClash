class MvpProfileItem {
  final String id;
  final String label;
  final String url;

  const MvpProfileItem({
    required this.id,
    required this.label,
    required this.url,
  });
}

enum MvpCoreStatus {
  disconnected,
  connecting,
  connected,
}
