import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';
import 'package:google_fonts/google_fonts.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color surfaceOf(BuildContext c) => isDark(c) ? const Color(0xFF211D63) : Colors.white;
Color accentOf(BuildContext c) => isDark(c) ? kGold : kViolet;
Color hintOf(BuildContext c) => Theme.of(c).hintColor;

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

// ───────────────────────── Arrière-plan ─────────────────────────
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final ink = dark ? Colors.white : kIndigo;
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF0E0B2E), Color(0xFF1B1464)]
                  : const [Color(0xFFF7F5FF), Color(0xFFE6E1FF)],
            ),
          ),
        ),
      ),
      Positioned(
        right: -70,
        bottom: 90,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -16 * _c.value),
              child: Transform.rotate(
                angle: 0.06 * (_c.value - .5),
                child: Image.asset('assets/icon/logo.png', width: 340, color: ink.withOpacity(.07), colorBlendMode: BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: -40,
        top: 120,
        child: IgnorePointer(
          child: Icon(Icons.menu_book_rounded, size: 170, color: ink.withOpacity(.035)),
        ),
      ),
      widget.child,
    ]);
  }
}

// ───────────────────────── Navigation ─────────────────────────
const navItems = [
  (Icons.menu_book_rounded, 'Dico'),
  (Icons.explore_rounded, 'Explorer'),
  (Icons.school_rounded, 'Apprendre'),
  (Icons.favorite_rounded, 'Favoris'),
  (Icons.settings_rounded, 'Réglages'),
];

class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const FloatingNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = Theme.of(context).colorScheme.onSurface.withOpacity(.55);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: surfaceOf(context),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: kIndigo.withOpacity(.25), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          for (var i = 0; i < navItems.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 6, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: i == index ? const LinearGradient(colors: [kIndigo, kViolet]) : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AnimatedScale(
                      scale: i == index ? 1.15 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(navItems[i].$1, size: 22, color: i == index ? Colors.white : off),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(navItems[i].$2,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                          color: i == index ? accentOf(context) : off)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class LexikaDrawer extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const LexikaDrawer({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(32))),
      child: ListView(padding: EdgeInsets.zero, children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 28, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kIndigo, kViolet]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: kGold, width: 2)),
              child: Image.asset('assets/icon/logo.png', width: 40, height: 40),
            ),
            const SizedBox(height: 16),
            Text('Bomoko Lexika',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700)),
            Text('${langs.length} langues · ${entries.length} entrées',
                style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < navItems.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ListTile(
              selected: i == current,
              selectedTileColor: kViolet.withOpacity(.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Icon(navItems[i].$1),
              title: Text(
                  const ['Dictionnaire', 'Explorer', 'Apprendre', 'Favoris', 'Réglages'][i],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                onSelect(i);
              },
            ),
          ),
        const Divider(indent: 24, endIndent: 24),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          secondary: const Icon(Icons.dark_mode_rounded),
          title: const Text('Mode sombre'),
          value: s.dark,
          onChanged: s.setDark,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('À propos'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Bomoko Lexika',
            applicationVersion: '1.1.0',
            applicationLegalese: '© 2026 Bomoko Solution. Tous droits réservés.',
            applicationIcon: Image.asset('assets/icon/logo.png', width: 44, height: 44),
            children: const [
              SizedBox(height: 12),
              Text('Dictionnaire multilingue de nouvelle génération.'),
              SizedBox(height: 8),
              Text('Développé par Bomoko Solution.'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Développé avec ❤️ par Bomoko Solution', style: TextStyle(color: hintOf(context), fontSize: 12)),
        ),
      ]),
    );
  }
}

// ───────────────────────── Composants ─────────────────────────
class SpeakButton extends StatefulWidget {
  final String text;
  final Lang lang;
  final double size;
  final String? id; // identifiant du mot : permet de jouer l'enregistrement natif
  const SpeakButton({super.key, required this.text, required this.lang, this.size = 40, this.id});
  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  bool on = false;

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    final rate = Scope.of(context).rate;
    setState(() => on = true);
    Speaker.speak(widget.text, widget.lang, rate, id: widget.id);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => on = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: on ? const [kGold, Color(0xFFFF9F43)] : const [kIndigo, kViolet]),
          boxShadow: on ? [BoxShadow(color: kGold.withOpacity(.6), blurRadius: 16, spreadRadius: 2)] : [],
        ),
        child: Icon(on ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
            color: Colors.white, size: widget.size * .5),
      ),
    );
  }
}

class Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const Reveal({super.key, required this.index, required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index.clamp(0, 8) * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

class EntryCard extends StatelessWidget {
  final Entry e;
  final int index;
  final Widget Function(Entry)? detailBuilder;
  const EntryCard({super.key, required this.e, required this.index, this.detailBuilder});

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final src = langOf(s.src), dst = langOf(s.dst);
    final fav = s.favs.contains(e.id);
    final sw = e.w(src.code), dw = e.w(dst.code);
    return Reveal(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: surfaceOf(context),
          elevation: 2,
          shadowColor: kIndigo.withOpacity(.2),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              s.addHistory(e.id);
              if (detailBuilder != null) {
                Navigator.push(context, fadeRoute(detailBuilder!(e)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Hero(
                  tag: 'emoji_${e.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kViolet.withOpacity(.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(e.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${src.flag}  ${sw ?? '—'}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${dst.flag}  ${dw ?? 'pas encore disponible'}',
                        style: dw == null
                            ? TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: hintOf(context))
                            : TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accentOf(context))),
                  ]),
                ),
                Column(children: [
                  if (dw != null) SpeakButton(text: dw, lang: dst, size: 38, id: e.id) else const SizedBox(height: 38),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => s.toggleFav(e.id),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                      child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(fav), color: fav ? Colors.redAccent : null),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

void showLangPicker(BuildContext context, String current, ValueChanged<String> onPick) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .92,
      builder: (_, ctl) => ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        for (final l in langs)
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            selected: l.code == current,
            selectedTileColor: kViolet.withOpacity(.12),
            leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
            title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(l.nativeVoice ? 'Voix native' : 'Voix approchante'),
            trailing: l.code == current ? const Icon(Icons.check_circle_rounded, color: kViolet) : null,
            onTap: () {
              Navigator.pop(c);
              onPick(l.code);
            },
          ),
      ]),
    ),
  );
}

class LangBtn extends StatelessWidget {
  final String code;
  final VoidCallback onTap;
  const LangBtn({super.key, required this.code, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final l = langOf(code);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(children: [
          Text(l.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(l.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          const Icon(Icons.expand_more_rounded, size: 18),
        ]),
      ),
    );
  }
}
