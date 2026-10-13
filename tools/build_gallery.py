#!/usr/bin/env python3
"""Build SL100:Gallery, the art library for Game Directors, from images/generated/originals.

Sections follow the file-name prefix (SL100 Location X, SL100 NPC X, ...). Run after
tools/register_generated.py. Only one DB writer at a time."""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_pages as bp  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
ORIG = ROOT / "images" / "generated" / "originals"

SECTIONS = [
    ("Location", "Places", "Scenes to show the table when the party arrives somewhere: cantinas, docking bays, outposts, dens and ruins.", 170),
    ("NPC", "People", "Portraits for non-player characters: contacts, rivals, patrons, officials and passers-by.", 200),
    ("Creature", "Creatures", "Original beasts for wild worlds. Pair them with a stat block from [[SL100:Bestiary]].", 170),
    ("Force", "The Force", "Illustrations for Force powers and traditions; see [[SL100:The Force]].", 170),
    ("Material", "Materials", "Prop studies for [[SL100:Special Materials]].", 160),
    ("Origin", "Origins", "The worlds characters grow up on; see [[SL100:Origin]].", 150),
    ("Faction", "Factions", "Who characters worked for; see [[SL100:Faction]].", 150),
    ("Gear", "Gear", "Weapons and equipment; see [[SL100:Weapons]], [[SL100:Armour]] and [[SL100:Gear]].", 150),
    ("Career", "Careers", "One portrait per career; see [[SL100:Careers]].", 150),
]


def build():
    names = sorted(p.stem for p in ORIG.glob("SL100 *.webp")) + sorted(p.stem for p in ORIG.glob("SL100 *.jpg"))
    out = ["'''Gallery''' of original Star Legends artwork, for Game Directors to show at the table. "
           "Every picture here is SL100 original artwork (AI-generated; credits in NOTICE.md); none of it is "
           "franchise material. Click a picture for the full-size file.", "", "__TOC__", ""]
    for key, head, blurb, h in SECTIONS:
        items = [n for n in dict.fromkeys(names) if n.startswith("SL100 %s " % key)]
        if not items:
            continue
        out.append("== %s (%d) ==" % (head, len(items)))
        out.append(blurb)
        out.append('<gallery mode="packed" heights="%d">' % h)
        for n in items:
            out.append("File:%s.jpg|%s" % (n, n[len("SL100 %s " % key):]))
        out.append("</gallery>")
        out.append("")
    out.append("[[Category:SL100]]")
    return "\n".join(out) + "\n"


def main():
    title, body = "SL100:Gallery", build()
    try:
        con = bp.db_connect()
        bp.serve.load_index()
        bp.serve.save_page(con, title, body, "Art gallery (tools/build_gallery.py)")
        con.close()
        how = "saved and registered"
    except sqlite3.OperationalError as e:
        bp.write_direct(title, body)
        how = "written as file only (%s)" % e
    print("%s %s, %d bytes" % (title, how, len(body.encode())))


if __name__ == "__main__":
    main()
