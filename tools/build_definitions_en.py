#!/usr/bin/env python3
"""Génère assets/definitions_en.txt (id|definition anglaise) depuis le dictionnaire Webster en CSV.
Usage : python3 tools/build_definitions_en.py "chemin/vers/Dictionary in csv"
Relancez-le après avoir ajouté des mots dans assets/dictionary.txt."""
import sys, re, glob, pathlib, collections
src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else sys.exit(__doc__)
EN = 5  # colonne en_US : id|cat|emoji|exemple|fr|ln|en_US ...
want = {}
cats = {}
for line in pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines():
    if not line.strip() or line.startswith("#"): continue
    p = line.split("|")
    w = p[6].strip()
    if re.fullmatch(r"[A-Za-z]+", w):
        want[p[0]] = w.lower(); cats[p[0]] = p[1]
heads = set(want.values())
defs = collections.defaultdict(list)  # mot -> [(pos, texte)]
pat = re.compile(r'^"([^"]+?) \(([^)]*)\) (.*)"\s*$')
for f in sorted(glob.glob(str(src / "*.csv"))):
    for line in open(f, encoding="utf-8", errors="replace"):
        m = pat.match(line)
        if m and m.group(1).lower() in heads:
            defs[m.group(1).lower()].append((m.group(2), m.group(3)))
PREF = {"Verbes": "v", "Adjectifs": "a"}
out, miss = [], []
for i, w in want.items():
    items = defs.get(w, [])
    pref = PREF.get(cats[i], "n")
    good = [t for pos, t in items if pos.startswith(pref)] or [t for _, t in items]
    good = [t for t in good if len(t) > 15][:1]
    if not good: miss.append(w); continue
    text = " • ".join(re.sub(r"\s+", " ", t).strip()[:230].rsplit(" ", 1)[0] + ("…" if len(t) > 230 else "") if len(t) > 230 else re.sub(r"\s+", " ", t).strip() for t in good)
    out.append(f"{i}|{text.replace('|','/')}")
pathlib.Path("assets/definitions_en.txt").write_text(
    "# English definitions (id|text) — source : Webster's Unabridged (1913), domaine public ; langue parfois ancienne.\n" + "\n".join(out) + "\n", encoding="utf-8")
print(f"{len(out)} définitions, {len(miss)} sans définition")
print("sans définition :", ", ".join(miss[:60]))
