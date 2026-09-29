-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, jamais un « au plus » dans ses styles ; elle est réalisable
-- avec ce que le joueur a ouvert (déblocages), et ses exigences de style montent avec son prestige.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Notation = require(dossier:WaitForChild("Notation"))
local Deblocages = require(dossier:WaitForChild("Deblocages"))
local Progression = require(dossier:WaitForChild("Progression"))

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
-- La qualité est supposée atteignable (≤ 0,9). ouverts (facultatif, Deblocages.ouverts) : seulement avec ce
-- qui est ouvert. Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences, ouverts)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if ouverts and accessoireImpose and not ouverts.accessoires[accessoireImpose] then
		return false
	end
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local permis = not ouverts
				or (ouverts.tissus[t.id] and ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe])
			local bilan = permis and {
				styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }),
				qualite = 1,
				teinte = t.teinte,
				accessoires = accessoireImpose and { [accessoireImpose] = 1 } or {},
			}
			if bilan and Notation.verifierExigences(exigences, bilan) then
				return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
			end
		end
	end
	return false
end

local function tirer(liste, rng)
	return liste[rng:NextInteger(1, #liste)]
end

-- plafond : dizaines de points au plus pour le style demandé (monte avec le prestige) ; ouverts : accessoires
-- qu'on peut demander (nil : tous)
local function tirerExigences(rng, cliente, plafond, ouverts)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, plafond) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin and not (cliente and table.find(cliente.styles, style))
			table.insert(exigences, { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 })
		elseif genre == "qualite" then
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 })
		elseif genre == "teinte" then
			table.insert(exigences, { type = "teinte", teinte = cliente and cliente.teinte or tirer(Catalogue.Tissus, rng).teinte })
		else
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
					table.insert(objets, a.id)
				end
			end
			table.insert(exigences, { type = "accessoire", id = tirer(objets, rng) })
		end
	end
	return exigences
end

-- Dizaines de points au plus pour le style demandé : 5 au prestige 1, puis une de plus par niveau, 8 au plus
function Commandes.plafond(niveauPrestige)
	return math.min(8, 4 + niveauPrestige)
end

-- rng : un objet Random ; cliente (facultatif) : une fiche de Clientes ; progres (facultatif) : le prestige et
-- les amitiés du joueur (l'état de l'atelier convient). Retourne { taille, mesures, exigences } (anonyme), ou
-- { cliente, taille, exigences } : ses mesures seront prises à l'atelier.
function Commandes.generer(rng, cliente, progres)
	local ouverts = progres and Deblocages.ouverts(progres)
	local plafond = progres and Commandes.plafond(Progression.niveauPrestige(progres.prestige)) or 7
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts)
		if Commandes.realisable(candidat, ouverts) then
			exigences = candidat
			break
		end
	end
	exigences = exigences or { { type = "min", style = cliente and cliente.styles[1] or "decontracte", valeur = 20 } }
	if cliente then
		return { cliente = cliente.id, taille = cliente.taille, exigences = exigences }
	end
	local taille = tirer(NOMS_TAILLES, rng)
	return { taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = exigences }
end

return Commandes
