#!/usr/bin/env python3
"""Fusionne des CSV « fr-<langue>_*.csv » (mot;français;;catégorie) dans assets/dictionary.txt.
Usage : python3 tools/merge_lang.py de <dossier des fr-de_*.csv>      (langues gérées : es, de, pt, nl_BE...)
Écrit MERGE_REPORT_<LANGUE>.md. Les articles (der/die/das, el/la...) sont retirés pour rester cohérent avec le reste du dictionnaire."""
import sys, re, glob, unicodedata, pathlib, collections
LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
lang, src_dir = sys.argv[1], sys.argv[2]
COL = 4 + LANGS.index(lang)
file_code = {"nl_BE": "nl", "pt": "pt", "de": "de", "es": "es"}.get(lang, lang)
CAT = {"technologie":"Technologie","temps":"Temps","santé":"Santé","santé, corps":"Corps","informations personnelles":"Identité",
       "verbes":"Verbes","technologie, verbes":"Verbes","verbes, achats":"Verbes","adjectifs":"Adjectifs","couleurs":"Couleurs",
       "nombres":"Nombres","transports":"Transports","nourriture":"Nourriture","achats":"Achats","hébergement":"Hébergement",
       "environnement":"Lieux","orientation":"Orientation","communication":"Phrases","phrases":"Phrases","phrases, questions":"Phrases"}
EMO = {"Technologie":"💻","Temps":"⏳","Santé":"🩺","Corps":"🫀","Identité":"🪪","Verbes":"🔤","Adjectifs":"✨","Couleurs":"🎨","Nombres":"🔢",
       "Transports":"🚆","Nourriture":"🍽️","Achats":"🛍️","Hébergement":"🛏️","Lieux":"📍","Orientation":"🧭","Phrases":"💬"}
ART_FR = re.compile(r"^(le/la|l[’']|les|le|la|un|une)\s*", re.I)
ART_T = {"es": re.compile(r"^(el/la|los|las|el|la|un|una)\s+", re.I),
         "de": re.compile(r"^(der|die|das|den|dem|des|ein|eine)\s+", re.I)}.get(lang, re.compile(r"^$"))

def norm(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ", "oe").replace("ß", "ss"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]+", "", s).strip()
def cap(s): return s[:1].upper() + s[1:] if s else s
def merge_tokens(*groups):
    seen, out = set(), []
    for g in groups:
        for tok in g.split(" / "):
            tok = tok.strip()
            if tok and norm(tok) not in seen: seen.add(norm(tok)); out.append(tok)
    return " / ".join(out[:4])
def fr_alts(raw, keep_punct):
    out, had = [], False
    for alt in re.split(r"\s+/\s+", raw.strip()):
        shown = alt if keep_punct else re.sub(r"\s*[!?.]+$", "", alt).strip()
        dis = re.findall(r"\(([a-zéèêàç]{4,})\)", shown)
        base = re.sub(r"\s*\([^)]*\)", "", shown).strip()
        m = ART_FR.match(base)
        if m: had = True; base = base[m.end():]
        base = base.split("/")[0].strip()
        label = base + (f" ({dis[0]})" if dis else "")
        if base: out.append((base, label))
    return out, had
def clean_target(raw, strip_article, keep_punct):
    s = re.sub(r"\s*\((?![a-zäöüáéíóúñ]{4,}\))[^)]*\)", "", raw.strip())
    s = re.sub(r"^[¡¿]+", "", s)
    s = s.strip() if keep_punct else re.sub(r"[!?.]+$", "", s).strip()
    if strip_article: s = ART_T.sub("", s)
    return re.sub(r"/a\b", "", s).strip() if lang == "es" else s

raw = pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines()
head = [l for l in raw if l.startswith("#")]
rows = [l.split("|") for l in raw if l.strip() and not l.startswith("#")]
byfr = collections.defaultdict(list)
for i, p in enumerate(rows): byfr[norm(p[4].split(" / ")[0])].append(i)
ids = {p[0] for p in rows}
rep = collections.defaultdict(list)
files = sorted(glob.glob(str(pathlib.Path(src_dir) / f"*fr-{file_code}_*.csv")))
for f in files:
    for line in open(f, encoding="utf-8-sig"):
        parts = line.rstrip("\n").split(";")
        if len(parts) < 4 or not parts[0].strip(): continue
        t_raw, fr_raw, cat_raw = parts[0], parts[1], parts[3].strip().lower()
        keep = cat_raw.startswith("phrases")
        alts, had = fr_alts(fr_raw, keep)
        if not alts: continue
        tv = cap(clean_target(t_raw, had, keep))
        base0, label0 = alts[0]
        dis = label0 != base0
        keys = [norm(label0)] + ([norm(base0)] if dis else [])
        hit = []
        for k in keys:
            hit = list(byfr.get(k, []))
            if hit and k != keys[0]: hit = [i for i in hit if norm(rows[i][COL].split(" / ")[0]) == norm(tv)]
            if hit: break
        if not dis: hit = sorted({i for b, _ in alts for i in byfr.get(norm(b), [])}) or hit
        if hit:
            i = hit[0]; old = rows[i][COL]
            new = merge_tokens(tv, old)
            if old and norm(old.split(" / ")[0]) != norm(new.split(" / ")[0]): rep["conflict"].append((rows[i][0], rows[i][4], old, new))
            rows[i][COL] = new; rep["upd"].append(rows[i][0])
        else:
            cat = CAT.get(cat_raw, cap(cat_raw.split(",")[0]))
            label = cap(label0)
            slug = re.sub(r"[^a-z0-9]+", "_", norm(label)).strip("_") or "mot"
            nid, k = slug, 2
            while nid in ids: nid = f"{slug}_{k}"; k += 1
            ids.add(nid)
            p = [nid, cat, EMO.get(cat, "🔤"), ""] + [""] * len(LANGS)
            p[4] = label; p[COL] = tv
            rows.append(p); byfr[norm(label0) if dis else norm(base0)].append(len(rows) - 1)
            rep["new"].append((nid, label, tv, cat))
pathlib.Path("assets/dictionary.txt").write_text("\n".join(head + ["|".join(p) for p in rows]) + "\n", encoding="utf-8")
cats = collections.Counter(c for _, _, _, c in rep["new"])
R = [f"# Rapport — {lang}\n", f"- {len(files)} fichier(s) lus : {len(rep['upd'])} mots existants complétés, {len(rep['new'])} nouveaux ({', '.join(f'{k} {v}' for k, v in cats.most_common())}).\n",
     "## La source remplace ma valeur (à trancher)\n| id | français | ancienne | maintenant |\n|---|---|---|---|"]
R += [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in rep["conflict"]]
R += ["\n## Nouveaux mots\n| id | français | traduction | catégorie |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in rep["new"]]
pathlib.Path(f"MERGE_REPORT_{lang.upper()}.md").write_text("\n".join(R) + "\n", encoding="utf-8")
print(lang, {k: len(v) for k, v in rep.items()}, "fichiers", len(files))
