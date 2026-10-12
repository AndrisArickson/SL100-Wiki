#!/usr/bin/env python3
"""Register SL100 original artwork (images/generated/originals/*.jpg) in the wiki: WebP copy in images/full/ and a row in imglic.
Idempotent. Run when no other image job is writing to data/wiki.db:  python3 tools/register_generated.py [--webp-only]"""
import glob
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402
import images as I  # noqa: E402
from PIL import Image  # noqa: E402


def main():
    webp_only = "--webp-only" in sys.argv
    con = None if webp_only else I.db()
    n = 0
    for f in sorted(glob.glob(str(C.ROOT / "images/generated/originals/*.jpg"))):
        name = os.path.basename(f)
        p = I.dest(name, "free")
        if not p.exists() or p.stat().st_mtime < os.path.getmtime(f):
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(I.to_webp(open(f, "rb").read()))
            n += 1
        if con:
            w, h = Image.open(f).size
            con.execute("INSERT OR REPLACE INTO imglic(name,bucket,licence,artist,credit,cats,descurl,srcurl,ow,oh,obytes,status,path,bytes,fetched_at) "
                        "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        (name, "free", "SL100 original artwork (AI-generated)", "SL100 project (Google Flow, Nano Banana)",
                         "Generated for Star Legends; see meta/generated_images.tsv", "SL100 generated images", "", "", w, h,
                         os.path.getsize(f), "ok", p.relative_to(C.ROOT).as_posix(), p.stat().st_size, C.now_iso()))
    if con:
        con.commit()
    print("webp written: %d; registered in db: %s" % (n, "no (--webp-only)" if webp_only else "yes"))


if __name__ == "__main__":
    main()
