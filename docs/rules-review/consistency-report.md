# Consolidation and consistency pass (13 Oct 2026)

Purpose: one consistent rule set across chapters 03, 05, 06, 07, 08 and 10 and the equipment catalogue, so the Roll20 character sheet can be rebuilt from it. Everything below was applied by `tools/consolidate/consolidate.py` (re-runnable; it changes nothing on a second run) and checked by `tools/consolidate/check_consistency.py`. The Roll20 hand-off lives in `rules/roll20/` (`skills.csv`, `talents.csv`, `careers.csv`).

## 1. Weapon skills: the consolidated scheme

Ranged (BS, advanced, grouped) now has five Specialisations and Melee (WS, basic, grouped) has four. Every old name across the live chapters, the catalogue builder and the wiki pages has been replaced.

| New skill | Covers | Old names folded in |
| --- | --- | --- |
| Ranged (Blaster) | every blaster: hold-out, pistol, carbine, rifle, sporting, heavy and repeating blasters, E-Web; ion, disruptor and sonic weapons | Blaster Pistol, Blaster Rifle, Heavy Blaster, Disruptor, Sniper |
| Ranged (Archaic) | bows, crossbows, slings, slugthrowers (pistol and rifle), bowcasters, black-powder and any projectile weapon that must be aimed | Slugthrower, Bow, Crossbow, Sling, Bowcaster, Blackpowder |
| Ranged (Thrown) | grenades, thermal detonators, throwing knives and razors, darts and spears thrown by hand | Throwing, Grenade/Explosives |
| Ranged (Exotic) | nets and net launchers, whips used at range, flame projectors, glue and adhesive projectors, dart and flechette launchers, wrist-mounted weapons, Mandalorian mini-rockets, tensor rifles, magna casters | Entangling |
| Ranged (Ordnance) | missile and rocket launchers, handheld grenade launchers, mortars, crew-served artillery fired by hand | Missile/Rocket, Engineering |
| Melee (1H) | one-handed weapons: vibroblades, vibroknives, stun batons, axes, clubs, swords, improvised weapons | Vibroblade, Basic, Fencing, Stun Baton, Parry |
| Melee (2H) | both-handed weapons: vibro-axes, force pikes, electrostaffs, quarterstaffs, great weapons | Two-Handed, Force Pike, Vibro-Axe, Electrostaff, Cavalry, Polearm, Flail |
| Melee (Brawling) | unarmed, knuckle-dusters, shock gloves, grapples; defending while unarmed | unchanged |
| Melee (*Lightsaber) | all lightsabers, double-bladed sabers, lightsaber pikes; −20 without Force Sensitive | unchanged (spelling kept as the chapters have it: "Lightsaber") |

Two choices in that table are mine rather than yours, and are the ones to look at first:

- **Melee (Brawling) kept as a fourth melee skill.** You suggested 1H / 2H / Lightsaber only. I kept Brawling because unarmed fighting is its own competence in WFRP and in Star Wars (Teräs Käsi, Echani, shockboxing, every cantina), the Martial Artist career and the two martial-arts tables in chapter 10 are built on it, and a Jedi or a sniper with no melee skill at all should still be able to throw a punch on bare WS. If you would rather fold it into Melee (1H), it is a one-line change in `tools/consolidate/skillmap.py` and the script re-applies everywhere.
- **Ranged (Ordnance) as a fifth ranged skill.** You listed launchers only by implication (Mandalorian mini-rockets, which are Exotic). Full missile launchers, mortars and the Thumper are a different trade from an E-Web or a flamethrower, so I gave them their own group; it holds three catalogue items. Folding Ordnance into Exotic is likewise one line.

Other consequences applied: careers that had two of the old names at different levels (for example Blaster Pistol at level 1 and Blaster Rifle at level 3) kept the first and had the second replaced with a fitting skill, each noted under Conversion notes (Engineer, Gunslinger, Noble, Marshal, Pirate, Marine, Guard, Martial Artist, Dock Pilot, Sorcerer). The Sniper-type talent now reads "Ranged (Any) at Long or Extreme Range". Chapter 06's Melee and Ranged entries carry the new Specialisation lists with a sentence on using the wrong one. The catalogue builder (`tools/convert/equipment.py`) classifies by the new scheme and the Weapons page has a new "Exotic ranged weapons" section (18 items) and a "Launchers" section (3). Enc changed for nine catalogue rows as a side effect and each is defensible (slugthrower rifle 2, heavy blaster rifle 3, nets 1, flame carbine kept at 2 via the carbine exception).

## 2. Ten skills at level 1

All 91 careers now list ten skills at level 1. Supplement conversions that had trimmed the parent's ten got the trimmed skills back (Camp Follower, Hired Gun, Beachcomber, Beast Handler, Beast Rider, Navigator, Armoured Knight, Elite Guard, Gunner, Officer, Sharpshooter, Freelance). Every other career got two skills chosen to fit its role and not already present at any level; Force Warrior (your draft, which had four) got six. Each addition is recorded as `[review: level 1 raised to ten skills (13 Oct ruling): X and Y added]` under the career's Conversion notes, so you can swap any you dislike. Three I would point you at: Sharpshooter now has Ranged (Blaster) at level 1 (it only had Archaic), the four Jedi-style drafts (Force Savant, Shadow, Warrior and Templar) now carry Use the Force at level 1, and Monastic likewise.

## 3. Consistency findings and what was done

Fixed in this pass:

- **Use the Force** was referenced by every Force career and talent but had no entry in chapter 06. It now has one (WP, advanced, grouped: Sense, Control, Alter), tagged `[review]`, written to match the Force Sense/Control/Alter (Discipline) talents in chapter 07.
- **Charm Creature** existed in chapter 06 as a paragraph without a heading, so nothing could link to it. It is a proper entry now.
- Typos from the earlier word-map conversion: "Briberyry" (Bribery), "Briberyr" (the Briber talent), "Slice Security System System", "Stout-hearted" (Stout-Hearted), "Netural", "Maurauder".
- Specialisation spellings unified: Entertain (Act/Acting → Acting; Sing/Singing → Singing), Perform (Oratory) → Entertain (Speeches), Perform (Dance) → Perform (Dancing), Lore (Local (world)) → Lore (Local), Lore (Galactic Republic or Galactic Empire, by era) → Lore (Galactic Republic or Galactic Empire), Lore (Force Lore) → Lore (The Force), Play (Any instrument) → Play (Any), "(any one)" and "(any)" → "(Any)", Language (Old Tongue) → Language (Old Galactic Standard), Profession (Cartographer) → Profession (Stellar Cartographer).
- **Ride**: chapter 06 defines Ride (Air / Land / Water); careers used Ride (Creature) and Ride (Bantha). All now read Ride (Land). If you prefer Ride (Creature) as the single Star Wars specialisation, change 06 and the map; the Roll20 sheet needs one answer.
- The grouped-skill Specialisation lists in chapter 06 now include every specialisation a career actually uses (Lore, Codes, Entertain, Profession, Language, Art, Perform), so a player can find each one. The Language list also lost a stray editing note.
- Talent List (revised) was missing Animal Companion, Cadence, Captain's Word and Large; added. Chapter 07 and the list now match exactly (168 general + 23 Force = 191).
- The Character creation wiki page (built from `docs/collation/character_assembly.md`) was still using the old weapon skills; regenerated.

Still open (your call; nothing changed):

1. Lore list has near-duplicates worth merging: History / Galactic History, Underworld / Criminal Organisations, Technology / Engineering, Astrogation is both a Lore and a Profession, "Lore (Etiquette)" (Guard level 3) and "Lore (Tradition)" (Zealot) read as placeholders, "Lore (Sith & Dark Side Cults)" vs Lore (Sith Lore) and Lore (Dark Side).
2. Codes mixes factions (Rebel, Imperial, Hutt Cartel, Black Sun) with trades (Smuggler, Spacer, Miner, Trade Guild); "Codes (Shadow Cipher)" in Force Shadow is a one-career special.
3. Language (Diplomacy) (Force Savant) is not a language; Etiquette (Diplomats) talent may be what was meant.
4. Profession (Artist) vs the Art skill; Profession (Medic) vs Medicine; Profession (Armourer) used for lightsaber construction.
5. Stealth (Underground) is WFRP's word; "Stealth (Ship/Station)" or "(Interior)" may suit the setting better.
6. Melee (Force Tradition Weapon) and "Melee (Lightsaber — defensive form only)" in your Jedi drafts are flavour notes rather than skills; the sheet will want plain Melee (Lightsaber).
7. "Ace Pilot or Roughrider" as a level-1 talent choice (Force Warrior) is fine in print but the sheet cannot hold an "or".
8. The earlier open points in `careers-conflicts.md` still stand (Soldier 4 "Officer", Force careers' talent squeeze, status tier names, proposed advance schemes, Unshakeable vs Iron Jaw).

## 4. Roll20 hand-off

`rules/roll20/skills.csv`: 45 skills with characteristic, basic/advanced, grouped flag and the full specialisation list (the sheet's dropdowns). `rules/roll20/talents.csv`: 191 talents with Max, Tests, section and description. `rules/roll20/careers.csv`: 363 career levels (91 careers × 4) with class, title, status, skills, talents and trappings, tags stripped. The master remains the chapter markdown; rerun `tools/consolidate/consolidate.py` then the two CSV builders after any edit.

Characteristics for the sheet: WS, BS, S, T, I, Ag, Dex, Int, WP, Fel (Initiative, not Intuition). Weapon-skill dropdown: Ranged (Blaster / Archaic / Thrown / Exotic / Ordnance), Melee (1H / 2H / Brawling / Lightsaber). Force: Use the Force (Sense / Control / Alter) gated by Force Sensitive (Tradition) and the matching discipline talent.
