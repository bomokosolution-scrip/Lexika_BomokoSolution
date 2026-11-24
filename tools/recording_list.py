#!/usr/bin/env python3
"""Génère la liste des mots à faire enregistrer pour une langue.
Usage : python3 tools/recording_list.py ln   ->  recording_ln.csv (id ; mot ; nom du fichier)"""
import sys, csv, pathlib
LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
if len(sys.argv) != 2 or sys.argv[1] not in LANGS:
    sys.exit("Langue attendue parmi : " + " ".join(LANGS))
lang = sys.argv[1]; col = 4 + LANGS.index(lang)
rows = []
for line in pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines():
    if not line.strip() or line.startswith("#"): continue
    p = line.split("|")
    if len(p) == 4 + len(LANGS) and p[col].strip():
        rows.append((p[0], p[col].strip().split(" / ")[0], f"{p[0]}.mp3"))
out = pathlib.Path(f"recording_{lang}.csv")
with out.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f, delimiter=";"); w.writerow(["id", "mot_a_enregistrer", "fichier"]); w.writerows(rows)
print(f"{len(rows)} mots -> {out}")
