-- Patron : pièces à poser pour un croquis, trajets de couture, et enroulement 3D des pièces
-- autour du corps. Repère du corps (en dm) : origine au centre de la taille, Y vers le haut,
-- devant vers −Z, droite du personnage vers +X (comme un avatar Roblox).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Patron = {}

-- Ellipse du buste et des hanches : plus large que profonde
local EX, EZ = 1.12, 0.88
local LIGNE_HANCHES = 1.8 -- dm sous la taille
local LIGNE_POITRINE = 2.4 -- dm au-dessus de la taille
local HAUTEUR_EPAULE = 4.0
local HAUTEUR_COU, RAYON_COU = 4.3, 0.62
local INCLINAISON_BRAS = math.rad(12)

local function lisse(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Patron.def(id)
	local def = Catalogue.piece(id)
	assert(def, "pièce inconnue : " .. tostring(id))
	return def
end

-- Copies obtenues à la découpe : { "gauche", "droite" } si coupée pliée, sinon { "unique" }
function Patron.copies(id)
	return Patron.def(id).pliee and { "gauche", "droite" } or { "unique" }
end

-- Surface de tissu d'une pièce, toutes copies comprises (dm²)
function Patron.aire(id)
	local def = Patron.def(id)
	return Polygone.aire(def.contour) * #Patron.copies(id)
end

-- croquis = { corsage = idVariante, manches = …, col = …, jupe = … }
-- Retourne la liste ordonnée des identifiants de pièces à poser.
function Patron.piecesDuCroquis(croquis)
	local pieces = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local variante = Catalogue.variante(croquis[famille])
		assert(variante and variante.famille == famille, "variante invalide pour " .. famille)
		for _, id in ipairs(variante.pieces) do
			table.insert(pieces, id)
		end
	end
	return pieces
end

-- Trajet de couture : liste de segments { a, b } décalés de la valeur de couture, et sa longueur totale
function Patron.trajetCouture(id)
	local def = Patron.def(id)
	local segments, longueur = {}, 0
	for _, i in ipairs(def.coutures) do
		local s = Polygone.areteDecalee(def.contour, i, Catalogue.VALEUR_COUTURE)
		table.insert(segments, s)
		longueur += Polygone.longueur(s)
	end
	return segments, longueur
end

-- Coordonnées normalisées (u, v) d'un point du patron : v suit la hauteur de la pièce,
-- u va d'un bord à l'autre de la ligne (les bords de côté tombent toujours sur les coutures).
function Patron.uv(id, x, y)
	local def = Patron.def(id)
	local b = Polygone.boite(def.contour)
	local v = (y - b.minY) / (b.maxY - b.minY)
	local x0, x1 = Polygone.etendueLigne(def.contour, math.clamp(y, b.minY, b.maxY))
	local u = 0.5
	if x0 and x1 - x0 > 1e-9 then
		u = math.clamp((x - x0) / (x1 - x0), 0, 1)
	end
	return u, v, b
end

---------------------------------------------------------------------------
-- Enroulements : (u, v) → position et direction « vers l'extérieur »
---------------------------------------------------------------------------
local function angleCote(cote, u)
	-- Devant : de +X (u = 0) à −X (u = 1) en passant par −Z ; dos : de −X à +X par +Z.
	-- Les coutures de côté du devant et du dos tombent donc au même endroit.
	if cote == "devant" then
		return 2 * math.pi - u * math.pi
	end
	return math.pi - u * math.pi
end

local function jupe(e, u, v, hauteur, m)
	local yd = v * hauteur
	local rT = m.taille / (2 * math.pi) + 0.12
	local rH = m.hanches / (2 * math.pi) + 0.15
	local phi = angleCote(e.cote, u)
	local r = rT + (rH - rT) * lisse(yd / LIGNE_HANCHES) + e.evasement * math.max(0, yd - LIGNE_HANCHES)
	r += e.fronces * v * 0.5 * (0.5 + 0.5 * math.sin(phi * 16))
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), -yd, r * EZ * math.sin(phi)), dehors
end

local function corsage(e, u, v, hauteur, m)
	local h = (1 - v) * hauteur -- hauteur au-dessus de la taille
	local rT = m.taille / (2 * math.pi) + 0.08
	local rP = m.poitrine / (2 * math.pi) + 0.1
	local rE = rP * 0.92
	local r
	if h <= LIGNE_POITRINE then
		r = rT + (rP - rT) * lisse(h / LIGNE_POITRINE)
	else
		r = rP + (rE - rP) * lisse((h - LIGNE_POITRINE) / math.max(0.1, hauteur - LIGNE_POITRINE))
	end
	local phi = angleCote(e.cote, u)
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), h, r * EZ * math.sin(phi)), dehors
end

-- Manche droite (+X) ; la gauche est son symétrique
local function manche(e, u, v, hauteur, m)
	local epaule = Vector3.new((m.poitrine / (2 * math.pi) + 0.1) * EX + 0.35, HAUTEUR_EPAULE, 0)
	local axe = Vector3.new(math.sin(INCLINAISON_BRAS), -math.cos(INCLINAISON_BRAS), 0)
	local n1 = Vector3.new(0, 0, 1)
	local n2 = axe:Cross(n1).Unit
	local rayon = 0.55 - 0.12 * v + e.bouffant * math.sin(math.pi * v)
	local theta = 2 * math.pi * u
	local dehors = n1 * math.cos(theta) + n2 * math.sin(theta)
	return epaule + axe * (v * hauteur) + dehors * rayon, dehors
end

-- Col, moitié droite (+X) : du milieu devant (u = 0) au milieu dos (u = 1)
local function col(e, u, v, hauteur, _m)
	local phi = -math.pi / 2 + u * math.pi
	local rayon, y
	if e.forme == "claudine" then
		rayon, y = RAYON_COU + v * hauteur * 0.9, HAUTEUR_COU - v * hauteur * 0.35
	else
		-- v = 1 (bord bas, cousu) à l'encolure : le haut du patron reste en haut, l'imprimé n'est pas inversé
		rayon, y = RAYON_COU + 0.05, HAUTEUR_COU + (1 - v) * hauteur
	end
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(rayon * math.cos(phi), y, rayon * math.sin(phi)), dehors
end

local ENROULEMENTS = { jupe = jupe, corsage = corsage, manche = manche, col = col }

-- Point du patron (x, y en dm) → position 3D (Vector3, dm) et direction extérieure (Vector3 unitaire).
-- « dehors » est la direction radiale approximative (pas la normale : voir Patron.normale).
-- copie : "unique", "gauche" ou "droite". mesures : { poitrine, taille, hanches }.
function Patron.point(id, copie, x, y, mesures)
	local def = Patron.def(id)
	local u, v, b = Patron.uv(id, x, y)
	local position, dehors = ENROULEMENTS[def.enroulement.type](def.enroulement, u, v, b.maxY - b.minY, mesures)
	if copie == "gauche" then
		position = Vector3.new(-position.X, position.Y, position.Z)
		dehors = Vector3.new(-dehors.X, dehors.Y, dehors.Z)
	end
	return position, dehors
end

-- Place (u, v) sur le patron (boîte normalisée, comme les accessoires) du point de la surface le plus
-- proche de « point » (repère du corps, dm), et la distance en dm. Sert à poser une décoration là où
-- l'on touche la robe 3D : recherche sur une grille dans la pièce, puis affinée autour du meilleur point.
local GRILLE_UV = 24
function Patron.versUV(id, copie, point, mesures)
	local contour = Patron.def(id).contour
	local b = Polygone.boite(contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local function distance(u, v)
		return (Patron.point(id, copie, b.minX + u * l, b.minY + v * h, mesures) - point).Magnitude
	end
	local meilleurU, meilleurV, meilleure = 0.5, 0.5, math.huge
	for i = 0, GRILLE_UV do
		for j = 0, GRILLE_UV do
			local u, v = i / GRILLE_UV, j / GRILLE_UV
			if Polygone.contient(contour, b.minX + u * l, b.minY + v * h) then
				local d = distance(u, v)
				if d < meilleure then
					meilleurU, meilleurV, meilleure = u, v, d
				end
			end
		end
	end
	local pas = 1 / GRILLE_UV
	for _ = 1, 6 do
		local bu, bv = meilleurU, meilleurV
		for di = -2, 2 do
			for dj = -2, 2 do
				local u, v = math.clamp(bu + di * pas / 2, 0, 1), math.clamp(bv + dj * pas / 2, 0, 1)
				local d = distance(u, v)
				if d < meilleure then
					meilleurU, meilleurV, meilleure = u, v, d
				end
			end
		end
		pas /= 2
	end
	return meilleurU, meilleurV, meilleure
end

-- Normale exacte de la surface au point (x, y) du patron, tournée vers l'extérieur
-- (sert à poser les accessoires à plat sur le tissu)
function Patron.normale(id, copie, x, y, mesures)
	local h = 0.01
	local tx = Patron.point(id, copie, x + h, y, mesures) - Patron.point(id, copie, x - h, y, mesures)
	local ty = Patron.point(id, copie, x, y + h, mesures) - Patron.point(id, copie, x, y - h, mesures)
	local _, dehors = Patron.point(id, copie, x, y, mesures)
	local n = tx:Cross(ty)
	if n.Magnitude < 1e-12 then
		return dehors
	end
	n = n.Unit
	if n:Dot(dehors) < 0 then
		n = -n
	end
	return n
end

return Patron
