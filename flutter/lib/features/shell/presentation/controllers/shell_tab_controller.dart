import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shell_tab_controller.g.dart';

/// The selected bottom-tab index (Dashboard/History/Shop/Profile) —
/// Riverpod state instead of `setState`, so `IndexedStack`'s selection
/// lives alongside every other piece of app state rather than being
/// `RootShell`-local.
@riverpod
class ShellTabIndex extends _$ShellTabIndex {
  @override
  int build() => 0;

  void select(int index) => state = index;
}
