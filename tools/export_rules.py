#!/usr/bin/env python3
"""Export the SL100 rules pages back to markdown, for the tools and the Roll20 sheet generator.

    python3 tools/export_rules.py [OUT_DIR]        (default: build/rules, git-ignored)

The SL100: wiki pages are the master copy of the rules. Reviewers edit them in the wiki; nothing edits the markdown.
The collation and consistency scripts, the equipment converter and the Roll20 sheet's scripts/gen-data.js still read
markdown, so this script writes one markdown file per source, under the file names they expect. The conversion is
the reverse of the old build_pages.py markdown -> wikitext step: headings, bold and italic, Legends links, pictures,
tables and lists come back in the form the parsers read. Run it after pulling or after editing the rules pages.
"""
import re
import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402

LEGENDS = "https://starwars.fandom.com/wiki/"

# page -> [(markdown file, heading base, title line or None)]. "base" is the markdown level that the page's "=="
# headings stand for; "title" is the document title the page builder dropped (the page name replaces it).
SOURCES = {
    "SL100:How to Play": [("11 New Star Wars - How to Play.md", 2, "# How to Play")],
    "SL100:Characteristics": [("01 New Star Wars - Introduction & Characteristics.md", 2, "# Introduction")],
    "SL100:Species": [("02 New Star Wars - Species (revised).md", 2, "# Species")],
    "SL100:Origin": [("03 New Star Wars - Origin.md", 2, "## ORIGIN")],
    "SL100:Faction": [("04 New Star Wars - Faction.md", 1, "## CAREER PATH & FACTION")],
    "SL100:Careers": [("05 New Star Wars - Careers (revised).md", 2, "# Careers")],
    "SL100:Skills": [("06 New Star Wars - Skills.md", 2, None)],
    "SL100:Talents": [("07 New Star Wars - Talents (revised).md", 2, "# Talents")],
    "SL100:Equipment": [("08 New Star Wars - Equipment.md", 1, "# EQUIPMENT")],
    "SL100:Special Materials": [("Special Materials.md", 3, None)],
    "SL100:The Force": [("09 New Star Wars - Force Influence.md", 1, None)],
    "SL100:Combat": [("10 New Star Wars - Combat and Lightsaber Forms.md", 1, None)],
    "SL100:Hyperspace": [("All about hyperspace.md", 1, None)],
    "SL100:Bestiary": [("Star Wars Bestiary.md", 2, None)],
    "SL100:Vehicles and Starships": [("Star Wars Mounts_Vehicles.md", 1, None), ("Star Wars Space Ships.md", 1, None),
                                     ("Starships circa 3000-4000 BBY.md", 1, None)],
}
# The section heading build_pages.py put above each file on a page built from several files.
PART_HEADING = {f: Path(f).stem.replace("Star Wars ", "").replace("_", " / ") for f in
                ("Star Wars Mounts_Vehicles.md", "Star Wars Space Ships.md", "Starships circa 3000-4000 BBY.md")}


def page_text(title):
    path = C.PAGES_DIR / C.page_relpath(title, 3000)
    return path.read_text(encoding="utf-8")


def strip_frame(text):
    """Drop what the page adds around the rules text: __NOTOC__, comments, the info box, the lead paragraph, the
    Talents index and the categories."""
    text = re.sub(r"<!--.*?-->\n?", "", text, flags=re.S)
    text = text.replace("__NOTOC__\n", "")
    text = re.sub(r"\n*\[\[Category:[^\]]*\]\]\s*", "\n", text).rstrip() + "\n"
    lines = text.split("\n")
    i = 0
    if lines and lines[0].startswith("{{SL100 Rules"):
        i = 1
        if i < len(lines) and lines[i].strip() and not lines[i].startswith(("=", "{|")):
            i += 1                       # the lead paragraph
    lines = lines[i:]
    if lines and not lines[0].strip():
        lines = lines[1:]
    if lines and lines[0].strip() == "== Index ==":
        # the generated talents index: two tables under "=== ... talents (n) ===" headings
        j, tables = 1, 0
        while j < len(lines) and tables < 2:
            if lines[j].startswith("|}"):
                tables += 1
            j += 1
        lines = lines[j:]
    return "\n".join(lines).strip("\n") + "\n"


def legends_link(raw, target, label):
    """[[Title|label]] -> [label](Legends URL). SL100 and category links stay as they are."""
    if target.startswith(("SL100:", "Category:", ":", "#")):
        return raw
    url = LEGENDS + urllib.parse.quote(target.replace(" ", "_"), safe="/:'!,&-._~")
    return "[%s](%s)" % (label if label is not None else target, url)


def inline(s):
    s = re.sub(r"\[\[File:([^|\]]+)\|thumb\|right\|360px\|([^\]]*)\]\]", r"![\2](File:\1)", s)
    s = re.sub(r"\[\[File:([^|\]]+)(?:\|[^\]]*)?\]\]", r"![](File:\1)", s)
    s = re.sub(r"\[\[([^|\]]+)\|([^\]]*)\]\]", lambda m: legends_link(m.group(0), m.group(1), m.group(2)), s)
    s = re.sub(r"\[\[([^|\]]+)\]\]", lambda m: legends_link(m.group(0), m.group(1), None), s)
    s = re.sub(r"\[(https?://\S+) ([^\]]+)\]", r"[\2](\1)", s)
    s = s.replace("'''''", "***")
    s = re.sub(r"'''(.+?)'''", r"**\1**", s)
    s = re.sub(r"(?<!')''(?!')(.+?)(?<!')''(?!')", r"*\1*", s)
    s = re.sub(r"<code>(.*?)</code>", r"`\1`", s)
    return s


def table(block):
    rows, cur, header = [], None, None
    for ln in block:
        if ln.startswith("{|") or ln.startswith("|}"):
            continue
        if ln.startswith("|-"):
            if cur is not None:
                rows.append(cur)
            cur = []
            continue
        if ln.startswith("!"):
            header = [c.strip() for c in ln[1:].split("!!")]
            continue
        if ln.startswith("|"):
            cur = (cur or []) + [c.strip() for c in ln[1:].split("||")]
    if cur:
        rows.append(cur)
    out = []
    if header is not None:
        out.append("| " + " | ".join(inline(c) for c in header) + " |")
        out.append("| " + " | ".join("---" for _ in header) + " |")
    out += ["| " + " | ".join(inline(c) for c in r) + " |" for r in rows]
    return out


def wiki_to_md(text, base):
    lines = text.replace("\r", "").split("\n")
    out, i = [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("{|"):
            j = i
            while j < len(lines) and not lines[j].startswith("|}"):
                j += 1
            out += table(lines[i:j + 1])
            i = j + 1
            continue
        if ln.strip() == '<div style="clear:both"></div>':
            i += 1
            continue
        h = re.match(r"^(=+) (.*?) \1\s*$", ln)
        if h:
            out.append("#" * max(1, len(h.group(1)) - 2 + base) + " " + inline(re.sub(r"'{2,}", "", h.group(2))))
            i += 1
            continue
        li = re.match(r"^([*#]+) (.*)$", ln)
        if li:
            depth = len(li.group(1))
            mark = "1." if li.group(1)[-1] == "#" else "-"
            out.append("  " * (depth - 1) + mark + " " + inline(li.group(2)))
            i += 1
            continue
        if ln.strip() == "----":
            out.append("---")
        elif ln.startswith(": "):
            out.append("> " + inline(ln[2:]))
        else:
            out.append(inline(ln))
        i += 1
    return "\n".join(out).strip("\n") + "\n"


def talent_list(md):
    """'Talent List (revised).md' rebuilt from the Talents page (the index the page shows is made from it)."""
    rows, sec = {"General": [], "Force": []}, "General"
    for m in re.finditer(r"^(## Force Talents)|^### (.+?)\n\*\*Max:\*\* (.+?)(?: · \*\*Tests:\*\* (.+?))?\n", md, re.M):
        if m.group(1):
            sec = "Force"
            continue
        rows[sec].append((m.group(2).strip(), m.group(3).strip(), (m.group(4) or "-").strip()))
    out = ["# Talent List", "", "Index of every talent on the [[SL100:Talents|Talents]] page. Max is the number of ranks "
           "allowed; Tests are the Tests the talent adds +1 SL per rank to.", ""]
    for sec in ("General", "Force"):
        out += ["## %s talents (%d)" % (sec, len(rows[sec])), "", "| Talent | Max | Tests |", "| --- | --- | --- |"]
        out += ["| %s | %s | %s |" % r for r in rows[sec]] + [""]
    return "\n".join(out)


def export(out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for title, files in SOURCES.items():
        body = strip_frame(page_text(title))
        if len(files) == 1:
            parts = {files[0][0]: body}
        else:
            names = [PART_HEADING[f] for f, _, _ in files]
            pieces = re.split(r"^== (%s) ==\s*$" % "|".join(re.escape(n) for n in names), body, flags=re.M)
            parts = {}
            for k in range(1, len(pieces), 2):
                f = next(f for f, _, _ in files if PART_HEADING[f] == pieces[k])
                parts[f] = re.sub(r"^=(=+ .*? =+)=\s*$", r"\1", pieces[k + 1], flags=re.M)   # undo the extra level
        for f, base, head in files:
            md = wiki_to_md(parts.get(f, ""), base)
            if head:
                md = head + "\n\n" + md
            (out_dir / f).write_text(md, encoding="utf-8")
            written.append(f)
            if f.startswith("07 "):
                (out_dir / "Talent List (revised).md").write_text(talent_list(md), encoding="utf-8")
                written.append("Talent List (revised).md")
    return written


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else C.RULES_DIR
    files = export(out)
    print("exported %d files to %s" % (len(files), out))


if __name__ == "__main__":
    main()
