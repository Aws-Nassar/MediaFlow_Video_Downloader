import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/models/media_models.dart';
import 'package:mediaflow/state/app_state.dart';
import 'package:mediaflow/state/media_flow_scope.dart';
import 'package:mediaflow/theme/studio_theme.dart';
import 'package:mediaflow/widgets/drive_selection_sheet.dart';

import 'support/fake_disk_space_probe.dart';

AppState _state({int? freeBytes = 1 << 30}) {
  return AppState(diskSpaceProbe: FakeDiskSpaceProbe(freeBytes));
}

const _descriptor = MediaDescriptor(
  sourceId: 'drive.google.com',
  sourceLabel: 'Google Drive',
  canonicalUrl: 'https://drive.google.com/drive/folders/fixtureFolder',
  title: 'Project folder',
  kind: MediaKind.collection,
  isCollection: true,
  itemCount: 3,
  entries: [
    MediaEntry(
      title: 'One',
      url: 'https://drive.google.com/file/d/fixtureOne/view',
      sizeBytes: 100,
      relativePath: 'One.txt',
    ),
    MediaEntry(
      title: 'Two',
      url: 'https://drive.google.com/file/d/fixtureTwo/view',
      sizeBytes: 200,
      relativePath: 'Nested/Two.txt',
    ),
    MediaEntry(
      title: 'Blocked form',
      url: 'https://docs.google.com/forms/d/fixtureForm/view',
      relativePath: 'Blocked form',
      blockedCode: MediaFlowErrorCode.unsupportedUrl,
    ),
  ],
);

void main() {
  testWidgets('selection sheet returns only checked rows', (tester) async {
    final state = _state();
    addTearDown(state.dispose);
    late Future<CollectionSelection?> pending;

    await tester.pumpWidget(
      MediaFlowScope(
        state: state,
        child: MaterialApp(
          theme: buildStudioTheme(StudioThemeMode.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    pending = showDriveCollectionSelection(
                      context,
                      _descriptor,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('FOLDER CONTENTS'), findsOneWidget);
    expect(find.text('Project folder'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Blocked form'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Blocked form'), findsOneWidget);
    expect(find.textContaining('not supported'), findsOneWidget);
    expect(find.text('2 selected'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('One.txt'),
      -80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('0 selected'), findsWidgets);

    await tester.tap(find.text('One.txt'));
    await tester.pump();
    await tester.tap(find.text('Download selected'));
    await tester.pumpAndSettle();

    final selection = await pending;
    expect(selection, isNotNull);
    expect(selection!.entries.length, 1);
    expect(selection.entries.single.title, 'One');
    expect(selection.asZip, isFalse);
  });

  testWidgets('download as ZIP returns the checked rows', (tester) async {
    final state = _state();
    addTearDown(state.dispose);
    late Future<CollectionSelection?> pending;

    await tester.pumpWidget(
      MediaFlowScope(
        state: state,
        child: MaterialApp(
          theme: buildStudioTheme(StudioThemeMode.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    pending = showDriveCollectionSelection(
                      context,
                      _descriptor,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.tap(find.text('One.txt'));
    await tester.pump();
    await tester.tap(find.text('Download as ZIP'));
    await tester.pumpAndSettle();

    final selection = await pending;
    expect(selection, isNotNull);
    expect(selection!.asZip, isTrue);
    expect(selection.entries.single.title, 'One');
  });

  testWidgets('warns when a ZIP needs more free space than available', (
    tester,
  ) async {
    final state = _state(freeBytes: 400);
    addTearDown(state.dispose);
    late Future<CollectionSelection?> pending;

    await tester.pumpWidget(
      MediaFlowScope(
        state: state,
        child: MaterialApp(
          theme: buildStudioTheme(StudioThemeMode.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    pending = showDriveCollectionSelection(
                      context,
                      _descriptor,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Free space: 400 B'), findsOneWidget);

    await tester.tap(find.text('Download as ZIP'));
    await tester.pumpAndSettle();
    expect(find.text('Low disk space'), findsOneWidget);
    expect(find.textContaining('600 B'), findsOneWidget);
    expect(find.textContaining('400 B'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('FOLDER CONTENTS'), findsOneWidget);

    await tester.tap(find.text('Download as ZIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download anyway'));
    await tester.pumpAndSettle();

    final selection = await pending;
    expect(selection, isNotNull);
    expect(selection!.asZip, isTrue);
    expect(selection.entries, hasLength(2));
  });

  testWidgets('download all excludes blocked rows', (tester) async {
    final state = _state();
    addTearDown(state.dispose);
    late Future<CollectionSelection?> pending;

    await tester.pumpWidget(
      MediaFlowScope(
        state: state,
        child: MaterialApp(
          theme: buildStudioTheme(StudioThemeMode.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    pending = showDriveCollectionSelection(
                      context,
                      _descriptor,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download all'));
    await tester.pumpAndSettle();

    final selection = await pending;
    expect(selection, isNotNull);
    expect(selection!.entries.length, 2);
    expect(
      selection.entries.map((entry) => entry.title),
      isNot(contains('Blocked form')),
    );
  });
}
