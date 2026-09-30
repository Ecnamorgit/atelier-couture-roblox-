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
		return def.style, (a.longueur or 0) / 5 -- points proportionnels à la longueur (valeurs du catalogue pour 5 dm)
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

-- Jauges du carnet : choix = { [idPiece] = idTissu ou nil } ; accessoires = accessoires imposés par
-- la commande ({ { id } }, voir accessoiresImposes), qui seront forcément sur la robe.
-- Retourne { [style] = { acquis, min, max } } : acquis = points des variantes seules,
-- min / max = fourchette possible selon les tissus encore à choisir.
function Notation.fourchette(croquis, choix, accessoires)
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
		for _, a in ipairs(accessoires or {}) do
			local style, fois = pointsAccessoire(a)
			bas += K.accessoires * (style[s] or 0) * fois
			haut += K.accessoires * (style[s] or 0) * fois
		end
		out[s] = {
			acquis = base[s],
			min = math.clamp(brutAcquis + bas, 0, 100),
			max = math.clamp(brutAcquis + haut, 0, 100),
		}
	end
	return out
end

-- Accessoires qu'une commande impose : { { id } }
function Notation.accessoiresImposes(exigences)
	local out = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			table.insert(out, { id = e.id })
		end
	end
	return out
end

-- Teinte dominante : surfaces additionnées par couleur (deux tissus roses comptent ensemble).
-- À égalité, la couleur de la première pièce. pieces = { { id, tissu } } dans l'ordre du croquis.
function Notation.teinteDominante(pieces)
	local parTeinte = {}
	for _, p in ipairs(pieces) do
		local t = Catalogue.tissu(p.tissu).teinte
		parTeinte[t] = (parTeinte[t] or 0) + Patron.aire(p.id)
	end
	local teinte, aireMax = nil, -1
	for _, p in ipairs(pieces) do
		local t = Catalogue.tissu(p.tissu).teinte
		if parTeinte[t] > aireMax + 1e-9 then
			teinte, aireMax = t, parTeinte[t]
		end
	end
	return teinte
end

-- Prévision du carnet pour une exigence : "ok", "non", ou "?" (dépend des tissus encore à choisir,
-- de la couture ou des décorations). fourchette = Notation.fourchette(croquis, choix, imposés).
function Notation.prevision(e, croquis, choix, fourchette, ajustement)
	if e.type == "qualite" and ajustement and e.valeur > ajustement then
		return "non" -- la qualité est multipliée par l'ajustement : celle-ci est hors d'atteinte
	elseif e.type == "min" then
		local f = fourchette[e.style]
		return f.min >= e.valeur - 1e-9 and "ok" or (f.max < e.valeur - 1e-9 and "non" or "?")
	elseif e.type == "max" then
		local f = fourchette[e.style]
		return f.max <= e.valeur + 1e-9 and "ok" or (f.min > e.valeur + 1e-9 and "non" or "?")
	elseif e.type == "teinte" then
		local pieces = {}
		for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
			if not choix[id] then
				return "?"
			end
			table.insert(pieces, { id = id, tissu = choix[id] })
		end
		return Notation.teinteDominante(pieces) == e.teinte and "ok" or "non"
	end
	return "?" -- qualité (à la couture) et accessoire (aux décorations)
end

---------------------------------------------------------------------------
-- Bilan d'une recette, exigences, paie
---------------------------------------------------------------------------
-- Ajustement de la robe à la cliente (sous-projet 2) : 1 si les mesures prises sont justes à 0,2 dm près ;
-- chaque écart au-delà coûte (1,5 dm d'écart en tout : 0), jamais sous 50 %
Notation.TOLERANCE_MESURE = 0.2
Notation.PENTE_MESURE = 1.5
function Notation.ajustement(vraies, prises)
	local total = 0
	for _, cle in ipairs({ "poitrine", "taille", "hanches" }) do
		total += math.max(0, math.abs(prises[cle] - vraies[cle]) - Notation.TOLERANCE_MESURE)
	end
	return math.clamp(1 - total / Notation.PENTE_MESURE, 0.5, 1)
end

-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
function Notation.bilan(recette)
	local tissus, piecesNotees = {}, {}
	for _, p in ipairs(recette.pieces) do
		assert(Catalogue.tissu(p.tissu), "tissu inconnu : " .. tostring(p.tissu))
		local aire = Patron.aire(p.id)
		tissus[p.tissu] = (tissus[p.tissu] or 0) + aire
		local df = Notation.droitFil(Notation.angleFil(p.angle, p.id), Catalogue.piece(p.id).biais)
		table.insert(piecesNotees, { aire = aire, droitFil = df, couture = p.couture or 0 })
	end
	local teinte = Notation.teinteDominante(recette.pieces)
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
		if e.type == "min" then -- (à l'arrondi près : un score qui s'affiche 30 vaut 30)
			ok = bilan.styles[e.style] >= e.valeur - 1e-9
		elseif e.type == "max" then
			ok = bilan.styles[e.style] <= e.valeur + 1e-9
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
