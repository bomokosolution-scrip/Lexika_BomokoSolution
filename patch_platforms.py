#!/usr/bin/env python3
"""Ajoute les permissions micro / synthèse vocale aux dossiers android/ et ios/
générés par `flutter create`. Peut être relancé sans risque."""
import pathlib, re

manifest = pathlib.Path("android/app/src/main/AndroidManifest.xml")
if manifest.exists():
    x = manifest.read_text(encoding="utf-8")
    if "RECORD_AUDIO" not in x:
        block = """
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <queries>
        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
        <intent><action android:name="android.speech.RecognitionService"/></intent>
    </queries>"""
        i = x.index("<manifest")
        j = x.index(">", i) + 1
        x = x[:j] + block + x[j:]
    x = re.sub(r'android:label="[^"]*"', 'android:label="Bomoko Lexika"', x, count=1)
    manifest.write_text(x, encoding="utf-8")
    print("AndroidManifest.xml OK")

plist = pathlib.Path("ios/Runner/Info.plist")
if plist.exists():
    x = plist.read_text(encoding="utf-8")
    if "NSMicrophoneUsageDescription" not in x:
        add = """	<key>NSMicrophoneUsageDescription</key>
	<string>Lexika utilise le micro pour la recherche vocale.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Lexika utilise la reconnaissance vocale pour rechercher un mot.</string>
"""
        k = x.rindex("</dict>")
        x = x[:k] + add + x[k:]
    x = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*", r"\1Bomoko Lexika", x, count=1)
    plist.write_text(x, encoding="utf-8")
    print("Info.plist OK")

# --- Gradle : forcer compileSdk 36 pour tous les plugins (erreur « requires compileSdk 36 » avec file_picker, etc.) ---
KTS = """// Lexika: compileSdk 36
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
            }
        }
    }
}

"""
GROOVY = """// Lexika: compileSdk 36
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android { compileSdkVersion 36 }
        }
    }
}

"""
for name, snippet in (("android/build.gradle.kts", KTS), ("android/build.gradle", GROOVY)):
    g = pathlib.Path(name)
    if g.exists():
        t = g.read_text(encoding="utf-8")
        if "Lexika: compileSdk 36" not in t:
            k = t.find("subprojects {")           # doit précéder evaluationDependsOn(":app")
            t = (t[:k] + snippet + t[k:]) if k >= 0 else (t + "\n" + snippet)
            g.write_text(t, encoding="utf-8")
        print(name, "OK")
