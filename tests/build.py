import sys, glob, os, json
S, SRC = sys.argv[1], sys.argv[2]
ICI = os.path.dirname(os.path.abspath(__file__))
sim = S + "/sim/"
def lire(p): return open(p, encoding="utf-8").read()
def nom(chemin): return os.path.basename(chemin)[: -len(".luau")]
# Le point d'apparition du lieu (default.project.json) n'a pas de bulle de protection : l'avatar est aussitôt
# déplacé à l'entrée de sa boutique, et la bulle le suivrait (le jeu n'a pas de combat)
projet = json.load(open(os.path.join(SRC, "..", "default.project.json"), encoding="utf-8"))
assert projet["tree"]["Workspace"]["SpawnLocation"]["$properties"].get("Duration") == 0,     "SpawnLocation : « Duration » doit valoir 0 (pas de bulle de protection à l'arrivée)"
ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn, Content, RaycastParams =
	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir, G.Content, G.RaycastParams
"""
OUTILS_UNITAIRES = """local U = { compte = 0 }
function U.verifier(condition, message)
	U.compte += 1
	if not condition then
		error("ÉCHEC : " .. message, 2)
	end
end
function U.proche(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end
local dossierUnitaires
function U.module(nomModule)
	if dossierUnitaires and dossierUnitaires.Parent ~= M.services.ReplicatedStorage then
		dossierUnitaires.Parent = M.services.ReplicatedStorage -- un test a réinitialisé le monde
	end
	if not dossierUnitaires then
		M.initialiser()
		dossierUnitaires = M.nouvelleInstance("Folder")
		dossierUnitaires.Name = "Couture"
		dossierUnitaires.Parent = M.services.ReplicatedStorage
		for _, n in ipairs(NOMS_MODULES) do
			local ms = M.nouvelleInstance("ModuleScript")
			ms.Name = n
			ms.Parent = dossierUnitaires
		end
	end
	return requireModule(dossierUnitaires[nomModule])
end
"""
out = []
out.append("local APIDB = (function()\n" + lire(sim + "apidb.luau") + "\nend)()")
out.append("local M = (function()\n" + lire(sim + "mock.luau") + "\nend)()")
out.append("local G = M.env")
out.append("local function avertir(...) table.insert(M.avertissements, table.concat({ ... }, ' ')) end")
out.append("local MODULES, cache, requireModule = {}, {}, nil")
out.append("""requireModule = function(ms)
	local nom = ms.Name
	if cache[nom] == nil then
		cache[nom] = MODULES[nom](ms)
	end
	return cache[nom]
end""")
# Modules partagés, du client et du serveur (sauf les scripts de démarrage) : chargés automatiquement
def sansDemarrage(dossier):
    return sorted(c for c in glob.glob(SRC + dossier + "/*.luau") if not os.path.basename(c).startswith("init."))
modules = sorted(glob.glob(SRC + "/shared/*.luau")) + sansDemarrage("/client/Atelier") + sansDemarrage("/server")
# Un seul espace de noms dans la simulation : deux modules ne peuvent pas porter le même nom
doublons = sorted({nom(c) for c in modules if [nom(m) for m in modules].count(nom(c)) > 1})
assert not doublons, "modules de même nom : " + ", ".join(doublons)
for chemin in modules:
    out.append(f"MODULES[\"{nom(chemin)}\"] = function(script)\n" + ENTETE + lire(chemin) + "\nend")
out.append("local NOMS_MODULES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules) + " }")
# Noms séparés pour le scénario : modules partagés (ReplicatedStorage.Couture) et modules du client (enfants du LocalScript)
out.append("local NOMS_PARTAGES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/shared/" in c.replace("\\", "/")) + " }")
out.append("local NOMS_CLIENT = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/client/" in c.replace("\\", "/")) + " }")
out.append("local NOMS_SERVEUR = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/server/" in c.replace("\\", "/")) + " }")
out.append("local SCRIPTS = {}")
for nomScript, chemin in [("Atelier", "client/Atelier/init.client.luau"), ("Serveur", "server/init.server.luau")]:
    if os.path.exists(SRC + "/" + chemin):
        out.append(f"SCRIPTS[\"{nomScript}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
# Tests unitaires (tests/unitaires/*.luau), exécutés avant le scénario
out.append(OUTILS_UNITAIRES)
for f in sorted(glob.glob(ICI + "/unitaires/*.luau")):
    out.append("do\n" + ENTETE + lire(f) + "\nend")
out.append("print((\"Unitaires : %d vérifications\"):format(U.compte))")
out.append("M.avertissements = {} -- le scénario ne voit pas les avertissements des tests unitaires")
out.append("table.clear(cache) -- le scénario recharge des modules neufs, liés à ses propres instances")
out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
