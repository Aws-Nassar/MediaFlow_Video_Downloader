import 'package:flutter_test/flutter_test.dart';
import 'package:mediaflow/drive/drive_html.dart';

void main() {
  test('decodes entities and strips tags from labels', () {
    expect(
      htmlToText('<b>Plan</b> &amp; Scope&nbsp;2026'),
      'Plan & Scope 2026',
    );
    expect(decodeHtmlEntities('A &#38; B &#x26; C'), 'A & B & C');
  });

  test('reads quoted attributes without matching data- prefixes', () {
    expect(
      attributeValue(
        '<a data-href="wrong" href="https://drive.google.com/file/d/abc/view">',
        'href',
      ),
      'https://drive.google.com/file/d/abc/view',
    );
    expect(
      attributeValue("<a href='https://example.com/a?x=1&amp;y=2'>", 'href'),
      'https://example.com/a?x=1&y=2',
    );
    expect(
      attributeValue('<a href="https://example.com/a" class="x">', 'href'),
      'https://example.com/a',
    );
    expect(attributeValue('<a class="x">', 'href'), isNull);
  });

  test('parses content-disposition filenames', () {
    expect(
      fileNameFromDisposition('attachment; filename="report.pdf"'),
      'report.pdf',
    );
    expect(
      fileNameFromDisposition("attachment; filename*=UTF-8''My%20File.mp4"),
      'My File.mp4',
    );
    expect(
      fileNameFromDisposition('attachment; filename="folder/name.txt"'),
      'folder_name.txt',
    );
    expect(fileNameFromDisposition(null), isNull);
  });

  test('reads media type and content length case-insensitively', () {
    expect(
      mediaType({'Content-Type': 'video/mp4; charset=binary'}),
      'video/mp4',
    );
    expect(contentLength({'Content-Length': '123'}), 123);
    expect(contentLength({'Content-Length': '0'}), isNull);
    expect(contentLength({}), isNull);
  });

  test('extracts a hidden confirmation form with its query values', () {
    final html = '''
      <html><body>
      <form action="https://drive.google.com/search">
        <input type="search" name="q" value="ignored">
      </form>
      <form action="https://drive.usercontent.google.com/download" method="get">
        <input type="hidden" name="id" value="fixtureFileADDDDDDDDDDDDDD">
        <input type="hidden" name="export" value="download">
        <input type="hidden" name="confirm" value="t">
        <input type="hidden" name="uuid" value="abc">
      </form>
      </body></html>
    ''';

    final uri = DriveConfirmationForm.parse(
      html,
      Uri.parse('https://drive.google.com/uc?id=fixtureFileADDDDDDDDDDDDDD'),
    );

    expect(uri, isNotNull);
    expect(uri!.host, 'drive.usercontent.google.com');
    expect(uri.queryParameters['id'], 'fixtureFileADDDDDDDDDDDDDD');
    expect(uri.queryParameters['confirm'], 't');
    expect(uri.queryParameters['uuid'], 'abc');
  });

  test('resolves a relative confirmation action against the page', () {
    final uri = DriveConfirmationForm.parse(
      '<form action="/download"><input name="id" value="abc"></form>',
      Uri.parse('https://drive.google.com/uc?id=abc'),
    );

    expect(uri, isNotNull);
    expect(uri!.host, 'drive.google.com');
    expect(uri.path, '/download');
  });

  test('rejects confirmation forms on non-Google hosts', () {
    final uri = DriveConfirmationForm.parse(
      '<form action="https://evil.example/download">'
      '<input name="id" value="abc"></form>',
      Uri.parse('https://drive.google.com/uc?id=abc'),
    );

    expect(uri, isNull);
  });

  test('falls back to a confirmation anchor', () {
    final uri = DriveConfirmationForm.parse(
      '<a href="https://drive.google.com/uc?export=download&amp;confirm=t&amp;id=abc">'
      'Download anyway</a>',
      Uri.parse('https://drive.google.com/uc?id=abc'),
    );

    expect(uri, isNotNull);
    expect(uri!.queryParameters['confirm'], 't');
  });
}
