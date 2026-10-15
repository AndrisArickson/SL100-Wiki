# Reviewing and editing the SL100 wiki

The rules of *Star Legends – Galactic Wars* live in the `SL100:` pages of this wiki. Those pages are the master copy:
change them in the wiki, and the change reaches everyone once the project owner approves it.

## The short version

1. **Get the wiki** (once): install [Git](https://git-scm.com/) and Python 3.8 or newer, then
   ```bash
   git clone https://github.com/AndrisArickson/SL100-Wiki.git
   cd SL100-Wiki
   ./wiki.sh rebuild      # first time only: builds the local page index (a few minutes)
   ./wiki.sh serve        # open http://127.0.0.1:8100/
   ```
2. **Fill in Reviewer settings** (left-hand menu, once): your name and a GitHub token (see below).
3. **Edit** any page with the *Edit* tab, say what you changed in the summary box, and press **Save draft**.
   The page shows your change straight away with an orange **Edited – not yet submitted** banner. Only you can see it.
4. **Submit**: open **Review changes** in the menu. Check each draft with *changes*, tick the ones to send, give the batch
   a title and press **Submit for approval**. The banner turns green: **Submitted for approval**, with a link.
5. **Approval**: the owner reviews the submission on GitHub and merges it, or replies there with questions.
6. **Pull** before your next session, so you are editing the latest pages:
   ```bash
   git pull
   ```
   Drafts that have been merged clear themselves once you have pulled.

You can keep several drafts on the go and submit them together. To throw a draft away, press *Discard* in its
banner or on Review changes; the page goes back to the version you last pulled.

## Your GitHub token

Submitting needs a GitHub account and a personal access token.

1. On GitHub: your picture → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** →
   **Generate new token**.
2. Repository access: **Only select repositories** → `SL100-Wiki`.
3. Permissions: **Contents: Read and write** and **Pull requests: Read and write**.
4. Copy the token into **Reviewer settings** in the wiki. It is stored in `data/reviewer.json` on your computer only;
   `data/` is never committed.

If the owner has added you as a collaborator, leave **Your fork** empty. Otherwise, press **Fork** on the
repository page on GitHub and enter your fork (for example `yourname/SL100-Wiki`) under **Your fork**.

## Pictures

Every page with pictures has a folded **Images on this page** list at the bottom (each picture's own File page has the
same controls). For each picture:

1. **Wookieepedia file page** opens the original, so you can check its size, licence and author before using it.
2. **Download & replace from Wookieepedia** fetches it as WebP (at most 800 pixels wide) and shows it in the wiki at once.
   When the original is an SVG drawing (emblems, logos, maps), the wiki fetches both the SVG and a WebP copy and keeps
   whichever file is smaller.
3. If the download fails, save the picture from the Wookieepedia page yourself and use **Upload instead**. WebP and SVG
   files are used as they are; other formats are converted when Pillow is installed (`pip install pillow`).

SVG files can carry scripts, so the wiki removes scripts, event handlers and links to other sites from every SVG it
saves, refuses one it cannot clean, and serves SVGs in a way that cannot run code.

A new picture is a draft like a page edit: it appears on **Review changes**, where *changes* shows the old and new
picture side by side, and it reaches GitHub (and so the other reviewers) only when you **submit** it.

## Review notes

A note for other reviewers goes straight into the page text, in backticks:

```
`[review: Rybet males are 1.5 m tall; should the species be Small?]`
```

Review notes are hidden from players. Press **Show review notes (n)** at the top of a page to see them highlighted;
the wiki remembers your choice. Remove a note once its question is settled.

## Writing conventions

- Pages use MediaWiki wikitext: `'''bold'''`, `''italic''`, `== Heading ==`, `* list item`, and tables with `{|`.
  *Show preview* lets you check the result before saving.
- Link to another rules page with `[[SL100:Skills|Skills]]` or straight to a section with `[[SL100:Talents#Small|Small]]`.
- Keep the established forms that tools read: species lines such as `'''Talents:''' …` and `'''Size:''' …`, and
  career level lines such as `'''1. Title — Status'''`.
- Rules come from the design group: if something is missing or unclear, leave a review note rather than inventing it.

## If the wiki says a page changed on GitHub

Submitting refuses a page that someone else changed on GitHub after your last pull, so nobody's work is overwritten.
Run `git pull`, open the page, check your draft still reads right (Git merges the two versions when it can), then
submit again. If `git pull` reports a conflict in a page, ask the owner for help.

## For the owner: tools that read the rules

The Roll20 sheet generator and the consistency and collation scripts read markdown copies of the rules pages.
Write them with:

```bash
./wiki.sh rules-md     # writes build/rules/ (git-ignored)
```

The original markdown chapters and design documents stay on your own computer (for example in `../SL100-Sources`);
they are not part of the repository.
