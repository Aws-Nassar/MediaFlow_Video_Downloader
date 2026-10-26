import '../models/media_models.dart';
import 'drive_folder_parser.dart';

enum DriveSkipReason { depthLimit, itemLimit, cycle }

class DriveFolderFile {
  final String id;
  final String name;
  final String relativePath;
  final DriveEntryKind kind;
  final String? nativeKind;
  final String url;

  const DriveFolderFile({
    required this.id,
    required this.name,
    required this.relativePath,
    required this.kind,
    required this.url,
    this.nativeKind,
  });

  bool get isNative => kind == DriveEntryKind.native;
}

class DriveFolderSkip {
  final String id;
  final String name;
  final DriveSkipReason reason;
  final int depth;

  const DriveFolderSkip({
    required this.id,
    required this.name,
    required this.reason,
    required this.depth,
  });
}

class DriveFolderExpansion {
  final String name;
  final List<DriveFolderFile> files;
  final List<DriveFolderSkip> skipped;
  final bool truncated;

  const DriveFolderExpansion({
    required this.name,
    required this.files,
    required this.skipped,
    required this.truncated,
  });
}

typedef DriveFolderLoader = Future<DriveFolderPage> Function(String folderId);

/// Walks a link-shared folder tree with depth, item, and cycle guards.
class DriveFolderExpander {
  final DriveFolderLoader loadFolder;
  final int maxDepth;
  final int maxItems;

  const DriveFolderExpander({
    required this.loadFolder,
    this.maxDepth = 10,
    this.maxItems = 10000,
  });

  Future<DriveFolderExpansion> expand(String rootId) async {
    final root = await loadFolder(rootId);
    final files = <DriveFolderFile>[];
    final skipped = <DriveFolderSkip>[];
    final visited = <String>{rootId};
    final usedPaths = <String>{};
    final queue = <_FolderTask>[];
    var processedItems = 0;
    var truncated = false;

    bool takeItem() {
      if (processedItems >= maxItems) {
        truncated = true;
        return false;
      }
      processedItems++;
      return true;
    }

    void addEntries(DriveFolderPage page, String parentPath, int folderDepth) {
      for (final entry in page.entries) {
        if (!takeItem()) {
          skipped.add(
            DriveFolderSkip(
              id: entry.id,
              name: entry.name,
              reason: DriveSkipReason.itemLimit,
              depth: folderDepth,
            ),
          );
          return;
        }

        if (entry.isFolder) {
          if (folderDepth >= maxDepth) {
            skipped.add(
              DriveFolderSkip(
                id: entry.id,
                name: entry.name,
                reason: DriveSkipReason.depthLimit,
                depth: folderDepth + 1,
              ),
            );
            continue;
          }
          if (!visited.add(entry.id)) {
            skipped.add(
              DriveFolderSkip(
                id: entry.id,
                name: entry.name,
                reason: DriveSkipReason.cycle,
                depth: folderDepth + 1,
              ),
            );
            continue;
          }
          queue.add(
            _FolderTask(
              id: entry.id,
              path: _join(parentPath, safeFileName(entry.name)),
              depth: folderDepth + 1,
            ),
          );
          continue;
        }

        final relativePath = _uniquePath(
          _join(parentPath, safeFileName(entry.name)),
          entry.id,
          usedPaths,
        );
        files.add(
          DriveFolderFile(
            id: entry.id,
            name: entry.name,
            relativePath: relativePath,
            kind: entry.kind,
            nativeKind: entry.nativeKind,
            url: entry.url,
          ),
        );
      }
    }

    addEntries(root, '', 0);
    while (queue.isNotEmpty && !truncated) {
      final task = queue.removeAt(0);
      final page = await loadFolder(task.id);
      addEntries(page, task.path, task.depth);
    }

    return DriveFolderExpansion(
      name: root.name,
      files: files,
      skipped: skipped,
      truncated: truncated,
    );
  }

  static String _join(String parent, String child) {
    if (parent.isEmpty) return child;
    if (child.isEmpty) return parent;
    return '$parent/$child';
  }

  static String _uniquePath(String path, String id, Set<String> used) {
    if (used.add(path)) return path;
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    final hasExtension = dot > slash + 1;
    final stem = hasExtension ? path.substring(0, dot) : path;
    final extension = hasExtension ? path.substring(dot) : '';
    final suffix = id.length >= 6 ? id.substring(0, 6) : id;
    var candidate = '$stem [$suffix]$extension';
    var counter = 2;
    while (!used.add(candidate)) {
      candidate = '$stem [$suffix $counter]$extension';
      counter++;
    }
    return candidate;
  }
}

class _FolderTask {
  final String id;
  final String path;
  final int depth;

  const _FolderTask({
    required this.id,
    required this.path,
    required this.depth,
  });
}
