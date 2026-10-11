# Star Legends - Galactic Wars (SL100): Game Rules design summary and gap analysis

Written 2026-10-11 from (a) the full text of the WFRP 4e Rulebook, the WFRP4 Quick Reference 1.7 and the WFPA player aid (extracted to `SL100/WFRP_Text/`, kept out of git), and (b) the 19 conversion documents in `SL100-Wiki/*.md`. The four detailed working papers behind this summary are in `SL100-Wiki/docs/rules-review/`: `wfrp4-mechanics-digest.md`, `review-01-05-character.md`, `review-06-08-skills-talents-equipment.md`, `review-09-force-combat-setting.md`.

## 1. What WFRP 4e gives us (the base engine)

WFRP 4e is a d100 roll-under game. Ten characteristics (WS, BS, S, T, I, Ag, Dex, Int, WP, Fel), generated as 2d10 plus a species modifier, with the tens digit as the Characteristic Bonus. Wounds = SB + 2×TB + WPB. Every test is d100 against characteristic + skill advances + a difficulty modifier (Very Easy +60 to Very Hard −30, combat defaults to Challenging +0); Success Levels = tens of target minus tens of roll; doubles are criticals or fumbles. Opposed tests compare SL; extended tests accumulate SL; Advantage is a +10-per-token momentum counter that is won and lost in combat. Fate/Fortune and Resilience/Resolve give players a bounded safety net, with Resolve refuelled by acting on a stated Motivation.

Characters are built from Species, then a Class and a Career with four levels. Each level opens characteristics in an Advance Scheme, lists skills, talents, trappings and a Status (tier + standing), and is "complete" at 5/10/15/20 advances. Skills are basic or advanced, some grouped into specialisations; talents have a Max rank and often add +1 SL per rank to a named test. XP costs follow one fixed bracket table (characteristics 25→520, skills 10→440, talents 100 per rank) and changing career costs 100/200 (+100 across classes).

Combat is an opposed Melee test (ranged is unopposed), hit location by reversing the roll, Damage = weapon + SL, Wounds lost = Damage − TB − armour points, with Critical Wound tables by location, twelve Conditions, weapon qualities and flaws, and a death rule based on Critical Wounds versus TB. Magic uses a Casting Number met by SL on a Language (Magick) test, Channelling as an extended test, miscast tables on doubles, and overcasting for +2 SL. Corruption is a slow-burn track (Dark Deals, exposure tests, a WPB + TB threshold, Mental and Physical mutation tables). Downtime is three Endeavours between adventures. Money is crowns/shillings/pennies, items have Availability by settlement, Qualities and Flaws double or halve price, Encumbrance limit = SB + TB.

Almost all of this is setting-neutral. The setting-bound parts are the Winds and Lores of magic, the gods and Sin/Wrath, Chaos corruption flavour, species, class names and status tiers, coinage, horses and boats, and the Old World text in every example. The full item-by-item "what must change" list is section 7 of the mechanics digest.

## 2. What SL100 has already decided (as written in the .md files)

These are the design choices that are actually present in the documents, as opposed to leftover WFRP text.

Characteristics are rolled flat (2d10 + 20 each) with WFRP's 50/25/0 XP rewards or a 100-point buy; species and Origin then add modifiers instead of WFRP's per-species base values. Species (17 so far, Legends-only with Wookieepedia links) give roughly +30 net in characteristic modifiers plus talents, Movement, Fate and Resilience. Origin (13 world types: Hive, Civilized, Paradise, Feudal, Feral, Industrial, Force Nexus, Hostile, Agri, Ocean, Tundra, Lava, Space) replaces the species skill package: +5 fixed, +5 chosen, and 12 skills to place 3×+5 and 3×+3. Faction is intended as the character's pre-Patron background and the social layer, with Force Traditions (light, grey, dark) in the same list.

Careers keep WFRP's class → career → four-level grid and its 8/6/4/2 skill pattern: 24 careers in seven classes (Academics, Citizens, Dignitaries, Force Wielders, Freelancers, Scoundrels, Warriors), every level with skills, talents, trappings and status. The three Force careers (Savant, Shadow, Warrior) are shared by all traditions with per-tradition level titles.

Skills are WFRP's list with renames: Drive/Row/Sail → Pilot (Speeder / Starship / Capital Ship), Pick Lock → Slice Security System, Set Trap → Demolitions, Secret Signs → Codes, Pray → Meditate, Trade → Profession, Heal → Medicine, Animal → Creature, Channelling → Use the Force, Language (Magick) → Language (The Force). Lightsabers are a Melee specialisation at −20 for non-Force-sensitives.

Talents are WFRP's list (148 general) with Star Wars examples, a handful of new ones (Datapad Literate, Spacer, Vacuum Legs, Heavy Gunner, Hyperlane Pilot, Amphibious, Eidetic Memory, Regeneration (Minor), Noble Blood rewrite) and 19 Force talents. Two Force models sit side by side: WFRP's spell/Channel/miscast model and a West End Games style Sense/Control/Alter discipline model with a Force Specialty rank-buy.

Equipment introduces a dual armour value, AP against blasters and kinetic damage and Resist against lightsabers, driven by the material (Special Materials gives AP/Resist/weight per fabric, alloy and crystal), lightsaber damage of 6 + Form Bonus, a Mag column, force fields, settlement-scaled availability (Outpost / Spaceport / City / Megopolis with Uncommon and Unique tiers added), and credits in place of coin.

Force Influence replaces Corruption with a symmetric ±1…±128 doubling ladder earned by acts, feeding ±SL into light- or dark-sided forms and talents. Lightsaber and combat forms (10 lightsaber forms, dual-blaster, Echani, Teras Kasi, Dun Moch, Force Imbued Combat) are a new three-tier progression track built on Advantage, SL bonuses and weapon qualities, bought with XP.

The bestiary (65 creatures) uses the full WFRP stat line with WFRP traits plus new Star Wars traits. Mounts, vehicles and about 52 starships have tables with cost, crew, speed and availability, and a 16-category ship upgrade list. Hyperspace is a Legends lore essay that fixes the campaign at roughly 3,700 to 4,000 BBY (beacon era, Hydian Way "not yet discovered"), matched by the "Starships circa 3000-4000 BBY" note.

## 3. Status of each document

| Document | Estimate | State | What is there | Biggest gaps |
|---|---|---|---|---|
| 01 Introduction & Characteristics | 70% | near-complete text, open design question | 9 characteristics, rolling and point-buy | says nine characteristics and drops Dex; no Fate/Resilience/Wounds/Movement; still says "Warhammer Star Wars" and "page 51" |
| 02 Species | 60% | partial | 17 species, modifiers, talents | fields not uniform (Wookiee/Zabrak lack derived stats, Gungan/Togruta lack modifiers); abbreviations differ from 01; "I +10" ambiguous; no random talent list |
| 03 Origin | 65% | partial | 13 world types, bonuses, 12 skills each | d100 table has holes (41-45, 91-99) and an overlap at 55; "Intuition" where Initiative is meant; promised Origin→Faction link absent |
| 04 Faction | 20% | lore only | about 100 organisations by era | no mechanics at all; wrong era labels; Disney-era entries; Republic, Rebellion, Empire, Mandalorians missing |
| 05 Careers | 65% | partial | 24 careers, all four levels | Dex column in every scheme; 22 vs 24 in the list; Force careers full of "xx" placeholders; fantasy trappings (halberd, riverboat, 3d10 GC); dead WFRP page refs |
| 06 Skills | 65% | renamed, not rewritten | 45 skills with descriptions and specialisations | Use the Force has no entry; Pilot skills still carry oar and sail text; duplicates and truncations; three different specialisation schemes |
| 07 Talents | 70% | near-complete list | 167 entries with Max/Tests/text | about 12 broken entries (Briber, Inspiring, Criminal...); two Force models; Old World residue |
| Talent List | 55% | stale index | 142 unique names | 26 talents in 07 missing from the list; 3 duplicates; 20 Force powers listed as talents |
| 08 Equipment | 45% | scaffolded | all weapon categories, 3 armour tables, mods, cybernetics, genetics | about 40% of cells blank; notes are d20 Saga text (Reflex DC, squares); 23 traits used and none defined; three incompatible armour tables |
| Special Materials | 70% | solid reference | availability tiers, AP/Resist/weight per material, crystals, spices | numbers disagree with 08; Plastoid/Trimantium missing; crystals have no mechanics; no era tags |
| 09 Force Influence | 25% | notes | ±128 ladder, award list | 0…±4 bands empty; "table xx"; sign convention conflicts with 10; ±4 SL is too strong for d100; no loss/redemption rules |
| 10 Combat & Lightsaber Forms | 55% forms / 10% combat | forms drafted | 15 forms in three tiers | no general combat chapter; no Force power list or test; d20 action vocabulary; "ranks" instead of Advances; prerequisite slips |
| All about hyperspace | 70% lore / 5% rules | essay | lane history, class multiplier, beacon era | no Astrogation test, travel-time rule or mishap table |
| Star Wars Bestiary | 80% | usable draft | 65 statted creatures, 50-trait glossary | 3 undefined starred traits; corrupted last line; Loth-cat/Loth-wolf/Purrgil are canon-only; Force traits depend on unwritten rules |
| Mounts & Vehicles | 60% | draft tables | 11 mounts, 17 vehicles | no vehicle damage or handling model; Enc conversion conflict (10 kg vs 8 kg); Imperial-era kit in an Old Republic campaign |
| Star Wars Space Ships | 55% | tables plus author questions | about 52 hulls, 16 upgrade categories | no ship profile or combat; column shifts; duplicate A-wing; undefined availability codes; High Republic Jedi Vector |
| Starships circa 3000-4000 BBY | 40% | era note | 14 era ships | stats conflict with the compendium; needs merging as an era filter |

Overall the system is roughly half-written: the character side (01-07) is a solid WFRP reskin that needs a consistency pass and a few decisions, the equipment side has the right ideas and about half its numbers, and the rules side (core tests, personal combat, the Force, ships, travel, downtime) has not been written yet beyond the forms and the influence ladder.

## 4. The decisions that block everything downstream

Nine or ten characteristics. Chapter 01 says nine and omits Dexterity. Chapter 05 opens Dex in 12 careers, chapter 06 keys six skills to it, chapter 07 ten talents, the bestiary gives droids and sentients Dex values, and the Roll20 sheet keeps all ten. Whichever way this goes, it has to be propagated through every table. Keeping ten is the smaller change and keeps the XP, point-buy and career maths calibrated as WFRP intended; dropping Dex means re-keying six skills and ten talents (most would go to Ag) and rewriting twelve advance schemes.

One Force model. Chapter 07 carries both WFRP's spell model (Petty Magic, Channel tests, miscasts, Force Magic (Lore) XP brackets) and a Sense/Control/Alter discipline model. The WFRP skeleton (a Use the Force test against a per-power number, overcasting for +2 SL, Channelling as an extended test, doubles feeding an overdraw table, talent-gated learning, −1 SL per AP of armour) is proven and already fits the rest of the engine; Sense/Control/Alter is the better organising vocabulary for the power list. The recommendation is to use the WFRP mechanics underneath Sense/Control/Alter disciplines in place of Lores, and delete Petty Magic, Instinctive Diction, Magical Sense and the Lore XP table as separate things.

Force Influence versus Corruption. The ±128 ladder and WFRP Corruption cover the same ground. Corruption's machinery (Dark Deals for a reroll, exposure tests, threshold at WPB + TB, Dark Whispers, Absolution, "I Deny You!") is a complete, play-tested dark-side system; the ladder adds the light side and the act-based awards. Pick one chassis, fix the sign convention (chapter 10 counts Dark Side Influence upward), and cap the SL bonuses at ±1 or ±2.

Campaign era. The hyperspace and era-ships documents place play around 3,700 to 4,000 BBY, but the species, ship, vehicle and mount tables are mostly Clone Wars and Imperial. Either every entry gets an era tag and the tables are filtered, or the era is widened.

Vocabulary. Standardise on WFRP terms before more text is written: Advances not ranks, modifiers not "target bonus", Move/Action not half/standard/full-round actions, yards or metres (one of them), one abbreviation key (S/T/Ag/Int/I/WP/Fel as in 01), one specialisation scheme for Melee, Ranged and Stealth shared by 06 and 08, Datapad Literate not Read/Write, Medicine not Heal, Profession not Trade.

Legends-only policy. Remove or flag Loth-cat, Loth-wolf, Purrgil, the Jedi Vector, Lasan High Guard, the Bendu, the Spice Runners of Kijimi and the Crymorah Syndicate.

## 5. What still has to be written

In rough order of dependency: the core rules chapter (tests, SL, Advantage, Fate and Resolve, Conditions, Criticals, healing, Psychology, adapted from WFRP's Rules chapter with the setting words changed); the personal combat chapter (blasters including stun and power packs, lightsaber profile and its interaction with AP/Resist, personal shields, hit locations, the forms as the advanced layer); the Force chapter (Use the Force skill, power list by discipline, test and cost, overdraw table, dark-side pull); a Qualities and Flaws glossary and range bands in one unit; a starship and vehicle profile (hull Wounds, armour, weapon damage, system crits, a scale rule against personal weapons) and ship combat built on WFRP's Pursuit rule; hyperspace travel as a rule (class × squares × 8 h, Astrogation test by lane quality and era, mishaps, beacon hops); economy and trappings (credits, cost of living by status tier, career trappings converted, cybernetics list); downtime (Endeavours and Events rewritten for the setting); master skill and talent lists regenerated from 06 and 07; Faction mechanics (what a faction grants, how it is chosen, the Patron, which factions unlock Force careers); and finally conversion of the chapters into the wiki's `SL100:` pages and a playtest.

## 6. How this feeds the other workstreams

The Roll20 sheet is waiting on the SL100 career list, talent list and species presets; all three exist in draft in 05, 07 and 02 and can be exported once the characteristic decision is made and the lists are de-duplicated. The wiki's "Write SL100 pages with converted stats" task depends on the equipment schema (08 plus Special Materials) being unified first, since every weapon and armour page will carry those columns. Book ingestion's "Convert d20 stats to SL100 values" needs the damage, range and availability scales fixed in the combat and equipment chapters before any conversion table can be built.
