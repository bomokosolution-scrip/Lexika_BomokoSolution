#!/usr/bin/env python3
"""Fusionne dans assets/dictionary.txt :
  - un lexique lingala-français CSV (Categorie,Nature,Lingala,Francais)
  - le lexique kikongo de Dereau (texte brut, section FRANÇAIS-KIKONGO)
Usage : python3 tools/merge_sources.py lexique-lingala.csv kikongo.txt
Écrit aussi MERGE_REPORT.md (à faire relire par des locuteurs)."""
import sys, re, csv, unicodedata, pathlib, collections
LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
CAT = {"Salutations":"Salutations","Personnes et Famille":"Famille","Vie quotidienne":"Société",
       "Nourriture et Boissons":"Nourriture","Temps":"Temps","Verbes":"Verbes","Adjectifs":"Adjectifs","Nombres":"Nombres"}
EMO = {"Salutations":"💬","Famille":"👪","Société":"🏷️","Nourriture":"🍽️","Temps":"⏳","Verbes":"🔤","Adjectifs":"✨","Nombres":"🔢","Pronoms":"👤"}
HOMONYM = {'neuf'}  # sens différent en kikongo (neuf = nouveau)
SKIP_PAREN = ("avec","selon","taille")

def norm(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ","oe"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]+", "", s).strip()

def alts(fr):
    out = []
    for a in fr.split(" / "):
        main = re.sub(r"\(.*?\)", "", a).strip()
        if main: out.append(main)
        for par in re.findall(r"\(([^)]*)\)", a):
            if par and not par[0].isdigit() and len(par.split()) <= 3 and not par.lower().startswith(SKIP_PAREN) and par.lower() != "e":
                out.append(par.strip())
    return out

def merge_tokens(*groups):
    seen, out = set(), []
    for g in groups:
        for tok in g.split(" / "):
            tok = tok.strip()
            if tok and norm(tok) not in seen:
                seen.add(norm(tok)); out.append(tok)
    return " / ".join(out[:4])

lin_csv, kg_txt = sys.argv[1], sys.argv[2]
raw = pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines()
head = [l for l in raw if l.startswith("#")]
rows = [l.split("|") for l in raw if l.strip() and not l.startswith("#")]
byfr = collections.defaultdict(list)
for i, p in enumerate(rows): byfr[norm(p[4].split(" / ")[0])].append(i)
ids = {p[0] for p in rows}
report = {"ln_conflict": [], "ln_new": [], "ln_upd": [], "kg_upd": [], "kg_skip": []}

# ---- Lingala ----
lex = list(csv.DictReader(open(lin_csv, encoding="utf-8-sig")))
cand = collections.defaultdict(list)
unmatched = []
for r in lex:
    al = alts(r["Francais"]); hit = False
    for a in al:
        for i in byfr.get(norm(a), []):
            cand[i].append((len(al), r["Lingala"].strip())); hit = True
    if not hit: unmatched.append(r)
for i, c in cand.items():
    c.sort(key=lambda x: x[0])
    old = rows[i][5]
    exact = c[0][0] == 1  # ligne source à sens unique : elle passe en premier ; sinon l'ancienne valeur reste première
    vals = [v for _, v in c]
    new = merge_tokens(*(vals + [old] if exact or not old else [old] + vals))
    if norm(old.split(" / ")[0]) != norm(new.split(" / ")[0]) and old:
        report["ln_conflict"].append((rows[i][0], rows[i][4], old, new))
    rows[i][5] = new; report["ln_upd"].append(rows[i][0])
for r in unmatched:
    al = alts(r["Francais"]); main = al[0]
    cat = "Pronoms" if r["Nature"] == "Pronom" else CAT.get(r["Categorie"], r["Categorie"])
    base = re.sub(r"[^a-z0-9]+", "_", norm(main)).strip("_") or "mot"
    nid, k = base, 2
    while nid in ids: nid = f"{base}_{k}"; k += 1
    ids.add(nid)
    p = [nid, cat, EMO.get(cat, "🔤"), ""] + [""] * len(LANGS)
    p[4] = main[0].upper() + main[1:]; p[5] = r["Lingala"].strip()
    rows.append(p); byfr[norm(main)].append(len(rows) - 1)
    report["ln_new"].append((nid, p[4], p[5], cat))

# ---- Kikongo (Dereau, section FRANÇAIS-KIKONGO) ----
t = pathlib.Path(kg_txt).read_text(encoding="utf-8")
m = re.search(r"FRAN\S{1,4}AIS-KIKONGO", t)
lines = t[m.start():].split("\n")
HW = re.compile(r"^[a-zàâçéèêëîïôûù' ]+(\([^)]*\))?\s*:")
def entry(w):
    for i, l in enumerate(lines):
        if re.match(r"^" + re.escape(w) + r"\s*:", l):
            txt = l; j = i + 1
            while j < len(lines) and lines[j].strip() and not HW.match(lines[j]) and j - i < 5:
                txt += " " + lines[j].strip(); j += 1
            return re.sub(r"-\s+", "-", txt)
def forms(txt, verb):
    body = txt.split(":", 1)[1]
    body = re.sub(r"\(\s*N\.?\s*\)", "§N", body); body = re.sub(r"\(\s*S\.?\s*\)", "§S", body)
    body = re.split(r"\.(?:\s|$)", body)[0]
    ok, mk, bad = [], [], 0
    items = [s.strip() for s in body.split(",") if s.strip()]
    if not items or "\ufffd" in items[0] or ":" in items[0]: return [], 1  # forme principale illisible : on ignore
    for it in items:
        if "\ufffd" in it or ":" in it: bad += 1; continue
        mm = re.fullmatch(r"(-?[a-z][a-z'’\-]*?)(?:\s+\(?\d+(?:-\d+)?\)?)?\s*(§N|§S)?", it)
        if not mm: bad += 1; continue
        w, tag = mm.group(1), mm.group(2)
        if verb:
            if "-" not in w: bad += 1; continue
            w = "ku" + w.split("-")[0]
        else: w = w.lstrip("-")
        if len(w.lstrip('-')) < 3 or w.startswith('ku') and len(w) < 5: bad += 1; continue
        (mk if tag else ok).append(w[0].upper() + w[1:])
    return (ok + mk)[:2], bad
for p in rows:
    w = norm(p[4].split(" / ")[0]).replace(" ", " ")
    if not w or " " in w: continue
    if p[0] in HOMONYM: continue
    txt = entry(p[4].split(" / ")[0].lower())
    if not txt: continue
    f, bad = forms(txt, p[1] == "Verbes")
    if not f:
        report["kg_skip"].append((p[0], p[4], bad)); continue
    new = merge_tokens(" / ".join(f), p[10])
    report["kg_upd"].append((p[0], p[4], p[10], new)); p[10] = new

pathlib.Path("assets/dictionary.txt").write_text("\n".join(head + ["|".join(p) for p in rows]) + "\n", encoding="utf-8")
R = ["# Rapport de fusion — à faire relire par des locuteurs natifs\n",
     f"- Lingala : {len(report['ln_upd'])} mots existants mis à jour, {len(report['ln_new'])} nouveaux mots.",
     f"- Kikongo (Dereau) : {len(report['kg_upd'])} mots renseignés, {len(report['kg_skip'])} ignorés (lettres accentuées perdues dans le fichier).\n",
     "## Lingala : la source remplace une ancienne valeur (à trancher)\n| id | français | ancienne | maintenant |\n|---|---|---|---|"]
R += [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in report["ln_conflict"]]
R += ["\n## Lingala : nouveaux mots\n| id | français | lingala | catégorie |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in report["ln_new"]]
R += ["\n## Kikongo : valeurs ajoutées\n| id | français | avant | maintenant |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in report["kg_upd"]]
R += ["\n## Kikongo : trouvés mais illisibles (à refaire avec le texte brut d'archive.org)\n" + ", ".join(f"{b}" for a, b, c in report["kg_skip"])]
pathlib.Path("MERGE_REPORT.md").write_text("\n".join(R) + "\n", encoding="utf-8")
print({k: len(v) for k, v in report.items()})
