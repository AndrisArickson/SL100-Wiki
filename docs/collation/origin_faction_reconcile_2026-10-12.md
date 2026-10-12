# 03 Origin and 04 Faction reconciliation — 12 Oct 2026

Both chapters were checked against chapter 06 (Skills) and the Legends-only wiki, then rebuilt as SL100:Origin and SL100:Faction (`tools/build_pages.py --only`). Backups of the originals are in `data/history/03 Origin.md.2026-10-12.bak` and `data/history/04 Faction.md.2026-10-12.bak`.

## 03 Origin — decisions (Andris, 12 Oct)

- **d100 table** (option "Nexus 96–00"): Feral 41–50, Lava 56–60, Space 81–95, Force Nexus 96–00. The other ranges are unchanged. This fixes the 41–45 and 91–99 gaps and the double 55.
- **Skills mapped to chapter 06 names:**
  - Charm Creature and Creature Care → Creature Training (any one). Agri had both, so it now has Creature Training twice (two different specialisations).
  - Melee (1H/2H) → Melee (any one).
  - Ranged (Blaster) → Ranged (Blaster Pistol or Blaster Rifle).
  - Ranged (Blaster/Heavy) → Ranged (Blaster Pistol, Blaster Rifle or Heavy Blaster).
  - Ranged (Archaic) → Ranged (Slugthrower).
  - Ranged (…/Ordinance) → adds Missile/Rocket.
  - Stealth (Wilderness) → Stealth (Rural).
  - Ride (Air/Land/Water) → Ride (Air, Land or Water).
  - Entertain and Play → (any one).
  - Skill lists sorted alphabetically.
- **Still undefined in 06:** Intimidate, Perception and Meditate. They're noted on the page.
- **Lava** gets Perception as its 12th skill.
- **Legends examples:**
  - Jedha (canon) removed; Force Nexus examples are Tython, Ossus and Ilum.
  - Ungor (no article) removed from Hostile.
  - Lothal (canon) → Dantooine.
  - Chandrilla → Chandrila.
  - Mon Cala → Dac (Mon Calamari).
  - Ilum added to Tundra.
  - All examples link to their /Legends article.
- **Text fixes:**
  - "Shrine Origin" → Force Nexus; "Forge" → Industrial; "planets or animals" → "planets or moons".
  - The table now has separate fixed +5 and choice +5 columns.
  - New "How an Origin works" summary, restating the 3 × +5 / 3 × +3 rule from the original.
- **Open:** Lava and Tundra have identical characteristic options. Bespin (a gas giant) is still listed as a Feral world.

## 04 Faction — decisions

- The intro list now matches the sections that exist: Force Traditions, Criminal Underworld, Mega Corporations and Federations, Imperial Powers.
- **Era fixes:** "(4 BBY+)" → "(4 ABY+)"; "(19–4 BBY)" → "(19 BBY–4 ABY)".
- Every entry links to its Legends article where one exists; all 103 links resolve in the local wiki.
- **Swapped to Legends names:**
  - Jedi Bendu → Je'daii Order.
  - Sullust Orbital Yards → Sullustan Orbital Shipyards.
  - Imperial Dept. of Military Research → Imperial Department of Military Research.
  - Project Spaarti → Spaarti cloning facility (Wayland).
  - Mount Tantiss Cloning Vaults → Mount Tantiss.
  - Imperial Bioweapons Division → Imperial Biological Weapons Division.
  - Thrawn's Clone Programme → Mount Tantiss project.
- **Canon-only, kept and marked:** The Bendu, Lasan High Guard, Spice Runners of Kijimi, Tarkin Initiative.
- **Marked SL100 homebrew (no Legends article):**
  - Alsakan Megacorp, Subpro Corporation, Transgalactic Industries, Geonosis Hive Industries.
  - Imperial Naval Shipyards, Corulag Fleet Yards, Scarl Shipyards.
  - Imperial Starfighter Corps Production Bureau, Imperial Weapons Development Bureau, Project Blackwing Facility, Imperial Torpedo Sphere Programme, Imperial Army Ordnance Corps, Imperial Stormtrooper Materiel Command, Imperial Cloning Programme (Kamino).
  - Where a related Legends article exists, the entry gets a "See …" link.
- **Open, not invented here:**
  - Faction mechanics (skills, talents, Patron rules).
  - Where Faction sits in the creation order.
  - How Origin changes the chance of a Faction.
  - Some entries appear under both Mega Corporations and Imperial Powers (Maw Installation, Santhe/Sienar, Imperial Department of Military Research).

## Tooling

- `tools/collate/assembly.py` now parses the new 03 layout. `origins.csv` gains `fixed_plus5`, `choice_plus5` and `examples` columns.
- `tools/build_pages.py` status lines updated for Origin and Faction.

## Round 2 (Andris, 12 Oct)

### 06 Skills
- **Intimidate, Perception and Meditate** were in 06 already, but their headings were plain bold text, so the collation missed them. Perception's text also stopped mid-sentence.
- All three were rewritten in Star Wars terms and promoted to `###` headings:
  - **Intimidate (S) basic**, with a Star Wars example and Other Characteristics options.
  - **Perception (I) basic**. It notes that Perception is what is there, while Intuition is what it means.
  - **Meditate (WP) advanced** (was Fel). It replaces the WFRP Pray port with three uses: Clear the Mind, Centre Yourself, and Listen to the Force.
- Creature Care and Ride headings were promoted the same way.
- A duplicated block at the end of 06 (Ride, Sleight of Hand, Stealth, Swim, Track) was removed.
- The Basic and Advanced summary lists now match the entries. Ranged is now listed as Advanced, as its entry says.
- Backup: `data/history/06 Skills.md.2026-10-12.bak`.

### 03 Origin
- Agri gets Creature Care back, since it is defined in 06.
- Bespin → Dathomir as a Feral example.
- Removed the notes section: Lava and Tundra can share options, and the skills are now defined.

### 04 Faction
- **How Factions work:** a Faction is who you work with, giving second-order benefits and third-order detriments, with no first-order game bonus.
- **Eras at a glance:** a key to the era labels and their dates.
- **Origin and Faction:** Origin rarely limits your choice. Exceptions are listed (Force-sensitivity, Dathomir, Voss, Aing-Tii, Yanibar, Corellia, Lasat, Tapani nobility, Hapans, Chiss, Kaminoans, Mon Calamari, Zygerrians, Hutts).
- **Governments, Militaries and Powers**, with Legends date ranges:
  - 13 states and governments, plus a note that the Yuuzhan Vong are not a player Faction.
  - 17 militaries and intelligence services.
  - 6 Mandalorian factions.
- All 143 links resolve.

### Still open
- Career skill names in 05 that don't match 06:
  - Bribe → Bribery
  - Consume Alcohol → Consume Intoxicant
  - Heal → Medicine
  - Slice Security → Slice Security System
  - Secret Signs → Codes
  - Trade → Profession
  - Underworld → Lore (Underworld)
  - Charm Creature → Creature Training

## Round 3: career skill names (12 Oct)

Applied the renames to the 05 skill lines:
- Bribe ×1, Consume Alcohol ×18, Heal ×2, Slice Security ×3, Secret Signs ×2, Trade (Armourer…) ×2, Underworld (Street…) ×1, Charm Creature ×2.

Applied elsewhere:
- 06: Consume Alcohol → Consume Intoxicant ×3, in the drinking table.
- Creature Affinity tests: Charm Creature → Creature Training, in 07 (revised) and the revised Talent List.

Results:
- `lists_report.md` now shows 0 career skills undefined in 06.
- The "06 opening list" check splits on commas outside brackets only, so specialisation lists no longer show up as false gaps.
- Backups: `data/history/*.skillnames.2026-10-12.bak`.
