import re, sys, glob
S = sys.argv[1]; SRC = sys.argv[2]
lines = open(S + "/globalTypes.d.luau", encoding="utf-8").read().split("\n")
classes = {}; enums = {}
cur = None
for ln in lines:
    # Deux formats : « declare class X extends Y » (luau-lsp 1.5x) et « declare extern type X extends Y with » (1.6x et plus)
    m = re.match(r"^declare (?:class|extern type) (\w+)(?: extends (\w+))?(?: with)?(.*)$", ln)
    if m:
        name, parent, rest = m.group(1), m.group(2), m.group(3)
        cur = {"parent": parent, "props": {}, "methods": set()}
        if name.startswith("Enum") and name.endswith("_INTERNAL"):
            enums[name[4:-9]] = cur
        else:
            classes[name] = cur
        if rest.strip() == "end":
            cur = None
        continue
    if cur is None: continue
    if ln.startswith("end"): cur = None; continue
    m = re.match(r"^\t+(?:function (\w+)\(.*|(\w+): (.+))$", ln)
    if m:
        if m.group(1): cur["methods"].add(m.group(1))
        else: cur["props"][m.group(2)] = m.group(3).strip()

# Vérification statique des Enum.X.Y dans le code source
bad = []
src_all = ""
for f in glob.glob(SRC + "/**/*.luau", recursive=True):
    txt = open(f, encoding="utf-8").read(); src_all += txt
    for m in re.finditer(r"Enum\.(\w+)\.(\w+)", txt):
        e, item = m.group(1), m.group(2)
        if e not in enums or item not in enums[e]["props"]:
            bad.append(f"{f}: Enum.{e}.{item}")
print("ENUM CHECK:", "OK" if not bad else bad, file=sys.stderr)

# Classes nécessaires (+ ancêtres)
needed = set(re.findall(r'Instance\.new\("(\w+)"', src_all)) | set(re.findall(r'creer\(\s*"(\w+)"', src_all))
needed |= {"Workspace","Players","ReplicatedStorage","DataStoreService","UserInputService","RunService",
           "ContextActionService","ProximityPromptService","Player","Model","Folder","ModuleScript","Script",
           "LocalScript","Camera","Humanoid","Part","MeshPart","PlayerGui","DataModel","IntValue","RemoteFunction","ServerScriptService","StarterPlayer","StarterPlayerScripts","SpawnLocation"}
def anc(c):
    out = []
    while c:
        out.append(c); c = classes.get(c, {}).get("parent")
    return out
allc = set()
for c in needed:
    if c not in classes: print("CLASSE INCONNUE:", c, file=sys.stderr); continue
    allc |= set(anc(c))
def q(s): return '"' + s.replace('\\','\\\\').replace('"','\\"') + '"'
out = ["return {"]
for c in sorted(allc):
    d = classes[c]
    props = ", ".join(f"[{q(k)}] = {q(v)}" for k, v in sorted(d["props"].items()))
    meths = ", ".join(f"[{q(k)}] = true" for k in sorted(d["methods"]))
    par = q(d["parent"]) if d["parent"] and d["parent"] in classes else "nil"
    out.append(f"\t[{q(c)}] = {{ parent = {par}, props = {{ {props} }}, methods = {{ {meths} }} }},")
out.append("}")
open(S + "/sim/apidb.luau", "w", encoding="utf-8").write("\n".join(out))
print("classes:", len(allc), file=sys.stderr)
