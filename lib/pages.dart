import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core.dart';
import 'data.dart';
import 'learn.dart';
import 'ui.dart';

Widget _card(Entry e, int i) =>
    EntryCard(key: ValueKey('${e.id}_$i'), e: e, index: i, detailBuilder: (x) => DetailPage(e: x));

// ───────────────────────── Splash ─────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final done = Scope.of(context).onboarded;
      Navigator.of(context).pushReplacement(fadeRoute(done ? const HomeShell() : const OnboardingPage()));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF14104F), kIndigo, kViolet]),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.12),
                  border: Border.all(color: kGold, width: 3),
                  boxShadow: [BoxShadow(color: kGold.withOpacity(.4), blurRadius: 40)],
                ),
                child: Padding(padding: const EdgeInsets.all(20), child: Image.asset('assets/icon/logo.png')),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: fade,
              child: Column(children: [
                Text('BOMOKO',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 6, color: kGold)),
                Text('Lexika',
                    style: GoogleFonts.poppins(
                        fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: 3, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Le dictionnaire de toutes vos langues',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 28),
                SizedBox(
                  width: 280,
                  child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    for (final l in langs) Text(l.flag, style: const TextStyle(fontSize: 22)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Présentation ─────────────────────────
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _i = 0;

  static final _pages = [
    ('🌍', '${langs.length} langues, un seul dictionnaire', 'Français, lingala, swahili, tshiluba, kikongo, anglais, espagnol, portugais, allemand, russe, afrikaans, zoulou, espéranto, wallon, flamand et deux argots.'),
    ('🔊', 'Écoutez les prononciations', 'Touchez le haut-parleur pour entendre un mot. Réglez la vitesse dans les réglages.'),
    ('🎓', 'Apprenez en vous amusant', 'Quiz, cartes de révision, favoris et mot du jour pour progresser chaque jour.'),
  ];

  void _finish() {
    Scope.of(context).finishOnboarding();
    Navigator.of(context).pushReplacement(fadeRoute(const HomeShell()));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _pages.length - 1;
    return AppBackground(
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Passer')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey(i),
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (_, v, c) => Transform.scale(scale: v, child: c),
                      child: Container(
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [kIndigo, kViolet]),
                          boxShadow: [BoxShadow(color: kViolet.withOpacity(.4), blurRadius: 30)],
                        ),
                        child: Text(_pages[i].$1, style: const TextStyle(fontSize: 72)),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(_pages[i].$2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(_pages[i].$3, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: hintOf(context))),
                  ]),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  width: i == _i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _i ? kViolet : kViolet.withOpacity(.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kViolet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => last
                      ? _finish()
                      : _pc.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
                  child: Text(last ? 'Commencer' : 'Suivant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Coque principale ─────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  void go(int i) => setState(() => tab = i);

  Widget _page() {
    switch (tab) {
      case 0:
        return const DictionaryPage();
      case 1:
        return ExplorePage(onGoDict: () => go(0));
      case 2:
        return const LearnPage();
      case 3:
        return FavoritesPage(onGoDict: () => go(0));
      default:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    return AppBackground(
      child: Scaffold(
        extendBody: true,
        drawer: LexikaDrawer(current: tab, onSelect: go),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Builder(
            builder: (c) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 28),
              onPressed: () => Scaffold.of(c).openDrawer(),
            ),
          ),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            Text('Lexika', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ]),
          actions: [
            IconButton(
              tooltip: 'Thème',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (w, a) => RotationTransition(turns: a, child: ScaleTransition(scale: a, child: w)),
                child: Icon(s.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, key: ValueKey(s.dark)),
              ),
              onPressed: () => s.setDark(!s.dark),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(tab), child: _page()),
        ),
        bottomNavigationBar: FloatingNav(index: tab, onTap: go),
      ),
    );
  }
}

// ───────────────────────── Dictionnaire ─────────────────────────
class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});
  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _ctl = TextEditingController();
  String q = '';
  int turns = 0;
  bool listening = false;

  @override
  void dispose() {
    Voice.stop();
    _ctl.dispose();
    super.dispose();
  }

  List<Entry> _results(String? cat) {
    final n = norm(q.trim());
    return entries.where((e) {
      if (cat != null && e.cat != cat) return false;
      if (n.isEmpty) return true;
      return e.t.values.any((w) => norm(w).contains(n)) || norm(e.example).contains(n);
    }).toList();
  }

  Future<void> _mic(AppState s) async {
    if (listening) {
      await Voice.stop();
      setState(() => listening = false);
      return;
    }
    setState(() => listening = true);
    final ok = await Voice.listen(langOf(s.src), (text, done) {
      if (!mounted) return;
      setState(() {
        q = text;
        _ctl.text = text;
        if (done) listening = false;
      });
    });
    if (!ok && mounted) {
      setState(() => listening = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Recherche vocale indisponible sur cet appareil.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final res = _results(s.cat);
    final cats = entries.map((e) => e.cat).toSet().toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceOf(context),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: kIndigo.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Expanded(child: LangBtn(code: s.src, onTap: () => showLangPicker(context, s.src, s.setSrc))),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => turns++);
                    s.swap();
                  },
                  child: AnimatedRotation(
                    turns: turns / 2,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [kGold, Color(0xFFFF9F43)])),
                      child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(child: LangBtn(code: s.dst, onTap: () => showLangPicker(context, s.dst, s.setDst))),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctl,
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                hintText: 'Rechercher dans les ${langs.length} langues…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (q.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _ctl.clear();
                        setState(() => q = '');
                      },
                    ),
                  IconButton(
                    tooltip: 'Recherche vocale',
                    icon: Icon(listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: listening ? Colors.redAccent : null),
                    onPressed: () => _mic(s),
                  ),
                ]),
                filled: true,
                fillColor: surfaceOf(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final c in [null, ...cats])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c ?? 'Tous'),
                      selected: s.cat == c,
                      onSelected: (_) => s.setCat(c),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      if (res.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, size: 64, color: hintOf(context)),
              const SizedBox(height: 8),
              const Text('Aucun mot trouvé'),
            ]),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          sliver: SliverList.builder(itemCount: res.length, itemBuilder: (_, i) => _card(res[i], i)),
        ),
    ]);
  }
}

// ───────────────────────── Détail d'un mot ─────────────────────────
class DetailPage extends StatelessWidget {
  final Entry e;
  const DetailPage({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src);
    final fav = s.favs.contains(e.id);
    return AppBackground(
      child: Scaffold(
        body: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: kIndigo,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: fav ? Colors.redAccent : Colors.white),
                onPressed: () => s.toggleFav(e.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(e.w(src.code) ?? e.id,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kIndigo, kViolet]),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 30),
                child: Hero(
                  tag: 'emoji_${e.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(e.emoji, style: const TextStyle(fontSize: 84)),
                  ),
                ),
              ),
            ),
          ),
          if (e.example.isNotEmpty)
          SliverToBoxAdapter(
            child: Reveal(
              index: 0,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGold.withOpacity(.5)),
                ),
                child: Row(children: [
                  const Icon(Icons.format_quote_rounded, color: kGold, size: 30),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.example, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15))),
                  SpeakButton(text: e.example, lang: langs.first, size: 36),
                ]),
              ),
            ),
          ),
          if (e.definition != null || e.definitionEn != null || e.definitionSw != null)
            SliverToBoxAdapter(
              child: Reveal(
                index: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surfaceOf(context), borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DÉFINITION',
                        style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 11)),
                    const SizedBox(height: 6),
                    if (e.definition != null)
                      Text(e.definition!, style: const TextStyle(fontSize: 15, height: 1.4)),
                    if (e.definitionEn != null) ...[
                      const SizedBox(height: 12),
                      Text('DEFINITION (ENGLISH)',
                          style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(e.definitionEn!, style: TextStyle(fontSize: 14, height: 1.4, color: hintOf(context))),
                    ],
                    if (e.definitionSw != null) ...[
                      const SizedBox(height: 12),
                      Text('MAANA (KISWAHILI)',
                          style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(e.definitionSw!, style: TextStyle(fontSize: 14, height: 1.4, color: hintOf(context))),
                    ],
                  ]),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList.builder(
              itemCount: langs.length,
              itemBuilder: (c, i) {
                final l = langs[i];
                final word = e.w(l.code);
                final x = e.x(l.code);
                final hi = l.code == s.src || l.code == s.dst;
                return Reveal(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceOf(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: hi ? kViolet : Colors.transparent, width: 1.6),
                      ),
                      child: Row(children: [
                        Text(l.flag, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.name, style: TextStyle(fontSize: 11.5, color: hintOf(context))),
                            Text(word ?? 'pas encore disponible',
                                style: word == null
                                    ? TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: hintOf(context))
                                    : const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            if (word != null && x != null && x.pron.isNotEmpty)
                              Text('🗣 ${x.pron}',
                                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: accentOf(context))),
                            if (word != null && hasAudio(l.code, e.id))
                              const Text('🎙️ enregistrement natif', style: TextStyle(fontSize: 10.5, color: kTeal))
                            else if (word != null && !l.nativeVoice)
                              Text('voix approchante', style: TextStyle(fontSize: 10.5, color: hintOf(context))),
                            if (word != null && x != null && x.example.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(x.example, style: const TextStyle(fontSize: 13.5, height: 1.3)),
                              if (x.exampleFr.isNotEmpty)
                                Text(x.exampleFr,
                                    style: TextStyle(fontSize: 12, height: 1.3, color: hintOf(context))),
                            ],
                          ]),
                        ),
                        if (word != null) ...[
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: word));
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(SnackBar(content: Text('« $word » copié')));
                            },
                          ),
                          SpeakButton(text: word, lang: l, size: 40, id: e.id),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Explorer ─────────────────────────
class ExplorePage extends StatelessWidget {
  final VoidCallback onGoDict;
  const ExplorePage({super.key, required this.onGoDict});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src), dst = langOf(s.dst);
    final pool = learnPool(s);
    final cats = entries.map((e) => e.cat).toSet().toList();
    final w = pool.isEmpty
        ? null
        : pool[DateTime.now().difference(DateTime(DateTime.now().year)).inDays % pool.length];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
      if (w != null)
        Reveal(
          index: 0,
          child: GestureDetector(
            onTap: () {
              s.addHistory(w.id);
              Navigator.push(context, fadeRoute(DetailPage(e: w)));
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kIndigo, kViolet]),
                boxShadow: [BoxShadow(color: kViolet.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('✨ MOT DU JOUR',
                        style: TextStyle(color: kGold, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 10),
                    Text('${w.emoji}  ${w.w(src.code)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${dst.flag}  ${w.w(dst.code)}', style: const TextStyle(color: Colors.white70, fontSize: 17)),
                  ]),
                ),
                SpeakButton(text: w.w(dst.code)!, lang: dst, size: 52, id: w.id),
              ]),
            ),
          ),
        ),
      const SizedBox(height: 24),
      Text('Catégories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < cats.length; i++)
          Reveal(
            index: i,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                s.setCat(cats[i]);
                onGoDict();
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: surfaceOf(context), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entries.firstWhere((e) => e.cat == cats[i]).emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(cats[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${entries.where((e) => e.cat == cats[i]).length} entrées',
                      style: TextStyle(fontSize: 12, color: hintOf(context))),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 24),
      Text('Langues', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < langs.length; i++)
          Reveal(
            index: i,
            child: ActionChip(
              avatar: Text(langs[i].flag, style: const TextStyle(fontSize: 18)),
              label: Text(langs[i].name),
              backgroundColor: surfaceOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                s.setSrc(langs[i].code);
                onGoDict();
              },
            ),
          ),
      ]),
    ]);
  }
}

// ───────────────────────── Favoris ─────────────────────────
class FavoritesPage extends StatelessWidget {
  final VoidCallback onGoDict;
  const FavoritesPage({super.key, required this.onGoDict});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final favs = entries.where((e) => s.favs.contains(e.id)).toList();
    final hist = <Entry>[];
    for (final id in s.history) {
      final m = entries.where((e) => e.id == id);
      if (m.isNotEmpty) hist.add(m.first);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
      Text('Mes favoris', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (favs.isEmpty)
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: surfaceOf(context), borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            const Icon(Icons.favorite_border_rounded, size: 52, color: kViolet),
            const SizedBox(height: 10),
            const Text('Aucun favori pour le moment', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Appuyez sur ♡ dans le dictionnaire.', style: TextStyle(color: hintOf(context))),
            const SizedBox(height: 12),
            FilledButton(onPressed: onGoDict, child: const Text('Ouvrir le dictionnaire')),
          ]),
        )
      else
        for (var i = 0; i < favs.length; i++) _card(favs[i], i),
      if (hist.isNotEmpty) ...[
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Récemment consultés', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700))),
          TextButton(onPressed: s.clearHistory, child: const Text('Effacer')),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in hist)
            ActionChip(
              avatar: Text(e.emoji),
              label: Text(e.w(s.src) ?? e.id),
              backgroundColor: surfaceOf(context),
              onPressed: () => Navigator.push(context, fadeRoute(DetailPage(e: e))),
            ),
        ]),
      ],
    ]);
  }
}

// ───────────────────────── Réglages ─────────────────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _box(BuildContext c, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: surfaceOf(c), borderRadius: BorderRadius.circular(24)),
        child: Column(children: children),
      );

  Future<void> _confirm(BuildContext context, String title, VoidCallback onYes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (ok == true) onYes();
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src), dst = langOf(s.dst);
    final sample = entries.isEmpty ? '' : (entries.first.w(s.src) ?? '');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
      _box(context, [
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_rounded),
          title: const Text('Mode sombre'),
          value: s.dark,
          onChanged: s.setDark,
        ),
      ]),
      _box(context, [
        ListTile(
          leading: Text(src.flag, style: const TextStyle(fontSize: 26)),
          title: const Text('Langue source'),
          subtitle: Text(src.name),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showLangPicker(context, s.src, s.setSrc),
        ),
        ListTile(
          leading: Text(dst.flag, style: const TextStyle(fontSize: 26)),
          title: const Text('Langue cible'),
          subtitle: Text(dst.name),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showLangPicker(context, s.dst, s.setDst),
        ),
      ]),
      _box(context, [
        ListTile(
          leading: const Icon(Icons.speed_rounded),
          title: const Text('Vitesse de prononciation'),
          subtitle: const Text('Touchez le bouton pour tester'),
          trailing: SpeakButton(text: sample, lang: src, size: 38),
        ),
        Slider(value: s.rate, min: .2, max: .8, divisions: 12, label: s.rate.toStringAsFixed(2), onChanged: s.setRate),
      ]),
      _box(context, [
        ListTile(
          leading: const Icon(Icons.restart_alt_rounded),
          title: const Text('Réinitialiser la progression'),
          subtitle: Text('${s.learned.length} mots appris · record ${s.best}/10'),
          onTap: () => _confirm(context, 'Effacer la progression ?', s.resetProgress),
        ),
        ListTile(
          leading: const Icon(Icons.heart_broken_rounded),
          title: const Text('Vider les favoris'),
          subtitle: Text('${s.favs.length} favoris'),
          onTap: () => _confirm(context, 'Vider tous les favoris ?', s.clearFavs),
        ),
      ]),
      _box(context, [
        ListTile(
          leading: const Icon(Icons.upload_file_rounded),
          title: const Text('Importer des mots'),
          subtitle: Text(s.custom.isEmpty
              ? 'Fichier CSV ou texte : ajoutez ou complétez des traductions'
              : '${s.custom.length} ligne(s) importée(s)'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const _ImportSheet(),
          ),
        ),
        if (s.custom.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded),
            title: const Text('Supprimer les mots importés'),
            onTap: () => _confirm(context, 'Supprimer les mots importés ?', () async {
              s.clearCustom();
              await loadEntries();
              s.refresh();
            }),
          ),
      ]),
      _box(context, [
        const ListTile(
          leading: Icon(Icons.record_voice_over_rounded),
          title: Text('À propos des voix'),
          subtitle: Text(
              'La prononciation utilise les voix installées sur votre appareil. Pour le lingala, le tshiluba, le kikongo et le wallon, aucune voix native n’existe : une voix proche est utilisée.'),
        ),
        ListTile(
          leading: const Icon(Icons.fact_check_rounded),
          title: const Text('À propos des traductions'),
          subtitle: const Text(
              'Les entrées « pas encore disponible » attendent d’être complétées. Les langues africaines, le wallon et les argots doivent être relus par des locuteurs natifs.'),
        ),
      ]),
    ]);
  }
}

// ───────────────────────── Import de mots ─────────────────────────
class _ImportSheet extends StatefulWidget {
  const _ImportSheet();
  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _ctl = TextEditingController();
  String? msg;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _run(String text) {
    final s = Scope.of(context);
    final r = importText(text.replaceFirst('﻿', ''));
    s.addCustom(r.lines);
    setState(() => msg = '${r.added} ajoutée(s), ${r.updated} complétée(s), ${r.skipped} ignorée(s).');
  }

  Future<void> _pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt', 'tsv'],
        withData: true,
      );
      final bytes = r?.files.single.bytes;
      if (bytes == null) return;
      _run(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      if (mounted) setState(() => msg = 'Impossible de lire ce fichier.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Importer des mots', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Une ligne par mot : id, catégorie, emoji, exemple, puis les ${langs.length} traductions '
            '(${langs.map((l) => l.code).join(', ')}), '
            'séparés par | ; tabulation ou virgule. Si l’id existe déjà, les cases remplies complètent le mot.',
            style: TextStyle(color: hintOf(context), fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kViolet, minimumSize: const Size.fromHeight(50)),
            onPressed: _pick,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choisir un fichier CSV / TXT'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctl,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Ou collez vos lignes ici…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => _run(_ctl.text),
            child: const Text('Importer le texte collé'),
          ),
          if (msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(msg!, style: const TextStyle(fontWeight: FontWeight.w600, color: kTeal)),
            ),
        ]),
      ),
    );
  }
}
