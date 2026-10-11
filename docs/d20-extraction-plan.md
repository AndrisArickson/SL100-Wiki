# Plan: extracting text from the Star Wars d20 source books

Status: PLAN ONLY - nothing has been extracted or run. Based on a read-only survey of `SL100/Source_Books` (80 PDFs, 7,781 pages, 1.8 GB).

## What the survey found
1. **Most of the important books are scanned images, not text.** The Revised Core Rulebook, Arms & Equipment Guide, Hero's Guide, Alien Anthologies, Starships of the Galaxy, Power of the Jedi, Rebellion Era, Coruscant, Galactic Campaign Guide, Ultimate Adversaries, Tempest Feud, NJO, Geonosis, Secrets of Naboo/Tatooine, Living Force and Tales of the Jedi are 150 dpi greyscale page scans (Acrobat "Scan Plug-in"). They need **OCR** (Tesseract 4.1.1 + English is installed).
2. **About 35 files have a real text layer** (the adventures, web enhancements, Dark Side Sourcebook, Imperial Sourcebook, Jedi Handbook, Netbook of Prestige Classes, Revenge of the Sith, Silent Death, Galactic Gazetteer, Smugglers of Naboo, and the 1,895-page *Completely Unofficial Star Wars Encyclopedia*). These extract in minutes with `pdftotext`.
3. **Heavy duplication.** The same book often appears 2-4 times under different names (identical byte sizes prove it for ~14 sets). Extracting each once cuts the OCR load from ~6,000 scanned pages to **~2,950 unique pages**.
4. `D20 - WotC - Star Wars - Ships Enhancement.pdf` is unreadable (pdfinfo error) but is a duplicate of other copies. Character sheets, the Naboo ship map and "Ship Sheeta" are image-only forms with no rules text - skip.

## Method
* **Hybrid per page:** try `pdftotext -layout` for each page; if a page has fewer than ~40 characters, render it (`pdftoppm -r 300 -gray`) and OCR it with `tesseract --psm 3` (`preserve_interword_spaces=1`, TSV output for confidence). Handles mixed books such as *All WotC Equipment Articles* and *The Jedi Path*.
* **Resumable:** one text file per page; existing pages are skipped, so stopping and restarting loses nothing. Runs under `nice`, background via `./wiki.sh books ...`, stop with `touch data/STOP`.
* **Workers:** default = CPU cores minus 1 (max 4); about 300 MB RAM each. The script prints measured pages/minute after the first 10 pages so the ETA is real. Rough estimate: 5-10 s per page per core -> 3-6 CPU-hours for all OCR, i.e. 1.5-3 hours wall-clock on 2-4 cores.
* **Output location (proposed):** `/run/media/andris/Bubba/SL100/Source_Text/` - deliberately **outside** the git repo so copyrighted text cannot be pushed by accident.

```
Source_Text/
  catalog.tsv            every PDF: pages, text-layer ratio, md5, duplicate group, chosen canonical copy
  books.json             editable: canonical file, slug, batch number, method (text | ocr | hybrid | skip)
  <slug>/pages/0001.txt  one file per page (resume point)
  <slug>/<slug>.txt      all pages joined with "=== Page N ===" markers
  <slug>/<slug>.meta.json   method per page, mean OCR confidence, low-confidence page list
  qa_report.html         flagged pages across all books
```

## Batches (run in this order; each can be reviewed before the next)
| # | Batch | Books (canonical copy) | Pages | Method | Est. time |
|---|-------|------------------------|-------|--------|-----------|
| 0 | Catalogue and de-duplicate | all 80 files | 7,781 | md5 + page counts, writes `catalog.tsv` / `books.json` for your review | ~5 min |
| 1a | Short text-layer items | 9 adventures, 6 web enhancements, Smuggling Rules, Lightsaber Construction, Silent Death, Revenge of the Sith, Galactic Gazetteer, Smugglers of Naboo, Ships Enhancement | ~300 | pdftotext | <5 min |
| 1b | Big text-layer books | Dark Side Sourcebook (161), Imperial Sourcebook (56), Jedi Handbook (118), Netbook of Prestige Classes (65), *Completely Unofficial Encyclopedia* (1,895) | ~2,300 | pdftotext | ~10 min |
| 2 | **Core rules and gear** (highest value for stats, cost, availability) | Revised Core Rulebook (387), Arms & Equipment Guide (97), Hero's Guide with WE (185), GM Screen (8), Dark Side errata (2) | ~680 | OCR | ~1 h |
| 3 | **Ships, vehicles, worlds** | Starships of the Galaxy (114), Platt's Smugglers Guide (106), Rebellion Era (161), Coruscant and the Core Worlds (162), Galactic Campaign Guide (162) | ~705 | OCR | ~1 h |
| 4 | **Species and adversaries** | Ultimate Alien Anthology with WE (229), Alien Anthology (135), Ultimate Adversaries (162), Geonosis and the Outer Rim (162) | ~690 | OCR | ~1 h |
| 5 | **Jedi, Force, campaign** | Power of the Jedi (163), Tales of the Jedi Companion (143), NJO Sourcebook (182), Tempest Feud (130), Living Force (66), Secrets of Naboo (98), Secrets of Tatooine (94) | ~875 | OCR | ~1.3 h |
| 6 | Mixed/odd | All WotC Equipment Articles (72), The Jedi Path (10), others flagged by batch 0 | ~85 | hybrid | ~15 min |
| 7 | QA | all | - | mean confidence per book, list of pages under 70, 5 random pages per book for you to eyeball against the PDF | ~5 min |

Times are rough guesses until the first OCR run measures the real speed on your machine.

## Duplicate decisions I propose (please object to any)
* Use the larger, higher-resolution copy when several exist: Arms & Equipment = the 100 MB `WTC88664` (not the 24 MB copies); Secrets of Naboo = 75 MB `WTC11794`; Living Force = 42 MB `WTC11963`; Secrets of Tatooine = `WTC11839`.
* Hero's Guide: use "(with WE)" (185 pp) rather than `WTC17667` (161 pp). Ultimate Alien Anthology: use "(with WE)" (229 pp).
* `Star Wars - D20 - The New Jedi Order Sourcebook.pdf` (162 pp, 34 MB) has the same page count and size as the Geonosis book, so it may be mislabelled; batch 0 compares them by content before anything is OCR'd. `WTC88658` (182 pp) is the NJO book to use.
* `01_WTC17650` is a byte-identical copy of `WTC17650` - skip.
* Skip: Darkside Character Sheet, Character Record Sheets, Royal Naboo Starship map, Ship Sheeta (forms/maps).

## After extraction (separate follow-up, not part of this plan's run)
1. Pull the stat tables (weapons, armour, equipment, vehicles, starships, species, Force powers) into CSV under `Source_Text/tables/` with page references.
2. Convert them to SL100 values (WFRP-style damage, encumbrance, price, availability) and write `SL100:` wiki pages that link to the matching Legends articles. Only converted, rewritten statistics go into the public wiki; raw d20 text stays in `Source_Text/`.
3. Add a "Source QA" and "Search source books" page to the local server (private, local only) so you can look things up while writing.

## Questions to confirm before I write and run the scripts
1. Output in `SL100/Source_Text/` (outside the repo) - OK?
2. Priority order: is batch 2 (core rules and gear) the right first OCR target?
3. Should the 1,895-page Unofficial Encyclopedia be included at all? It is fan-written, not WotC, and large; it can be skipped or left to last.
