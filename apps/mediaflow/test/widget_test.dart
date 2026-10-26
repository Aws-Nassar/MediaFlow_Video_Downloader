import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/app.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/sources/fake_source_adapter.dart';
import 'package:mediaflow/state/app_state.dart';

AppState _state() {
  return AppState(
    adapter: FakeSourceAdapter(
      probeDelay: Duration.zero,
      stepDelay: Duration.zero,
    ),
    concurrency: 2,
  );
}

void main() {
  testWidgets('analyze flow reaches the queue', (tester) async {
    final state = _state();
    addTearDown(state.dispose);

    await tester.pumpWidget(MediaFlowApp(appState: state));
    expect(find.text('Paste a link'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'https://example.com/video/1',
    );
    await tester.pump();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsWidgets);
    expect(state.jobs.single.status, JobStatus.completed);
    expect(find.text('Download complete'), findsOneWidget);
  });

  testWidgets('a failed item is visible with a batch summary', (tester) async {
    final state = _state();
    addTearDown(state.dispose);

    await tester.pumpWidget(MediaFlowApp(appState: state));
    await tester.enterText(
      find.byType(TextField).first,
      'https://example.com/cookies',
    );
    await tester.pump();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(state.jobs.single.status, JobStatus.failed);
    expect(find.text('Batch finished with issues'), findsOneWidget);
    expect(find.textContaining('sign-in'), findsWidgets);
    expect(find.text('Retry failed'), findsOneWidget);
  });

  testWidgets('Arabic switches the UI to RTL', (tester) async {
    final state = _state();
    addTearDown(state.dispose);

    await tester.pumpWidget(MediaFlowApp(appState: state));
    await tester.tap(find.text('AR'));
    await tester.pumpAndSettle();

    expect(state.locale.languageCode, 'ar');
    expect(find.text('الصق رابطًا'), findsOneWidget);
    final directions = tester
        .widgetList<Directionality>(find.byType(Directionality))
        .map((widget) => widget.textDirection);
    expect(directions, contains(TextDirection.rtl));
  });
}
