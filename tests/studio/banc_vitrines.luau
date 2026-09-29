-- Banc des vitrines et de la génération étalée, à exécuter dans Studio en mode Play, côté client
-- (connecteur MCP Studio : execute_luau, datamodel « Client »). Il n'est pas lancé par tests/lancer.sh.
-- 1. Budget libre de maillages modifiables avant l'essai.
-- 2. Trois vitrines (étalement réel, task.wait) dont une robe à manches longues rayées (pièce pliée).
-- 3. Le joueur s'éloigne pendant la première construction, revient, puis un socle est détruit en cours de route.
-- 4. Budget libre après l'essai : identique au départ = aucun objet modifiable oublié.
local RS = game:GetService("ReplicatedStorage"):WaitForChild("Couture")
local AssetService = game:GetService("AssetService")
local LogService = game:GetService("LogService")
local Catalogue = require(RS.Catalogue)
local Recette = require(RS.Recette)
local Vitrines = require(RS.Vitrines)

local function budgetLibre()
	local liste = {}
	for k = 1, 20 do
		local em = AssetService:CreateEditableMesh()
		if not em then
			break
		end
		liste[k] = em
	end
	for _, em in ipairs(liste) do
		em:Destroy()
	end
	return #liste
end

local messages = {}
local ecoute = LogService.MessageOut:Connect(function(texte, genre)
	if genre == Enum.MessageType.MessageWarning or genre == Enum.MessageType.MessageError then
		table.insert(messages, texte)
	end
end)

local avant = budgetLibre()
local ancien = workspace:FindFirstChild("Vitrines")
if ancien then
	ancien:Destroy()
end
local dossier = Instance.new("Folder")
dossier.Name = "Vitrines"
dossier.Parent = workspace
local function recette(corsage, manches, tissu, angle)
	local r = {
		croquis = { corsage = corsage, manches = manches, col = "col_sans", jupe = "jupe_trapeze" },
		mesures = table.clone(Catalogue.TAILLES.M),
		pieces = {},
		accessoires = { { id = "noeud_satin", piece = 1, u = 0.5, v = 0.9, echelle = 1, angle = 0 } },
	}
	local ids = { corsage .. "_devant", corsage == "corsage_v" and "corsage_droit_dos" or corsage .. "_dos" }
	if manches == "manches_longues" then
		table.insert(ids, "manche_longue")
	end
	table.insert(ids, "jupe_trapeze_devant")
	table.insert(ids, "jupe_trapeze_dos")
	for i, id in ipairs(ids) do
		table.insert(r.pieces, { id = id, tissu = tissu, x = 3, y = 3 + 7 * i, angle = angle, couture = 1 })
	end
	return r
end
local socles = {}
for i, r in ipairs({
	recette("corsage_droit", "manches_longues", "lin_vert_rayures", 0),
	recette("corsage_v", "manches_sans", "soie_rose_fleurs", 45),
	recette("corsage_bretelles", "manches_sans", "velours_noir", 0),
}) do
	assert(Recette.valider(r))
	local s = Instance.new("Part")
	s.Name = "Socle" .. i
	s.Anchored = true
	s.Size = Vector3.new(4, 1, 4)
	s.CFrame = CFrame.new(-40 + 6 * i, 0.5, -40) * CFrame.Angles(0, math.pi, 0)
	s:SetAttribute("Recette", Recette.encoder(r))
	s.Parent = dossier
	socles[i] = s
end

local pres, loin = Vector3.new(-28, 3, -30), Vector3.new(200, 3, 200)
local ici = pres
local v = Vitrines.nouveau(dossier, function()
	return ici
end)
task.wait(0.8) -- la première vitrine est en cours de construction
ici = loin
task.wait(1.2) -- libérée
local libereeEnRoute = socles[1]:FindFirstChild("Exposition") == nil
ici = pres
task.wait(1.5)
socles[2]:Destroy() -- détruit pendant sa construction ou juste après
task.wait(8)
local construites = 0
for _, s in ipairs(socles) do
	local expo = s.Parent and s:FindFirstChild("Exposition")
	if expo and expo:FindFirstChild("Robe") then
		construites += 1
	end
end
v.arreter()
task.wait(0.5)
local apres = budgetLibre()
ecoute:Disconnect()
return ("budgetAvant=%d budgetApres=%d libereeEnRoute=%s construitesAvantArret=%d messages=%d %s"):format(
	avant, apres, tostring(libereeEnRoute), construites, #messages, table.concat(messages, " | "))
