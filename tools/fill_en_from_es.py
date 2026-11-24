#!/usr/bin/env python3
"""Complète l'anglais (US et UK) des entrées qui ont un mot espagnol mais pas d'anglais, à partir des
flashcards espagnol→anglais (PDF « SpanishFlashCards »). Ne remplit que les correspondances sans ambiguïté
et signale les désaccords avec les valeurs déjà présentes.
Usage : python3 tools/fill_en_from_es.py SpanishFlashCards1-3000.pdf"""
import sys, re, subprocess, pathlib, collections
LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
ES, US, GB = (4 + LANGS.index(c) for c in ("es", "en_US", "en_GB"))
txt = subprocess.run(["pdftotext", "-layout", sys.argv[1], "-"], capture_output=True, text=True, errors="replace").stdout
fix = lambda s: s.encode("cp1252", errors="replace").decode("mac_roman")   # le PDF est en MacRoman mal décodé
gl = collections.defaultdict(list)
for line in txt.splitlines():
    for m in re.finditer(r"([^\d\s][^\d]*?)\s+(\d+)\s+([^\d]+?)\s+\2(?=\s|$)", line):
        es, en = fix(m.group(1).strip().lower().lstrip("<")), fix(m.group(3).strip())
        en = re.sub(r"^to\s+", "", en)
        if en not in gl[es]: gl[es].append(en)
# Le glossaire donne un seul sens par mot : pour ces mots français, il est faux ou trop éloigné. Valeurs corrigées à la main.
OVERRIDE = {"entree": "Entrance", "sortie": "Exit", "carte": "Map", "important": "Important", "heure": "Hour",
            "a_ta_sante": "Cheers", "attention": "Watch out", "au_secours": "Help!", "chercher": "Look for",
            "prenom": "First name", "repas": "Meal", "aide": "Help", "dos": "Back"}
raw = pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines()
head = [l for l in raw if l.startswith("#")]
rows = [l.split("|") for l in raw if l.strip() and not l.startswith("#")]
filled, skipped, disagree = [], [], []
for p in rows:
    es = p[ES].split(" / ")[0].strip().lower()
    if not es or es not in gl: continue
    g = gl[es]
    if not p[US].strip() and p[0] in OVERRIDE:
        p[US] = p[GB] = OVERRIDE[p[0]]; filled.append((p[0], p[4], p[ES], OVERRIDE[p[0]] + " (corrigé)"))
    elif not p[US].strip():
        if len(g) == 1 and len(g[0].split()) <= 2 and "/" not in g[0]:
            v = g[0][:1].upper() + g[0][1:]
            p[US] = v
            if not p[GB].strip(): p[GB] = v
            filled.append((p[0], p[4], p[ES], v))
        else: skipped.append((p[0], p[4], p[ES], " ; ".join(g)))
    elif p[US].split(" / ")[0].strip().lower() not in [x.lower() for x in g]:
        disagree.append((p[0], p[4], p[US], " ; ".join(g)))
pathlib.Path("assets/dictionary.txt").write_text("\n".join(head + ["|".join(p) for p in rows]) + "\n", encoding="utf-8")
R = ["# Rapport — anglais complété depuis les flashcards espagnol→anglais\n",
     f"- {len(filled)} mots anglais ajoutés (US et UK identiques ; à vérifier pour l'orthographe britannique).",
     f"- {len(skipped)} mots laissés vides (plusieurs sens possibles).",
     f"- {len(disagree)} désaccords avec les valeurs déjà présentes (à vérifier).\n",
     "## Ajoutés\n| id | français | espagnol | anglais |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in filled]
R += ["\n## Laissés vides (plusieurs sens)\n| id | français | espagnol | sens possibles |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in skipped]
R += ["\n## Désaccords\n| id | français | anglais actuel | flashcards |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in disagree]
pathlib.Path("MERGE_REPORT_EN.md").write_text("\n".join(R) + "\n", encoding="utf-8")
print({"remplis": len(filled), "vides": len(skipped), "desaccords": len(disagree)}, "paires", sum(len(v) for v in gl.values()))
