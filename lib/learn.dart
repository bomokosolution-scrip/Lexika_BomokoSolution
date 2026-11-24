import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core.dart';
import 'data.dart';
import 'ui.dart';

/// Entrées traduites dans la langue source ET la langue cible.
List<Entry> learnPool(AppState s) =>
    entries.where((e) => e.w(s.src) != null && e.w(s.dst) != null).toList();

// ───────────────────────── Hub Apprendre ─────────────────────────
class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final pool = learnPool(s);
    final src = langOf(s.src), dst = langOf(s.dst);
    final ready = pool.length >= 4;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
      Reveal(
        index: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kIndigo, kViolet]),
            boxShadow: [BoxShadow(color: kViolet.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎯 VOTRE PROGRESSION',
                style: TextStyle(color: kGold, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              _stat('${s.learned.length}', 'mots appris'),
              _stat('${s.best}/10', 'record quiz'),
              _stat('${pool.length}', 'mots ${src.flag}→${dst.flag}'),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Reveal(
        index: 1,
        child: _ModeCard(
          icon: Icons.quiz_rounded,
          title: 'Quiz',
          subtitle: '10 questions : ${src.flag} → ${dst.flag}',
          enabled: ready,
          onTap: () => Navigator.push(context, fadeRoute(const QuizPage())),
        ),
      ),
      const SizedBox(height: 12),
      Reveal(
        index: 2,
        child: _ModeCard(
          icon: Icons.style_rounded,
          title: 'Cartes de révision',
          subtitle: 'Retournez les cartes et mémorisez',
          enabled: pool.isNotEmpty,
          onTap: () => Navigator.push(context, fadeRoute(const FlashcardsPage())),
        ),
      ),
      if (!ready)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Pas assez de mots disponibles pour cette paire de langues. Choisissez-en une autre dans le dictionnaire.',
            style: TextStyle(color: hintOf(context)),
          ),
        ),
    ]);
  }

  Widget _stat(String big, String small) => Expanded(
        child: Column(children: [
          Text(big, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(small, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ]),
      );
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool enabled;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: surfaceOf(context),
        elevation: 2,
        shadowColor: kIndigo.withOpacity(.2),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [kGold, Color(0xFFFF9F43)]),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: hintOf(context), fontSize: 13)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Quiz ─────────────────────────
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _rnd = Random();
  bool _init = false;
  List<Entry> _qs = [];
  List<String> _opts = [];
  int _i = 0, _score = 0, _streak = 0;
  String? _picked;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _start();
    }
  }

  void _start() {
    final s = Scope.of(context);
    final pool = learnPool(s)..shuffle(_rnd);
    _qs = pool.take(10).toList();
    _i = 0;
    _score = 0;
    _streak = 0;
    _picked = null;
    _done = false;
    _buildOptions();
  }

  void _buildOptions() {
    if (_qs.isEmpty) return;
    final s = Scope.of(context);
    final cur = _qs[_i];
    final right = cur.w(s.dst)!;
    final others = learnPool(s)
        .where((e) => e.id != cur.id)
        .map((e) => e.w(s.dst)!)
        .where((w) => w != right)
        .toSet()
        .toList()
      ..shuffle(_rnd);
    _opts = [right, ...others.take(3)]..shuffle(_rnd);
  }

  void _pick(String o) {
    if (_picked != null) return;
    final s = Scope.of(context);
    final ok = o == _qs[_i].w(s.dst);
    HapticFeedback.mediumImpact();
    setState(() {
      _picked = o;
      if (ok) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    final s = Scope.of(context);
    if (_i + 1 >= _qs.length) {
      s.recordScore(_score);
      setState(() => _done = true);
    } else {
      setState(() {
        _i++;
        _picked = null;
        _buildOptions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src), dst = langOf(s.dst);
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Quiz', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          actions: [
            if (!_done && _streak >= 2)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Text('🔥 $_streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              ),
          ],
        ),
        body: _qs.length < 4
            ? const Center(child: Text('Pas assez de mots pour ce quiz.'))
            : _done
                ? _result()
                : _question(s, src, dst),
      ),
    );
  }

  Widget _question(AppState s, Lang src, Lang dst) {
    final e = _qs[_i];
    final right = e.w(s.dst)!;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: (_i + (_picked != null ? 1 : 0)) / _qs.length, minHeight: 8),
      ),
      const SizedBox(height: 6),
      Text('Question ${_i + 1} / ${_qs.length}', style: TextStyle(color: hintOf(context), fontSize: 12)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kIndigo, kViolet]),
        ),
        child: Column(children: [
          Text(e.emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text('${src.flag}  ${e.w(src.code)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SpeakButton(text: e.w(src.code)!, lang: src, size: 44, id: e.id),
          const SizedBox(height: 6),
          Text('Traduction en ${dst.name} ${dst.flag}', style: const TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 18),
      for (final o in _opts)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _option(o, right),
        ),
      if (_picked != null) ...[
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            onPressed: _next,
            child: Text(_i + 1 >= _qs.length ? 'Voir le résultat' : 'Suivant', style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    ]);
  }

  Widget _option(String o, String right) {
    final answered = _picked != null;
    final isRight = o == right;
    final isPicked = o == _picked;
    Color bg = surfaceOf(context);
    Color border = Colors.transparent;
    if (answered && isRight) {
      bg = Colors.green.withOpacity(.2);
      border = Colors.green;
    } else if (answered && isPicked) {
      bg = Colors.red.withOpacity(.18);
      border = Colors.redAccent;
    }
    return GestureDetector(
      onTap: () => _pick(o),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(children: [
          Expanded(child: Text(o, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          if (answered && isRight) const Icon(Icons.check_circle_rounded, color: Colors.green),
          if (answered && isPicked && !isRight) const Icon(Icons.cancel_rounded, color: Colors.redAccent),
        ]),
      ),
    );
  }

  Widget _result() {
    final pct = _score / _qs.length;
    final (emoji, msg) = pct >= .9
        ? ('🏆', 'Magnifique !')
        : pct >= .6
            ? ('🎉', 'Très bien !')
            : pct >= .3
                ? ('💪', 'Continuez, ça vient !')
                : ('📚', 'Révisez et réessayez !');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (_, v, c) => Transform.scale(scale: v, child: c),
            child: Text(emoji, style: const TextStyle(fontSize: 96)),
          ),
          const SizedBox(height: 12),
          Text('$_score / ${_qs.length}', style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w700)),
          Text(msg, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kViolet, minimumSize: const Size(220, 52)),
            onPressed: () => setState(_start),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Rejouer'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Terminer')),
        ]),
      ),
    );
  }
}

// ───────────────────────── Cartes de révision ─────────────────────────
class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});
  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool _init = false, _front = true, _done = false;
  List<Entry> _deck = [];
  int _i = 0, _known = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _start();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _start() {
    final s = Scope.of(context);
    _deck = (learnPool(s)..shuffle()).take(20).toList();
    _i = 0;
    _known = 0;
    _done = false;
    _front = true;
    _flip.value = 0;
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_front) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
    _front = !_front;
  }

  void _next(bool known) {
    final s = Scope.of(context);
    if (known) {
      _known++;
      s.markLearned(_deck[_i].id);
    }
    if (_i + 1 >= _deck.length) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _i++;
      _front = true;
      _flip.value = 0;
    });
  }

  Widget _face(Widget child, {required bool back}) => Container(
        width: double.infinity,
        height: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: back ? const [kGold, Color(0xFFFF9F43)] : const [kIndigo, kViolet],
          ),
          boxShadow: [BoxShadow(color: kViolet.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Center(child: child),
      );

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src), dst = langOf(s.dst);
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Cartes de révision', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: _deck.isEmpty
            ? const Center(child: Text('Aucune carte disponible.'))
            : _done
                ? _summary()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: _i / _deck.length, minHeight: 8),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Carte ${_i + 1} / ${_deck.length}',
                            style: TextStyle(color: hintOf(context), fontSize: 12)),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _toggle,
                        child: AnimatedBuilder(
                          animation: _flip,
                          builder: (_, __) {
                            final a = _flip.value * pi;
                            final back = a > pi / 2;
                            final e = _deck[_i];
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(a),
                              child: back
                                  ? Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(pi),
                                      child: _face(back: true, Column(mainAxisSize: MainAxisSize.min, children: [
                                        Text('${dst.flag}  ${e.w(dst.code)}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 16),
                                        SpeakButton(text: e.w(dst.code)!, lang: dst, size: 48, id: e.id),
                                        if (e.example.isNotEmpty) ...[
                                          const SizedBox(height: 14),
                                          Text(e.example,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                                        ],
                                      ])),
                                    )
                                  : _face(back: false, Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text(e.emoji, style: const TextStyle(fontSize: 64)),
                                      const SizedBox(height: 10),
                                      Text('${src.flag}  ${e.w(src.code)}',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 16),
                                      const Text('Touchez pour retourner', style: TextStyle(color: Colors.white70)),
                                    ])),
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                            onPressed: () => _next(false),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('À revoir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: kTeal,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                            onPressed: () => _next(true),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Je sais'),
                          ),
                        ),
                      ]),
                    ]),
                  ),
      ),
    );
  }

  Widget _summary() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎓', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 12),
            Text('$_known / ${_deck.length} mots maîtrisés',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kViolet, minimumSize: const Size(220, 52)),
              onPressed: () => setState(_start),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Recommencer'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Terminer')),
          ]),
        ),
      );
}
