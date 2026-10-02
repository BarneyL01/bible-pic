import 'package:bible_pic/data/bulk_parse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses blocks with translation and topics', () {
    final v = parseVerseText('''
Psalm 23:1 (ESV)
The Lord is my shepherd;
I shall not want.
# comfort, trust

Isaiah 41:10
Fear not.
''');
    expect(v, hasLength(2));
    expect(v[0].reference, 'Psalm 23:1');
    expect(v[0].translation, 'ESV');
    expect(v[0].text, 'The Lord is my shepherd; I shall not want.');
    expect(v[0].topics, ['comfort', 'trust']);
    expect(v[1].translation, isNull);
    expect(v[1].topics, isEmpty);
  });

  test('skips blocks with no text', () {
    expect(parseVerseText('Only a reference'), isEmpty);
  });

  test('parses a JSON array and a {verses: []} object', () {
    const body =
        '[{"reference":"A 1:1","text":"t","topics":["x"],"favourite":true}]';
    expect(parseVerseJson(body).single.favourite, isTrue);
    expect(parseVerseJson('{"verses":$body}').single.topics, ['x']);
  });

  test('rejects JSON entries missing text', () {
    expect(() => parseVerseJson('[{"reference":"A"}]'), throwsFormatException);
    expect(() => parseVerseJson('"nope"'), throwsFormatException);
  });
}
