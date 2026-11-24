import 'package:flutter_test/flutter_test.dart';
import 'package:lexika/data.dart';

void main() {
  test('norm retire accents et ligatures', () {
    expect(norm('Éléphant'), 'elephant');
    expect(norm('Œil'), 'oeil');
    expect(norm('Straße'), 'strasse');
  });

  test('Entry.w ignore les cases vides', () {
    final e = Entry('x', 'c', '🙂', 'ex', {'fr': 'Bonjour', 'ln': ''});
    expect(e.w('fr'), 'Bonjour');
    expect(e.w('ln'), isNull);
    expect(e.w('zz'), isNull);
  });

  test('les 18 langues sont déclarées, y compris afrikaans, espéranto, russe et zoulou', () {
    expect(langs.length, 18);
    for (final c in ['af', 'eo', 'ru', 'zu']) {
      expect(langs.any((l) => l.code == c), isTrue);
    }
  });
}
