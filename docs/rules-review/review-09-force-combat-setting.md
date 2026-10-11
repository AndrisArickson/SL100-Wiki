# SL100 Review – Force Influence, Combat Forms, Hyperspace, Bestiary, Mounts/Vehicles, Ships

Scope: seven draft wiki documents in `SL100-Wiki/` (README read for context only: pages are MediaWiki wikitext, game stats go in `{{SL100 ...}}` infobox templates under the `SL100:` prefix). All seven reviewed files are Markdown exports, not yet in that template form.

---

## 1. `09 New Star Wars - Force Influence.md`

**(a) Contents.** A single bipolar scale replacing WFRP Corruption. Light-side acts add points (+1 for saving a life, +10 for freeing a slave or taking a light-side apprentice); dark-side acts subtract (−1 accidental killing in anger, −10 deliberate killing, slavery, drug trade, dark apprentice). A doubling ladder (±1, 2, 4, 8, 16, 32, 64, 128) assigns effects and example Legends characters (Odan-Urr at 128, Yoda at 16, Vader at −64, Sidious/Nihilus/Sion at −128). Effects are: ±1 to ±4 SL on "light-sided / dark-sided Light Saber combat forms and Force Talents", ±10/±20 Cool and Charm modifiers, animal docility/aversion in a Fellowship-metre/km radius, and at the dark extremes Mental Corruption, "Chaotic Dreams", Sith eyes and bodily change. It is a half-page of notes, not a rule.

**(b) Design decisions.** Corruption becomes symmetric (virtue is tracked as well as taint), awarded by narrative act rather than by exposure test, and feeds directly into combat as SL bonuses. WFRP's Mental/Physical Corruption tables are reused only at the dark end.

**(c) Inconsistencies / placeholders.**
- Ladder rows 4, 2, 1, 0, −1, −2, −4 are empty.
- "Mental corruption from the table xx" – unresolved reference.
- "Intimidate check +10 TN" – d20 vocabulary; "Suspicious Mind", "Chaotic Dreams", "FRENZY – UNHOLY RAGE" are undefined effects.
- Sign convention conflicts with doc 10: here dark side is negative, but Dun Moch requires "more than 8 dark side influence" and Juyo awards "gain 2 Dark Side Influence" as a positive count. Either DSI is a separate positive counter or the table should be read as magnitude.
- "Light sided" and "dark sided" forms are never defined; doc 10 does not tag any form as either.
- ±4 SL is enormous in a d100/SL system (equivalent to ≥+40). Odan-Urr's +4 SL to all light-side forms makes a 128-point Jedi effectively unbeatable; the ladder needs recalibration or a cap.
- No Dexterity reference (consistent with a 9-characteristic model, but only because characteristics are barely touched).

**(d) Gaps.** How points are lost/redeemed; whether a character can hold both light and dark points; what "per month" entries mean mechanically; interaction with WFRP Corruption/Mutation (replace or coexist?); the 0..±4 band; whether non-Force-sensitives track it; GM guidance on awarding.

---

## 2. `10 New Star Wars - Combat and Lightsaber Forms.md`

**(a) Contents.** Despite the title there is no general combat chapter: no restatement of WFRP combat, no blaster/lightsaber/shield/armour/stun rules, no hit-location or critical changes, and no Force power list or casting mechanic. The file is fifteen three-tier "Forms" (Initiate / Practitioner / Master), each with characteristic + skill-rank + XP prerequisites and a bonus block:

- *Lightsaber forms (10):* Shii-Cho (Str/Ag/WP by tradition), Makashi (Ag), Soresu (Ag), Ataru (Ag), Shien (Ag)/Djem So (Str), Niman (WP), Juyo (Str)/Vaapad (Str+WP), Jar'Kai, Trakata, Form Zero (non-violence; social/Cool-based).
- *Blaster forms (1):* Dual Wielding Blaster Combat (Pistoleer/Gunslinger/Dead-eye).
- *General combat forms (4):* Echani, Teras Kasi ("playtest required"), Dun Moch (dark side, requires DSI > 8), Force Imbued Combat (Jedi/Sith/Matukai variants).

Prerequisites: Force Sensitive talent, a lightsaber, an instructor or holocron. Each form grants target-number bonuses, SL bonuses, Advantage economy tweaks (e.g. Shii-Cho spends 2 Advantage to strike all adjacent; Juyo spends 2 Advantage per attack for +1 SL), special opposed tests (deflect = opposed Melee vs Ranged), and WFRP weapon qualities (Pummel, Precise, Defensive, Fast, Damaging, Impact, Penetrating). They are not WFRP talents; they are a new progression track resembling Saga-edition feat chains with WFRP mechanics inside.

Force powers appear only by reference: "Use the Force" skill ranks, "Force Talents", "a free use of a force ability", "Force weapons", "Psychometry", "Telekinesis-tier". No power list, test, cost, or miscast analogue exists in these files.

**(b) Design decisions.** Lightsaber damage stat varies by tradition (Force Warrior/Shadow/Savant careers – referenced but not defined here). Blaster deflection is an opposed Melee vs Ranged test. Advantage is the currency for form abilities. Dark-side techniques are paid for with Dark Side Influence gated by Cool tests of rising difficulty. Skills have "ranks" (5/10/15/20/25/30) rather than WFRP Advances – a substantive change if intended.

**(c) Inconsistencies / placeholders.**
- Terminology drift: AGL/Ag/Agl, S/Str/STR, "target bonus" used for penalties ("−10 target bonus"), "Cool 10" vs "10 ranks Cool" vs "Cool test".
- Non-WFRP action vocabulary: "adjacent squares", "attacks of opportunity", "free action", "half action", "full round action", "Standard Action", "Penetration 5", "Penetrating 3" (WFRP Penetrating has no rating).
- Shii-Cho Initiate has no requirement/XP and the whole form costs 300 XP vs 900–1,750 for others.
- Soresu Master repeats the Practitioner +20 deflect bonus (no progression on that line).
- Form 5 is headed "Shien (AG)" but all requirements are Strength-based.
- Form 7 says "choose a specialty at Practitioner" but Initiate already lists Juyo/Vaapad stats; Vaapad "+20 vs Ataru, Djem So and Juyo/Vaapad" – self-referential.
- Jar'Kai "Gain the Dual Wielder talent" is granted again at every tier.
- Echani Master requirement is garbled: "Melee Brawling 25 Ranks, 25 Melee (Any melee Weapon) 15 Ranks".
- Force Imbued Combat Initiate requires WP 35 but Practitioner/Master require WS 50/75 (WP→WS slip); "Steadying Touch" becomes "Steadying Hand".
- Dual blaster: "fired as a in addition" (typo); Dead-eye adds "both Success Levels … as damage".
- Dun Moch Initiate "gains 1 Dark Side Influence" – unclear whether per use, per combat, or on learning.
- Teras Kasi Master "+4 Armour Point on all locations" and Palawa +6: stacks with worn armour to absurd values.
- No Dexterity anywhere, so the doc is compatible with a 9-characteristic model.

**(d) Gaps.** The actual combat chapter: ranged combat with blasters (stun setting, ammo/power cells, burst fire), lightsaber weapon profile and armour interaction, personal shields, hit locations and critical tables, Advantage changes, conditions; which forms are "light" or "dark" (needed by doc 09); the Force power list, Use the Force skill, casting/channelling analogue, failure/dark-side cost; definitions of Force Warrior/Shadow/Savant; a skill "ranks" rule; form stacking rules beyond "lightsaber form cannot be used with a general form".

---

## 3. `All about hyperspace.md`

**(a) Contents.** A well-sourced Legends lore essay (Fandom links): S-threads, jump beacons, hyperlanes, hyperdrive class as a multiplier, 8 h per galactic grid square at Class 1 (~1,500 parsecs), speed factors (Deep Core slower, damage, tampered beacons), BoSS and Republic Spacelane Bureau, lane discovery timeline from Koros Trunk Line (27,000 BBY) to Hydian Way (3,694 BBY). The heading **"NOT YET DISCOVERED"** before the Hydian Way fixes the campaign date at roughly 3,700–4,000 BBY, which matches the "Starships circa 3000–4000 BBY" note.

**(b) Design decisions.** Three technology phases (beacon hops → continuous lanes → fast drives) are intended to shape play in the chosen era: beacon reliability "only about 80%", pirates reprogramming beacons, navies pinning fleets by disabling beacons.

**(c) Inconsistencies.** None internal; "Hyperdrive speed (~4,000 BBY to 19 BBY)" header overlaps the era when beacons were still in use per the same document (beacons obsolete "by 4100 BBY"). Minor duplication between the summary list and the detailed sections.

**(d) Gaps.** No game mechanics: no Astrogation test, difficulty by lane quality/era, time formula (class × squares × 8 h is implied, not stated as a rule), mishap table (misjump, beacon tamper, interdiction), beacon-hop procedure for the ancient era, fuel/upkeep, or the microjump referenced by the ship upgrades.

---

## 4. `Star Wars Bestiary.md`

**(a) Contents.** 65 creatures (Acklay … Zillo Beast), each with a one-line descriptor, flavour paragraph, a stat table, Traits and Optional traits, followed by a 50-entry New Traits glossary. The stat line is **M, WS, BS, S, T, I, Ag, Dex, Int, WP, Fel, W** – the full WFRP 4e 10-characteristic line plus Movement and Wounds. All numbers are filled; "-" is used where WFRP would also omit (BS, Dex, Fel for beasts). Entries mix beasts, sentient species (Falleen, Geonosian, Killik, Talz, Colicoid), droids (Droideka, Basilisk) and a spirit (Dark Side Wraith).

**(b) Design decisions.** WFRP traits reused verbatim (Bestial, Size, Fear, Terror, Ethereal, Construct, Regeneration, Swarm, Web, Breath, Flight, Hatred, Mental Corruption). Star-Wars-specific traits added: Vacuum-Adapted, Deflector Shield, Networked, Force Sense, Force Neutral Zone, Lightsaber-/Blaster-Resistant Hide, Corruption (dark-side aura that inflicts Dark Side Influence), Dark Side Venom, Force Conduit, Hyperspace Jump. Several assume Force rules not yet written: "Immunity (Force Powers): cannot be targeted by powers that require a Willpower-vs-Willpower contest", "Spellcaster (Dark Side Powers)", "Telekinesis-tier Force powers".

**(c) Inconsistencies / placeholders.**
- **Dexterity is present** as a column, and has values for Basilisk 35, Droideka 40, Colicoid 30, Falleen 25, Geonosian 30, Killik 20, Talz 20, Mynock 25. Docs 09/10 never use Dex. If SL100 is a 9-characteristic game the column must go (or be folded into Ag) in both this file and Mounts/Vehicles.
- Starred traits with no glossary entry: Hardened Scales*, Great Leap*, Three Riders*. Unstarred non-WFRP traits: Corrosive Blood, Corrosive Bite (glossary defines "Corrosive Touch"), Infestation, Hungry, Cunning/Clever used as traits. Force Disruption is defined but unused.
- Starring is inconsistent (Tunneller and Lightsaber-Resistant Hide starred on some entries, not others).
- Glossary last line is corrupted: "Movement is always 0.ay climb at full Movement without a Test."
- Range units alternate between "yards" (WFRP) and "metres".
- Rakghoul has Int "-" without Bestial; Basilisk has WP "-" though a Construct normally has WP; Vornskr W 10 is low for S 35/T 30.
- Legends policy: Loth-cat, Loth-wolf and Purrgil are *Rebels* (Disney canon) creatures, and the glossary "Force Conduit… hyperspace tunnel" is canon lore. Zillo Beast is TCW (dual-canon). Flag or drop for a Legends-only product.
- Era: most entries are fine for any era, but Droideka/Basilisk appear without era tags while the campaign is ~3,700+ BBY.

**(d) Gaps.** Size-based damage/wound scaling rules for Enormous/Monstrous vs vehicle-scale weapons; how creature Armour interacts with blasters vs lightsabers generally (only special hides are covered); the Force rules the traits depend on; era/region tags; a sentient-species section separated from beasts (species belong in character creation).

---

## 5. `Star Wars Mounts_Vehicles.md`

**(a) Contents.** 11 living mounts (Aiwha listed twice by design, Dactillion, Uvak, Bantha, Dewback, Eopie, Kaadu, Ronto, Tauntaun, Varactyl, Fambaa) using the Bestiary stat line plus **Cost / Carries (Enc) / Availability**, cross-referencing the WFRP Core "Animals and Vehicles" table (p. 306). Then a 4-row Speeder table, a prose entry for the T-16 Skyhopper, a 6-row Tank table and a 6-row Walker table with fields **Era/Faction, Size, Crew, Cargo (Enc), Cost, Speed km/h, Weapons, Availability**. Numbers are filled (costs are GM estimates).

**(b) Design decisions.** Mounts are creatures; vehicles borrow the Starship Compendium table instead of a WFRP vehicle profile. Speed in km/h for ground craft.

**(c) Inconsistencies.**
- Duplicated creatures (Bantha, Eopie, Kaadu, Tauntaun, Varactyl, Fambaa, Aiwha) match the Bestiary exactly – good, but two copies will drift; the wiki should transclude.
- Encumbrance: "1 Enc = 10 kg, matching the Starship Compendium's conversion" – but the Compendium also says "1 Tonne = 125 Encumbrance" (i.e. 8 kg). Pick one.
- Speeder table reuses ship headers ("Ship", "Hyperdrive N/A", "Def. Turrets") and lacks Availability and Weapons columns that the Tank/Walker tables have; the T-16 is not in table form.
- Uvak cost "Not for sale (Keshiri-bred) credits".
- Dex column present (see Bestiary).
- Dewback/74-Z/AT-AT etc. are Imperial-era in a ~3,700 BBY campaign; no era-appropriate ground vehicles (e.g. Mandalorian Wars/Great Galactic War walkers) are given.

**(d) Gaps.** No vehicle damage model (no Wounds/Toughness/Armour/hull values, no weapon damage, no crit table); no handling/Drive test rules; no mounted-combat rules (WFRP Ride rules could be cited); no Carries for vehicles beyond cargo; no fuel/maintenance; no speeder weapons stats.

---

## 6. `Star Wars Space Ships.md` (Starship Compendium)

**(a) Contents.** ~52 vessels across Star Fighters (6), Strikecraft (4), docking ring (1), Droid ships (1), Bombers (3), Freighters (4), Corvettes (4), Frigates (3), Cruisers (3), Heavy Cruisers (4), Capital (10), Dreadnoughts (6), Space Stations (3). Fields: **Era/Faction, Hyperdrive (primary(backup)), Size m, Crew, Pax, Astromech, Cargo, Cost, Speed MGLT, Speed kph, Def. Turrets, Availability.** Numbers are mostly filled. Then an Upgrades section: a size cost-multiplier ladder (x1 fighter → x512 station), an unexplained worker-count multiplier table, and 16 upgrade categories (Alarms, Armour, Astromech, Blast Doors, Circuitry, EWAR/EMP, Engines, Interior, Navigation, Power Conversion, Security, Sensors, Shields, Special Plating, Tractor Beams, Weapons) each with Mk I–III(IV) tiers, effect and cost. **No ship combat rules are present.**

**(b) Design decisions.** Modelled on *Sea of Claws* boat tables; cargo in Enc; licence/restriction codes (C, L (x), RM, R (x), RLE); upgrades scale by hull class; astromech as a socket upgrade. Upgrades presuppose a ship profile with Armour, Critical Hits, "Engine rating", Toughness/Wounds and system damage.

**(c) Inconsistencies / placeholders.**
- Author notes left in: "Strikecraft *** combine with table above", "Emplacement points? When can you upgrade…?", "Limits to what upgrades…?", "Check the ship categorys below is correct", and a row of "???????" above the worker multiplier table.
- Cargo unit flips between Enc and tonnes per table ("Cargo (Enc)" vs "Cargo (t)"), and "1 Enc = 10 kg" vs "1 Tonne = 125 Enc".
- Capital table rows Recusant, Centurion, Oppressor, Allegiance are column-shifted (cargo sits under Pax, availability spills into a blank column).
- Availability uses "C", "M", "M (any)", "L (anyone with money)" – "M" is never defined (Military is listed as a sub-type of Restricted); Bombers have an empty Availability column.
- A-wing appears twice with different factions (Fighters: "Galactic Empire" – wrong; Strikecraft: Rebel Alliance). Fighters header says "Crew is 1" yet ARC-170 has 2.
- Jedi Vector is **High Republic** (Disney-era publishing) – violates the Legends-only policy; Isotope-5 "bled from Purrgil migration trails" is invented canon-Legends fusion.
- Cross-document conflicts with `Starships circa 3000-4000 BBY.md`: Thranta hyperdrive Class 1 vs Class 2, crew 250 vs 300; Praetorian 260 m vs 180 m; Harrower Class 1 vs "Unknown"; Centurion crew 4,500 vs 31,452; Chela is a "Bomber, hyperdrive Nil, 11 m" here vs "Starfighter with hyperdrive" there; Hammerhead crew 300 vs 300+224 gunners.
- Upgrade effects use personal-scale language ("+1 Armour", "dodged at any range category", "criticals on 10s and doubles") with no ship-scale definitions; Beskar "+2 Armour vs lightsabers" on a hull is odd.
- No Dex issue (no characteristics).

**(d) Gaps.** Starship combat (initiative, pilot tests, ranges, weapon profiles/damage, shields vs armour, hull Wounds, crit/system-damage table, boarding); weapon lists per ship (only turret counts exist); crew-role actions; repair rules; era filtering for the 3,700 BBY campaign (most hulls are Clone Wars/Imperial); emplacement/upgrade-slot rules the author already flags.

---

## 7. `Starships circa 3000-4000 BBY.md`

**(a) Contents.** An era note filtering ships to the pre-3,000 BBY campaign window: three starfighters (Star Saber XC-01, Aurek, S-250 Chela) as bullet entries, an 11-row capital table (Xolochi, Thanium Star-Glaive, Kumauri, Cal-class, Praetorian, Hammerhead, Foray, Inexpugnable, Centurion, Thranta, Harrower) with First Service, Troops, Min Crew, Hyperdrive Class, Notes. Explicitly lore-only ("Unknown entries reflect genuine gaps"); the Harrower (3,712 BBY) is justified as inside the cutoff. No game statistics.

**(b) Design decisions.** Confirms the campaign era and the Legends sourcing discipline (Essential Atlas / KOTOR / SWTOR).

**(c) Inconsistencies.** First-person "I've included it" author voice; the data conflicts with the Compendium listed above; Inexpugnable, Star Saber, Kumauri, Cal, Xolochi are absent from the Compendium.

**(d) Gaps.** Needs merging into the Compendium as an era column or a filtered table; needs Compendium-format stats for the era ships; Sith Empire/Mandalorian ships of the era (Basilisk carriers, Sith Interdictor already in Compendium) are thin.

---

## Cross-cutting findings

1. **Characteristic model.** Bestiary and Mounts carry a Dex column with real values for droids/sentients; docs 09/10 never mention Dex. Decide 9 vs 10 and normalise.
2. **Force rules are the missing keystone.** Force Influence, forms (Niman, Force Imbued), bestiary traits (Immunity, Spellcaster, Force Neutral Zone) and the Dun Moch gate all depend on an undefined Force power system (powers, Use the Force skill, casting test, cost, dark-side pull).
3. **Vehicle/ship profile missing.** Upgrades, bestiary leviathans and vehicle tables all need a common vehicle-scale profile (Armour, Wounds, weapon damage, crits, scale rule vs personal weapons).
4. **Era discipline.** Hyperspace doc dates the campaign ~3,700–4,000 BBY; the ship, vehicle and mount tables are predominantly Clone Wars/Imperial.
5. **Legends policy breaches:** Loth-cat, Loth-wolf, Purrgil (Rebels), Jedi Vector (High Republic).
6. **Vocabulary.** Standardise on WFRP terms (Advances not ranks, modifiers not "target bonus", Action/Move not half/standard/full-round, metres or yards).

## Status per document

| Document | % complete | State | Top 3 gaps |
|---|---|---|---|
| 09 Force Influence | 25% | Notes / table skeleton | Empty 0..±4 bands & "table xx"; sign convention vs doc 10; gain/loss and redemption rules |
| 10 Combat & Lightsaber Forms | 55% (forms) / 10% (combat chapter) | Forms drafted, combat rules absent | General combat/blaster/lightsaber/armour/stun rules; Force power list & test; terminology and prerequisite clean-up |
| All about hyperspace | 70% lore / 5% rules | Lore essay | Astrogation test & difficulty; travel-time formula and mishaps; era beacon-hop procedure |
| Star Wars Bestiary | 80% | Usable draft | Dex decision; 3 undefined starred traits + corrupted last line; Force-dependent traits & canon-only creatures |
| Mounts & Vehicles | 60% | Draft tables | Vehicle damage/handling model; Enc conversion conflict; era-appropriate vehicles & speeder table fields |
| Space Ships (Compendium) | 55% | Tables plus unresolved author questions | Starship combat and ship profile; column shifts, duplicate A-wing, unit/availability codes; upgrade slot rules |
| Starships circa 3000–4000 BBY | 40% | Era note, lore only | Reconcile stats with Compendium; convert to Compendium format; merge as era filter |
