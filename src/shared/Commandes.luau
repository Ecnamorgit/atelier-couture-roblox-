-- Commandes : génère des commandes de clientes anonymes, toujours réalisables avec le catalogue.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Notation = require(dossier:WaitForChild("Notation"))

local Commandes = {}

local NOMS_TAILLES = { "S", "M", "L" }
local ESSAIS = 30

-- Toutes les combinaisons de variantes du carnet (3 × 3 × 3 × 4 = 108)
local function croquisPossibles()
	local out = {}
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		for _, m in ipairs(Catalogue.variantesDe("manches")) do
			for _, k in ipairs(Catalogue.variantesDe("col")) do
				for _, j in ipairs(Catalogue.variantesDe("jupe")) do
					table.insert(out, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				end
			end
		end
	end
	return out
end
local CROQUIS = croquisPossibles()

-- Cherche une robe simple (un seul tissu, au plus l'accessoire imposé) qui remplit les exigences.
-- La qualité est supposée atteignable (≤ 0,9). Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local bilan = {
				styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }),
				qualite = 1,
				teinte = t.teinte,
				accessoires = accessoireImpose and { [accessoireImpose] = 1 } or {},
			}
			if Notation.verifierExigences(exigences, bilan) then
				return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
			end
		end
	end
	return false
end

local function tirer(liste, rng)
	return liste[rng:NextInteger(1, #liste)]
end

local function tirerExigences(rng)
	local exigences = {}
	local styleMin = tirer(Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, 7) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin
			table.insert(exigences, { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 })
		elseif genre == "qualite" then
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 })
		elseif genre == "teinte" then
			table.insert(exigences, { type = "teinte", teinte = tirer(Catalogue.Tissus, rng).teinte })
		else
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" then
					table.insert(objets, a.id)
				end
			end
			table.insert(exigences, { type = "accessoire", id = tirer(objets, rng) })
		end
	end
	return exigences
end

-- rng : un objet Random. Retourne { taille, mesures, exigences }
function Commandes.generer(rng)
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng)
		if Commandes.realisable(candidat) then
			exigences = candidat
			break
		end
	end
	exigences = exigences or { { type = "min", style = "decontracte", valeur = 20 } }
	local taille = tirer(NOMS_TAILLES, rng)
	return { taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = exigences }
end

return Commandes
