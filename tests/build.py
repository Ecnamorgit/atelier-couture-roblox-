import sys
S, SRC = sys.argv[1], sys.argv[2]
sim = S + "/sim/"
def lire(p): return open(p, encoding="utf-8").read()
ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn =
	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir
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
out.append("local SCRIPTS = {}")
for nom, chemin, table_ in [("CoutureData", "shared/CoutureData.luau", "MODULES"),
                            ("Rendu3D", "shared/Rendu3D.luau", "MODULES"),
                            ("AtelierServer", "server/AtelierServer.server.luau", "SCRIPTS"),
                            ("AtelierClient", "client/AtelierClient.client.luau", "SCRIPTS")]:
    out.append(f"{table_}[\"{nom}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
