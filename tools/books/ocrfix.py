#!/usr/bin/env python3
"""Shared repairs for OCR slips in d20 item and ship NAMES (2026-10-12).

The scans of the WotC books often read a bold 'o' as 'ao' (Pistaol, Draoid, Maodified), 'I' as 'l' (lon cannon,
lkas-Adno) and 'q' as 'g' (Mobguet). fix_name() repairs these and a short list of one-off slips, each checked against
the page image. Used by statblocks.py and starships.py.
"""
import re

AO_KEEP = {"haor", "chaos", "kaon", "maori", "laos", "gaol"}          # real words/names containing 'ao'
ONE_OFF = [("Merr-Sann", "Merr-Sonn"), ("Intimidatar", "Intimidator"), ("Ouickfire", "Quickfire"), ("A2B0", "A280"),
           ("Serv-0-Oroid", "Serv-O-Droid"), ("Corparation", "Corporation"), ("Corporatin ", "Corporation "),
           ("Automatan", "Automaton"), ("Mobgquet", "Mobquet"), ("Mobguet", "Mobquet"), ("Firespray-3- ", "Firespray-31 "),
           ("GL-llsa", "GL-11sa"), ("Fleel Systems", "Fleet Systems"), ("Seinar Fleet", "Sienar Fleet"),
           ("Deslroyer", "Destroyer"), ("Assault Armar", "Assault Armor"), ("Yard’'s", "Yards"), ("Maodified", "Modified")]


def fix_word(w):
    core = w.strip("“”\"'()_.,")
    if "ao" in core and core.lower() not in AO_KEEP:
        w = w.replace("ao", "o").replace("Ao", "O")
    return w


def fix_name(n):
    for a, b in ONE_OFF:
        n = n.replace(a, b)
    n = " ".join(fix_word(w) for w in n.split())
    n = re.sub(r"\blon\b", "Ion", n)
    n = re.sub(r"\blan (Pistol|Carbine|Rifle|Cannon)", r"Ion \1", n)
    n = re.sub(r"\bl(?=[A-Z]|kas\b|kas-)", "I", n)                     # lkas-Adno -> Ikas-Adno
    n = n.replace(" _(", " (").replace("“\"", "“").replace("\"”", "”")
    n = re.sub(r'"([^"”]+)”', r"“\1”", n)                               # mixed straight/curly quote pairs
    n = re.sub(r'“([^"”]+)"', r"“\1”", n)
    return re.sub(r"\s{2,}", " ", n).strip()


if __name__ == "__main__":
    import sys
    for a in sys.argv[1:]:
        print(fix_name(a))
