"""Build the SL100 player-facing wiki pages from the rules markdown.   python3 tools/build_pages.py [--only Title]

Every numbered rules file (01 ... 10) and the setting files are converted to wikitext and saved as SL100: pages;
SL100:Main Page is rebuilt as the card grid that links them. Re-run after editing any markdown file. Pages are
saved through the normal local-edit path when the database is writable (history in data/history/); otherwise the
.wiki files are written directly and serve.py registers new ones when it next starts.
"""
import re
import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import serve  # noqa: E402
from common import PAGES_DIR, db_connect, page_relpath, title_ns, write_atomic  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]

# title, source markdown file(s), status note, lead paragraph
PAGES = [
    ("SL100:How to Play", ["11 New Star Wars - How to Play.md"], "First draft (13 Oct 2026), tagged [review]",
     "The '''core d100 rules''': Tests and Success Levels, difficulty, opposed and extended Tests, Advantage, Fortune and Resolve in play, Conditions, Wounds and healing, fear, Status, experience and advancement."),
    ("SL100:Characteristics", ["01 New Star Wars - Introduction & Characteristics.md"], "Revised draft (12 Oct): ten characteristics, creation steps, Wounds, Movement, Destiny and Resilience",
     "How a character's ten '''characteristics''' are rolled or bought, what each one measures, and the Characteristic Bonus that drives damage, Wounds and talent limits."),
    ("SL100:Species", ["02 New Star Wars - Species (revised).md"], "223 species, complete for now (13 Oct 2026)",
     "The playable '''species''' of the Legends galaxy with their characteristic modifiers, talents, Movement, Destiny and Resilience. Each entry links to its Legends article; the index at the top shows which entries are settled and which await review."),
    ("SL100:Origin", ["03 New Star Wars - Origin.md"], "Reconciled draft (12 Oct): full d100 table, skills matched to chapter 06, Legends example worlds",
     "'''Origin''' is the kind of world you grew up on. It adds to your characteristics and gives the twelve skills you may start with."),
    ("SL100:Faction", ["04 New Star Wars - Faction.md"], "Lore draft, checked against Legends (12 Oct); mechanics still to be written",
     "The '''factions''' a character may have belonged to before being recruited by a Patron: Force traditions, the underworld, the mega-corporations and the Imperial bureaux, by era."),
    ("SL100:Careers", ["05 New Star Wars - Careers (revised).md"], "24 design-group careers [sl100] (names converted) + 57 added [review]",
     "'''Careers''' are grouped into classes and have four levels each. Every level lists the skills, talents, trappings and status that come with it."),
    ("SL100:Skills", ["06 New Star Wars - Skills.md"], "Draft (about 65%)",
     "Every '''skill''' in the game, the characteristic it is tested against, whether it is Basic or Advanced, and its specialisations."),
    ("SL100:Talents", ["07 New Star Wars - Talents (revised).md"], "Revised draft, under review",
     "'''Talents''' are the knacks, training and quirks that set one character apart from another. Each heading is a link target, so other pages can link to a talent as <code>[[SL100:Talents#Datapad Use]]</code>."),
    ("SL100:Equipment", ["08 New Star Wars - Equipment.md"], "Draft (about 45%); many values still to be filled",
     "'''Weapons, armour and gear''' with their d100 statistics: damage, range, magazine, encumbrance, cost, availability and traits. Armour carries two values, Armour Points against blasters and kinetic damage and Resist against lightsabers."),
    ("SL100:Special Materials", ["Special Materials.md"], "Reference draft (about 70%)",
     "The '''materials''' of the galaxy: fabrics, alloys, gases, crystals and organics, with the Armour Points, Resist, weight, availability and price each one gives to the things made from it."),
    ("SL100:The Force", ["09 New Star Wars - Force Influence.md"], "Notes (about 25%)",
     "How the '''Force''' is used in Star Legends. The three disciplines (Sense, Control and Alter), Force powers and the sorcerous traditions are described under [[SL100:Talents#Force Talents|Force Talents]]; this page holds '''Force Influence''', the measure of a character's pull toward the light or the dark."),
    ("SL100:Combat", ["10 New Star Wars - Combat and Lightsaber Forms.md"], "Forms drafted (about 55%); the general combat rules are still to be written",
     "'''Combat''' in Star Legends uses the d100 opposed-test engine. This page currently holds the '''lightsaber and combat forms'''; blasters, stun settings, armour, shields and hit locations follow."),
    ("SL100:Hyperspace", ["All about hyperspace.md"], "Lore essay (about 70%); travel rules still to be written",
     "'''Hyperspace''' travel in the campaign era: hyperlanes, jump beacons, hyperdrive classes and how long a journey takes."),
    ("SL100:Bestiary", ["Star Wars Bestiary.md"], "Draft (about 80%)",
     "'''Creatures''' of the Legends galaxy with full d100 stat blocks and traits."),
    ("SL100:Vehicles and Starships", ["Star Wars Mounts_Vehicles.md", "Star Wars Space Ships.md", "Starships circa 3000-4000 BBY.md"],
     "Draft tables (about 55%); vehicle and ship combat still to be written",
     "'''Mounts, vehicles and starships''': riding beasts, speeders, walkers and tanks, then the starship compendium and its upgrades, and the ships in service in the 3,000 to 4,000 BBY era."),
]

CARDS = [
    ("Play the game", [
        ("How to Play", "How to Play", "Tests, Success Levels, Advantage, Fate and Resolve, Conditions and Critical Wounds: the core d100 rules."),
        ("Combat", "Combat", "Blasters, lightsabers, stun settings, armour and shields, hit locations, lightsaber and combat forms."),
        ("The Force", "The Force", "Sense, Control and Alter disciplines, Force powers, sorcerous traditions and Force Influence."),
        ("Game Master", "Game Master", "Running the game, downtime Endeavours, rewards and the campaign era."),
    ]),
    ("Build a character", [
        ("Character creation", "Character creation", "The steps in order: species, origin, career, characteristics, skills, talents and trappings."),
        ("Characteristics", "Characteristics", "The ten characteristics, how they are rolled and what each one does."),
        ("Species", "Species", "Playable Legends species with their modifiers, talents and traits."),
        ("Origin", "Origin", "The world you grew up on: Hive, Feral, Industrial, Force Nexus and more."),
        ("Faction", "Faction", "Who you served before your Patron found you: traditions, syndicates, corporations, bureaux."),
        ("Careers", "Careers", "Classes and careers with four levels each: skills, talents, trappings and status."),
        ("Skills", "Skills", "Every skill, its characteristic and its specialisations."),
        ("Talents", "Talents", "All %d talents of the d100 rules, revised for the galaxy far, far away."),
    ]),
    ("The galaxy in d100", [
        ("Weapons", "Weapons", "The full catalogue: blasters, slugthrowers, vibroweapons, lightsabers and explosives with SL100 statistics."),
        ("Armour", "Armour", "Every armour piece with Armour Points and lightsaber Resist by material."),
        ("Gear", "Gear", "Tools, medical kit, comms, survival and slicing gear: everything else a character carries."),
        ("Equipment", "Equipment rules", "Weapon modifications, armour construction, materials ranks, cybernetics and the economy."),
        ("Special Materials", "Materials", "Fabrics, alloys, crystals and organics: what things are made of and what that costs."),
        ("Vehicles and Starships", "Vehicles & Starships", "Mounts, speeders, walkers, starfighters and capital ships."),
        ("Bestiary", "Bestiary", "Creatures of the Legends galaxy with full stat blocks."),
        ("Hyperspace", "Hyperspace", "Travel, hyperlanes and astrogation in the campaign era."),
    ]),
]

CARD = ('<div style="flex:1 1 230px;max-width:320px;border:1px solid #8a8f98;border-radius:10px;padding:12px 14px;background:rgba(127,127,127,0.07)">'
        "%s'''[[SL100:%s|%s]]'''<br>%s</div>")
# SL100 original card art (images/generated/originals; prompts in meta/generated_images.tsv). Cards without an entry show text only.
CARD_ART = {
    "How to Play": "SL100 Card How to Play.jpg", "Combat": "SL100 Card Combat.jpg", "The Force": "SL100 Card The Force.jpg",
    "Game Master": "SL100 Card Game Master.jpg", "Character creation": "SL100 Card Character creation.jpg",
    "Characteristics": "SL100 Card Characteristics.jpg", "Species": "SL100 Card Species.jpg", "Origin": "SL100 Origin Hive.jpg",
    "Faction": "SL100 Faction Galactic Senate.jpg", "Careers": "SL100 Card Careers.jpg", "Skills": "SL100 Card Skills.jpg",
    "Talents": "SL100 Card Talents.jpg", "Weapons": "SL100 Gear Blaster Rifle.jpg", "Armour": "SL100 Gear Combat Armour.jpg",
    "Gear": "SL100 Gear Utility Belt.jpg", "Equipment": "SL100 Card Equipment.jpg", "Special Materials": "SL100 Card Special Materials.jpg",
    "Vehicles and Starships": "SL100 Card Vehicles and Starships.jpg", "Bestiary": "SL100 Card Bestiary.jpg", "Hyperspace": "SL100 Card Hyperspace.jpg",
}


def card_img(page):
    f = CARD_ART.get(page)
    return "[[File:%s|frameless|296px|link=SL100:%s]]<br>" % (f, page) if f else ""

MAIN_HEAD = """<div class="sl-hero"><div class="sl-hero-inner"><div class="sl-title"><span class="back">Star Legends</span><span class="front">Star Legends</span></div><div class="sl-tagline">Galactic Wars</div><div class="sl-sub">SL100 Game Wiki</div></div></div>
<div class="sl-intro">'''Star Legends - Galactic Wars''' is a roleplaying game set in the Star Wars ''Legends'' universe, played with a d100 system adapted from ''Warhammer Fantasy Roleplay'' 4th edition. Everything a player or GM needs is on the cards below; the Legends background articles (harvested from Wookieepedia, CC BY-SA 3.0) sit behind them and every game page links to its source.</div>
"""
MAIN_TAIL = """
== Gallery ==
[[SL100:Gallery]] holds all of our original artwork in one place: places, people, creatures, Force powers and materials to show at the table.

== Working papers ==
Design notes and look-ups that sit behind the rules: [[SL100:Collation]] (reports from the source books), [[SL100:Source books]], [[SL100:Careers compared with WFRP]], [[SL100:Example Weapon]].

== How this wiki is organised ==
* Pages starting with <code>SL100:</code> are our own game material; pages ending in <code>/Legends</code> are the Wookieepedia (Legends) reference.
* The Weapons, Armour and Gear catalogues are generated by <code>tools/convert/equipment.py</code> from chapter 08, Special Materials and the d20 stat tables; items marked ''(converted)'' are awaiting review.
* Red cards are pages still to be written; press ''Edit'' on any page to work on it. The rules pages are generated from the markdown chapters by <code>tools/build_pages.py</code>, so edit the markdown and re-run it rather than editing those pages here. [[SL100:Example Weapon]] shows the layout for a statistics page.

[[Category:SL100]]
"""


# ------------------------------------------------------------------ markdown -> wikitext
def wiki_link(m):
    text, url = m.group(1), m.group(2)
    f = re.match(r"https?://starwars\.fandom\.com/wiki/([^#?]+)", url)
    if f:
        title = urllib.parse.unquote(f.group(1)).replace("_", " ")
        return "[[%s|%s]]" % (title, text) if text and text != title else "[[%s]]" % title
    return "[%s %s]" % (url, text)


def inline(s):
    s = s.replace("\\*", "\x00")                                   # escaped asterisks
    s = s.replace("&#32;", " ").replace("***", "'''''")
    s = re.sub(r"!\[([^\]]*)\]\(File:([^)]+)\)", lambda m: "[[File:%s|thumb|right|360px|%s]]" % (m.group(2).strip(), m.group(1)), s)   # ![caption](File:Name.jpg)
    s = re.sub(r"\[([^\]]*)\]\((https?://[^)\s]+)\)", wiki_link, s)
    s = re.sub(r"\*\*(.+?)\*\*", r"'''\1'''", s)
    s = re.sub(r"(?<!\w)\*(?!\s)(.+?)(?<!\s)\*(?!\w)", r"''\1''", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = s.replace("&#160;", " ").replace("\x00", "*")
    return s


def split_cells(ln):
    """Split a markdown table row on | but not inside [[...]] links or `code`."""
    out, cur, depth, code = [], "", 0, False
    for ch in ln.strip().strip("|"):
        if ch == "`":
            code = not code
        if ch == "[" and not code:
            depth += 1
        elif ch == "]" and not code and depth:
            depth -= 1
        if ch == "|" and depth == 0 and not code:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out


def md_table(lines):
    def cells(ln):
        return split_cells(ln)
    head = cells(lines[0])
    has_sep = len(lines) > 1 and re.match(r"^\|\s*:?-", lines[1]) is not None
    all_bold = any(head) and all(re.match(r"^\*\*.+\*\*$", c) or not c for c in head)
    out = ['{| class="wikitable"']
    rest = lines[2:] if has_sep else lines[1:]
    if has_sep or all_bold:
        if any(head):
            out.append("! " + " !! ".join(inline(h) for h in head))
    else:
        rest = lines
    for ln in rest:
        out.append("|-")
        out.append("| " + " || ".join(inline(c) for c in cells(ln)))
    out.append("|}")
    return "\n".join(out)


def md_to_wiki(md, drop_title=True):
    lines = md.replace("\r", "").splitlines()
    levels = [len(m.group(1)) for m in (re.match(r"^(#{1,6})\s*(\S.*)$", l) for l in lines) if m]
    if drop_title and levels and levels[0] <= 2:
        levels = levels[1:]
    base = min(levels) if levels else 1
    out, i, first = [], 0, True
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("|"):
            j = i
            while j < len(lines) and lines[j].startswith("|"):
                j += 1
            out.append(md_table(lines[i:j]))
            i = j
            continue
        m = re.match(r"^(#{1,6})\s*(.*)$", ln)
        if m:
            text = inline(m.group(2)).strip().strip("'").strip()
            if not text:
                i += 1
                continue
            if first and drop_title and len(m.group(1)) <= 2:
                first = False
                i += 1
                continue
            first = False
            eq = "=" * max(2, min(len(m.group(1)) - base + 2, 6))
            out.append("%s %s %s" % (eq, text, eq))
            i += 1
            continue
        b = re.match(r"^\*\*([^*]{2,40})\*\*:?\s*$", ln)      # a short line that is only bold text: treat as a heading
        if b and " — " not in b.group(1) and not b.group(1).endswith("."):
            out.append("=== %s ===" % b.group(1).strip().rstrip(":"))
            i += 1
            continue
        l = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)$", ln)
        if l:
            depth = len(l.group(1)) // 2 + 1
            mark = ("#" if l.group(2)[0].isdigit() else "*") * depth
            out.append("%s %s" % (mark, inline(l.group(3))))
            i += 1
            continue
        if re.match(r"^\s*(---|\*\*\*|___)\s*$", ln):
            out.append("----")
            i += 1
            continue
        if ln.startswith(">"):
            out.append(": " + inline(ln.lstrip("> ")))
            i += 1
            continue
        out.append(inline(ln))
        first = first and not ln.strip()
        i += 1
    text = "\n".join(out)
    return re.sub(r"\n{3,}", "\n\n", text)


# ------------------------------------------------------------------ talents index (SL100:Talents only)
def talents_index(md):
    rows, sec = [], "General"
    for m in re.finditer(r"^(## Force Talents)|^### (.+?)\n\*\*Max:\*\* (.+?)(?: · \*\*Tests:\*\* (.+?))?\n", md, re.M):
        if m.group(1):
            sec = "Force"
            continue
        rows.append((sec, m.group(2).strip(), m.group(3).strip(), (m.group(4) or "-").strip()))
    out = ["== Index =="]
    for sec in ("General", "Force"):
        part = [r for r in rows if r[0] == sec]
        out.append("=== %s talents (%d) ===" % (sec, len(part)))
        out.append('{| class="wikitable sortable"\n! Talent !! Max !! Tests')
        for _, name, mx, tests in part:
            out.append("|-\n| [[#%s|%s]] || %s || %s" % (name, name, inline(mx), inline(tests)))
        out.append("|}")
    return "\n".join(out), len(rows)


# ------------------------------------------------------------------ pages
def build_page(title, files, status, lead):
    parts, extra, n = [], "", None
    for f in files:
        md = (ROOT / f).read_text(encoding="utf-8")
        if title == "SL100:Talents":
            extra, n = talents_index(md)
        body = md_to_wiki(md)
        if len(files) > 1:
            body = "== %s ==\n" % Path(f).stem.replace("Star Wars ", "").replace("_", " / ") + re.sub(r"^(=+) (.*?) \1$", lambda m: "=" + m.group(0) + "=", body, flags=re.M)
        parts.append(body)
    box = ("{{SL100 Rules|chapter=%s|status=%s|source=%s%s}}\n" %
           (title.split(":", 1)[1], status, "; ".join(files), "|entries=%d" % n if n else ""))
    body_text = "\n\n".join(parts)
    notoc = "__NOTOC__\n" if (extra or re.search(r"^== Index ==", body_text, re.M)) else ""
    text = notoc + box + lead + "\n\n" + (extra + "\n\n" if extra else "") + body_text + "\n\n[[Category:SL100]]\n[[Category:SL100 rules]]\n"
    return text, n


def build_main(n_talents):
    out = [MAIN_HEAD]
    for heading, cards in CARDS:
        out.append("== %s ==" % heading)
        out.append('<div style="display:flex;flex-wrap:wrap;gap:14px;margin:8px 0 18px">')
        for page, label, blurb in cards:
            out.append(CARD % (card_img(page), page, label, blurb % n_talents if "%d" in blurb else blurb))
        out.append("</div>\n")
    out.append(MAIN_TAIL)
    return "\n".join(out)


def write_direct(title, text):
    ns = title_ns(title) or (3000 if title.lower().startswith("sl100:") else 0)
    write_atomic(PAGES_DIR / page_relpath(title, ns), text)


def main():
    import sqlite3
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    pages, n_talents = [], 167
    for title, files, status, lead in PAGES:
        if only and title != only and title.split(":", 1)[1] != only:
            continue
        text, n = build_page(title, files, status, lead)
        if n:
            n_talents = n
        pages.append((title, text, "Built from %s by tools/build_pages.py" % "; ".join(files)))
    if not only:
        pages.append(("SL100:Main Page", build_main(n_talents), "Front page card grid (tools/build_pages.py)"))
    try:
        con = db_connect()
        serve.load_index()
        for title, body, summary in pages:
            serve.save_page(con, title, body, summary)
        con.close()
        how = "saved and registered"
    except sqlite3.OperationalError as e:
        for title, body, _ in pages:
            write_direct(title, body)
        how = "written as files only (database not writable: %s); restart ./wiki.sh serve to register new pages" % e
    print("%d pages %s:" % (len(pages), how))
    for t, body, _ in pages:
        print("  %-32s %6d bytes" % (t, len(body.encode())))


if __name__ == "__main__":
    main()
