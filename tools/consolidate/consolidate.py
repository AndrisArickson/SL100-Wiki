#!/usr/bin/env python3
"""Consolidation pass (13 Oct 2026): weapon-skill scheme, ten level-1 skills per career, typo fixes.
Run from SL100-Wiki root. Idempotent: a second run changes nothing."""
import re, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "consolidate"))
import skillmap

LIVE = ["01 New Star Wars - Introduction & Characteristics.md", "02 New Star Wars - Species (revised).md",
        "03 New Star Wars - Origin.md", "04 New Star Wars - Faction.md", "05 New Star Wars - Careers (revised).md",
        "06 New Star Wars - Skills.md", "07 New Star Wars - Talents (revised).md", "08 New Star Wars - Equipment.md",
        "09 New Star Wars - Force Influence.md", "10 New Star Wars - Combat and Lightsaber Forms.md",
        "Talent List (revised).md", "Star Wars Bestiary.md", "Star Wars Mounts_Vehicles.md", "Star Wars Space Ships.md",
        "Special Materials.md"]
TYPOS = [("Briberyry", "Bribery"), ("Slice Security System System", "Slice Security System"), ("Netural", "Neutral"),
         ("Maurauder", "Marauder")]

# career -> (two or more skills added at level 1)
ADD = {
 "Advocate": ["Entertain (Rhetoric)", "Dodge"], "Engineer": ["Evaluate", "Profession (Fabricator)"],
 "Pharmacist": ["Evaluate", "Sleight of Hand"], "Physician (Medic)": ["Intuition", "Language (Old Galactic Standard)"],
 "Scholar": ["Evaluate", "Lore (Galactic History)"], "Slicer": ["Lore (Science)", "Intuition"],
 "Agitator": ["Entertain (Speeches)", "Stealth (Urban)"], "Artisan": ["Art (Any)", "Climb"],
 "Beggar": ["Gamble", "Climb"], "Camp Follower": ["Perception", "Perform (Dance)"],
 "Chemist": ["Evaluate", "Research"], "Citizen": ["Athletics", "Endurance"], "Colonist": ["Climb", "Navigation"],
 "Fieldwarden": ["Lore (Local)", "Swim"], "Holonet Journalist": ["Evaluate", "Lore (Galactic History)"],
 "Investigator": ["Research", "Lore (Local)"], "Mechanic": ["Intuition", "Dodge"],
 "Merchant": ["Pilot (Starship)", "Lore (Hyperlanes)"], "Miner": ["Athletics", "Navigation"],
 "Security Officer": ["Ranged (Blaster)", "Stealth (Urban)"], "Vermin Hunter": ["Outdoor Survival", "Lore (Beasts)"],
 "Advisor": ["Research", "Lore (Law)"], "Artist": ["Climb", "Entertain (Storytelling)"],
 "Attendant": ["Sleight of Hand", "Melee (Brawling)"], "Envoy": ["Perception", "Evaluate"],
 "Gunslinger": ["Ride (Creature)", "Stealth (Urban)"], "Noble": ["Evaluate", "Pilot (Speeder)"],
 "Politician": ["Consume Intoxicant", "Language (Old Galactic Standard)"], "Revenue Agent": ["Ranged (Blaster)", "Research"],
 "Spy": ["Slice Security System", "Lore (Politics)"], "Warden": ["Track", "Navigation"],
 "Dark Side Cultist": ["Meditate", "Outdoor Survival"], "Force Mystic": ["Dodge", "Language (The Force)"],
 "Force Savant": ["Use the Force", "Meditate"], "Force Shadow": ["Use the Force", "Perception"],
 "Force Warrior": ["Use the Force", "Meditate", "Perception", "Pilot (Speeder)", "Lore (The Force)", "Climb"],
 "Hedge Adept": ["Charm Creature", "Stealth (Rural)"], "Monastic": ["Use the Force", "Intuition"],
 "Seer": ["Meditate", "Research"], "Sorcerer": ["Meditate", "Endurance"], "Templar": ["Use the Force", "Athletics"],
 "Beast Handler": ["Consume Intoxicant", "Demolitions"], "Beast Rider": ["Haggle", "Ranged (Thrown)"],
 "Bounty Hunter": ["Cool"], "Clan Ranger": ["Lore (Beasts)", "Stealth (Rural)"], "Courier": ["Intuition", "Ranged (Blaster)"],
 "Driver": ["Dodge", "Haggle"], "Entertainer": ["Cool", "Dodge"], "Freelance": ["Creature Care", "Charm Creature"],
 "Hired Gun": ["Gamble", "Outdoor Survival"], "Hunter": ["Athletics", "Dodge"], "Inquisitor": ["Research", "Lore (The Force)"],
 "Marshal": ["Cool", "Dodge"], "Pilot": ["Athletics", "Evaluate"], "Scout": ["Intuition", "Charm Creature"],
 "Shadow Scout": ["Lore (Local)", "Swim"], "Smuggler": ["Navigation", "Ranged (Blaster)"], "Trader": ["Dodge", "Navigation"],
 "Zealot": ["Meditate", "Consume Intoxicant"], "Bawd": ["Sleight of Hand", "Stealth (Urban)"],
 "Charlatan": ["Lore (Local)", "Language (Any)"], "Fence": ["Sleight of Hand", "Stealth (Urban)"],
 "Gambler": ["Athletics", "Intimidate"], "Outlaw": ["Climb", "Navigation"], "Racketeer": ["Gamble", "Athletics"],
 "Thief": ["Haggle", "Codes (Underworld)"], "Tomb Raider": ["Athletics", "Lore (Any)"],
 "Beachcomber": ["Dodge", "Gossip"], "Customs Officer": ["Haggle", "Language (Trade Cant)"],
 "Deckhand": ["Climb", "Melee (Brawling)"], "Dock Pilot": ["Endurance", "Athletics"], "Dock Worker": ["Haggle", "Lore (Local)"],
 "Marine": ["Gamble", "Gossip"], "Navigator": ["Climb", "Lore (Hyperlanes)"], "Pirate": ["Gamble", "Gossip"],
 "Salvager": ["Evaluate", "Athletics"], "Spacer": ["Gamble", "Ranged (Blaster)"], "Starship Crew": ["Haggle", "Lore (Hyperlanes)"],
 "Armoured Knight": ["Creature Care", "Charm Creature"], "Berserker": ["Athletics", "Climb"],
 "Elite Guard": ["Consume Intoxicant", "Play (Any)"], "Enforcer": ["Consume Intoxicant", "Stealth (Urban)"],
 "Guard": ["Lore (Local)", "Haggle"], "Gunner": ["Climb", "Intimidate"], "Line Trooper": ["Ranged (Blaster)", "Ranged (Thrown)"],
 "Martial Artist": ["Medicine", "Sleight of Hand"], "Officer": ["Climb", "Lore (Warfare)"],
 "Pit Fighter": ["Climb", "Entertain (Taunt)"], "Sharpshooter": ["Ranged (Blaster)", "Consume Intoxicant"],
 "Soldier": ["Ranged (Blaster)", "Intimidate"], "Speeder Trooper": ["Dodge", "Athletics"],
}
# career -> [(level, old skill (post-rename), new skill)] where the consolidation left the same skill twice
REPLACE = {
 "Engineer": [(2, "Ranged (Blaster)", "Lore (Science)")], "Gunslinger": [(3, "Melee (1H)", "Sleight of Hand")],
 "Noble": [(2, "Melee (1H)", "Ranged (Blaster)")], "Marshal": [(3, "Ranged (Blaster)", "Track")],
 "Pirate": [(2, "Ranged (Blaster)", "Ranged (Thrown)")], "Marine": [(3, "Ranged (Blaster)", "Ranged (Ordnance)")],
 "Guard": [(3, "Melee (2H)", "Climb")], "Martial Artist": [(2, "Melee (1H)", "Melee (2H)")],
 "Dock Pilot": [(3, "Lore (Local)", "Dodge")], "Sorcerer": [(1, "Melee (2H)", "Cool")],
 "Force Shadow": [(1, "Stealth,", "Stealth (Urban),")],
}
NOTE = "`[review: level 1 raised to ten skills (13 Oct ruling): %s added]`"
NOTE_R = "`[review: weapon-skill consolidation left %s twice; level %d copy replaced by %s]`"


def level_line(block, n):
    m = re.search(r"(\*\*%d\. [^\n]*\*\*[^\n]*\n+\*\*Skills:\*\*)([^\n]*)" % n, block)
    return m


def split_skills(s):
    s = re.sub(r"`\[[^\]]*\]`", "", s)
    items, buf = [], ""
    for p in s.split(","):
        buf = (buf + "," + p) if buf else p
        if buf.count("(") == buf.count(")"):
            items.append(buf.strip().strip("*").strip()); buf = ""
    if buf.strip():
        items.append(buf.strip().strip("*").strip())
    return [i for i in items if i]


def fix_careers(text, log):
    blocks = re.split(r"\n(?=### )", text)
    out = [blocks[0]]
    for b in blocks[1:]:
        name = b.split("\n")[0][4:].strip()
        notes = []
        for n, old, new in REPLACE.get(name, []):
            m = level_line(b, n)
            if m and old in m.group(2):
                line = m.group(2).replace(old, new, 1)
                b = b[:m.start(2)] + line + b[m.end(2):]
                if not old.endswith(","):
                    notes.append(NOTE_R % (old, n, new))
        m = level_line(b, 1)
        if m:
            have = split_skills(m.group(2))
            allsk = set()
            for n in (1, 2, 3, 4):
                mm = level_line(b, n)
                if mm:
                    allsk |= set(split_skills(mm.group(2)))
            adds = [a for a in ADD.get(name, []) if a not in allsk]
            if adds and len(have) < 10:
                adds = adds[:max(0, 10 - len(have))] if name != "Force Warrior" else adds
                line = m.group(2)
                tag = re.search(r"\s*`\[[^\]]*\]`\s*$", line)
                body = line[:tag.start()] if tag else line
                body = body.rstrip().rstrip(",")
                line = body + ", " + ", ".join(adds) + (tag.group(0) if tag else "")
                b = b[:m.start(2)] + line + b[m.end(2):]
                notes.append(NOTE % " and ".join(adds) if len(adds) <= 2 else NOTE % ", ".join(adds))
                log.append("%s: +%s" % (name, ", ".join(adds)))
            cnt = len(split_skills(level_line(b, 1).group(2)))
            if cnt != 10:
                log.append("!! %s level 1 has %d skills" % (name, cnt))
        else:
            log.append("!! %s: no level 1 found" % name)
        if notes:
            notes = [n for n in notes if n not in b]
            if notes:
                if "*Conversion notes:*" in b:
                    b = b.rstrip("\n") + "\n" + "\n".join(notes) + "\n"
                else:
                    b = b.rstrip("\n") + "\n\n*Conversion notes:*\n" + "\n".join(notes) + "\n"
        out.append(b)
    return "\n".join(out)


MELEE_SPEC = ("Specialisations: 1H (one-handed weapons: vibroblades, vibroknives, stun batons, axes, clubs, swords and improvised weapons held in one hand), "
              "2H (weapons that need both hands: vibro-axes, force pikes, electrostaffs, quarterstaffs and other great weapons), "
              "Brawling (unarmed strikes, knuckle-dusters, shock gloves, grapples and wrestling; also used to defend when you have no weapon), "
              "\\*Lightsaber (all lightsabers, including double-bladed sabers and lightsaber pikes; −20 unless you have Force Sensitive). "
              "A weapon used with the wrong Specialisation is Tested on bare Weapon Skill (see Chapter 10).")
RANGED_SPEC = ("Specialisations: Blaster (every blaster from hold-out pistols to heavy repeating blasters and the E-Web, together with ion, disruptor and sonic weapons: the standard ranged skill of the galaxy), "
               "Archaic (bows, crossbows, slings, slugthrowers, bowcasters and any other projectile weapon that must be aimed rather than pointed), "
               "Thrown (grenades, thermal detonators, throwing knives, darts, spears and anything else hurled by hand), "
               "Exotic (nets and net launchers, whips used at range, flame projectors, glue and adhesive projectors, dart and flechette launchers, wrist-mounted weapons, Mandalorian mini-rockets and other unusual ranged weapons), "
               "Ordnance (missile and rocket launchers, grenade launchers, mortars and crew-served artillery fired by hand; mounted vehicle and starship weapons are covered in the Starships chapter). "
               "A weapon used with the wrong Specialisation is Tested on bare Ballistic Skill with the weapon's penalties (see Chapter 10).")


def fix_06(text):
    text = re.sub(r"Specialisations: Brawling, Vibroblade[^\n]*", MELEE_SPEC, text)
    text = re.sub(r"Specialisations: Blaster Pistol, Blaster Rifle[^\n]*", RANGED_SPEC, text)
    text = text.replace("Melee (1H, 2H, Brawling, \\*Lightsaber)", "Melee (1H, 2H, Brawling, \\*Lightsaber)")
    return text


def main():
    log = []
    for f in LIVE:
        p = ROOT / f
        if not p.exists():
            log.append("missing " + f); continue
        t0 = p.read_text(encoding="utf-8")
        t = skillmap.apply(t0)
        for a, b in TYPOS:
            t = t.replace(a, b)
        if f.startswith("05 "):
            t = fix_careers(t, log)
        if f.startswith("06 "):
            t = fix_06(t)
        if t != t0:
            p.write_text(t, encoding="utf-8")
            log.append("changed " + f)
    print("\n".join(log))


if __name__ == "__main__":
    main()
