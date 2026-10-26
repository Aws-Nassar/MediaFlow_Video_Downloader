import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal process contract so the engine can be tested without spawning
/// yt-dlp or touching the network.
abstract interface class EngineProcess {
  int get pid;

  Stream<String> get stdoutLines;

  Stream<String> get stderrLines;

  Future<int> get exitCode;

  Future<void> kill();
}

abstract interface class EngineProcessRunner {
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

class SystemEngineProcessRunner implements EngineProcessRunner {
  const SystemEngineProcessRunner();

  @override
  Future<EngineProcess> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: true,
      runInShell: false,
    );
    return _SystemEngineProcess(process);
  }
}

class _SystemEngineProcess implements EngineProcess {
  final Process _process;

  _SystemEngineProcess(this._process);

  @override
  int get pid => _process.pid;

  @override
  late final Stream<String> stdoutLines = _lines(_process.stdout);

  @override
  late final Stream<String> stderrLines = _lines(_process.stderr);

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> kill() async {
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', [
          '/PID',
          '${_process.pid}',
          '/T',
          '/F',
        ], runInShell: false);
      } on ProcessException {
        // The process may already have exited. Fall through to kill().
      }
    }
    _process.kill();
  }

  Stream<String> _lines(Stream<List<int>> bytes) {
    return bytes
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());
  }
}
