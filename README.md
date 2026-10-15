# SL100 Wiki - Star Legends: Galactic Wars

Local, editable wiki of **Star Wars Legends** reference material plus our own **SL100** game rules and statistics.
Pages are stored as plain **MediaWiki wikitext** (`pages/**/*.wiki`), so the whole tree can be imported into a real
MediaWiki site later (or served by any wiki engine that reads wikitext). Everything is Python 3.8+ standard library only
- nothing to install.

```
SL100-Wiki/
  wiki.sh            controller (start / stop / status / serve / push ...)
  config.json        throttle, priority categories, port, placeholder settings
  pages/             wikitext, one file per page   Main/<letter>/Title.wiki, Template/, Module/, SL100/
  meta/pages.tsv     index of every page: title, page id, revision, timestamp (attribution record) - committed
  meta/images.tsv    every image referenced, with original size and the placeholder to generate - committed
  images/placeholders/   generated blank .webp files (regenerable)
  images/full/       real images (Wookieepedia CC BY-SA or our own art); the server prefers them over placeholders - pushed
  data/              local database, logs, edit history (git-ignored)
  tools/             crawl.py  serve.py  wikitext.py  placeholders.py  push.sh
  NOTICE.md          CC BY-SA 3.0 attribution + licensing notes
  private/           put copyrighted d20 text extracts here (git-ignored, never pushed)
```

## Quick start
```bash
cd /run/media/andris/Bubba/SL100/SL100-Wiki
chmod +x wiki.sh
./wiki.sh pilot          # optional: 200 pages in a couple of minutes, to see it working
./wiki.sh serve          # open http://127.0.0.1:8100/
./wiki.sh start          # full background harvest (see below)
./wiki.sh status         # progress;   ./wiki.sh log  follows the log
./wiki.sh stop           # clean stop - progress is kept, 'start' resumes
```

## How the harvest behaves (gentle by design)
* One request at a time, **2.5 s (+ random jitter) between requests**, 50 pages per request, honours `maxlag`,
  `Retry-After`, 429/5xx back-off, and a descriptive User-Agent. Change `delay_seconds` in `config.json`.
* Uses the official MediaWiki API (`api.php`) - no HTML scraping.
* Steps: **discover** every article in *Category:Legends articles* (about 117,000) -> **prioritize** weapons, armour,
  equipment, starships, vehicles, droids, species, planets, Force powers, organisations -> **fetch** wikitext
  (priority order) -> **images** (sizes only) -> **placeholders** -> **export** index files.
* Expect roughly 2,500 fetch requests, i.e. **a few hours** in total; it is fully resumable (SQLite state in `data/`).
  Template and Lua-module pages are fetched too so the pages can be rebuilt on a real wiki.
* Pages you edit are flagged `local_edit` and are **never overwritten** by later harvests.
* Only Legends pages are listed; links to pages that were not harvested show red.

## Images
No image files are downloaded. Every `[[File:...]]`, gallery entry and infobox image is recorded, its original width and
height are looked up through the API, and a **blank lossless .webp of the same proportions** (scaled to at most
640 px, ~32 bytes each) is generated so page layout matches the original. The list is in **`meta/images.tsv`**
(`name, width, height, placeholder size, mime, bytes, uses, placeholder path, original URL`). Re-create the placeholders
any time with `./wiki.sh images`. To use real art later, place a file at `images/full/<letter>/<name>` and the server
will use it instead.

## Real images (optional, long-running)
```bash
./wiki.sh images-classify          # licence + author for every image our pages use (~1 h, 50 per request)
./wiki.sh images-fetch             # background download as WebP (max 800 px); all go to images/full (pushed),
                                   # fair use and untagged included. ~1 s apart, resumable; stop: touch data/STOP
./wiki.sh images-qc                # score every image (size, sharpness vs the whole set, blank, aspect, compression, duplicates)
./wiki.sh images-status
```
Review at http://127.0.0.1:8100/image-review: contact sheets of 120, lowest scores first. Tick the bad ones and one button
saves the whole page (ticked = replace, the rest = OK); "Auto-approve" accepts everything above a score in one go.
`meta/image_replace.tsv` lists the images marked for replacement, with the pages that use them, as a work list for new art.

## Editing and adding game content
The `SL100:` rules pages (`SL100:Characteristics` ... `SL100:Vehicles and Starships`) are the **master copy of the rules**.
Edit them in the wiki: press **Edit**, then **Save draft**. The page is flagged *Edited – not yet submitted* until you send
it from **Review changes**, which submits your drafts to GitHub as a pull request for the owner to approve. The whole
process, including the GitHub token reviewers need, is in [CONTRIBUTING.md](CONTRIBUTING.md). Old versions of every page
are kept in `data/history/`. Notes for reviewers are written `` `[review: ...]` `` and stay hidden until a reader presses
*Show review notes*. Each page also lists its pictures under *Images on this page*, with a link to the original on
Wookieepedia, **Download & replace** (fetches it as WebP, or as SVG when that is smaller) and an upload box; a new picture is a draft submitted the same way.

Use the `SL100:` prefix for new game pages (e.g. `SL100:Weapons/Blaster pistol`) and put game statistics in an
infobox-style template, for example `{{SL100 Weapon|name=...|damage=...|price=...|availability=...}}` - see
`SL100:Example Weapon`. The renderer shows any template with three or more named parameters as an infobox, so new stat
templates need no extra code. `python3 tools/build_pages.py` rebuilds the front-page cards.

The repository holds only the finished wiki: the pages and their WebP images. The original markdown chapters and the
design and review documents stay on the owner's computer (`.gitignore` lists them). Tools that read the rules as markdown -
the consistency and collation scripts, the equipment converter and the Roll20 sheet generator - read copies written by
`./wiki.sh rules-md` into `build/rules/`. The Weapons, Armour and Gear catalogues (`rules/equipment/*.csv`, pages
`SL100:Weapons`, `SL100:Armour`, `SL100:Gear`) are built by `python3 tools/convert/equipment.py` from the Equipment and
Special Materials pages and the d20 tables in `../Source_Text/tables/`.

## Pushing to GitHub
```bash
./wiki.sh push           # commits in chunks of 1,500 files and pushes after each chunk
```
Target: https://github.com/AndrisArickson/SL100-Wiki (create the empty repo first; authenticate with your usual
git credentials, or `REMOTE=git@github.com:AndrisArickson/SL100-Wiki.git ./wiki.sh push` for SSH). Re-running continues where it
stopped. `data/`, `private/` and the d20/WFRP text (kept outside the repo in `../Source_Text`, `../WFRP_Text`) are never pushed. All images are pushed, as WebP only: Wookieepedia images and our own artwork (see `NOTICE.md`); non-WebP originals stay outside the repo in `../art_originals`. On a fresh clone run `./wiki.sh rebuild`
to recreate the local database from `meta/pages.tsv`.
A full harvest is on the order of 1 GB across ~120,000 files; GitHub accepts this but the first push will be slow.

## Limits of the local renderer
It displays headings, links, lists, tables, galleries, references, categories and infoboxes, but does not run
Wikipedia-style template logic or Lua. Pages are therefore a faithful *reading copy*; the wikitext on disk is the
master and is untouched by the renderer.
