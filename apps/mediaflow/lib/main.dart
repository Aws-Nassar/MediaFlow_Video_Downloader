import 'package:flutter/material.dart';

import 'app.dart';
import 'sources/default_source_adapter.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MediaFlowApp(appState: AppState(adapter: createDefaultSourceAdapter())),
  );
}
