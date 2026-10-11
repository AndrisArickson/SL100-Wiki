# Collation outputs

Mechanical lookups and comparisons for the rules work. Nothing in these files is a design decision: names and numbers
are copied as written, matched by name, and listed where sources disagree. Re-run everything with `./wiki.sh collate`.

## In this folder (from the SL100 design documents only, safe to push)

| File | What it holds | Script |
|---|---|---|
| `legends_check.csv` / `legends_check_summary.md` | every name in the design docs (headings, first table column, Wookieepedia links) looked up in the Legends wiki: `legends`, `legends-link`, `canon-link`, `canon-only` (live Wookieepedia has only a canon page), `not-found` | `tools/collate/legends_check.py` |
| `talents_master.csv` | every talent entry in 07 with Max and Tests as written, line, flags (no Max, no text, placeholder) | `tools/collate/lists.py` |
| `talent_list_index.csv` | the entries of `Talent List.md` with section and summary | same |
| `skills_master.csv` | every skill entry in 06: name, characteristic, basic/advanced, grouped | same |
| `career_refs.csv` | every skill and talent named in each career level of 05 | same |
| `lists_report.md` | differences between 07, Talent List, 06 and 05: missing, undefined, duplicates, near-duplicate spellings | same |
| `species.csv`, `origins.csv`, `factions.csv`, `careers_l1.csv`, `character_assembly.md` | what each character-creation layer gives, as written in 01-05 (also the wiki page SL100:Character creation) | `tools/collate/assembly.py` |
| `intuition_fixes.md` | every Intuition -> Initiative change made (characteristic uses only; the Intuition skill is kept) | one-off fix, 2026-10-11 |
| `vocab_hits.csv` / `vocab_report.md` | leftover WFRP / d20 / fantasy vocabulary, placeholders and dead page references, with line and context | `tools/collate/vocab.py` |

## In `../Source_Text/` (contains d20 book data, kept out of git)

| File | What it holds | Script |
|---|---|---|
| `tables/*.csv` | raw d20 stat blocks: weapons, armour, droids, vehicles, gear, starships (+ starship weapons), Core Rulebook tables | `tools/books/statblocks.py`, `coretables.py`, `starships.py` |
| `tables/wiki_match.csv` | each d20 item matched to its Legends article (`exact`, `code`, `generic`, `words`, `multi`, `none`) with the infobox facts copied (manufacturer, model, class, cost, length, crew, affiliation...) | `tools/books/wikimatch.py` |
| `collation/wfrp_careers.csv`, `sl100_careers.csv`, `careers_compare.md` | every WFRP 4e career level vs the SL100 careers in 05: missing careers, level-by-level skill/talent/trapping differences (summary on the wiki page SL100:Careers compared with WFRP) | `tools/collate/careers_compare.py` |
| `collation/ships_compare.csv` / `.md` | every source's figures for each ship or vehicle side by side: Space Ships doc, era doc, Mounts & Vehicles doc, d20 books, Legends wiki | `tools/collate/ships_compare.py` |

## Wiki pages generated from these (tools/collate/wiki_pages.py)
SL100:Character creation, SL100:Collation (+ /Legends check, /Talent and skill lists, /Vocabulary, /Intuition fixes),
SL100:Careers compared with WFRP, SL100:Source books. Front-page cards use `{{SL100 Card|link=|title=|image=|text=}}`
inside `<div class="sl-cards">`; card images are listed with their Wookieepedia source in `meta/card_images.tsv`.
The private d20 book browser is at http://127.0.0.1:8100/books (local only).
