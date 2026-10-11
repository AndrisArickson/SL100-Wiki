"""Blank placeholder images (lossless WebP) so page layout matches the original without downloading images.

A solid-colour VP8L image needs no pixel data at all (every Huffman code has one symbol), so each
file is ~70 bytes regardless of dimensions. Pure Python - no Pillow required.

Usage:  python3 tools/placeholders.py [--all] [--force]
"""
import struct
import sys

from common import (CFG, PLACEHOLDER_DIR, META_DIR, db_connect, log, safe_name, shard, write_atomic)


class _Bits:
    def __init__(self):
        self.v = 0
        self.n = 0

    def put(self, value, nbits):
        self.v |= (value & ((1 << nbits) - 1)) << self.n
        self.n += nbits

    def bytes(self):
        return self.v.to_bytes((self.n + 7) // 8, "little")


def blank_webp(width, height, rgb=(205, 211, 217)):
    width, height = max(1, min(int(width), 16384)), max(1, min(int(height), 16384))
    b = _Bits()
    b.put(width - 1, 14)
    b.put(height - 1, 14)
    b.put(0, 1)        # alpha_is_used
    b.put(0, 3)        # version
    b.put(0, 1)        # no transform
    b.put(0, 1)        # no colour cache
    b.put(0, 1)        # no meta prefix image
    r, g, bl = rgb
    for sym in (g, r, bl, 255):          # green, red, blue, alpha: simple code, 1 symbol, 8 bits
        b.put(1, 1)    # simple code
        b.put(0, 1)    # one symbol
        b.put(1, 1)    # symbol uses 8 bits
        b.put(sym, 8)
    b.put(1, 1)        # distance code: simple
    b.put(0, 1)        # one symbol
    b.put(0, 1)        # 1-bit symbol
    b.put(0, 1)        # symbol 0
    payload = b"\x2f" + b.bytes()
    chunk = b"VP8L" + struct.pack("<I", len(payload)) + payload + (b"\0" if len(payload) % 2 else b"")
    return b"RIFF" + struct.pack("<I", 4 + len(chunk)) + b"WEBP" + chunk


def scaled_size(w, h):
    mx = int(CFG["placeholder_max_px"])
    if not w or not h:
        return tuple(CFG["placeholder_default_size"])
    s = min(1.0, mx / max(w, h))
    return max(1, round(w * s)), max(1, round(h * s))


def placeholder_relpath(name):
    stem = safe_name(name)
    return "%s/%s.webp" % (shard(stem), stem)


def ensure_placeholder(name, w=None, h=None):
    rel = placeholder_relpath(name)
    p = PLACEHOLDER_DIR / rel
    if not p.exists():
        p.parent.mkdir(parents=True, exist_ok=True)
        pw, ph = scaled_size(w, h)
        p.write_bytes(blank_webp(pw, ph, tuple(CFG["placeholder_rgb"])))
    return p


def generate_all(force=False):
    con = db_connect()
    rows = con.execute("SELECT name,width,height,placeholder FROM imgs").fetchall()
    made = 0
    for r in rows:
        if r["placeholder"] and not force:
            continue
        p = PLACEHOLDER_DIR / placeholder_relpath(r["name"])
        if force and p.exists():
            p.unlink()
        ensure_placeholder(r["name"], r["width"], r["height"])
        con.execute("UPDATE imgs SET placeholder=1 WHERE name=?", (r["name"],))
        made += 1
        if made % 2000 == 0:
            con.commit()
    con.commit()
    export_manifest(con)
    log("placeholders written: %d (total images %d)" % (made, len(rows)))


def export_manifest(con):
    """meta/images.tsv - the list of images that need (or have) a placeholder. Committed to git."""
    lines = ["name\twidth\theight\tplaceholder_w\tplaceholder_h\tmime\tbytes\tuses\tplaceholder_path\toriginal_url"]
    for r in con.execute("SELECT * FROM imgs ORDER BY name COLLATE NOCASE"):
        pw, ph = scaled_size(r["width"], r["height"])
        lines.append("\t".join(str(x if x is not None else "") for x in (
            r["name"], r["width"], r["height"], pw, ph, r["mime"], r["size"], r["uses"],
            "images/placeholders/" + placeholder_relpath(r["name"]), r["url"])))
    write_atomic(META_DIR / "images.tsv", "\n".join(lines) + "\n")
    return len(lines) - 1


if __name__ == "__main__":
    generate_all(force="--force" in sys.argv)
