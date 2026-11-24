#!/usr/bin/env python3
"""Fusionne les CSV français-espagnol (es;fr;;catégorie), ajoute des définitions swahili (kamusi)
et signale les mots swahili suspects (corpus de phrases).
Usage : python3 tools/merge_es_sw.py <dossier des fr-es_*.csv> <kamusi words.csv> <plain_swahili_sentences.csv>
Écrit assets/dictionary.txt, assets/definitions_sw.txt, MERGE_REPORT_ES_SW.md"""
import sys, re, csv, glob, unicodedata, pathlib, collections
csv.field_size_limit(10**8)
LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
ES, SW = 4 + LANGS.index("es"), 4 + LANGS.index("sw")
CAT = {"technologie":"Technologie","temps":"Temps","santé":"Santé","santé, corps":"Corps","informations personnelles":"Identité",
       "verbes":"Verbes","technologie, verbes":"Verbes","verbes, achats":"Verbes","adjectifs":"Adjectifs","couleurs":"Couleurs",
       "nombres":"Nombres","transports":"Transports","nourriture":"Nourriture","achats":"Achats","hébergement":"Hébergement",
       "environnement":"Lieux","orientation":"Orientation","communication":"Phrases"}
EMO = {"Technologie":"💻","Temps":"⏳","Santé":"🩺","Corps":"🫀","Identité":"🪪","Verbes":"🔤","Adjectifs":"✨","Couleurs":"🎨","Nombres":"🔢",
       "Transports":"🚆","Nourriture":"🍽️","Achats":"🛍️","Hébergement":"🛏️","Lieux":"📍","Orientation":"🧭","Phrases":"💬"}

def norm(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ","oe"))
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

ART_FR = re.compile(r"^(le/la|l[’']|les|le|la|un|une)\s*", re.I)
ART_ES = re.compile(r"^(el/la|los|las|el|la|un|una)\s+", re.I)
def fr_alts(raw):
    """-> liste de (base_pour_correspondance, étiquette_affichée), a_article"""
    out, had = [], False
    for alt in re.split(r"\s+/\s+", raw.strip()):
        alt = re.sub(r"\s*[!?.]+$", "", alt).strip()
        dis = re.findall(r"\(([a-zéèêàç]{4,})\)", alt)
        base = re.sub(r"\s*\([^)]*\)", "", alt).strip()
        m = ART_FR.match(base)
        if m: had = True; base = base[m.end():]
        base = base.split("/")[0].strip()
        label = base + (f" ({dis[0]})" if dis else "")
        if base: out.append((base, label))
    return out, had
def es_clean(raw, strip_article):
    s = re.sub(r"^\(a\)\s*", "a ", raw.strip(), flags=re.I)
    s = re.sub(r"^[¡¿]+|[!?.]+$", "", s).strip()
    s = re.sub(r"\s*\([^)]*\)", lambda m: m.group(0) if re.fullmatch(r"\s*\([a-záéíóúñ]{4,}\)", m.group(0)) else "", s)
    if strip_article: s = ART_ES.sub("", s)
    return re.sub(r"/a\b", "", s).strip()

src_dir, kamusi_csv, corpus_csv = sys.argv[1:4]
raw = pathlib.Path("assets/dictionary.txt").read_text(encoding="utf-8").splitlines()
head = [l for l in raw if l.startswith("#")]
rows = [l.split("|") for l in raw if l.strip() and not l.startswith("#")]
byfr = collections.defaultdict(list)
for i, p in enumerate(rows):
    byfr[norm(p[4].split(" / ")[0])].append(i)
ids = {p[0] for p in rows}
rep = collections.defaultdict(list)

for f in sorted(glob.glob(str(pathlib.Path(src_dir) / "*fr-es_*.csv"))):
    for line in open(f, encoding="utf-8-sig"):
        parts = line.rstrip("\n").split(";")
        if len(parts) < 4 or not parts[0].strip(): continue
        es_raw, fr_raw, cat_raw = parts[0], parts[1], parts[3].strip().lower()
        alts, had = fr_alts(fr_raw)
        if not alts: continue
        es = cap(es_clean(es_raw, had))
        base0, label0 = alts[0]
        dis = label0 != base0                      # mot à plusieurs sens : « Temps (durée) », « Entrée (plat) »
        keys = [norm(label0)] + ([norm(base0)] if dis else [])
        hit = []
        for k in keys:
            hit = [i for i in byfr.get(k, [])]
            if hit and k != keys[0]:               # trouvé par la forme sans précision : seulement si l'espagnol est identique
                hit = [i for i in hit if norm(rows[i][ES].split(" / ")[0]) == norm(es)]
            if hit: break
        if not dis:
            hit = sorted({i for base, _ in alts for i in byfr.get(norm(base), [])}) or hit
        if hit:
            i = hit[0]; old = rows[i][ES]
            old_first = bool(old) and es.lower().startswith(("por ", "a ", "al ", "con ", "de ")) and len(old.split()) == 1
            new = merge_tokens(old, es) if old_first else merge_tokens(es, old)
            if old and norm(old.split(" / ")[0]) != norm(new.split(" / ")[0]): rep["conflict"].append((rows[i][0], rows[i][4], old, new))
            rows[i][ES] = new; rep["upd"].append(rows[i][0])
        else:
            cat = CAT.get(cat_raw, cap(cat_raw.split(",")[0]))
            label = cap(label0)
            base = re.sub(r"[^a-z0-9]+", "_", norm(label)).strip("_") or "mot"
            nid, k = base, 2
            while nid in ids: nid = f"{base}_{k}"; k += 1
            ids.add(nid)
            p = [nid, cat, EMO.get(cat, "🔤"), ""] + [""] * len(LANGS)
            p[4] = label; p[ES] = es
            rows.append(p); byfr[norm(label0) if dis else norm(base0)].append(len(rows) - 1)
            rep["new"].append((nid, label, es, cat))

# ---- Swahili : définitions kamusi + vérification par le corpus ----
words = collections.defaultdict(list)
for r in csv.DictReader(open(kamusi_csv, encoding="utf-8", errors="replace")):
    w = (r.get("Word") or "").strip().lower()
    m = (r.get("Meaning") or "").strip()
    if w and len(m) > 10: words[w].append(m)
freq = collections.Counter()
for line in open(corpus_csv, encoding="utf-8", errors="replace"):
    freq.update(re.findall(r"[a-zà-ÿ']+", line.lower()))
defs, suspect = [], []
for p in rows:
    sw = p[SW].split(" / ")[0].strip().lower()
    if not sw: continue
    keys = [sw] + ([sw[2:]] if sw.startswith("ku") and len(sw) > 4 else [])
    hit = next((k for k in keys if k in words), None)
    if hit:
        sense = re.sub(r"\s+", " ", words[hit][0].split(" | ")[0]).strip()
        if len(sense) > 220: sense = sense[:220].rsplit(" ", 1)[0] + "…"
        defs.append((p[0], sense.replace("|", "/")))
    toks = [t for t in re.findall(r"[a-zà-ÿ']+", sw) if len(t) > 2]
    if toks and not hit and min(freq[t] for t in toks) < 3:
        suspect.append((p[0], p[SW], p[4]))

pathlib.Path("assets/dictionary.txt").write_text("\n".join(head + ["|".join(p) for p in rows]) + "\n", encoding="utf-8")
pathlib.Path("assets/definitions_sw.txt").write_text(
    "# Maana ya Kiswahili (id|maana) — source : kamusi (données extraites de kamusi.appsmata.com), à vérifier\n" + "\n".join(f"{a}|{b}" for a, b in defs) + "\n", encoding="utf-8")
cats = collections.Counter(c for _, _, _, c in rep["new"])
R = ["# Rapport — espagnol et swahili\n",
     f"- Espagnol : {len(rep['upd'])} mots existants complétés, {len(rep['new'])} nouveaux mots ({', '.join(f'{k} {v}' for k, v in cats.most_common())}).",
     f"- Swahili : {len(defs)} définitions ajoutées (kamusi) ; {len(suspect)} mots swahili absents de kamusi et rares dans le corpus : à vérifier.\n",
     "## Espagnol : la source remplace ma valeur (à trancher)\n| id | français | ancienne | maintenant |\n|---|---|---|---|"]
R += [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in rep["conflict"]]
R += ["\n## Swahili : mots à faire vérifier (peut être du swahili de RDC, légitime)\n| id | swahili | français |\n|---|---|---|"] + [f"| {a} | {b} | {c} |" for a, b, c in suspect]
R += ["\n## Espagnol : nouveaux mots\n| id | français | espagnol | catégorie |\n|---|---|---|---|"] + [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in rep["new"]]
pathlib.Path("MERGE_REPORT_ES_SW.md").write_text("\n".join(R) + "\n", encoding="utf-8")
print({k: len(v) for k, v in rep.items()}, "defs_sw", len(defs), "suspects", len(suspect))
