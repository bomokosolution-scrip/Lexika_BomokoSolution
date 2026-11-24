# Bomoko Lexika — dictionnaire multilingue

Application développée par **Bomoko Solution** · Identifiant du paquet : `com.bomoko.lexika` · Version 1.1.0

**18 langues** : français, lingala, anglais (US/UK), swahili (RDC), tshiluba, kikongo, espagnol, portugais, allemand,
wallon, flamand, argot anglais, argot français, **afrikaans, espéranto, russe et zoulou**.

## Fonctions
Dictionnaire avec recherche texte et vocale · prononciation (synthèse vocale) · fiche détaillée dans les 18 langues,
avec **prononciation figurée et phrases d'exemple** (lingala, swahili, kikongo, tshiluba, espagnol) · mot du jour ·
catégories (dont conjugaison, proverbes, spiritualité) · favoris et historique · quiz · cartes de révision ·
définitions · enregistrements natifs · import CSV · mode sombre · fonctionne hors ligne · présentation au premier lancement.

## Contenu
Voir `MERGE_REPORT_CSV_PACK.md` : couverture par langue, mots ajoutés, valeurs en conflit à faire trancher.

## Ajouter ou corriger des mots
Tout est dans `assets/dictionary.txt` (un mot par ligne) :
`id|catégorie|emoji|exemple|fr|ln|en_US|en_GB|sw|lua|kg|es|pt|de|wa|nl_BE|en_SL|fr_SL|af|eo|ru|zu`
Une case vide = « pas encore disponible ». Aucun code à modifier.
Les prononciations et phrases d'exemple sont dans `assets/extras.txt` : `id|langue|prononciation|phrase|traduction française`.
Les anciens fichiers d'import à 14 langues (18 colonnes) restent acceptés.

## Fusionner de nouveaux CSV
Déposer les fichiers dans `tools/sources_csv/` puis : `python3 tools/merge_csv_pack.py` (option `--dry` pour simuler).
La valeur de la source passe en premier, l'ancienne est conservée en variante ; le bilan est écrit dans `MERGE_REPORT_CSV_PACK.md`.

## Définitions
`assets/definitions.txt` : une ligne `id|définition`. Affichée sur la fiche du mot.
Définitions anglaises (`assets/definitions_en.txt`, Webster 1913, domaine public) et swahili (`assets/definitions_sw.txt`).

## Enregistrements natifs
Déposez `assets/audio/<langue>/<id>.mp3` (ex. `assets/audio/ln/bonjour.mp3`) : l'application le joue à la place de la voix
de synthèse. Liste des mots à enregistrer : `python3 tools/recording_list.py ln`.

## Importer des mots depuis l'application
Réglages → Importer des mots : fichier CSV/TXT ou texte collé. Si l'id existe, les cases remplies complètent le mot ;
sinon une nouvelle entrée est créée.

## Installation et compilation (équipe technique)
```
./setup.sh                          # prépare android/ios, permissions, icône, analyse
flutter run
flutter clean && flutter build apk --release
```
`patch_platforms.py` force `compileSdk 36` si nécessaire (voir le script).

## Compilation sur GitHub Actions
Le workflow `.github/workflows/build.yml` se lance à chaque push sur `main`, sur les pull requests, à la main
(onglet Actions → *Run workflow*) et sur les tags `v*`.
- **Android** : analyse, tests, puis APK et AAB (artefact `bomoko-lexika-android`).
- **iOS** (tag `v*` ou lancement manuel) : IPA non signé (artefact `bomoko-lexika-ios-unsigned`).
- **Tag `v*`** (ex. `git tag v1.1.0 && git push --tags`) : l'APK et l'AAB sont aussi joints à une release GitHub.

Signature Android de production (facultative) — secrets du dépôt (Settings → Secrets and variables → Actions) :
`ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
`ANDROID_KEY_ALIAS`. Sans ces secrets, la compilation réussit mais l'APK est signé avec la clé de debug
(inutilisable pour le Play Store).

## À savoir
- Les traductions en lingala, tshiluba, kikongo, wallon, afrikaans, espéranto, russe, zoulou et les argots, ainsi que le
  swahili de RDC, doivent être relues par des locuteurs natifs avant publication.
- Certaines langues n'ont pas de voix de synthèse native (lingala, tshiluba, kikongo, wallon, espéranto, zoulou) : une voix
  proche est utilisée (indiqué dans l'application).
- Sources et licences : `assets/SOURCES.md`.

© 2026 Bomoko Solution. Tous droits réservés.
