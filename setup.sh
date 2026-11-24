#!/usr/bin/env bash
# Prépare le projet : génère android/ios, applique les permissions, crée l'icône.
set -e
cd "$(dirname "$0")"

# flutter create ne doit pas écraser nos fichiers
BK=$(mktemp -d)
cp -r lib assets test pubspec.yaml "$BK"/
flutter create --org com.bomoko --project-name lexika --platforms android,ios .
rm -rf lib assets test pubspec.yaml
cp -r "$BK"/lib "$BK"/assets "$BK"/test "$BK"/pubspec.yaml .

flutter pub get
python3 patch_platforms.py
dart run flutter_launcher_icons
flutter analyze
echo
echo "Prêt. Lancez :  flutter run"
