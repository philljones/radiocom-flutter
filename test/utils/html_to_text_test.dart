import 'package:cuacfm/utils/html_to_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves spacing between adjacent HTML paragraphs', () {
    expect(
      htmlToPlainText(
        '<p>Music and stories starting the day.</p>'
        '<p>Presented by Rhys Bennett.</p>',
      ),
      'Music and stories starting the day. Presented by Rhys Bennett.',
    );
  });

  test('collapses formatting whitespace into single spaces', () {
    expect(
      htmlToPlainText('<p>First line</p>\n\n<div>Second line</div>'),
      'First line Second line',
    );
  });
}
