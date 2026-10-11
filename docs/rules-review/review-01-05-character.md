# Review: SL100 Wiki documents 01–05

Scope: `01 Introduction & Characteristics`, `02 Species`, `03 Origin`, `04 Faction`, `05 Careers` (all under `/mnt/user-data/uploads/SL100/SL100-Wiki/`). Read-only review against WFRP 4e as the stated base system.

---

## 01 – Introduction & Characteristics

**(a) Contents and completeness.** A short authorial preface (the Pathfinder-based predecessor, the move to WFRP 4e, set "in the year 2026") followed by the Characteristics chapter: definition, Characteristic Bonus (tens digit), a three-step rolling procedure (2d10+20 per characteristic, 50 XP if kept, 25 XP if rearranged, 0 XP if rerolled) plus a point-buy alternative (each starts at 20, 100 points, min 4 / max 18 per characteristic), and a 3×3 table describing **nine** characteristics: WS, BS, S, T, Ag, Int, I, WP, Fel. The chapter is structurally complete for what it covers; it is essentially the WFRP 4e text with Star Wars nouns swapped in.

**(b) Design decisions.**
- **Nine characteristics, not ten**: Dexterity is dropped. The text says "nine" three times and the table has nine cells.
- Rolling is a flat 2d10+20 for every characteristic; species no longer supply per-characteristic bases (as in WFRP) but instead add modifiers (doc 02), and Origin adds a further +5/+5 (doc 03). This is a real departure: WFRP species bases are *replaced* by a universal base plus two layers of modifiers.
- XP rewards for accepting random results are retained verbatim (50/25/0).
- "Origin" is explicitly named as the next step and as the source of extra characteristic increases ("do not count as Advances"), so Origin takes the place of WFRP's species-base step rather than its Class step.
- Point-buy numbers are reused from WFRP (which assumed 10 characteristics); with nine characteristics the same 100 points produce a higher average (≈31 vs ≈30).

**(c) Inconsistencies / placeholders.**
- Game is called "Warhammer Star Wars" ("Characters in Warhammer Star Wars have nine Characteristics"), not Star Legends – Galactic Wars.
- Dead WFRP page references: "move on to 2) Origin on page 51" (twice).
- Abbreviations defined here (S, T, AG, INT, I, WP, FEL) are not used consistently downstream (doc 02 uses STR/AGI/WILL; doc 05 uses Agi/Dex/Int).
- Flavour claim "towering Wookies having average strength scores in the 60s" is not borne out by the maths: 2d10+20 (avg 31) + Wookiee +20 + Origin +5 ≈ 56.
- Typo "Initative".
- No mention of Fate/Fortune/Resilience/Resolve, Movement or Wounds, all of which species entries in doc 02 reference.

**(d) Gaps.** Character-creation overview (the step list), the Fate/Resilience/Extra Points rules that doc 02 assumes, Wounds/Movement derivation, a worked example, and a clear statement of how species, Origin and starting XP interact. The nine-vs-ten decision needs to be settled and propagated (see doc 05).

---

## 02 – Species

**(a) Contents and completeness.** 17 species, each with a Wookieepedia Legends link, a lore table cell (with an empty cell evidently reserved for an image), and a stat line: Arkanian, Besalisk, Chironian, Chiss, Echani, Human, Kel Dor, Miraluka, Nautolan, Otolla Gungan, Togruta, Trandoshan, T'surr, Twi'lek, Weequay, Wookiee, Zabrak. Fields are **not uniform**:

| Field | Present on | Missing on |
|---|---|---|
| Characteristic modifiers | 14 | Human (deliberate: free talent + "+5 free ranks in any skill"), Otolla Gungan, Togruta |
| Talents | all 17 | – |
| Movement / Fate / Resilience / Extra Points | 15 | Wookiee, Zabrak |
| Size / Natural weapons | Chironian, T'surr, Wookiee | everyone else (incl. Besalisk four arms, Trandoshan claws) |

Most entries say "roll N talents from the random talents list", but no such list exists in these five documents. "Datapad Literate" appears on every species except Otolla Gungan.

**(b) Design decisions.**
- Species give **additive modifiers** (+10/+20/−10) on top of 2d10+20, rather than WFRP-style base values; budget is roughly +30 net per non-human (e.g. Arkanian +20/+10/+10/−10 = +30, T'surr +40−10 = +30, Chiss +30, Wookiee +40−10 = +30, Twi'lek +30). Chironian (+20 only, but Mv 7 and natural weapons) and Zabrak (+30) fit; Echani/Nautolan/Trandoshan/Weequay +30.
- Fate/Resilience/Extra Points follow WFRP's Human 2/1/3 and most aliens 1/1/2; Gungan and Togruta get 2/1/3 (human-like) *and* no characteristic penalties, which looks like the WFRP Halfling pattern but is not explained.
- Heading levels differ (some `####`, some bare links) – inconsistent, cosmetic.
- Force-sensitivity is handled via talents ("Force Ability (Alter, Control or Sense)", "Force Sensitive (Sight)") – a West End Games (d6) Alter/Control/Sense taxonomy, not WFRP.

**(c) Inconsistencies / placeholders.**
- Abbreviations clash with doc 01: "INT +20 WILL +10" (Arkanian), "AGI −10" (Besalisk), "STR +20" (Wookiee), "WILL" (Chiss) vs. doc 01's INT/WP/AG/S. Worse, **"I +10"** on Chiss, Kel Dor and Nautolan is ambiguous – doc 01 defines I = Initiative, but Chiss lore ("strategic and tactical prowess") suggests Intelligence was meant.
- "Stride (Sprinter?)" (Chironian) – unresolved choice.
- "Night Vision (Thermal)" (Arkanian/Chiss) vs "Night Sight(Thermal)" (Trandoshan).
- Besalisk "roll 3 talents" but has four arms with no mechanic; T'surr "Natural Weapon – Bite 3+SB & Horns 2+SB" though lore describes no horns; "Secondary claw hands have STR without the +20" is a rules note embedded in prose.
- Human "+5 free ranks in any skill" – "ranks" is not WFRP vocabulary (Advances).
- Kel Dor rule "Any force specialisation related to Force – Sense ... is one rank cheaper" references an undefined Force-specialisation system.
- Trailing empty heading `#### [](https://starwars.fandom.com/wiki/Miraluka/Legends)` at the end of the file.
- Twi'lek "Attractive or Beneath Notice", Zabrak "Craftsman (Profession) or Strider (Terrain)" – choices with no guidance.

**(d) Gaps.** A random species table (WFRP's d100 roll with XP reward); the "random talents list"; uniform stat block template; Wounds/Movement/Size rules; Wookiee and Zabrak derived stats; species-level skills (or a note that Origin supplies them); age/height tables if wanted; images; a canonical abbreviation key; a decision on whether Gungan/Togruta are meant to be mod-free.

---

## 03 – Origin

**(a) Contents and completeness.** A d100 table of 13 Origins with characteristic bonuses, then one section per world type with description, examples, starting characteristics (+5 fixed, +5 choice of three) and a 12-skill list: **Hive, Civilized, Paradise, Feudal, Feral, Industrial, Force Nexus, Hostile, Agri, Ocean, Tundra, Lava, Space**. All 13 have all three fields (Lava has 11 skills). Intro text states Origin also affects "your chances of being a part of a specific Faction" but no mechanism follows.

**(b) Design decisions.**
- Origin replaces the **skill-and-talent portion of WFRP species** (12 skills, "3x +3 and 3x +5") and the characteristic-base role; it is a world-environment taxonomy clearly modelled on Warhammer 40k/Dark Heresy home-world types (Hive, Feral, Feudal, Paradise, Agri…) rather than anything in WFRP 4e.
- Origin does **not** replace WFRP Class; Class survives in doc 05 as career groupings.
- Characteristic choice uses "one of three" like WFRP's species-talent choices.

**(c) Inconsistencies / placeholders.**
- d100 table has holes and overlaps: **41–45 is missing**, 51–55 Industrial and **55**–60 Lava overlap on 55, **91–99 is missing**, and Force Nexus is "00" only (1 %).
- The table says "+5 to either Ballistic Skill, **Initiative**, or Fellowship" but every world entry below says "**Intuition**" – Intuition is a WFRP skill, not a characteristic. Appears in Hive, Civilized, Feral, Force Nexus, Hostile, Ocean, Tundra, Lava.
- "World format: Description, starting characteristic modifications, 12 skills that you can put 3x +3 and 3x +5 into." – a design note left in the text.
- Tundra and Lava have identical characteristic bonuses; Hoth is an example for both Hostile and Tundra.
- "Hostile Worlds: These are planets **or animals** that are extremely hostile…"
- Doc 01's example Origins "Shrine" and "Forge" do not exist (presumably Force Nexus and Industrial).
- Skill vocabulary drifts: "Consume Intoxicant" here vs "Consume Alcohol" in doc 05; "Pilot (Speeder)" here vs "Pilot (Land Vehicle)" in doc 05; "Ranged (Blaster/Heavy/Ordinance)" (sic, Ordnance); "Stealth(Urban/Wilderness)" vs doc 05 "Stealth (Rural)".
- Section numbering "2.3 ORIGIN" does not match any numbering elsewhere.
- "Game Director" is used for GM here; doc 05 says nothing either way.

**(d) Gaps.** Fix the d100 ranges; add an XP reward for random roll (WFRP gives 20 XP); the promised Origin→Faction linkage; a master skill list so the 12-skill lists can be validated; possibly Origin talents; clarify whether Origin is chosen before or after species and whether a species constrains Origin (e.g. Kel Dor from Dorin).

---

## 04 – Faction

**(a) Contents and completeness.** Pure lore. A two-paragraph "Career Path & Faction" preamble (Faction = what you did "until you were recruited by your Patron"), a bullet list of five faction families, and then ~100 organisations in tables (name / description / era): Light, Grey and Dark Force traditions (9+5+8), crime syndicates (6), smugglers/pirates (5), spice/slaving (5), bounty hunter guilds (6), mega-corporations (14 shipbuilders, 10 weapons, 6 biotech, 5 research), and "Imperial Powers" (8 shipyards, 5 starfighter bodies, 7 weapons programmes, 5 ground vehicle, 5 cloning). **There are zero mechanics**: no characteristic, skill, talent, status, trapping or XP effect, no selection procedure, no table to roll on.

**(b) Design decisions.** The preamble implies Faction replaces WFRP's Status/Class-as-society and the "Patron" is the party hook. The bullet list suggests a curated set of playable factions, but the tables that follow read as a setting gazetteer (shipyards and R&D bureaux are not things a character "belongs to" in the same sense as the Jedi Order). The Republic, Rebel Alliance, Imperial military, CSA, Mandalorian clans as a culture, and Trade Federation/Separatists are all absent, which is odd for a "Faction" chapter.

**(c) Inconsistencies / placeholders.**
- Era labels are wrong in the first half: "Imperial era (19–4 BBY)" and "New Republic / NJO (4 BBY+)" should be 19 BBY–4 ABY and 4 ABY+ (the Imperial Powers section later uses the correct form).
- Legends-only brief is violated: **Lasan High Guard**, **The Bendu**, **Spice Runners of Kijimi**, **Crymorah Syndicate** are Disney-era inventions (Rebels, The Rise of Skywalker, Tarkin novel). Pyke Syndicate and Tarkin Initiative are borderline.
- Duplicates across sections: Maw Installation, Imperial Department of Military Research, Santhe/Sienar Technologies, Rothana, Kuat Drive Yards all appear twice.
- "*Source: Star Wars Legends / Legacy continuity…*" boilerplate repeated three times; stray trailing "## " heading at the end; emoji section markers.
- The careers in doc 05 reference "Etiquette (Trade Guild)", "Codes (Trade Guild)", "Bounty Hunters' Guild", "Rebel cells", "ISB" – none are defined as Factions here.

**(d) Gaps.** Everything mechanical: what a Faction grants (skills/talents/status/trappings/contacts), how it is chosen or rolled, how it interacts with Origin and Career, Faction-specific careers (e.g. only Force Traditions unlock Force careers), a Patron system, and a pruned Legends-only list of *playable* factions separate from the corporate gazetteer.

---

## 05 – Careers

**(a) Contents and completeness.** 24 careers in seven classes, each with description, a 10-column Advance Scheme, and four levels with Skills / Talents / Trappings / status tier (Brass/Silver/Gold n). All 24 have all four levels written:

| Class | Careers |
|---|---|
| Academics | Physician (Medic) |
| Citizens | Agitator, Artisan, Investigator, Merchant |
| Dignitaries | Advisor, Envoy, Noble, Spy, Warden |
| Force Wielders | Force Savant, Force Shadow, Force Warrior |
| Freelancers | Bounty Hunter, Scout, Smuggler |
| Scoundrels | Bawd, Charlatan, Fence, Outlaw, Thief |
| Warriors | Guard, Pit Fighter, Soldier |

Per-level skills/talents/trappings/status are present everywhere; the only thin spots are Force Warrior L1 (4 skills, trailing comma), Force Warrior L2 (3 talents), Bounty Hunter L4 (1 skill), Bounty Hunter L1 (9 skills, 5 talents), Smuggler L2 (7 skills). The three Force careers carry extra flavour sub-entries per tradition (Jedi / generic Force Tradition / Sith) with many unwritten.

**(b) Design decisions.**
- WFRP classes and the 8/6/4/2 skill pattern are retained, but the header says "First rank – 10 skills" (contradicted by nearly every career, which has 8).
- Status tiers Brass/Silver/Gold are retained wholesale, even though doc 04 implies Faction replaces society/status; currency is "Credits" but amounts are WFRP's (3d10, 20, 100, 1000) and one trapping is still "Jewellery worth 3d10 **GC**".
- Force careers: three archetypes (Consular-ish Savant, Sentinel-ish Shadow, Guardian-ish Warrior), each usable by Light/Grey/Dark traditions with alternative level titles. Schemes are explicitly derived from the WFRP Knight ("rulebook p. 111").
- Skills renamed: Secret Signs→Codes, Pick Lock→Slice Security, Heraldry→Lore (Galactic Sigils), Riverways→Lore (Hyperlanes), Classical→Old Tongue, Sail→Pilot (Starship), Row→Pilot (Capital Ship), Drive→Pilot (Land Vehicle), Set Trap→Demolitions.

**(c) Inconsistencies / placeholders.**
- **Dexterity is back**: every Advance Scheme has a Dex column and 12 careers open Dex (Physician, Artisan, Investigator, Noble, Force Shadow, Scout, Smuggler, Bawd, Charlatan, Fence, Thief; Scout's *level-4* characteristic is Dex). This directly contradicts doc 01's nine characteristics. Force Shadow's note even says "Dexterity replaces Strength".
- Dead WFRP references: "core rulebook (pp. 53–116)", "rulebook p. 48", "rulebook p. 111" (three times).
- Career list at the top names 22 careers and lacks Force Savant and Force Shadow; the body says "The 24 careers".
- Literal placeholders: "Force Sorcerer: xx", "Sith Sorcerer: xx", "(Tradition) xxx", "Force Master: xxx" (×3), "Acolyte: xxx", "Sith Acolyte: xxx", "Force Shadow: xxx", "Grand Inquisitor: xxx", "(Tradition) Protector: xxx", "Force Acolyte:" (empty). "(Light / Netural / Dark side)" twice. Force Savant's strapline and tradition paragraphs are copy-pasted from Force Warrior; Savant L3 is titled "Jedi Councillor" but its flavour reads "Jedi General"; "Sith Maurauder"; Sith ranks are ordered differently per career (Savant: Acolyte→Sorcerer→**Apprentice**→Lord; Warrior: Acolyte→Apprentice→Marauder→Lord). The Sith Lord quote is duplicated between Shadow and Warrior.
- Literacy talent is "Read/Write" in 11 careers but "Datapad Literate" in every species.
- Skill name drift: Heal vs Medicine (both used), Consume Alcohol vs Consume Intoxicant (doc 03), Bribe vs Bribery, Trade (Armourer) vs Profession (X), Codes vs "Secret Signs (any)" (Force Savant/Shadow L4), Pilot (Speeder) vs Pilot (Land Vehicle), "Underworld (Street)" (not a skill anywhere), "Melee (Vibroblade)/(Vibro-Axe)/(Electrostaff)" as if they were WFRP weapon groups. Talent drift: Dirty Fighter/Dirty Fighting, Public Speaking/Public Speaker, Resistant/Resistance (Disease).
- Invented talents with no definition: Datapad Literate, Combat Aware, Spacer, Vacuum Legs, Strider (Orbital), Pilot (as a talent), Shadowy, Scavenger, Eidetic Memory, Regenerate (Minor), Force Ability, Force Sensitive. Many WFRP talents are given in-line "reskin" glosses rather than new names ("Lightning Reflexes (Force-Assisted Awareness…)", "Attractive (Force Presence…)", "Disarm (Rhetorical Disarm…)", "Warleader (Network Handler…)", "Consume Alcohol (Endure Hardship…)") – design intent notes, not rules.
- Un-converted fantasy trappings: Hammer and Nails, Healing Draught, Bandages, Chalk, d10 rags, Riverboats, Skiff, River Runner (career title), Large Sack, Charcoal stick, Buckler, Shield, Spear, Halberd, Great Weapon, Flail, Dagger, Knuckledusters, Crowbar, Rope, Throwing Knives, Grappling Hook, Coach, Hand Mirror, Tent, Deck of Cards, Eye-glass, Profession (Engraver), Mounted Tauntaun ×5, Ride (Bantha) ×8, Creature Training (Massiff), Dose of Weirdroot, Play (Drums or Horn).
- Smuggler is a renamed WFRP Smuggler and keeps river imagery (River Runner, Skiff, Strong Swimmer, Fast Freighter at Brass 5).

**(d) Gaps.** Resolve 9 vs 10 characteristics and regenerate every scheme; a master skill and talent list (with definitions for invented ones); conversion of trappings and prices; the missing WFRP-equivalent careers that a Star Wars game obviously wants (Pilot, Slicer/Engineer, Droid-related, Mandalorian/Mercenary, Priest-analogue, Entertainer, Hunter/Ranger, Officer, Politician/Senator); a random career table keyed to Origin or Faction (WFRP's species-keyed d100); Force-career entry restrictions tied to Faction; Light/Dark side mechanics referenced by the Force careers; skill counts normalised (header 10/6/4/2 vs body 8/6/4/2).

---

## Status per document

| Document | % complete | State | Top 3 gaps |
|---|---|---|---|
| 01 Introduction & Characteristics | 70 % | Near-complete (text), undecided (design) | 1. Settle 9 vs 10 characteristics and the Dex question; 2. Add Fate/Resilience/Wounds/Movement rules the species chapter assumes; 3. Replace "Warhammer Star Wars"/"page 51" and give a creation-step overview |
| 02 Species | 60 % | Partial | 1. Uniform stat block (Wookiee/Zabrak derived stats, Gungan/Togruta modifiers, abbreviation key, ambiguous "I"); 2. The referenced "random talents list" and definitions of invented talents; 3. Random species table and Size/natural-weapon/Force rules |
| 03 Origin | 65 % | Partial | 1. Repair the d100 table (41–45, 55 overlap, 91–99); 2. Replace "Intuition" with Initiative and reconcile skill names with doc 05; 3. The promised Origin→Faction mechanic plus roll XP |
| 04 Faction | 20 % | Draft (lore only) | 1. Any mechanics at all (grants, selection, Patron); 2. Remove Disney-canon entries and fix BBY/ABY era labels; 3. Separate playable factions from the corporate/Imperial gazetteer and add the obvious missing ones (Republic, Rebellion, Empire, Mandalorians) |
| 05 Careers | 65 % | Partial | 1. Dex column vs nine characteristics; stale WFRP page refs; 22-vs-24 career list; 2. Force careers' "xx/xxx" placeholders, duplicated text and inconsistent Sith ranks; 3. Un-converted fantasy trappings/skills/talents and a master skill/talent list; additional Star Wars-native careers (Pilot, Slicer, Engineer, Mercenary) |
