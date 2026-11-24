import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'data.dart';

const kIndigo = Color(0xFF2B2A8C);
const kViolet = Color(0xFF6C4DF0);
const kGold = Color(0xFFF5B942);
const kTeal = Color(0xFF14B8A6);

class AppState extends ChangeNotifier {
  String src = 'fr', dst = 'ln';
  String? cat;
  bool dark = false;
  bool onboarded = false;
  double rate = 0.45;
  int best = 0; // meilleur score au quiz
  Set<String> favs = {};
  Set<String> learned = {};
  List<String> history = [];
  List<String> custom = []; // lignes importées par l'utilisateur
  SharedPreferences? _p;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _p = p;
      src = p.getString('src') ?? src;
      dst = p.getString('dst') ?? dst;
      dark = p.getBool('dark') ?? false;
      onboarded = p.getBool('onboarded') ?? false;
      rate = p.getDouble('rate') ?? rate;
      best = p.getInt('best') ?? 0;
      favs = (p.getStringList('favs') ?? []).toSet();
      learned = (p.getStringList('learned') ?? []).toSet();
      history = p.getStringList('hist') ?? [];
      custom = p.getStringList('custom') ?? [];
    } catch (_) {}
  }

  void _commit(VoidCallback change) {
    change();
    final p = _p;
    if (p != null) {
      p.setString('src', src);
      p.setString('dst', dst);
      p.setBool('dark', dark);
      p.setBool('onboarded', onboarded);
      p.setDouble('rate', rate);
      p.setInt('best', best);
      p.setStringList('favs', favs.toList());
      p.setStringList('learned', learned.toList());
      p.setStringList('hist', history);
      p.setStringList('custom', custom);
    }
    notifyListeners();
  }

  void setSrc(String c) => _commit(() {
        final old = src;
        src = c;
        if (dst == c) dst = old;
      });

  void setDst(String c) => _commit(() {
        final old = dst;
        dst = c;
        if (src == c) src = old;
      });

  void swap() => _commit(() {
        final t = src;
        src = dst;
        dst = t;
      });

  void setCat(String? c) => _commit(() => cat = c);
  void setDark(bool v) => _commit(() => dark = v);
  void setRate(double v) => _commit(() => rate = v);
  void finishOnboarding() => _commit(() => onboarded = true);
  void recordScore(int score) => _commit(() {
        if (score > best) best = score;
      });
  void markLearned(String id) => _commit(() => learned.add(id));
  void resetProgress() => _commit(() {
        learned = {};
        best = 0;
      });
  void clearFavs() => _commit(() => favs = {});

  void toggleFav(String id) => _commit(() {
        if (!favs.remove(id)) favs.add(id);
      });

  void addHistory(String id) => _commit(() {
        history.remove(id);
        history.insert(0, id);
        if (history.length > 20) history.removeLast();
      });

  void clearHistory() => _commit(() => history = []);

  /// Mémorise des lignes importées (déjà fusionnées dans `entries`).
  void addCustom(List<String> lines) => _commit(() => custom = [...custom, ...lines]);

  /// Oublie les mots importés (recharger ensuite le dictionnaire de base).
  void clearCustom() => _commit(() => custom = []);

  /// Redessine l'interface après une modification de `entries`.
  void refresh() => notifyListeners();
}

class Scope extends InheritedNotifier<AppState> {
  const Scope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

/// Synthèse vocale (prononciation).
class Speaker {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();

  /// Joue l'enregistrement natif (assets/audio/<langue>/<id>.mp3) s'il existe,
  /// sinon la voix de synthèse.
  static Future<void> speak(String text, Lang l, double rate, {String? id}) async {
    if (id != null) {
      final path = audioPath(l.code, id);
      if (path != null) {
        try {
          await _tts.stop();
          await _player.stop();
          await _player.play(AssetSource(path.substring('assets/'.length)));
          return;
        } catch (_) {}
      }
    }
    try {
      final first = text.split(' / ').first;
      await _tts.stop();
      await _tts.setLanguage(l.tts);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(1.0);
      await _tts.speak(first);
    } catch (_) {}
  }
}

/// Recherche vocale (reconnaissance de la parole).
class Voice {
  static final SpeechToText _stt = SpeechToText();
  static bool _ready = false;

  static Future<bool> _init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize();
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Retourne false si la reconnaissance vocale est indisponible.
  static Future<bool> listen(Lang l, void Function(String text, bool done) onText) async {
    if (!await _init()) return false;
    try {
      await _stt.listen(
        localeId: l.tts.replaceAll('-', '_'),
        listenFor: const Duration(seconds: 8),
        onResult: (r) => onText(r.recognizedWords, r.finalResult),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }
}
