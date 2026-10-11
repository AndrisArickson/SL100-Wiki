"""Full re-listing of Category:Legends articles, compared with the local DB. Resumable: run repeatedly until it says DONE.
Writes meta/verify_missing.tsv (titles in the live category that we do not have)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
import common as C
con = C.db_connect()
CFG = C.CFG
sf = os.path.join(C.ROOT, "data", "verify_state.json")
st = json.load(open(sf)) if os.path.exists(sf) else {"cont": None, "seen": 0, "missing": []}
t0 = time.time()
while time.time() - t0 < float(os.environ.get("VERIFY_SECONDS", "140")):
    p = dict(action="query", list="categorymembers", cmtitle=CFG["legends_category"], cmlimit="500", cmprop="ids|title|type", cmtype="page")
    if st["cont"]:
        p["cmcontinue"] = st["cont"]
    r = C.api(**p)
    mem = r["query"]["categorymembers"]
    have = {t for (t,) in con.execute("SELECT title FROM pages WHERE title IN (%s)" % ",".join("?" * len(mem)), [m["title"] for m in mem])} if mem else set()
    st["missing"] += [[m["title"], m["ns"]] for m in mem if m["title"] not in have]
    st["seen"] += len(mem)
    st["cont"] = r.get("continue", {}).get("cmcontinue")
    json.dump(st, open(sf, "w"))
    if not st["cont"]:
        open(os.path.join(C.ROOT, "meta", "verify_missing.tsv"), "w").write("".join("%s\t%s\n" % tuple(x) for x in st["missing"]))
        print("DONE: live category lists %d pages; %d are missing locally" % (st["seen"], len(st["missing"])))
        sys.exit(0)
print("partial: %d seen, %d missing so far - run again" % (st["seen"], len(st["missing"])))
