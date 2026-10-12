# Attribution and licensing

## Wookieepedia content
Pages harvested into `pages/` are text from **Wookieepedia** (https://starwars.fandom.com), restricted to the
*Legends* continuity. Wookieepedia text is available under the
[Creative Commons Attribution-Share Alike 3.0 (CC BY-SA 3.0)](https://creativecommons.org/licenses/by-sa/3.0/) licence.

* Each harvested page is listed in `meta/pages.tsv` with its original title, page id, revision id and timestamp.
  The original article and its full authorship history are at
  `https://starwars.fandom.com/wiki/<Title>` and `...?action=history`.
* The local wiki server prints an attribution footer on every harvested page.
* Pages you modify stay under CC BY-SA 3.0 (share-alike). Original game material you write may be licensed as you wish,
  but any text derived from a Wookieepedia article remains CC BY-SA 3.0.
* Images are **not** downloaded; blank placeholders are generated locally. Wookieepedia images carry their own
  (often more restrictive) licences, listed on each File page at the original site.

## Trademarks
Star Wars and related names are trademarks of Lucasfilm Ltd. This is an unofficial, non-commercial fan project.

## Source books
Text extracted from the Star Wars d20 books in `Source_Books/` is copyrighted. Keep any extracts in `private/`
(git-ignored) and publish only your own rewritten/converted game statistics.

## Images
* `images/full/` - images that are freely licensed on Wookieepedia (CC BY-SA, GFDL, public domain, "free use") or made by
  the SL100 group, plus a small set of front-page card images (listed in `meta/card_images.tsv`) that the project owner
  has chosen to publish. These are pushed to GitHub.
* `images/local/` - images Wookieepedia marks as fair use or carries without a licence tag (mostly Lucasfilm and
  publisher artwork). They are downloaded only for the private, locally hosted copy of this wiki and are git-ignored;
  they are never published from this repository.
* Every downloaded image is listed with its licence, author/credit and Wookieepedia file page in `meta/image_licences.tsv`;
  the local wiki shows the same on each `File:` page. Blank placeholders in `images/placeholders/` are generated.

### SL100 original artwork
Images named `SL100 …` (originals in `images/generated/originals/`, WebP copies in `images/full/S/`) were generated for this project with Google Flow (Nano Banana) from original prompts that avoid franchise designs, logos and named characters. Prompts and dates are listed in `meta/generated_images.tsv`.
