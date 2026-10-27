import 'package:flutter/material.dart';

import 'app.dart';
import 'platform/platform_storage.dart';
import 'sources/default_source_adapter.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final outputDirectory = await defaultOutputDirectory();
  runApp(
    MediaFlowApp(
      appState: AppState(
        adapter: createDefaultSourceAdapter(outputDirectory: outputDirectory),
        outputDirectory: outputDirectory,
      ),
    ),
  );
}
