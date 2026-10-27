import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/zip/zip_archive_writer.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mediaflow_zip_test_');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('writes stored entries that can be read back', () async {
    final one = File('${temp.path}/one.txt')..writeAsStringSync('hello');
    final two = File('${temp.path}/two.bin')
      ..writeAsBytesSync([0, 1, 2, 3, 255]);
    final target = File('${temp.path}/archive.zip');
    final progress = <ZipArchiveProgress>[];

    final bytes = await const ZipArchiveWriter().write(
      target: target,
      entries: [
        ZipArchiveEntry(name: 'Folder/One.txt', file: one),
        ZipArchiveEntry(name: 'Two.bin', file: two),
      ],
      onProgress: progress.add,
    );

    expect(bytes, await target.length());
    expect(progress, isNotEmpty);
    expect(progress.last.entriesWritten, 2);
    expect(progress.last.fraction, 1);
    expect(zipCrc32(utf8.encode('hello')), 0x3610a686);

    final entries = _readZip(await target.readAsBytes());
    expect(entries.map((entry) => entry.name), ['Folder/One.txt', 'Two.bin']);
    expect(utf8.decode(entries[0].data), 'hello');
    expect(entries[1].data, [0, 1, 2, 3, 255]);
    expect(entries[0].crc, 0x3610a686);
    expect(entries[0].zip64, isFalse);
  });

  test('writes ZIP64 records when forced', () async {
    final source = File('${temp.path}/small.txt')..writeAsStringSync('zip64');
    final target = File('${temp.path}/archive64.zip');

    await const ZipArchiveWriter(forceZip64: true).write(
      target: target,
      entries: [ZipArchiveEntry(name: 'small.txt', file: source)],
    );

    final raw = await target.readAsBytes();
    expect(_containsSignature(raw, 0x06064b50), isTrue);
    final entries = _readZip(raw);
    expect(entries.single.name, 'small.txt');
    expect(entries.single.zip64, isTrue);
    expect(utf8.decode(entries.single.data), 'zip64');
  });

  test('deduplicates entry names and writes an empty archive', () async {
    final source = File('${temp.path}/same.txt')..writeAsStringSync('same');
    final target = File('${temp.path}/duplicate.zip');

    await const ZipArchiveWriter().write(
      target: target,
      entries: [
        ZipArchiveEntry(name: 'same.txt', file: source),
        ZipArchiveEntry(name: 'same.txt', file: source),
      ],
    );

    final entries = _readZip(await target.readAsBytes());
    expect(entries.map((entry) => entry.name), ['same.txt', 'same (2).txt']);

    final empty = File('${temp.path}/empty.zip');
    await const ZipArchiveWriter().write(target: empty, entries: const []);
    expect(_readZip(await empty.readAsBytes()), isEmpty);
  });

  test('stops when cancelled', () async {
    final source = File('${temp.path}/large.bin')
      ..writeAsBytesSync(List<int>.filled(1024 * 1024, 7));
    final target = File('${temp.path}/cancelled.zip');

    await expectLater(
      const ZipArchiveWriter().write(
        target: target,
        entries: [ZipArchiveEntry(name: 'large.bin', file: source)],
        isCancelled: () => true,
      ),
      throwsA(isA<ZipArchiveCancelled>()),
    );
  });
}

class _ZipEntry {
  final String name;
  final List<int> data;
  final int crc;
  final bool zip64;

  const _ZipEntry({
    required this.name,
    required this.data,
    required this.crc,
    required this.zip64,
  });
}

List<_ZipEntry> _readZip(Uint8List bytes) {
  final eocd = _findSignature(bytes, 0x06054b50);
  if (eocd < 0) throw StateError('No ZIP end record.');

  var entryCount = _u16(bytes, eocd + 10);
  var centralOffset = _u32(bytes, eocd + 16);
  var zip64 = false;
  if (entryCount == 0xffff || centralOffset == 0xffffffff) {
    final locator = eocd - 20;
    if (_u32(bytes, locator) != 0x07064b50) {
      throw StateError('No ZIP64 locator.');
    }
    final zip64End = _u64(bytes, locator + 8);
    if (_u32(bytes, zip64End) != 0x06064b50) {
      throw StateError('No ZIP64 end record.');
    }
    entryCount = _u64(bytes, zip64End + 32);
    centralOffset = _u64(bytes, zip64End + 48);
    zip64 = true;
  }

  final entries = <_ZipEntry>[];
  var cursor = centralOffset;
  for (var i = 0; i < entryCount; i++) {
    if (_u32(bytes, cursor) != 0x02014b50) {
      throw StateError('Bad central directory at $cursor.');
    }
    final crc = _u32(bytes, cursor + 16);
    var dataSize = _u32(bytes, cursor + 24);
    var localOffset = _u32(bytes, cursor + 42);
    final nameLength = _u16(bytes, cursor + 28);
    final extraLength = _u16(bytes, cursor + 30);
    final commentLength = _u16(bytes, cursor + 32);
    final name = utf8.decode(
      bytes.sublist(cursor + 46, cursor + 46 + nameLength),
    );
    final extra = bytes.sublist(
      cursor + 46 + nameLength,
      cursor + 46 + nameLength + extraLength,
    );
    var entryZip64 = false;
    for (var offset = 0; offset + 4 <= extra.length;) {
      final id = _u16(extra, offset);
      final size = _u16(extra, offset + 2);
      if (id == 0x0001) {
        entryZip64 = true;
        var field = offset + 4;
        if (dataSize == 0xffffffff) {
          dataSize = _u64(extra, field);
          field += 16;
        }
        if (localOffset == 0xffffffff) {
          localOffset = _u64(extra, field);
        }
      }
      offset += 4 + size;
    }
    if (_u32(bytes, localOffset) != 0x04034b50) {
      throw StateError('Bad local header at $localOffset.');
    }
    final localNameLength = _u16(bytes, localOffset + 26);
    final localExtraLength = _u16(bytes, localOffset + 28);
    final dataStart = localOffset + 30 + localNameLength + localExtraLength;
    final dataEnd = dataStart + dataSize;
    entries.add(
      _ZipEntry(
        name: name,
        data: bytes.sublist(dataStart, dataEnd),
        crc: crc,
        zip64: zip64 || entryZip64,
      ),
    );
    cursor += 46 + nameLength + extraLength + commentLength;
  }
  return entries;
}

bool _containsSignature(Uint8List bytes, int signature) {
  final pattern = ByteData(4)..setUint32(0, signature, Endian.little);
  final value = pattern.buffer.asUint8List();
  for (var i = 0; i + 4 <= bytes.length; i++) {
    if (bytes[i] == value[0] &&
        bytes[i + 1] == value[1] &&
        bytes[i + 2] == value[2] &&
        bytes[i + 3] == value[3]) {
      return true;
    }
  }
  return false;
}

int _findSignature(Uint8List bytes, int signature) {
  final pattern = ByteData(4)..setUint32(0, signature, Endian.little);
  final value = pattern.buffer.asUint8List();
  for (var i = bytes.length - 4; i >= 0; i--) {
    if (bytes[i] == value[0] &&
        bytes[i + 1] == value[1] &&
        bytes[i + 2] == value[2] &&
        bytes[i + 3] == value[3]) {
      return i;
    }
  }
  return -1;
}

int _u16(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _u32(List<int> bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

int _u64(List<int> bytes, int offset) =>
    _u32(bytes, offset) | (_u32(bytes, offset + 4) << 32);
