-- Notation : droit-fil, couture, qualité, jauges de style, exigences des commandes et paie.
-- Utilisé par le serveur (qui fait foi) et par le client (affichage en direct).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Notation = {}

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

---------------------------------------------------------------------------
-- Droit-fil
---------------------------------------------------------------------------
-- Points de référence (angle modulo 180° → note), interpolés linéairement
local FIL_NORMAL = { { 0, 1 }, { 45, 0.6 }, { 90, 0.75 }, { 135, 0.6 }, { 180, 1 } }
local FIL_BIAIS = { { 0, 0.7 }, { 45, 1 }, { 90, 0.7 }, { 135, 1 }, { 180, 0.7 } }
local AIMANTATION = 6 -- degrés
local ANGLE_MAX = 3600 -- au-delà, le modulo perd sa précision (même borne que Coupon)

-- theta : angle (degrés) entre la flèche de droit-fil de la pièce et la chaîne du tissu
function Notation.droitFil(theta, biais)
	if not fini(theta) or math.abs(theta) > ANGLE_MAX then
		return 0 -- valeur invalide : jamais 100 %
	end
	local t = theta % 180
	local points = biais and FIL_BIAIS or FIL_NORMAL
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if t <= b[1] then
			return a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])
		end
	end
	return points[#points][2]
end

-- Angle de la flèche de droit-fil sur le rouleau pour une pièce posée à « angle »
function Notation.angleFil(angle, idPiece)
	return angle + (Catalogue.piece(idPiece).droitFil or 0)
end

-- Aligne exactement la pièce sur un angle à 100 % si elle en est à moins de 6°
function Notation.aimanter(angle, idPiece)
	local def = Catalogue.piece(idPiece)
	local theta = Notation.angleFil(angle, idPiece)
	for _, cible in ipairs(def.biais and { 45, 135 } or { 0 }) do
		local ecart = (theta - cible + 90) % 180 - 90
		if math.abs(ecart) <= AIMANTATION then
			return angle - ecart
		end
	end
	return angle
end

---------------------------------------------------------------------------
-- Couture et qualité
---------------------------------------------------------------------------
-- ecarts : écarts (dm) de l'aiguille à la ligne, une mesure tous les 0,1 dm de trajet
function Notation.noteCouture(ecarts, assistance)
	if #ecarts == 0 then
		return 0
	end
	local somme = 0
	for _, e in ipairs(ecarts) do
		if fini(e) then -- une mesure invalide compte comme ratée
			somme += math.clamp(1 - (math.abs(e) - 0.05) / 0.25, 0, 1)
		end
	end
	local note = somme / #ecarts
	if assistance then
		note = math.min(note, Catalogue.PLAFOND_ASSISTANCE)
	end
	return note
end

-- pieces = { { aire, droitFil, couture } } → qualité de la robe (moyenne pondérée par la surface)
function Notation.qualite(pieces)
	local total, aires = 0, 0
	for _, p in ipairs(pieces) do
		total += p.aire * p.droitFil * p.couture
		aires += p.aire
	end
	return aires > 0 and math.clamp(total / aires, 0, 1) or 0
end

---------------------------------------------------------------------------
-- Style
---------------------------------------------------------------------------
-- Longueur (dm) d'une garniture posée sur une pièce : trajet = { { u, v } } dans la boîte du patron
function Notation.longueurGarniture(idPiece, trajet)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local total = 0
	for i = 2, #trajet do
		local du, dv = (trajet[i].u - trajet[i - 1].u) * l, (trajet[i].v - trajet[i - 1].v) * h
		local d = math.sqrt(du * du + dv * dv)
		if fini(d) then -- un point non fini ne compte pas (jamais de NaN dans les prix ou les styles)
			total += d
		end
	end
	return total
end

local function pointsAccessoire(a)
	local def = Catalogue.accessoire(a.id)
	assert(def, "accessoire inconnu : " .. tostring(a.id))
	if def.genre == "garniture" then
		return def.style, math.ceil((a.longueur or 0) / 5 - 1e-9)
	end
	return def.style, 1
end

-- entree = { croquis, tissus = { [idTissu] = aire }, accessoires = { { id, longueur? } } }
-- Retourne { [style] = score de 0 à 100 }
function Notation.styles(entree)
	local K = Catalogue.K
	local brut = {}
	for _, s in ipairs(Catalogue.STYLES) do
		brut[s] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for s, pts in pairs(Catalogue.variante(entree.croquis[famille]).style) do
			brut[s] += K.pieces * pts
		end
	end
	local aireTotale = 0
	for _, aire in pairs(entree.tissus) do
		aireTotale += aire
	end
	if aireTotale > 0 then
		for idTissu, aire in pairs(entree.tissus) do
			for s, pts in pairs(Catalogue.tissu(idTissu).style) do
				brut[s] += K.tissu * pts * aire / aireTotale
			end
		end
	end
	for _, a in ipairs(entree.accessoires or {}) do
		local style, fois = pointsAccessoire(a)
		for s, pts in pairs(style) do
			brut[s] += K.accessoires * pts * fois
		end
	end
	local scores = {}
	for s, v in pairs(brut) do
		scores[s] = math.clamp(v, 0, 100)
	end
	return scores
end

-- Jauges du carnet : choix = { [idPiece] = idTissu ou nil }.
-- Retourne { [style] = { acquis, min, max } } : acquis = points des variantes seules,
-- min / max = fourchette possible selon les tissus encore à choisir.
function Notation.fourchette(croquis, choix)
	local K = Catalogue.K
	local pieces = Patron.piecesDuCroquis(croquis)
	local aireTotale = 0
	for _, id in ipairs(pieces) do
		aireTotale += Patron.aire(id)
	end
	local base = Notation.styles({ croquis = croquis, tissus = {}, accessoires = {} })
	local out = {}
	for _, s in ipairs(Catalogue.STYLES) do
		local mini, maxi = math.huge, -math.huge
		for _, t in ipairs(Catalogue.Tissus) do
			mini, maxi = math.min(mini, t.style[s] or 0), math.max(maxi, t.style[s] or 0)
		end
		local bas, haut = 0, 0
		for _, id in ipairs(pieces) do
			local part = Patron.aire(id) / aireTotale
			local idTissu = choix[id]
			if idTissu then
				local pts = Catalogue.tissu(idTissu).style[s] or 0
				bas += K.tissu * pts * part
				haut += K.tissu * pts * part
			else
				bas += K.tissu * mini * part
				haut += K.tissu * maxi * part
			end
		end
		local brutAcquis = 0
		for _, famille in ipairs(Catalogue.FAMILLES) do
			brutAcquis += K.pieces * (Catalogue.variante(croquis[famille]).style[s] or 0)
		end
		out[s] = {
			acquis = base[s],
			min = math.clamp(brutAcquis + bas, 0, 100),
			max = math.clamp(brutAcquis + haut, 0, 100),
		}
	end
	return out
end

---------------------------------------------------------------------------
-- Bilan d'une recette, exigences, paie
---------------------------------------------------------------------------
-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
function Notation.bilan(recette)
	local tissus, piecesNotees, parTeinte = {}, {}, {}
	local teinte, aireMax = nil, -1
	for _, p in ipairs(recette.pieces) do
		assert(Catalogue.tissu(p.tissu), "tissu inconnu : " .. tostring(p.tissu))
		local aire = Patron.aire(p.id)
		tissus[p.tissu] = (tissus[p.tissu] or 0) + aire
		local df = Notation.droitFil(Notation.angleFil(p.angle, p.id), Catalogue.piece(p.id).biais)
		table.insert(piecesNotees, { aire = aire, droitFil = df, couture = p.couture or 0 })
	end
	-- Teinte dominante : surfaces additionnées par couleur (deux tissus roses comptent ensemble)
	for idTissu, aire in pairs(tissus) do
		local t = Catalogue.tissu(idTissu).teinte
		parTeinte[t] = (parTeinte[t] or 0) + aire
	end
	for _, p in ipairs(recette.pieces) do
		local t = Catalogue.tissu(p.tissu).teinte
		if parTeinte[t] > aireMax then
			teinte, aireMax = t, parTeinte[t]
		end
	end
	local accessoires, comptes = {}, {}
	for _, a in ipairs(recette.accessoires or {}) do
		local entree = { id = a.id }
		if a.trajet then
			entree.longueur = Notation.longueurGarniture(recette.pieces[a.piece].id, a.trajet)
		end
		table.insert(accessoires, entree)
		comptes[a.id] = (comptes[a.id] or 0) + 1
	end
	return {
		styles = Notation.styles({ croquis = recette.croquis, tissus = tissus, accessoires = accessoires }),
		qualite = Notation.qualite(piecesNotees),
		teinte = teinte,
		accessoires = comptes,
		nbPieces = #recette.pieces,
	}
end

-- exigences : { { type = "min"|"max", style, valeur } | { type = "qualite", valeur }
--              | { type = "teinte", teinte } | { type = "accessoire", id } }
-- Retourne ok, et la liste des indices des exigences ratées
function Notation.verifierExigences(exigences, bilan)
	local ratees = {}
	for i, e in ipairs(exigences) do
		local ok
		if e.type == "min" then
			ok = bilan.styles[e.style] >= e.valeur
		elseif e.type == "max" then
			ok = bilan.styles[e.style] <= e.valeur
		elseif e.type == "qualite" then
			ok = bilan.qualite >= e.valeur - 1e-9
		elseif e.type == "teinte" then
			ok = bilan.teinte == e.teinte
		elseif e.type == "accessoire" then
			ok = (bilan.accessoires[e.id] or 0) > 0
		else
			error("exigence inconnue : " .. tostring(e.type))
		end
		if not ok then
			table.insert(ratees, i)
		end
	end
	return #ratees == 0, ratees
end

function Notation.base(nbPieces, nbExigences)
	return 20 + 10 * nbPieces + 15 * nbExigences
end

function Notation.paie(nbPieces, nbExigences, qualite)
	return math.floor(Notation.base(nbPieces, nbExigences) * (0.5 + qualite) + 0.5)
end

return Notation
