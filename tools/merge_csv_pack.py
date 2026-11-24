#!/usr/bin/env python3
"""Bomoko Solution — fusion du lot de dictionnaires CSV dans Lexika.

Usage (depuis la racine du projet) :
    python3 tools/merge_csv_pack.py [dossier_sources]      (défaut : tools/sources_csv)
    python3 tools/merge_csv_pack.py --dry                   (n'écrit rien, affiche seulement le bilan)

Effets :
  * assets/dictionary.txt : id|catégorie|emoji|exemple|22 langues (fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu)
  * assets/extras.txt     : id|langue|prononciation|phrase d'exemple|traduction française de la phrase
  * MERGE_REPORT_CSV_PACK.md : bilan détaillé (mots ajoutés, valeurs en conflit à trancher)

Règle de fusion : la valeur de la source passe en premier, l'ancienne valeur est conservée comme variante
(4 variantes maximum). Les sources sont traitées de la moins fiable à la plus fiable.
"""
import sys, re, csv, pathlib, unicodedata, collections

LANGS = "fr ln en_US en_GB sw lua kg es pt de wa nl_BE en_SL fr_SL af eo ru zu".split()
NL = len(LANGS)
COLS = 4 + NL
OLD_COLS = 18  # ancien format (14 langues)
DRY = "--dry" in sys.argv
args = [a for a in sys.argv[1:] if not a.startswith("--")]
SRC = pathlib.Path(args[0] if args else "tools/sources_csv")

# ───────────── catégories ─────────────
CAT = {
    # thèmes des fichiers « complet »
    "calendrier et temps": "Temps", "temps et calendrier": "Temps", "nature et temps": "Temps", "temps": "Temps",
    "salutations et politesse": "Salutations", "salutations": "Salutations", "politesse": "Salutations",
    "vie quotidienne et maison": "Vie", "vie quotidienne": "Vie", "courant": "Vie", "maison": "Vie", "divers": "Vie",
    "corps humain et santé": "Corps", "corps et santé": "Corps", "corps": "Corps",
    "alimentation et boissons": "Nourriture", "alimentation": "Nourriture", "restaurant": "Nourriture",
    "voyage et direction": "Orientation", "voyage": "Orientation",
    "nombres": "Nombres",
    "verbes courants": "Verbes", "actions": "Verbes", "verbes": "Verbes",
    "conjugaison de base": "Conjugaison", "conjugaison": "Conjugaison",
    "famille et personnes": "Famille", "famille": "Famille", "personnes": "Famille",
    "commerce et marché": "Achats", "commerce": "Achats", "achats": "Achats",
    "vocabulaire administratif et social": "Société", "administratif et social": "Société",
    "éducation": "Société", "travail": "Société",
    "lexique religieux et spirituel": "Spiritualité", "religieux et spirituel": "Spiritualité",
    # fichier allemand
    "adjectifs": "Adjectifs", "communication": "Phrases", "expressions": "Phrases", "pronoms": "Pronoms",
    "lieux": "Lieux", "transport": "Transports", "couleurs": "Couleurs", "urgences": "Santé",
}
def theme_cat(t):
    k = t.strip().lower()
    if k.startswith("proverbes"): return "Proverbes"
    return CAT.get(k)

EMO = {"Salutations": "👋", "Nourriture": "🍽️", "Verbes": "🔤", "Adjectifs": "✨", "Temps": "⏳", "Phrases": "💬",
       "Société": "🏛️", "Nombres": "🔢", "Lieux": "📍", "Corps": "🫀", "Orientation": "🧭", "Transports": "🚆",
       "Achats": "🛍️", "Nature": "🌿", "Vie": "🏠", "Animaux": "🐾", "Identité": "🪪", "Couleurs": "🎨",
       "Famille": "👨‍👩‍👧", "Technologie": "💻", "Pronoms": "👤", "Santé": "🩺", "Hébergement": "🛏️",
       "Conjugaison": "🧩", "Proverbes": "📜", "Spiritualité": "⛪", "Divers": "🔤"}

# ───────────── utilitaires texte ─────────────
def norm(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ", "oe").replace("ß", "ss"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]+", "", s).strip()
def cap(s): return s[:1].upper() + s[1:] if s else s
def clean_cell(s): return re.sub(r"\s+", " ", s.replace("|", "/")).strip()
def slug(label):
    s = re.sub(r"[^a-z0-9]+", "_", norm(label)).strip("_") or "mot"
    if len(s) > 40: s = s[:40].rsplit("_", 1)[0]
    return s
ART_FR = re.compile(r"^(le|la|les|l[’'])\s*", re.I)
ART_T = {"es": re.compile(r"^(el|la|los|las|un|una)\s+", re.I),
         "de": re.compile(r"^(der|die|das|den|dem|ein|eine)\s+", re.I),
         "af": re.compile(r"^(die)\s+", re.I),
         "eo": re.compile(r"^(la)\s+", re.I)}

def merge_tokens(*groups):
    seen, out = set(), []
    for g in groups:
        for tok in g.split(" / "):
            tok = tok.strip()
            if tok and norm(tok) not in seen:
                seen.add(norm(tok)); out.append(tok)
    return " / ".join(out[:4])

def has_letters(s): return bool(re.search(r"[^\W\d_]", s))

def parse_fr(raw):
    """-> (label, base, alts, gloss, keep_punct)"""
    raw = clean_cell(raw)
    glosses = re.findall(r"\(([^()]*)\)", raw)
    # on ignore les marques de genre « (e) », « (te) » et les notes grammaticales « (pluriel : …) »
    glosses = [g.strip() for g in glosses if has_letters(g) and len(re.sub(r"\W", "", g)) > 2 and ":" not in g]
    gloss = re.sub(r"\s+/\s+", ", ", glosses[0]) if glosses else None
    stripped = re.sub(r"\s*\([^()]*\)", "", raw).strip()
    alts = [a.strip() for a in re.split(r"\s+/\s+", stripped) if a.strip()]
    if not alts: return None
    alts2 = []
    for a in alts:
        m = ART_FR.match(a)
        if m and len(a.split()) <= 2 and a[m.end():].strip():
            a = a[m.end():].strip()
        alts2.append(a)
    alts = alts2
    base = alts[0]
    keep = bool(re.search(r"[?!.…]$", base)) and len(base.split()) >= 2
    if not keep: base = re.sub(r"\s*[?!.…]+$", "", base).strip()
    label = cap(base) + (f" ({gloss.lower()})" if gloss else "")
    return label, base, alts, gloss, keep

def clean_target(raw, lang, keep, fr_has_article_free=True):
    s = clean_cell(raw)
    s = re.sub(r"\s*\([^()]*\)", "", s)  # notes entre parenthèses : retirées
    toks = []
    for tok in re.split(r"\s+/\s+", s):
        tok = tok.strip()
        if not keep:
            tok = re.sub(r"^[¡¿]+", "", tok)
            tok = re.sub(r"\s*[!?.…]+$", "", tok).strip()
        art = ART_T.get(lang)
        if art and not keep and fr_has_article_free:
            m = art.match(tok)
            if m and len(tok.split()) == 2:
                tok = tok[m.end():].strip()
        tok = re.sub(r"/a\b", "", tok).strip() if lang == "es" else tok
        if tok: toks.append(cap(tok))
    return " / ".join(toks)

def split_example(raw, swahili=False):
    """-> (phrase dans la langue, traduction française)"""
    s = clean_cell(raw)
    if not s: return "", ""
    if " = " in s:
        a, b = s.split(" = ", 1); return a.strip(), b.strip()
    if s.endswith(")"):
        depth = 0
        for i in range(len(s) - 1, -1, -1):
            if s[i] == ")": depth += 1
            elif s[i] == "(":
                depth -= 1
                if depth == 0:
                    return s[:i].strip(), s[i + 1:-1].strip()
    return s, ""

# ───────────── lecture des sources ─────────────
def read_csv(name, delim):
    p = SRC / name
    with open(p, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.reader(f, delimiter=delim))
    return rows[1:]

class Rec:
    __slots__ = ("lang", "fr", "tgt", "cat", "pron", "ex", "kind", "src", "phrase")
    def __init__(self, **k):
        for a in self.__slots__: setattr(self, a, k.get(a, ""))

def load_sources():
    """Retourne la liste ordonnée (du moins prioritaire au plus prioritaire) de (nom, [Rec])."""
    out = []
    # 1) base multilingue (kikongo/kituba, afrikaans, espéranto, russe, zoulou)
    m = {"kikongo": "kg", "afrikaans": "af", "esperanto": "eo", "russe": "ru", "zulu": "zu"}
    f = "base_multilingue_traduction.csv"
    out.append((f, [Rec(lang=m[r[0]], fr=r[2], tgt=r[3], src=f) for r in read_csv(f, ";") if len(r) >= 4 and r[0] in m]))
    # 2) listes simples français → langue
    for f, lg in [("dictionnaire_francais_espagnol.csv", "es"), ("dictionnaire_francais_lingala.csv", "ln"),
                  ("dictionnaire_francais_swahili.csv", "sw")]:
        out.append((f, [Rec(lang=lg, fr=r[0], tgt=r[1], src=f) for r in read_csv(f, ";") if len(r) >= 2 and r[0].strip()]))
    f = "dictionnaire_francais_allemand_etendu.csv"
    out.append((f, [Rec(lang="de", fr=r[0], tgt=r[1], cat=r[2], kind=r[3], src=f) for r in read_csv(f, ";") if len(r) >= 4 and r[0].strip()]))
    f = "dictionnaire_tshiluba_francais.csv"
    out.append((f, [Rec(lang="lua", fr=r[1], tgt=r[0], cat=r[3], kind=r[2], src=f) for r in read_csv(f, ",") if len(r) >= 4 and r[0].strip()]))
    # 3) dictionnaires « complets » (langue → français, avec prononciation et exemple)
    for f, lg in [("dictionnaire_espagnol_francais_complet.csv", "es"), ("dictionnaire_lingala_francais_complet.csv", "ln"),
                  ("dictionnaire_swahili_francais_complet.csv", "sw"), ("dictionnaire_kikongo_francais_complet.csv", "kg"),
                  ("dictionnaire_tshiluba_francais_voyage_phonetique.csv", "lua")]:
        out.append((f, [Rec(lang=lg, fr=r[2], tgt=r[0], pron=r[1], cat=r[4], kind=r[3], ex=r[5], src=f)
                        for r in read_csv(f, ";") if len(r) >= 6 and r[0].strip()]))
    return out

# ───────────── dictionnaire existant ─────────────
dict_path = pathlib.Path("assets/dictionary.txt")
raw = dict_path.read_text(encoding="utf-8").splitlines()
head = [
    "# Lexika — dictionnaire multilingue · Bomoko Solution",
    "# Format : id|catégorie|emoji|exemple (français)|22 mots",
    "# Ordre des langues : " + "|".join(LANGS),
    "# Une case vide = traduction pas encore disponible (à compléter par un locuteur natif).",
]
rows = []
for l in raw:
    if not l.strip() or l.startswith("#"): continue
    p = l.split("|")
    if len(p) == OLD_COLS: p += [""] * (COLS - OLD_COLS)
    if len(p) != COLS:
        sys.exit(f"Ligne invalide ({len(p)} colonnes) : {l[:60]}")
    rows.append(p)
n_before = len(rows)
ids = {p[0] for p in rows}

def index_row(i):
    label = rows[i][4]
    gl = re.search(r"\(([^()]*)\)", label)
    base = re.sub(r"\s*\([^()]*\)", "", label)
    keys = {norm(label)}
    for tok in re.split(r"\s+/\s+", base):
        if tok.strip(): keys.add(norm(tok))
    if gl: keys.discard(norm(base))
    for k in keys: byfr[k].append(i)
byfr = collections.defaultdict(list)
for i in range(len(rows)): index_row(i)

# catégories connues par libellé français (pour classer les entrées issues des listes « Vocabulaire courant »)
catmap = {}
sources = load_sources()
for name, recs in sources:
    for r in recs:
        c = theme_cat(r.cat) if r.cat else None
        pf = parse_fr(r.fr)
        if c and pf and not (r.src.startswith("dictionnaire_tshiluba_francais.csv") and False):
            catmap.setdefault(norm(pf[1]), c)

# ───────────── fusion ─────────────
report = collections.defaultdict(list)
stats = collections.OrderedDict()
extras_cand = {}  # (id, lang) -> (pron, ex_t, ex_fr, first token)
warn = []
gloss_filled = set()

for name, recs in sources:
    st = collections.Counter()
    for r in recs:
        col = 4 + LANGS.index(r.lang)
        pf = parse_fr(r.fr)
        if not pf: st["ignorées"] += 1; continue
        label, base, alts, gloss, keep = pf
        phrase_cat = (r.kind or "").lower() in ("expression", "proverbe", "conjugaison", "salutation", "locution", "interjection") \
            or (theme_cat(r.cat) in ("Phrases", "Proverbes") if r.cat else False)
        keep = keep or (phrase_cat and bool(re.search(r"[?!.…]$", clean_cell(r.fr))) and len(base.split()) >= 2)
        tv = clean_target(r.tgt, r.lang, keep)
        if not tv: st["ignorées"] += 1; continue
        # recherche
        keys = [norm(label)] if gloss else [norm(base)]
        hit = []
        for k in keys:
            hit = list(byfr.get(k, []))
            if hit: break
        if hit:
            i = hit[0]
            old = rows[i][col]
            new = merge_tokens(tv, old)
            if old and norm(old.split(" / ")[0]) != norm(new.split(" / ")[0]):
                report["conflict"].append((rows[i][0], rows[i][4], r.lang, old, new, name))
            rows[i][col] = new
            st["mots existants complétés"] += 1
            target_idx = i
            # variantes françaises secondaires : on complète seulement les cases vides
            if not gloss:
                for a in alts[1:]:
                    for j in byfr.get(norm(a), []):
                        if j != i and not rows[j][col]:
                            rows[j][col] = tv; st["variantes remplies"] += 1
        else:
            c = theme_cat(r.cat) if r.cat else None
            c = c or catmap.get(norm(base)) or "Divers"
            nid, k = slug(label), 2
            while nid in ids: nid = f"{slug(label)}_{k}"; k += 1
            ids.add(nid)
            p = [nid, c, EMO.get(c, "🔤"), ""] + [""] * NL
            p[4] = label; p[col] = tv
            rows.append(p); target_idx = len(rows) - 1
            index_row(target_idx)
            st["nouveaux mots"] += 1

            report["new"].append((nid, label, r.lang, tv, c, name))
        # variante précisée (« Au revoir (à celui qui part) ») : on alimente aussi l'entrée générale
        # si sa case est vide ou ne contient que des variantes précisées issues de cette même logique
        if gloss:
            for j in byfr.get(norm(base), []):
                if j != target_idx and rows[j][4].find("(") < 0 and (not rows[j][col] or (j, col) in gloss_filled):
                    rows[j][col] = merge_tokens(rows[j][col], tv); gloss_filled.add((j, col)); st["variantes remplies"] += 1
                    break
        # exemple + prononciation
        if r.ex or r.pron:
            ex_t, ex_fr = split_example(r.ex)
            if ex_fr and not rows[target_idx][3]: rows[target_idx][3] = ex_fr
            extras_cand[(rows[target_idx][0], r.lang)] = (clean_cell(r.pron), ex_t, ex_fr, norm(tv.split(" / ")[0]))
    stats[name] = st

# extras : conservés seulement si le mot affiché en premier est bien celui de la source
extras = []
for (eid, lg), (pron, ex_t, ex_fr, first) in sorted(extras_cand.items()):
    row = next(p for p in rows if p[0] == eid)
    cur = row[4 + LANGS.index(lg)]
    if cur and norm(cur.split(" / ")[0]) == first and (pron or ex_t):
        extras.append((eid, lg, pron, ex_t, ex_fr))

# ───────────── bilan ─────────────
cover = {lg: sum(1 for p in rows if p[4 + LANGS.index(lg)]) for lg in LANGS}
print(f"Entrées : {n_before} → {len(rows)}")
for n, s in stats.items(): print(f"  {n}: {dict(s)}")
print("Couverture :", cover)
print("Extras :", len(extras), "| conflits :", len(report['conflict']), "| catégories :", collections.Counter(p[1] for p in rows).most_common())
if DRY: sys.exit(0)

dict_path.write_text("\n".join(head + ["|".join(p) for p in rows]) + "\n", encoding="utf-8")
pathlib.Path("assets/extras.txt").write_text(
    "# Lexika — prononciations et phrases d'exemple par langue · Bomoko Solution\n"
    "# Format : id|langue|prononciation|phrase d'exemple|traduction française de la phrase\n"
    + "\n".join("|".join(x) for x in extras) + "\n", encoding="utf-8")

R = ["# Rapport de fusion — lot de dictionnaires CSV\n",
     f"Entrées du dictionnaire : **{n_before} → {len(rows)}** (+{len(rows) - n_before}). "
     f"Langues : **{NL}** (dont 4 nouvelles : afrikaans, espéranto, russe, zoulou). "
     f"Prononciations / phrases d'exemple : **{len(extras)}**.\n",
     "## Couverture par langue (mots renseignés)\n| langue | mots |\n|---|---|"]
R += [f"| {lg} | {cover[lg]} |" for lg in LANGS]
R += ["\n## Détail par fichier source\n| fichier | lignes lues | complétés | nouveaux | variantes | ignorées |\n|---|---|---|---|---|---|"]
for name, recs in sources:
    s = stats[name]
    R.append(f"| {name} | {len(recs)} | {s['mots existants complétés']} | {s['nouveaux mots']} | {s['variantes remplies']} | {s['ignorées']} |")
R += ["\n## Nouvelles catégories / répartition des nouveaux mots\n| catégorie | nouveaux mots |\n|---|---|"]
R += [f"| {c} | {n} |" for c, n in collections.Counter(c for *_, c, _ in report["new"]).most_common()]
R += [f"\n## Valeurs en conflit — à trancher par un locuteur ({len(report['conflict'])})",
      "La valeur de la source passe en premier ; l'ancienne reste en variante.\n",
      "| id | français | langue | avant | maintenant | source |\n|---|---|---|---|---|---|"]
R += [f"| {a} | {b} | {c} | {d} | {e} | {f} |" for a, b, c, d, e, f in report["conflict"]]
R += [f"\n## Nouveaux mots ({len(report['new'])})", "| id | français | langue | traduction | catégorie |\n|---|---|---|---|---|"]
R += [f"| {a} | {b} | {c} | {d} | {e} |" for a, b, c, d, e, _ in report["new"]]
pathlib.Path("MERGE_REPORT_CSV_PACK.md").write_text("\n".join(R) + "\n", encoding="utf-8")
print("Écrit : assets/dictionary.txt, assets/extras.txt, MERGE_REPORT_CSV_PACK.md")
