import 'dart:convert';
import 'package:cuacfm/utils/simple_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  for (final contentType in ['application/rss+xml', 'application/rss+xml; charset=utf-8']) {
    test('RSS preserves Unicode with $contentType', () async {
      const text = 'Croeso—cafè, ‘cymuned’ a dŵr.';
      final response = http.Response.bytes(
        utf8.encode('<?xml version="1.0" encoding="utf-8"?><rss><channel><item><title>$text</title><description>$text</description></item></channel></rss>'),
        200, headers: {'content-type': contentType},
      );
      final client = SimpleClient();
      final items = await client.processResponse(Future.value(response), HTTPResponseType.XML);
      expect(items.single['title']['\$t'], text);
      expect(items.single['description']['\$t'], text);
      client.client.close();
    });
  }
}
