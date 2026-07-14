import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setTab(int index) {
    state = index;
  }
}

final selectedTabProvider =
    NotifierProvider<SelectedTabNotifier, int>(SelectedTabNotifier.new);
