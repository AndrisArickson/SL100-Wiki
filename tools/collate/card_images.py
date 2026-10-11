#!/usr/bin/env python3
"""Download a small set of Wookieepedia (Legends) images for the front-page cards - gently, thumbnails only.
The image named in each article's infobox is fetched at 480 px wide into images/full/ (where the local server
already prefers real files over blank placeholders). Attribution is recorded in meta/card_images.tsv.
  card_images.py            fetch what is missing
  card_images.py --list     only write meta/card_images.tsv (thumb URLs + destination), e.g. to download elsewhere
"""
import re, sys, time, urllib.parse, urllib.request
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import common as C, placeholders   # noqa: E401

CARDS = [  # card key, Legends article whose infobox image is used
    ("How to Play", "Sabacc/Legends"), ("Combat", "Blaster pistol/Legends"), ("The Force", "Force push/Legends"),
    ("Game Master", "Holocron/Legends"), ("Characteristics", "Human/Legends"), ("Species", "Twi'lek/Legends"),
    ("Origin", "Coruscant/Legends"), ("Careers", "Smuggler/Legends"), ("Skills", "Datapad/Legends"),
    ("Talents", "Bounty hunter/Legends"), ("Weapons", "DL-44 heavy blaster pistol/Legends"),
    ("Armour", "Stormtrooper armor/Legends"), ("Equipment", "Lightsaber/Legends"),
    ("Vehicles and Starships", "T-65 X-wing starfighter/Legends"), ("Bestiary", "Rancor/Legends"),
    ("Hyperspace", "Hyperspace/Legends"), ("Planets", "Tatooine/Legends"), ("History", "Galactic Republic/Legends"),
    ("Organisations", "Sith/Legends"), ("Droids", "R2-series astromech droid/Legends"), ("Starship classes", "YT-1300 light freighter/Legends"),
    ("Legends species", "Wookiee/Legends"), ("Jedi", "Jedi Order/Legends"), ("Source books", "Datacard/Legends"),
    ("Character creation", "Jedi/Legends"),
]


def infobox_image(con, title):
    r = con.execute("SELECT path FROM pages WHERE title=?", (title,)).fetchone()
    if not r or not r[0]:
        return None
    t = (C.PAGES_DIR / r[0]).read_text(encoding="utf-8", errors="replace")[:6000]
    m = re.search(r"\|\s*image\s*=\s*\[\[(?:File|Image):([^|\]]+)", t) or re.search(r"\[\[(?:File|Image):([^|\]]+)", t)
    return C.norm_title(m.group(1)) if m else None


def main():
    con = C.db_connect()
    want = {}
    for key, title in CARDS:
        img = infobox_image(con, title)
        print("%-22s %-40s %s" % (key, title, img))
        if img:
            want[img] = (key, title)
    tsv = C.META_DIR / "card_images.tsv"
    rows = ["card\tarticle\tfile\tsource_page\tlicence\tthumb_url\tdest"]
    names = list(want)
    info = {}
    for i in range(0, len(names), 50):
        r = C.api(action="query", prop="imageinfo", iiprop="url", iiurlwidth="480", titles="|".join("File:" + n for n in names[i:i + 50]))
        for p in r["query"].get("pages", []):
            ii = (p.get("imageinfo") or [{}])[0]
            info[p["title"][5:]] = ii
    for n in names:
        ii = info.get(n, {})
        url = ii.get("thumburl") or ii.get("url")
        dest = C.FULL_IMG_DIR / placeholders.placeholder_relpath(n).replace(".webp", "")
        if url and not dest.exists() and "--list" not in sys.argv:
            dest.parent.mkdir(parents=True, exist_ok=True)
            req = urllib.request.Request(url, headers={"User-Agent": C.CFG["user_agent"]})
            data = urllib.request.urlopen(req, timeout=60).read()
            dest.write_bytes(data)
            print("saved", dest.relative_to(C.ROOT), len(data))
            time.sleep(float(C.CFG.get("delay_seconds", 2.5)))
        key, title = want[n]
        rows.append("%s\t%s\t%s\t%s\t%s\t%s\t%s" % (key, title, n, ii.get("descriptionurl", ""), "CC BY-SA 3.0 (Wookieepedia); see source page",
                                                     url or "", dest.relative_to(C.ROOT).as_posix()))
    tsv.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print("wrote", tsv)


if __name__ == "__main__":
    main()
