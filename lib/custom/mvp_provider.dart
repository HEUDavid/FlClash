import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomMvpNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void setEnabled(bool value) {
    if (state == value) return;
    state = value;
  }
}

final customMvpProvider =
    NotifierProvider<CustomMvpNotifier, bool>(CustomMvpNotifier.new);
