import sys, glob, os
S, SRC = sys.argv[1], sys.argv[2]
ICI = os.path.dirname(os.path.abspath(__file__))
sim = S + "/sim/"
def lire(p): return open(p, encoding="utf-8").read()
def nom(chemin): return os.path.basename(chemin)[: -len(".luau")]
ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn =
	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir
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
# Tous les modules partagés sont chargés automatiquement
modules = sorted(glob.glob(SRC + "/shared/*.luau"))
for chemin in modules:
    out.append(f"MODULES[\"{nom(chemin)}\"] = function(script)\n" + ENTETE + lire(chemin) + "\nend")
out.append("local NOMS_MODULES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules) + " }")
out.append("local SCRIPTS = {}")
for nomScript, chemin in [("AtelierServer", "server/AtelierServer.server.luau"),
                          ("AtelierClient", "client/AtelierClient.client.luau")]:
    out.append(f"SCRIPTS[\"{nomScript}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
# Tests unitaires (tests/unitaires/*.luau), exécutés avant le scénario
out.append(OUTILS_UNITAIRES)
for f in sorted(glob.glob(ICI + "/unitaires/*.luau")):
    out.append("do\n" + ENTETE + lire(f) + "\nend")
out.append("print((\"Unitaires : %d vérifications\"):format(U.compte))")
out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
