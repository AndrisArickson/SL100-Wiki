# Careers: conflicts and open points (12 Oct 2026)

Collected while building `05 New Star Wars - Careers (revised).md` (24 `[sl100]` + 57 `[review]` careers). Nothing here was resolved silently; each item needs a ruling or a fix in another chapter.

## Crossed wires with other chapters

1. **Use the Force** is referenced by every Force talent and by the Force careers (Monastic, Force Mystic, Sorcerer, Hedge Adept, Seer, Dark Side Cultist, Templar, Force Savant/Shadow/Warrior) but chapter 06 lists it without an entry and `skills_master.csv` omits it. Chapter 06 needs the skill written (WP, Advanced, grouped by discipline: Sense / Control / Alter?).
2. **Charm Creature** is used by Scout, Warden, Chemist, Hunter, Seer, Beast Rider and Beast Handler; chapter 06 has it (WP) but the collation CSV omits it. Confirm it stays a skill (WFRP's Charm Animal) rather than a Charm specialisation.
3. **Pilot (Land Vehicle) vs Pilot (Speeder)**: chapter 05 used Land Vehicle, chapters 03 and 06 use Speeder. The revised chapter converts to Pilot (Speeder); the Roll20 sheet and chapter 08 should follow.
4. **Soldier level 4 is titled "Officer"** and there is now an Officer career. Suggest renaming Soldier 4 to "Veteran Sergeant" or "Company Commander", or folding the Officer career's levels 3-4 into Soldier.
5. **Armoured Adept** is a Force talent (Use the Force in armour) but the Armoured Knight career has no Force skill; the writer left it out. Decide whether Armoured Knight gets an optional Force-sensitive branch (Mandalorian Force users, Jensaarai) or Templar covers that.
6. **New Lores introduced by the conversions** that chapter 06 does not list: Lore (Pharmacology), Lore (Interrogation), Lore (Sith Lore), Lore (Salvage), Lore (Martial Arts), Lore (Orbital Lanes) (suggested), Lore (Astrogation) (Seer: reads oddly, was Astrology). Add to the Lore specialisation list or rename.
7. **New Etiquette and Strider groups**: Etiquette (Force Traditions) suggested for tradition careers; Strider (Starship Decks / Spaceport) used by Spacers careers; Resistance (Dark Side) used by Tomb Raider. Decide whether these are legal specialisations.
8. **Status tiers** still Brass / Silver / Gold; Zealot is Brass 0 throughout as in WFRP. The Fringe / Citizen / Elite renaming is pending.
9. **Melee (Lightsaber) at −20 for non-Force-sensitives** (chapter 06) interacts with Templar and Armoured Knight; fine, but the Combat chapter should restate it.

## Inside the careers

10. **Advance Scheme levels 2-4** of all 43 converted careers are proposals (only the level-1 trio could be read from the rulebook text), and the whole scheme of the 14 native/supplement careers is proposed. Writers also doubted the extracted level-1 trio for Force Mystic (T, Ag, WP), Monastic (Dex, Int, Fel), Vermin Hunter (WP), Merchant-derived careers. Check against the rulebook.
11. **Force careers had to drop a WFRP talent** at level 1 to fit Force Sensitive (Tradition) plus a discipline (Monastic lost Panhandle, Force Mystic Suave, Sorcerer Datapad Use, Templar Etiquette and Datapad Use). Decide whether Force careers get 5 talents at level 1 or whether Force Sensitive (Tradition) is granted free by the tradition.
12. **Advocate (WFRP Lawyer)**: the source text had only three levels; level 4 "Magistrate — Gold 2" was reconstructed from memory. Warden's WFRP parent likewise had three levels extracted; the `[sl100]` Warden is unaffected.
13. **Water-born skills in the Spacers class**: Swim, Fisherman, Strong Swimmer, Lore (Riverways) were remapped case by case (Cool, Scavenger, Vacuum Legs, Lore (Hyperlanes)); four Spacers careers still keep Swim at level 1 as a holdover. A blanket rule for the class would be cleaner.
14. **Ride (Horse) remaps** are inconsistent by design: urban careers took Pilot (Speeder), frontier careers Ride (Creature). Listed per career in the notes.
15. **Ranged (Thrown) -> Ranged (Grenade/Explosives)** sits badly with throwing-knife trappings (Enforcer 3, Berserker 3, Entertainer); Ranged (Slugthrower) or a Thrown specialisation may be wanted.
16. **Overlaps** flagged on almost every new career (Pharmacist/Physician, Engineer/Mechanic/Artisan, Advocate/Advisor, Security Officer/Guard/Warden, Politician/Noble/Envoy/Advisor, Marine/Soldier, Templar/Force Warrior, Monastic+Force Mystic/Force Savant, Pirate/Outlaw/Smuggler, Journalist/Agitator/Investigator). None was merged; the chapter is wide on purpose so you can cut.
17. **Placeholders left in the `[sl100]` Force careers** (14 lines marked `[review: placeholder]`: "xx", "xxx", "(Light / Netural / Dark side)").
18. **Trappings in the `[sl100]` careers** were converted by a word map (Halberd -> Force Pike, Hand Weapon -> Vibroblade, Riverboat -> Light Freighter share, Healing Draught -> Medpac, GC -> credits, Horse -> Speeder Bike ...); lines changed end `[converted]`. Two words were left for you: "Tauntaun" (Mounted Tauntaun, Ride (Bantha) choices) and "Shield" where a riot or personal shield was not clearly meant.

## Supplement careers (from the books, 12 Oct evening)

With the five supplements on disk, `tools/collate/supplement_careers.py` extracted 31 careers (Up in Arms 14, Sea of Claws 8, Archives I-III 9) with their real levels and level-1 characteristics into `Source_Text/collation/wfrp_supplement_careers.csv`. Six earlier drafts were rewritten from their real parents (Gunner from Ship's Gunner + Artillerist, Officer from the Sea of Claws Officer, Armoured Knight from the three Up in Arms Knights with an Orders note, Navigator from Cartographer, Beast Handler from Rhinox Herder, Beast Rider from Light Cavalry) and ten more added (Sharpshooter, Elite Guard, Line Trooper, Camp Follower, Freelance, Beachcomber, Shadow Scout, Fieldwarden, Clan Ranger, Hired Gun). Not converted: Chantyman, Sailor-Priest of Manann, Priest of Stromfels, Priest of Myrmidia, Priests of Handrich/Solkan/Rhya, Ogre Butcher, Maneater beyond Hired Gun, Huffer and Wrecker and Sailor (already Dock Pilot, Salvager, Starship Crew).

19. **Level-1 skill count.** The supplement careers list ten skills at level 1 (the core rulebook's first printing lists eight; chapter 05's own header says ten). The writers trimmed to eight per the brief and named the dropped skills. Rule on 8 or 10 and the trimmed skills can be restored in one pass.
20. **Unshakeable** exists in the talent list under its own name but the batch mapping sent it to Iron Jaw in five careers; one ruling reverts them.

## Supplement careers used (earlier, from memory)

Names taken from WFRP supplements and repurposed (no supplement text was readable online; all levels are our design): Artillerist -> Gunner (Up in Arms), Navigator / Pirate / Marine (Sea of Claws Seafarer class), Badger Rider -> Beast Rider (Archives I), Rhinox Herder -> Beast Handler (Archives II), Celestial Dragon Monk -> Martial Artist (Archives III). Not repurposed: Karak Ranger, Ghost Strider, Shirewarden, Dwarf Slayer (covered by Scout/Berserker), Ogre Butcher/Maneater, Scryer and Magister Vigilant (covered by Seer and Inquisitor), Mundane Alchemist (Chemist), Beadle (Security Officer), Amazon (Dathomiri belongs to species/tradition).
