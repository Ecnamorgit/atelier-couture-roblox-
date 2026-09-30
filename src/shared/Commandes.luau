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
Commandes.ESSAIS = 30 -- tirages avant le repli

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

-- Les styles s'additionnent (Notation.styles) : les points bruts de chaque croquis, de chaque tissu (toute la robe
-- dans ce tissu) et de chaque objet imposé sont calculés une fois ; une robe candidate se juge alors en quelques
-- additions, sans rien créer. (Une garniture imposée, sans longueur, ne compte pas : comme dans Notation.styles.)
local K = Catalogue.K
local POINTS_CROQUIS = {}
for i, croquis in ipairs(CROQUIS) do
	local points = {}
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for s, pts in pairs(Catalogue.variante(croquis[famille]).style) do
			points[s] += K.pieces * pts
		end
	end
	POINTS_CROQUIS[i] = points
end
local POINTS_TISSU = {}
for _, t in ipairs(Catalogue.Tissus) do
	local points = {}
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = K.tissu * (t.style[s] or 0)
	end
	POINTS_TISSU[t.id] = points
end
local function pointsImpose(idAccessoire)
	local points = {}
	local def = idAccessoire and Catalogue.accessoire(idAccessoire)
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = if def and def.genre == "objet" then K.accessoires * (def.style[s] or 0) else 0
	end
	return points
end

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
	-- Les exigences les plus fermées d'abord, une fois pour toutes : les accessoires (seul le dernier demandé est
	-- posé sur la robe témoin) et la teinte (seuls les tissus ouverts de cette teinte restent candidats) ;
	-- restent les styles, à vérifier robe par robe (la qualité, au plus 0,9, est tenue d'office)
	local aVerifier = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" and e.id ~= accessoireImpose then
			return false
		elseif e.type == "min" or e.type == "max" then
			table.insert(aVerifier, e)
		end
	end
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		local permis = not ouverts or ouverts.tissus[t.id]
		for _, e in ipairs(exigences) do
			if e.type == "teinte" and e.teinte ~= t.teinte then
				permis = false
			end
		end
		if permis then
			table.insert(tissus, t)
		end
	end
	if #tissus == 0 then
		return false
	end
	local pa = pointsImpose(accessoireImpose)
	for i, croquis in ipairs(CROQUIS) do
		if not ouverts or (ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe]) then
			local pc = POINTS_CROQUIS[i]
			for _, t in ipairs(tissus) do
				local pt = POINTS_TISSU[t.id]
				local ok = true
				for _, e in ipairs(aVerifier) do
					local v = math.clamp(pc[e.style] + pt[e.style] + pa[e.style], 0, 100)
					ok = if e.type == "min" then v >= e.valeur - 1e-9 else v <= e.valeur + 1e-9
					if not ok then
						break
					end
				end
				if ok then
					return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
				end
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
	for _ = 1, Commandes.ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts)
		if Commandes.realisable(candidat, ouverts) then
			exigences = candidat
			break
		end
	end
	-- Repli : un seul style demandé, à 20 puis à 10 ; ceux de la cliente d'abord, puis les autres ; toujours
	-- réalisable avec ce qui est ouvert
	if not exigences then
		local styles = cliente and table.clone(cliente.styles) or {}
		for _, s in ipairs(Catalogue.STYLES) do
			if not table.find(styles, s) then
				table.insert(styles, s)
			end
		end
		for _, valeur in ipairs({ 20, 10 }) do
			for _, s in ipairs(styles) do
				local candidat = { { type = "min", style = s, valeur = valeur } }
				if not exigences and Commandes.realisable(candidat, ouverts) then
					exigences = candidat
				end
			end
		end
		exigences = exigences or { { type = "qualite", valeur = 0.5 } }
	end
	if cliente then
		return { cliente = cliente.id, taille = cliente.taille, exigences = exigences }
	end
	local taille = tirer(NOMS_TAILLES, rng)
	return { taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = exigences }
end

return Commandes
