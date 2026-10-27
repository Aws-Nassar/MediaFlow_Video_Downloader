import 'package:flutter/material.dart';

import 'app.dart';
import 'platform/platform_storage.dart';
import 'sources/default_source_adapter.dart';
import 'state/app_state.dart';
import 'storage/app_database.dart';
import 'storage/drift_job_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final outputDirectory = await defaultOutputDirectory();
  final state = AppState(
    adapter: createDefaultSourceAdapter(outputDirectory: outputDirectory),
    outputDirectory: outputDirectory,
    repository: DriftJobRepository(AppDatabase()),
  );
  await state.initialize();
  runApp(MediaFlowApp(appState: state));
}
