import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../state/media_flow_scope.dart';
import '../theme/studio_theme.dart';

Future<CollectionSelection?> showDriveCollectionSelection(
  BuildContext context,
  MediaDescriptor descriptor,
) {
  return showModalBottomSheet<CollectionSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DriveCollectionSelectionSheet(descriptor: descriptor),
  );
}

class DriveCollectionSelectionSheet extends StatefulWidget {
  final MediaDescriptor descriptor;

  const DriveCollectionSelectionSheet({super.key, required this.descriptor});

  @override
  State<DriveCollectionSelectionSheet> createState() =>
      _DriveCollectionSelectionSheetState();
}

class _DriveCollectionSelectionSheetState
    extends State<DriveCollectionSelectionSheet> {
  final Set<int> _selected = {};
  String? _validation;

  List<MediaEntry> get _entries => widget.descriptor.entries;

  int get _downloadableCount =>
      _entries.where((entry) => !entry.isBlocked).length;

  bool get _allSelected => _selected.length == _downloadableCount;

  int? get _selectedBytes {
    var total = 0;
    for (final index in _selected) {
      final size = _entries[index].sizeBytes;
      if (size == null) return null;
      total += size;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _entries.length; i++) {
      if (!_entries[i].isBlocked) _selected.add(i);
    }
  }

  void _toggle(int index) {
    final entry = _entries[index];
    if (entry.isBlocked) return;
    setState(() {
      _validation = null;
      if (!_selected.add(index)) _selected.remove(index);
    });
  }

  void _setAll(bool selected) {
    setState(() {
      _validation = null;
      _selected.clear();
      if (selected) {
        for (var i = 0; i < _entries.length; i++) {
          if (!_entries[i].isBlocked) _selected.add(i);
        }
      }
    });
  }

  void _submit({bool all = false, bool asZip = false}) {
    if (all) _setAll(true);
    if (_selected.isEmpty) {
      setState(
        () => _validation = MediaFlowScope.of(context).strings.noFilesSelected,
      );
      return;
    }
    final selection = [
      for (var i = 0; i < _entries.length; i++)
        if (_selected.contains(i)) _entries[i],
    ];
    Navigator.of(
      context,
    ).pop(CollectionSelection(entries: selection, asZip: asZip));
  }

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = math.min(
      screenHeight * 0.9,
      math.max(320.0, 230.0 + _entries.length * 64.0),
    );
    final total = _selectedBytes;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SizedBox(
          height: height,
          child: Material(
            color: palette.surface,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _Header(
                    title: widget.descriptor.title,
                    itemCount: _entries.length,
                  ),
                  Divider(height: 1, color: palette.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _allSelected ? null : () => _setAll(true),
                          child: Text(strings.selectAll),
                        ),
                        TextButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () => _setAll(false),
                          child: Text(strings.selectNone),
                        ),
                        const Spacer(),
                        Text(
                          '${_selected.length} ${strings.selected}',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _entries.isEmpty
                        ? Center(
                            child: Text(
                              strings.noFilesSelected,
                              style: TextStyle(color: palette.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) => _EntryRow(
                              entry: _entries[index],
                              selected: _selected.contains(index),
                              onTap: () => _toggle(index),
                            ),
                          ),
                  ),
                  Divider(height: 1, color: palette.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selected.length} ${strings.selected}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              total == null
                                  ? strings.sizeUnavailable
                                  : formatBytes(total),
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (_validation != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _validation!,
                            style: TextStyle(
                              color: palette.danger,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: _downloadableCount == 0
                                  ? null
                                  : () => _submit(all: true),
                              child: Text(strings.downloadAll),
                            ),
                            OutlinedButton.icon(
                              onPressed: _selected.isEmpty
                                  ? null
                                  : () => _submit(asZip: true),
                              icon: const Icon(
                                Icons.archive_outlined,
                                size: 17,
                              ),
                              label: Text(strings.downloadAsZip),
                            ),
                            FilledButton(
                              onPressed: _selected.isEmpty ? null : _submit,
                              child: Text(strings.downloadSelected),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int itemCount;

  const _Header({required this.title, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 8, 10),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: palette.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_copy_outlined,
                  color: palette.accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.folderContents.toUpperCase(),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount ${strings.items}',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final MediaEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _EntryRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = MediaFlowScope.of(context);
    final strings = state.strings;
    final palette = context.palette;
    final path = entry.relativePath ?? entry.title;
    final slash = path.lastIndexOf('/');
    final name = slash >= 0 ? path.substring(slash + 1) : path;
    final directory = slash > 0 ? path.substring(0, slash) : null;
    final blocked = entry.blockedCode;

    return InkWell(
      onTap: blocked == null ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 16, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: blocked == null ? (_) => onTap() : null,
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                blocked == null
                    ? Icons.insert_drive_file_outlined
                    : Icons.lock_outline_rounded,
                size: 19,
                color: blocked == null ? palette.textMuted : palette.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: blocked == null
                            ? palette.text
                            : palette.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (directory != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        directory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textFaint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (blocked != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${strings.blocked} · ${strings.errorMessage(blocked)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.warning, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (blocked == null)
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  formatBytes(entry.sizeBytes),
                  style: TextStyle(color: palette.textFaint, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
