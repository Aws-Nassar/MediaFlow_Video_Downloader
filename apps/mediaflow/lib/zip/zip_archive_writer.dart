import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One file that should be stored in a new ZIP archive.
class ZipArchiveEntry {
  final String name;
  final File file;

  const ZipArchiveEntry({required this.name, required this.file});
}

class ZipArchiveProgress {
  final int bytesWritten;
  final int totalBytes;
  final int entriesWritten;
  final int entryCount;
  final String? currentEntry;

  const ZipArchiveProgress({
    required this.bytesWritten,
    required this.totalBytes,
    required this.entriesWritten,
    required this.entryCount,
    this.currentEntry,
  });

  double get fraction => totalBytes <= 0 ? 0 : bytesWritten / totalBytes;
}

class ZipArchiveCancelled implements Exception {
  const ZipArchiveCancelled();
}

/// A dependency-free ZIP writer using the Store method.
///
/// Files are streamed into the archive and the CRC is computed with a first
/// pass over each source file. ZIP64 records are emitted when an entry or the
/// archive crosses the classic format limits. Set [forceZip64] in tests to
/// exercise that path with small files.
class ZipArchiveWriter {
  final bool forceZip64;

  const ZipArchiveWriter({this.forceZip64 = false});

  Future<int> write({
    required File target,
    required List<ZipArchiveEntry> entries,
    void Function(ZipArchiveProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await target.parent.create(recursive: true);
    final totalBytes = await _totalBytes(entries);
    final sink = _ZipSink(target.openWrite());
    final central = <_CentralEntry>[];
    final usedNames = <String>{};
    var inputBytes = 0;
    var entriesWritten = 0;
    final stopwatch = Stopwatch()..start();
    var lastReport = -1000;

    void report(String? currentEntry, {bool force = false}) {
      final elapsed = stopwatch.elapsedMilliseconds;
      if (!force && elapsed - lastReport < 120) return;
      lastReport = elapsed;
      onProgress?.call(
        ZipArchiveProgress(
          bytesWritten: inputBytes,
          totalBytes: totalBytes,
          entriesWritten: entriesWritten,
          entryCount: entries.length,
          currentEntry: currentEntry,
        ),
      );
    }

    void checkCancelled() {
      if (isCancelled?.call() == true) throw const ZipArchiveCancelled();
    }

    try {
      for (final entry in entries) {
        checkCancelled();
        final name = _uniqueName(_normaliseName(entry.name), usedNames);
        final nameBytes = utf8.encode(name);
        final stat = await entry.file.stat();
        if (stat.type != FileSystemEntityType.file) {
          throw FileSystemException(
            'The ZIP source is not a file.',
            entry.file.path,
          );
        }
        final size = stat.size;
        final crc = await _crc32File(entry.file, checkCancelled);
        final modified = stat.modified.toLocal();
        final dos = _dosDateTime(modified);
        final localOffset = sink.offset;
        final zip64Size = forceZip64 || size >= _max32;
        final extraLength = zip64Size ? 20 : 0;
        final versionNeeded = zip64Size ? 45 : 20;
        final flags = 0x0800; // UTF-8 file names.

        sink
          ..u32(_localHeaderSignature)
          ..u16(versionNeeded)
          ..u16(flags)
          ..u16(0) // Store, no compression.
          ..u16(dos.time)
          ..u16(dos.date)
          ..u32(crc)
          ..u32(zip64Size ? _max32 : size)
          ..u32(zip64Size ? _max32 : size)
          ..u16(nameBytes.length)
          ..u16(extraLength)
          ..bytes(nameBytes);
        if (zip64Size) {
          sink
            ..u16(_zip64ExtraId)
            ..u16(16)
            ..u64(size)
            ..u64(size);
        }

        await for (final chunk in entry.file.openRead()) {
          checkCancelled();
          sink.bytes(chunk);
          inputBytes += chunk.length;
          report(name);
        }

        central.add(
          _CentralEntry(
            nameBytes: nameBytes,
            crc: crc,
            size: size,
            localOffset: localOffset,
            zip64Size: zip64Size,
            zip64Offset: forceZip64 || localOffset >= _max32,
            dosTime: dos.time,
            dosDate: dos.date,
          ),
        );
        entriesWritten++;
        report(name, force: true);
      }

      checkCancelled();
      final centralOffset = sink.offset;
      for (final entry in central) {
        final extraData =
            (entry.zip64Size ? 16 : 0) + (entry.zip64Offset ? 8 : 0);
        final extraLength = extraData == 0 ? 0 : extraData + 4;
        final versionNeeded = entry.zip64Size || entry.zip64Offset ? 45 : 20;
        sink
          ..u32(_centralHeaderSignature)
          ..u16(versionNeeded)
          ..u16(versionNeeded)
          ..u16(0x0800)
          ..u16(0)
          ..u16(entry.dosTime)
          ..u16(entry.dosDate)
          ..u32(entry.crc)
          ..u32(entry.zip64Size ? _max32 : entry.size)
          ..u32(entry.zip64Size ? _max32 : entry.size)
          ..u16(entry.nameBytes.length)
          ..u16(extraLength)
          ..u16(0)
          ..u16(0)
          ..u16(0)
          ..u32(0)
          ..u32(entry.zip64Offset ? _max32 : entry.localOffset)
          ..bytes(entry.nameBytes);
        if (extraLength > 0) {
          sink
            ..u16(_zip64ExtraId)
            ..u16(extraData);
          if (entry.zip64Size) {
            sink
              ..u64(entry.size)
              ..u64(entry.size);
          }
          if (entry.zip64Offset) {
            sink.u64(entry.localOffset);
          }
        }
      }

      final centralSize = sink.offset - centralOffset;
      final needsZip64End =
          forceZip64 ||
          entries.length >= 0xffff ||
          centralOffset >= _max32 ||
          centralSize >= _max32;
      if (needsZip64End) {
        final zip64EndOffset = sink.offset;
        sink
          ..u32(_zip64EndSignature)
          ..u64(44)
          ..u16(45)
          ..u16(45)
          ..u32(0)
          ..u32(0)
          ..u64(entries.length)
          ..u64(entries.length)
          ..u64(centralSize)
          ..u64(centralOffset)
          ..u32(_zip64LocatorSignature)
          ..u32(0)
          ..u64(zip64EndOffset)
          ..u32(1)
          ..u32(_endSignature)
          ..u16(0)
          ..u16(0)
          ..u16(0xffff)
          ..u16(0xffff)
          ..u32(_max32)
          ..u32(_max32)
          ..u16(0);
      } else {
        sink
          ..u32(_endSignature)
          ..u16(0)
          ..u16(0)
          ..u16(entries.length)
          ..u16(entries.length)
          ..u32(centralSize)
          ..u32(centralOffset)
          ..u16(0);
      }

      await sink.close();
      report(null, force: true);
      return sink.offset;
    } catch (_) {
      await sink.close(swallowErrors: true);
      rethrow;
    }
  }

  Future<int> _totalBytes(List<ZipArchiveEntry> entries) async {
    var total = 0;
    for (final entry in entries) {
      final stat = await entry.file.stat();
      if (stat.type == FileSystemEntityType.file) total += stat.size;
    }
    return total;
  }

  Future<int> _crc32File(File file, void Function() checkCancelled) async {
    var crc = 0xffffffff;
    await for (final chunk in file.openRead()) {
      checkCancelled();
      for (final byte in chunk) {
        crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

/// CRC-32/ISO-HDLC, the checksum used by ZIP.
int zipCrc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

class _CentralEntry {
  final List<int> nameBytes;
  final int crc;
  final int size;
  final int localOffset;
  final bool zip64Size;
  final bool zip64Offset;
  final int dosTime;
  final int dosDate;

  const _CentralEntry({
    required this.nameBytes,
    required this.crc,
    required this.size,
    required this.localOffset,
    required this.zip64Size,
    required this.zip64Offset,
    required this.dosTime,
    required this.dosDate,
  });
}

class _ZipSink {
  final IOSink _sink;
  int offset = 0;

  _ZipSink(this._sink);

  void bytes(List<int> value) {
    _sink.add(value);
    offset += value.length;
  }

  void u16(int value) => bytes(_u16(value));

  void u32(int value) => bytes(_u32(value));

  void u64(int value) => bytes(_u64(value));

  Future<void> close({bool swallowErrors = false}) async {
    try {
      await _sink.flush();
      await _sink.close();
    } catch (_) {
      if (!swallowErrors) rethrow;
    }
  }
}

class _DosDateTime {
  final int time;
  final int date;

  const _DosDateTime(this.time, this.date);
}

_DosDateTime _dosDateTime(DateTime value) {
  final year = value.year.clamp(1980, 2107);
  final date = ((year - 1980) << 9) | (value.month << 5) | value.day;
  final time = (value.hour << 11) | (value.minute << 5) | (value.second ~/ 2);
  return _DosDateTime(time, date);
}

String _normaliseName(String value) {
  var name = value.replaceAll('\\', '/').trim();
  while (name.startsWith('/')) {
    name = name.substring(1);
  }
  final parts = <String>[];
  for (final part in name.split('/')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty || trimmed == '.' || trimmed == '..') continue;
    parts.add(trimmed);
  }
  final result = parts.join('/');
  return result.isEmpty ? 'file' : result;
}

String _uniqueName(String name, Set<String> used) {
  if (used.add(name)) return name;
  final slash = name.lastIndexOf('/');
  final dot = name.lastIndexOf('.');
  final hasExtension = dot > slash + 1 && dot < name.length - 1;
  final stem = hasExtension ? name.substring(0, dot) : name;
  final extension = hasExtension ? name.substring(dot) : '';
  var counter = 2;
  while (true) {
    final candidate = '$stem ($counter)$extension';
    if (used.add(candidate)) return candidate;
    counter++;
  }
}

Uint8List _u16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u64(int value) {
  final data = ByteData(8)..setUint64(0, value, Endian.little);
  return data.buffer.asUint8List();
}

final List<int> _crcTable = List<int>.generate(256, (index) {
  var crc = index;
  for (var bit = 0; bit < 8; bit++) {
    crc = (crc & 1) == 1 ? (0xedb88320 ^ (crc >> 1)) : (crc >> 1);
  }
  return crc;
}, growable: false);

const _localHeaderSignature = 0x04034b50;
const _centralHeaderSignature = 0x02014b50;
const _endSignature = 0x06054b50;
const _zip64EndSignature = 0x06064b50;
const _zip64LocatorSignature = 0x07064b50;
const _zip64ExtraId = 0x0001;
const _max32 = 0xffffffff;
