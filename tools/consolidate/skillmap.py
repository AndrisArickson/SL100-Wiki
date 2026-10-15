"""Weapon-skill consolidation map (13 Oct 2026 ruling). Old specialisation -> new.
Ranged: Archaic | Blaster | Exotic | Ordnance | Thrown.  Melee: 1H | 2H | Brawling | Lightsaber.
15 Oct 2026: choices are written with slashes in that order, e.g. Melee (1H/2H), Ranged (Blaster/Ordnance);
apply() normalises "X or Y" / "X, Y" weapon choices to that form."""
import re
RENAME = [
    # multi-choice phrases first
    (r"Ranged \(Blaster Pistol, Blaster Rifle, Heavy Blaster or Missile/Rocket\)", "Ranged (Blaster/Ordnance)"),
    (r"Ranged \(Blaster Pistol, Blaster Rifle(?:,| or) Heavy Blaster\)", "Ranged (Blaster)"),
    (r"Ranged \(Blaster Pistol or Blaster Rifle\)", "Ranged (Blaster)"),
    (r"Ranged \(Blaster Pistol, Blaster Rifle, Heavy Blaster, Slugthrower, Bowcaster, Disruptor, Grenade/Explosives, Missile/Rocket, Sniper\)",
     "Ranged (Archaic/Blaster/Exotic/Ordnance/Thrown)"),
    (r"Melee \(Brawling, Vibroblade, Vibro-Axe, Force Pike, \\?\*?Lightsaber, Electrostaff, Stun Baton, Parry, Two-Handed\)",
     "Melee (1H/2H/Brawling/\\*Lightsaber)"),
    (r"Ranged \((?:Blaster Pistol|Blaster Rifle|Heavy Blaster|Disruptor|Sniper|Blaster Carbine)\)", "Ranged (Blaster)"),
    (r"Ranged \((?:Slugthrower|Bow|Crossbow|Sling|Bowcaster|Blackpowder)\)", "Ranged (Archaic)"),
    (r"Ranged \((?:Throwing|Grenade/Explosives|Grenade|Explosives)\)", "Ranged (Thrown)"),
    (r"Ranged \((?:Missile/Rocket|Missile|Rocket|Engineering)\)", "Ranged (Ordnance)"),
    (r"Ranged \(Entangling\)", "Ranged (Exotic)"),
    (r"Ranged \(Long[-–]Extreme Range\)", "Ranged (Any) at Long or Extreme Range"),
    (r"Melee \(Electrostaff or Two-Handed\)", "Melee (2H)"),
    (r"Melee \((?:Vibroblade|Basic|Fencing|Stun Baton|Parry)\)", "Melee (1H)"),
    (r"Melee \((?:Two-Handed|Force Pike|Vibro-Axe|Electrostaff|Cavalry|Polearm|Flail)\)", "Melee (2H)"),
    (r"Melee \(\\?\*Lightsaber\)", "Melee (Lightsaber)"),
    (r"Melee \((?:any one|any|Any Weapon|Any melee Weapon|Any)\)", "Melee (Any)"),
    (r"Ranged \((?:any one|any)\)", "Ranged (Any)"),
    (r"Melee Brawling", "Melee (Brawling)"),
    # --- specialisation spelling normalisation (13 Oct consistency pass)
    (r"Entertain \(Act\)", "Entertain (Acting)"), (r"Entertain \(Sing\)", "Entertain (Singing)"),
    (r"Perform \(Oratory\)", "Entertain (Speeches)"), (r"Lore \(Local \(world\)\)", "Lore (Local)"),
    (r"Play \(Any instrument\)", "Play (Any)"), (r"\((any one|any)\)", "(Any)"),
    (r"Lore \(Galactic Republic or Galactic Empire,? by era\)", "Lore (Galactic Republic or Galactic Empire)"),
    (r"Language \(Old Tongue\)", "Language (Old Galactic Standard)"),
    (r"Ride \((?:Creature|Bantha|Tauntaun|Dewback)\)", "Ride (Land)"),
    (r"Perform \(Dance\)", "Perform (Dancing)"), (r"Lore \(Force Lore\b[^)]*\)", "Lore (The Force)"),
    (r"Profession \(Cartographer\)", "Profession (Stellar Cartographer)"),
    (r"Briberyr\b", "Briber"), (r"Stout-hearted", "Stout-Hearted"),
]
ORDER = {"Melee": ["1H", "2H", "Brawling", "Lightsaber"], "Ranged": ["Archaic", "Blaster", "Exotic", "Ordnance", "Thrown"]}

def _slash(m):
    group, inner = m.group(1), m.group(2)
    parts = [p.strip() for p in re.split(r"\s*(?:/|,| or )\s*", inner) if p.strip()]
    if len(parts) > 1 and all(p in ORDER[group] for p in parts):
        return f"{group} ({'/'.join(sorted(set(parts), key=ORDER[group].index))})"
    return m.group(0)

def apply(text):
    for pat, rep in RENAME:
        text = re.sub(pat, rep, text)
    return re.sub(r"\b(Melee|Ranged) \(([^()]*)\)", _slash, text)
