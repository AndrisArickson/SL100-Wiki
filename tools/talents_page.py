"""Build the SL100 player-facing pages from the rules markdown.   python3 tools/talents_page.py

Converts "07 New Star Wars - Talents (revised).md" into the wiki page SL100:Talents (index table + every talent),
and (re)writes SL100:Main Page as a card grid pointing at the game-content pages. Re-run whenever the markdown
changes; the pages are saved through the normal local-edit path (history kept in data/history/).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import serve  # noqa: E402  (gives save_page + db)
from common import db_connect  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "07 New Star Wars - Talents (revised).md"


def inline(s):
    s = re.sub(r"\*\*(.+?)\*\*", r"'''\1'''", s)
    s = re.sub(r"(?<![\w'])\*(?!\s)(.+?)(?<!\s)\*(?![\w'])", r"''\1''", s)
    return s


def md_table(lines):
    head = [c.strip() for c in lines[0].strip().strip("|").split("|")]
    out = ['{| class="wikitable"', "! " + " !! ".join(inline(h) for h in head)]
    for ln in lines[2:]:
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        out.append("|-")
        out.append("| " + " || ".join(inline(c) for c in cells))
    out.append("|}")
    return "\n".join(out)


def md_to_wiki(md):
    lines = md.splitlines()
    out, i = [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("|") and i + 1 < len(lines) and re.match(r"^\|\s*-", lines[i + 1]):
            j = i
            while j < len(lines) and lines[j].startswith("|"):
                j += 1
            out.append(md_table(lines[i:j]))
            i = j
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", ln)
        if m:
            lvl = len(m.group(1))
            if lvl == 1:
                i += 1
                continue                      # page title: the wiki supplies it
            eq = "=" * lvl
            out.append("%s %s %s" % (eq, m.group(2).strip().strip("*"), eq))
        else:
            out.append(inline(ln))
        i += 1
    return "\n".join(out)


def talents_index(md):
    rows, sec = [], "General"
    for m in re.finditer(r"^(## Force Talents)|^### (.+?)\n\*\*Max:\*\* (.+?)(?: · \*\*Tests:\*\* (.+?))?\n", md, re.M):
        if m.group(1):
            sec = "Force"
            continue
        rows.append((sec, m.group(2).strip(), m.group(3).strip(), (m.group(4) or "-").strip()))
    out = []
    for sec in ("General", "Force"):
        part = [r for r in rows if r[0] == sec]
        out.append("=== %s talents (%d) ===" % (sec, len(part)))
        out.append('{| class="wikitable sortable"\n! Talent !! Max !! Tests')
        for _, name, mx, tests in part:
            out.append("|-\n| [[#%s|%s]] || %s || %s" % (name, name, inline(mx), inline(tests)))
        out.append("|}")
    return "\n".join(out), len(rows)


def build_talents():
    md = SRC.read_text(encoding="utf-8")
    body = md_to_wiki(md)
    index, n = talents_index(md)
    text = ("{{SL100 Rules|chapter=Talents|status=Revised draft, under review|entries=%d|source=07 New Star Wars - Talents (revised).md}}\n"
            "'''Talents''' are the knacks, training and quirks that set one character apart from another in ''Star Legends - Galactic Wars''. "
            "This page lists every talent in the d100 rules as currently drafted. Use the index to jump to an entry; each heading is a link target, so other pages can link to a talent as <code>[[SL100:Talents#Datapad Use]]</code>.\n\n"
            "== Index ==\n%s\n\n%s\n\n[[Category:SL100]]\n[[Category:SL100 rules]]\n" % (n, index, body))
    return text, n


MAIN = """'''Star Legends - Galactic Wars''' is a roleplaying game set in the Star Wars ''Legends'' universe, played with a d100 system adapted from ''Warhammer Fantasy Roleplay'' 4th edition. Everything a player or GM needs is on the cards below; the Legends background articles (harvested from Wookieepedia, CC BY-SA 3.0) sit behind them and every game page links to its source.

== Play the game ==
<div style="display:flex;flex-wrap:wrap;gap:14px;margin:8px 0 18px">
%s
</div>

== Build a character ==
<div style="display:flex;flex-wrap:wrap;gap:14px;margin:8px 0 18px">
%s
</div>

== The galaxy in d100 ==
<div style="display:flex;flex-wrap:wrap;gap:14px;margin:8px 0 18px">
%s
</div>

== How this wiki is organised ==
* Pages starting with <code>SL100:</code> are our own game material; pages ending in <code>/Legends</code> are the Wookieepedia (Legends) reference.
* Red cards are pages still to be written; press ''Edit'' on any page to work on it. [[SL100:Example Weapon]] shows the layout for a statistics page.

[[Category:SL100]]
"""

CARD = ('<div style="flex:1 1 230px;max-width:320px;border:1px solid #8a8f98;border-radius:10px;padding:12px 14px;background:rgba(127,127,127,0.07)">'
        "'''[[SL100:%s|%s]]'''<br>%s</div>")

CARDS = {
    "play": [
        ("How to Play", "How to Play", "Tests, Success Levels, Advantage, Fate and Resolve, Conditions and Critical Wounds: the core d100 rules."),
        ("Combat", "Combat", "Blasters, lightsabers, stun settings, armour and shields, hit locations, lightsaber and combat forms."),
        ("The Force", "The Force", "Sense, Control and Alter disciplines, Force powers, sorcerous traditions and Force Influence."),
        ("Game Master", "Game Master", "Running the game, downtime Endeavours, rewards and the campaign era."),
    ],
    "character": [
        ("Characteristics", "Characteristics", "The ten characteristics, how they are rolled and what each one does."),
        ("Species", "Species", "Playable Legends species with their modifiers, talents and traits."),
        ("Origin", "Origin", "The world you grew up on: Hive, Feral, Industrial, Force Nexus and more."),
        ("Careers", "Careers", "Classes and careers with four levels each: skills, talents, trappings and status."),
        ("Skills", "Skills", "Every skill, its characteristic and its specialisations."),
        ("Talents", "Talents", "All %d talents of the d100 rules, revised for the galaxy far, far away."),
    ],
    "galaxy": [
        ("Weapons", "Weapons", "Blasters, slugthrowers, vibroweapons and lightsabers with d100 statistics."),
        ("Armour", "Armour", "Armour points and lightsaber resistance by material; personal shields."),
        ("Equipment", "Equipment", "Gear, cybernetics, materials, prices and availability."),
        ("Vehicles and Starships", "Vehicles & Starships", "Speeders, walkers, starfighters and capital ships."),
        ("Bestiary", "Bestiary", "Creatures of the Legends galaxy with full stat blocks."),
        ("Hyperspace", "Hyperspace", "Travel, hyperlanes and astrogation in the campaign era."),
    ],
}


def build_main(n):
    parts = []
    for key in ("play", "character", "galaxy"):
        cards = []
        for page, label, blurb in CARDS[key]:
            cards.append(CARD % (page, label, blurb % n if "%d" in blurb else blurb))
        parts.append("\n".join(cards))
    return MAIN % tuple(parts)


def write_direct(title, text):
    """Fallback when the database cannot be written (e.g. the folder is mounted without delete rights):
    write the .wiki file only; serve.py registers untracked files when it starts."""
    from common import PAGES_DIR, page_relpath, title_ns, write_atomic
    ns = title_ns(title) or (3000 if title.lower().startswith("sl100:") else 0)
    write_atomic(PAGES_DIR / page_relpath(title, ns), text)


def main():
    import sqlite3
    text, n = build_talents()
    pages = [("SL100:Talents", text, "Built from 07 New Star Wars - Talents (revised).md by tools/talents_page.py"),
             ("SL100:Main Page", build_main(n), "Front page card grid (tools/talents_page.py)")]
    try:
        con = db_connect()
        serve.load_index()
        for title, body, summary in pages:
            serve.save_page(con, title, body, summary)
        con.close()
        print("SL100:Talents written with %d talents; SL100:Main Page updated (database registered)" % n)
    except sqlite3.OperationalError as e:
        for title, body, _ in pages:
            write_direct(title, body)
        print("Database not writable here (%s); wrote the .wiki files only. Restart ./wiki.sh serve to register them." % e)


if __name__ == "__main__":
    main()
