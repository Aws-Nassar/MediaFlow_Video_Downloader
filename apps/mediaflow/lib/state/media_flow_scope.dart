import 'package:flutter/widgets.dart';

import 'app_state.dart';

class MediaFlowScope extends InheritedNotifier<AppState> {
  const MediaFlowScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MediaFlowScope>();
    assert(scope != null, 'MediaFlowScope is missing above this context.');
    return scope!.notifier!;
  }
}
