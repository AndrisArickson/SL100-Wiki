# Plan: extracting text from the Star Wars d20 source books

Status: Batch 0 (catalogue, de-duplicate, rename) is DONE. Order confirmed. Extraction scripts and batches below are PLANNED ONLY - awaiting your approval; nothing has been extracted yet.

## Batch 0 - DONE: catalogue, de-duplicate, rename (completed on your drive)
* 80 PDFs -> **58**. **22 duplicates were deleted** (15 byte-identical by MD5, 6 same-book lower-quality or re-wrapped copies verified by page count and OCR of a sample page, 1 corrupt copy with no PDF trailer), plus `Nebula_new.pdf` whose extracted text was identical to the adventure copy. Source_Books went from 1.8 GB to 1.3 GB.
* All 58 survivors follow one naming scheme: `SW_<Title_Words>_<publisher code>.pdf`, with `SW_Adventure_..._L<level>`, `SW_WebEnh_...`, `SW_Errata_...`, `SW_Sheet_...`, `SW_Map_...`, and suffixes `_Fan`, `_GURPS`, `_WEG-d6`, `_Web` for non-WotC-d20 material. The Imperial Sourcebook is GURPS and Platt's Smugglers Guide is West End Games d6 (not d20).
* Every deletion and rename is logged in `Source_Text/catalog/applied.tsv` (old name, new name, size, MD5, proof). The full decision table is `SL100-Wiki/tools/books/books_seed.tsv`; `tools/books/catalog.py` can re-check or re-run it (idempotent).
* `Source_Text/catalog/catalog.tsv` now lists every book with pages, text-layer pages, scanned pages, MD5 and extraction method.
* **Four variant pairs were deliberately NOT deleted** (could not prove they are the same): Hero's Guide 161pp vs 185pp "with WE", Ultimate Alien Anthology 225pp vs 229pp "with WE", New Jedi Order 162pp vs 182pp, Secrets of Tatooine 94pp vs 95pp. They carry a `__variant-` tag and will be compared on the OCR'd text, then one of each pair deleted.

## What the catalogue shows
| Method | Books | Pages |
|--------|-------|-------|
| text layer (`pdftotext`) | 27 | 2,374 |
| scanned, needs OCR | 20 | 2,858 |
| mixed (text + scanned pages) | 7 | 916 (about 700 scanned) |
| forms / maps, no rules text (skipped) | 4 | 14 |

About 3,560 pages need OCR, of which roughly 900 belong to the variant books that may be dropped. The scans are 150 dpi greyscale (Hero's Guide pages are colour JPEG); Tesseract 4.1.1 with English is installed.

## Method (batches 1-6)
* **Hybrid per page:** try `pdftotext -layout`; if a page has fewer than ~40 characters, render it (`pdftoppm -r 300 -gray`) and OCR it with `tesseract --psm 3` (TSV output for confidence).
* **Resumable:** one text file per page; existing pages are skipped. Runs under `nice` in the background; stop with `touch data/STOP`.
* **Workers:** CPU cores minus 1 (max 4), about 300 MB RAM each. The script prints measured pages/minute after the first 10 pages. Rough guess: 5-10 s per page per core.
* **Output:** `/run/media/andris/Bubba/SL100/Source_Text/` (outside the git repo so copyrighted text cannot be pushed by accident): `<slug>/pages/0001.txt`, `<slug>/<slug>.txt` with page markers, `<slug>/<slug>.meta.json` (method per page, mean OCR confidence, low-confidence pages), `qa_report.html`.

## Order confirmed by you
OCR first: **Revised Core Rulebook, Arms and Equipment Guide, Hero's Guide**. Next: the **fan Encyclopedia**. Then the rest.

## Scripts to write (not run until you approve) - `SL100-Wiki/tools/books/`
* `extract.py` - runner: `pilot`, `run --batch N`, `status`, `qa`. Reads `Source_Text/catalog/catalog.tsv` and a `batches.json` (batch -> books).
* Per page: `pdftotext -layout`; if under ~40 characters, `pdftoppm -r 300 -gray` then `tesseract -l eng --psm 3 -c preserve_interword_spaces=1`. Results land in `Source_Text/<slug>/pages/0001.txt`, with a per-page log (method, characters, OCR confidence, seconds).
* Parallel with a worker pool (cores minus 1, max 4), `nice`, resumable (existing pages skipped), clean stop with a `data/STOP` file. Temporary page images are deleted after each page.
* When a book or batch finishes, the script itself writes `Source_Text/<slug>/<slug>.txt` (pages joined with `=== Page N ===` markers), `Source_Text/STATUS.json` and a line in `Source_Text/PROGRESS.md`, so progress is on disk even if no chat is open.
* Started in the background through `./wiki.sh books pilot | run N | status | stop`.

## Batches in your order
| Step | What | Pages | Method | Rough time |
|------|------|-------|--------|-----------|
| A | **Pilot**: 5 pages each from the three books (and the 161 pp Hero's Guide) with 2-3 OCR settings; I report speed, accuracy and what to use for the Hero's Guide colour pages (they returned no text in a first test) | ~20 | OCR | ~5 min |
| Batch 1 | **OCR Core Rulebook (387), Arms and Equipment (97), Hero's Guide (185 pp "with WE")**; then compare 10 sample pages of the 161 pp Hero's Guide with the 185 pp one and, if they match, delete the 161 pp copy | ~670 | OCR | 20-60 min depending on cores |
| Batch 2 | **Completely Unofficial Encyclopedia** (fan work) | 1,895 | pdftotext | a few minutes |
| Batch 3 | Other text-layer books: 9 adventures, 6 web enhancements, Dark Side Sourcebook, Jedi Handbook, Netbook of Prestige Classes, Imperial Sourcebook (GURPS), Smuggling Rules, Silent Death, Lightsaber Construction, Revenge of the Sith, Galactic Gazetteer, Smugglers of Naboo, WotC Equipment Articles | ~670 | pdftotext | minutes |
| Batch 4 | OCR ships, vehicles, worlds: Starships of the Galaxy, Platt's Smugglers Guide, Rebellion Era, Coruscant, Galactic Campaign Guide | ~705 | OCR | ~1 h |
| Batch 5 | OCR species and adversaries: Alien Anthology, Ultimate Alien Anthology, Ultimate Adversaries, Geonosis | ~690-915 | OCR | ~1 h |
| Batch 6 | OCR Jedi, Force, campaign: Power of the Jedi, Tales of the Jedi, New Jedi Order, Tempest Feud, Living Force, Secrets of Naboo and Tatooine | ~875-1,300 | OCR | ~1.3 h |
| Batch 7 | Mixed books, OCR quality report, resolve the remaining variant pairs (UAA, NJO, Tatooine) and delete the redundant copy of each | ~15 | hybrid | minutes |

## Progress is saved at every step
After each step (and each finished book or batch) these are updated together: the Star Legends dashboard, `SL100/PROJECT_STATUS.md` (current snapshot), `SL100/PROGRESS_LOG.md` (history), `SL100/dashboard_tasks.json` (copy of the dashboard's task table), the project doc, and the script-written `Source_Text/STATUS.json`. If a background run finishes while no chat is open, the on-disk files are the truth and the dashboard catches up at the next chat.

## After extraction (separate follow-up, not part of this plan's run)
1. Pull the stat tables (weapons, armour, equipment, vehicles, starships, species, Force powers) into CSV under `Source_Text/tables/` with page references.
2. Convert them to SL100 values (WFRP-style damage, encumbrance, price, availability) and write `SL100:` wiki pages that link to the matching Legends articles. Only converted, rewritten statistics go into the public wiki; raw d20 text stays in `Source_Text/`.
3. Add a "Source QA" and "Search source books" page to the local server (private, local only) so you can look things up while writing.

## Questions to confirm before I write and run the scripts
1. Output in `SL100/Source_Text/` (outside the repo) - OK?
2. Priority order: is batch 2 (core rules and gear) the right first OCR target?
3. Should the 1,895-page Unofficial Encyclopedia be included at all? It is fan-written, not WotC, and large; it can be skipped or left to last.
