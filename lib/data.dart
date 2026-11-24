import 'package:flutter/services.dart' show rootBundle, AssetManifest;

/// Langues de Lexika. `tts` = locale utilisée pour la voix de synthèse.
/// `nativeVoice` = false quand aucune voix native n'existe (voix approchante).
class Lang {
  final String code, name, flag, tts;
  final bool nativeVoice;
  const Lang(this.code, this.name, this.flag, this.tts, {this.nativeVoice = true});
}

const langs = <Lang>[
  Lang('fr', 'Français (France)', '🇫🇷', 'fr-FR'),
  Lang('ln', 'Lingala', '🇨🇩', 'fr-FR', nativeVoice: false),
  Lang('en_US', 'English (US)', '🇺🇸', 'en-US'),
  Lang('en_GB', 'English (UK)', '🇬🇧', 'en-GB'),
  Lang('sw', 'Kiswahili (RDC)', '🇨🇩', 'sw-KE'),
  Lang('lua', 'Tshiluba (RDC)', '🇨🇩', 'fr-FR', nativeVoice: false),
  Lang('kg', 'Kikongo (RDC)', '🇨🇩', 'fr-FR', nativeVoice: false),
  Lang('es', 'Español', '🇪🇸', 'es-ES'),
  Lang('pt', 'Português', '🇵🇹', 'pt-PT'),
  Lang('de', 'Deutsch', '🇩🇪', 'de-DE'),
  Lang('wa', 'Wallon', '🇧🇪', 'fr-BE', nativeVoice: false),
  Lang('nl_BE', 'Vlaams (Flamand)', '🇧🇪', 'nl-BE'),
  Lang('en_SL', 'English Slang', '😎', 'en-US'),
  Lang('fr_SL', 'Argot français', '🥖', 'fr-FR'),
  Lang('af', 'Afrikaans', '🇿🇦', 'af-ZA'),
  Lang('eo', 'Esperanto', '🟢', 'it-IT', nativeVoice: false),
  Lang('ru', 'Русский (Russe)', '🇷🇺', 'ru-RU'),
  Lang('zu', 'isiZulu (Zoulou)', '🇿🇦', 'sw-KE', nativeVoice: false),
];

Lang langOf(String code) => langs.firstWhere((l) => l.code == code, orElse: () => langs.first);

class Entry {
  final String id, cat, emoji, example;
  final Map<String, String> t;
  Entry(this.id, this.cat, this.emoji, this.example, this.t);

  /// Le mot dans une langue, ou null s'il n'est pas encore disponible.
  String? w(String code) {
    final v = t[code]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Prononciation et phrase d'exemple dans une langue, si disponibles.
  Extra? x(String code) => extras['$code/$id'];

  /// Définition (en français), si disponible.
  String? get definition => definitions[id];

  /// Définition anglaise (Webster), si disponible.
  String? get definitionEn => definitionsEn[id];

  /// Maana ya Kiswahili (kamusi), si disponible.
  String? get definitionSw => definitionsSw[id];
}

/// Prononciation figurée et phrase d'exemple (avec sa traduction française) d'un mot dans une langue.
class Extra {
  final String pron, example, exampleFr;
  const Extra(this.pron, this.example, this.exampleFr);
}

List<Entry> entries = [];
Map<String, Extra> extras = {};
Map<String, String> definitions = {};
Map<String, String> definitionsEn = {};
Map<String, String> definitionsSw = {};
final Map<String, String> _audio = {};

/// Chemin de l'enregistrement natif (assets/audio/<langue>/<id>.mp3), ou null.
String? audioPath(String lang, String id) => _audio['$lang/$id'];
bool hasAudio(String lang, String id) => _audio.containsKey('$lang/$id');

/// Charge le dictionnaire, les définitions et la liste des enregistrements.
Future<void> loadEntries() async {
  final raw = await rootBundle.loadString('assets/dictionary.txt');
  final out = <Entry>[];
  for (final line in raw.split('\n')) {
    final l = line.trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    final p = _pad(l.split('|'));
    if (p.length != _cols) continue;
    out.add(_make(p));
  }
  entries = out;

  final defs = <String, String>{};
  try {
    final d = await rootBundle.loadString('assets/definitions.txt');
    for (final line in d.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final i = l.indexOf('|');
      if (i > 0) defs[l.substring(0, i)] = l.substring(i + 1).trim();
    }
  } catch (_) {}
  definitions = defs;

  final en = <String, String>{};
  try {
    final d = await rootBundle.loadString('assets/definitions_en.txt');
    for (final line in d.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final i = l.indexOf('|');
      if (i > 0) en[l.substring(0, i)] = l.substring(i + 1).trim();
    }
  } catch (_) {}
  definitionsEn = en;

  final sw = <String, String>{};
  try {
    final d = await rootBundle.loadString('assets/definitions_sw.txt');
    for (final line in d.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final i = l.indexOf('|');
      if (i > 0) sw[l.substring(0, i)] = l.substring(i + 1).trim();
    }
  } catch (_) {}
  definitionsSw = sw;

  final ex = <String, Extra>{};
  try {
    final d = await rootBundle.loadString('assets/extras.txt');
    for (final line in d.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final p = l.split('|');
      if (p.length < 5) continue;
      ex['${p[1]}/${p[0]}'] = Extra(p[2].trim(), p[3].trim(), p[4].trim());
    }
  } catch (_) {}
  extras = ex;

  _audio.clear();
  try {
    final m = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final k in m.listAssets()) {
      if (!k.startsWith('assets/audio/')) continue;
      final rest = k.substring('assets/audio/'.length);
      final slash = rest.indexOf('/');
      if (slash < 0) continue;
      final name = rest.substring(slash + 1);
      final dot = name.lastIndexOf('.');
      if (dot <= 0) continue;
      _audio['${rest.substring(0, slash)}/${name.substring(0, dot)}'] = k;
    }
  } catch (_) {}
}

int get _cols => 4 + langs.length;

/// Ancien format (14 langues) : complété par des cases vides pour les langues ajoutées depuis.
const _legacyCols = 18;
List<String> _pad(List<String> p) =>
    p.length == _legacyCols ? [...p, for (var i = _legacyCols; i < _cols; i++) ''] : p;

Entry _make(List<String> p) => Entry(p[0], p[1], p[2], p[3], {
      for (var i = 0; i < langs.length; i++) langs[i].code: p[4 + i].trim(),
    });

// ───────────────────────── Import de mots ─────────────────────────
class ImportResult {
  final int added, updated, skipped;
  final List<String> lines; // lignes valides (format « | »), à mémoriser
  ImportResult(this.added, this.updated, this.skipped, this.lines);
}

/// Fusionne une ligne : ajoute l'entrée, ou complète les cases vides/modifie les mots d'une entrée existante.
/// Retourne 1 si ajout, 2 si mise à jour, 0 sinon.
int _merge(List<String> p) {
  final id = p[0].trim().toLowerCase().replaceAll(' ', '_');
  if (id.isEmpty) return 0;
  for (final e in entries) {
    if (e.id == id) {
      var changed = false;
      for (var i = 0; i < langs.length; i++) {
        final v = p[4 + i].trim();
        if (v.isNotEmpty && e.t[langs[i].code] != v) {
          e.t[langs[i].code] = v;
          changed = true;
        }
      }
      return changed ? 2 : 0;
    }
  }
  final q = [...p]..[0] = id;
  entries.add(_make(q));
  return 1;
}

List<String>? _split(String line) {
  for (final d in ['|', ';', '\t', ',']) {
    final p = _pad(line.split(d));
    if (p.length == _cols) {
      return p.map((s) {
        var v = s.trim();
        if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) v = v.substring(1, v.length - 1);
        return v.replaceAll('|', '/');
      }).toList();
    }
  }
  return null;
}

/// Importe du texte CSV ou « | » : id, catégorie, emoji, exemple + un mot par langue (voir `langs`).
ImportResult importText(String text) {
  var added = 0, updated = 0, skipped = 0;
  final keep = <String>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final l = raw.trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    final p = _split(l);
    if (p == null) {
      skipped++;
      continue;
    }
    if (p[0].toLowerCase() == 'id') continue; // ligne d'en-tête
    final r = _merge(p);
    if (r == 1) added++;
    if (r == 2) updated++;
    if (r == 0) {
      skipped++;
      continue;
    }
    keep.add(p.join('|'));
  }
  return ImportResult(added, updated, skipped, keep);
}

/// Réapplique au démarrage les lignes déjà importées.
void applyCustom(List<String> lines) {
  for (final l in lines) {
    final p = _pad(l.split('|'));
    if (p.length == _cols) _merge(p);
  }
}

/// Minuscules sans accents, pour la recherche.
String norm(String s) {
  const a = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const b = 'aaaaaaceeeeiiiinooooouuuuyy';
  var r = s.toLowerCase().replaceAll('œ', 'oe').replaceAll('ß', 'ss').replaceAll('ɛ', 'e');
  for (var i = 0; i < a.length; i++) {
    r = r.replaceAll(a[i], b[i]);
  }
  return r;
}
