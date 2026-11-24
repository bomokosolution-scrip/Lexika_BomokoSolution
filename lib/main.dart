import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core.dart';
import 'data.dart';
import 'pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  await loadEntries();
  applyCustom(state.custom);
  runApp(LexikaApp(state: state));
}

ThemeData _theme(Brightness b) {
  final base = ThemeData(brightness: b);
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme.fromSeed(seedColor: kIndigo, brightness: b),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    scaffoldBackgroundColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class LexikaApp extends StatelessWidget {
  final AppState state;
  const LexikaApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scope(
      state: state,
      child: Builder(builder: (context) {
        final s = Scope.of(context);
        return MaterialApp(
          title: 'Bomoko Lexika',
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashPage(),
        );
      }),
    );
  }
}
