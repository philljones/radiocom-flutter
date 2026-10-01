import 'package:html/parser.dart' as html_parser;

String htmlToPlainText(String html) {
  final spacedHtml = html.replaceAllMapped(
    RegExp(r'</(?:p|div|li|h[1-6])\s*>', caseSensitive: false),
    (match) => '${match.group(0)} ',
  );
  final document = html_parser.parse(spacedHtml);
  return (document.body?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}
