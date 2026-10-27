import 'package:mediaflow/platform/platform_storage.dart';

/// Deterministic free-space probe for widget and state tests.
class FakeDiskSpaceProbe implements DiskSpaceProbe {
  FakeDiskSpaceProbe(this.bytes);

  int? bytes;
  int calls = 0;

  @override
  Future<int?> availableBytes(String path) async {
    calls++;
    return bytes;
  }
}
