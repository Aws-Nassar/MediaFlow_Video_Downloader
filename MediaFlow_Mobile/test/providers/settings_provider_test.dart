import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow_android/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toPythonOptions uses the keys the backend actually reads', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.init();

    settings.setConcurrentFragments(8);
    settings.setCookieFile('/tmp/cookies.txt');

    final options = settings.toPythonOptions();

    expect(options['concurrent'], 8);
    expect(options['cookie_file'], '/tmp/cookies.txt');
    expect(options.containsKey('concurrent_fragments'), isFalse);
    expect(options.containsKey('cookiefile'), isFalse);
  });
}
