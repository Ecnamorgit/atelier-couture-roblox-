-- Coupon : un rouleau de tissu sur la table de découpe (14 dm de large, droit-fil le long de y).
-- Vérifie qu'une pièce posée tient dans le rouleau sans chevaucher les pièces déjà coupées.
-- Le chevauchement est détecté sur une grille de cases de 0,1 dm (le centre de chaque case).
-- Sous-projet 6 : le haut du rouleau peut être entamé par les robes d'avant ; leurs pièces y ont laissé des trous,
-- qu'on ne coupe pas deux fois : on coupe dans les vides, ou dessous.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Coupon = {}
Coupon.__index = Coupon

local PAS = 0.1
local EPSILON = 1e-6
local ANGLE_MAX = 3600 -- au-delà, le modulo perd sa précision : un client pourrait fausser le droit-fil
local COLONNES = math.floor(Catalogue.LARGEUR_ROULEAU / PAS + 0.5)
local TROU = "(trou)" -- une case prise par une robe d'avant

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Contours posés sur le rouleau : la pièce, et son symétrique par rapport au pli si elle est pliée.
-- placement = { x, y, angle } : le centre de la boîte du patron va en (x, y), puis rotation de angle degrés.
function Coupon.contoursPoses(idPiece, placement)
	local def = Catalogue.piece(idPiece)
	local pose = Polygone.poser(def.contour, placement, Polygone.centre(def.contour))
	if def.pliee then
		return { pose, Polygone.miroir(pose, Catalogue.PLI) }
	end
	return { pose }
end

local function cellulesDe(contour)
	local b = Polygone.boite(contour)
	local out = {}
	for colonne = math.max(0, math.floor(b.minX / PAS)), math.ceil(b.maxX / PAS) - 1 do
		for ligne = math.max(0, math.floor(b.minY / PAS)), math.ceil(b.maxY / PAS) - 1 do
			if Polygone.contient(contour, (colonne + 0.5) * PAS, (ligne + 0.5) * PAS) then
				table.insert(out, ligne * COLONNES + colonne)
			end
		end
	end
	return out
end

-- Une pièce à une place : connue, place finie, dans le rouleau, d'un côté du pli, sans chevaucher ce qui est déjà
-- pris. Retourne ok, erreur, et les contours et cases occupées si ok
local function place(self, idPiece, placement)
	local def = Catalogue.piece(idPiece)
	if not def then
		return false, "Pièce inconnue."
	end
	if type(placement) ~= "table" or not fini(placement.x) or not fini(placement.y) or not fini(placement.angle)
		or math.abs(placement.angle) > ANGLE_MAX then
		return false, "Position invalide."
	end
	local contours = Coupon.contoursPoses(idPiece, placement)
	local b = Polygone.boite(contours[1])
	if b.minX < -EPSILON or b.maxX > Catalogue.LARGEUR_ROULEAU + EPSILON or b.minY < -EPSILON or b.maxY > self.longueur + EPSILON then
		return false, "La pièce dépasse du tissu."
	end
	-- Pièce pliée : entièrement d'un côté du pli (à gauche ou à droite), son symétrique occupe l'autre côté
	if def.pliee and b.minX < Catalogue.PLI - EPSILON and b.maxX > Catalogue.PLI + EPSILON then
		return false, "Une pièce pliée doit tenir d'un côté du pli."
	end
	local cases = {}
	for _, contour in ipairs(contours) do
		for _, cle in ipairs(cellulesDe(contour)) do
			if self.cellules[cle] == TROU then
				return false, "La pièce passe sur un trou du tissu entamé."
			elseif self.cellules[cle] or cases[cle] then
				return false, "La pièce chevauche une autre pièce."
			end
			cases[cle] = true
		end
	end
	return true, nil, contours, cases
end

-- Prend les cases d'une pièce (valeur : son identifiant, ou TROU) ; renvoie le bas de la pièce
local function prendre(self, contours, cases, valeur)
	for cle in pairs(cases) do
		self.cellules[cle] = valeur
	end
	local bas = 0
	for _, contour in ipairs(contours) do
		bas = math.max(bas, Polygone.boite(contour).maxY)
	end
	return bas
end

-- longueur : longueur déroulée disponible (dm) ; trous (facultatif) : les pièces coupées pour les robes d'avant, en
-- haut du rouleau ({ piece, x, y, angle }), déjà vérifiées (Coupon.lireTrous)
function Coupon.nouveau(longueur, trous)
	local self = setmetatable({ longueur = longueur, cellules = {}, poses = {}, trous = {}, basTrous = 0, basMax = 0 }, Coupon)
	for _, t in ipairs(trous or {}) do
		local pose = { x = t.x, y = t.y, angle = t.angle }
		local cases = {}
		local contours = Coupon.contoursPoses(t.piece, pose)
		for _, contour in ipairs(contours) do
			for _, cle in ipairs(cellulesDe(contour)) do
				cases[cle] = true
			end
		end
		self.basTrous = math.max(self.basTrous, prendre(self, contours, cases, TROU))
		table.insert(self.trous, { piece = t.piece, x = t.x, y = t.y, angle = t.angle })
	end
	self.basMax = self.basTrous
	return self
end

-- Des trous venus d'ailleurs (une sauvegarde) : une liste de pièces connues, à des places finies, dans un rouleau de
-- cette longueur, qui ne se chevauchent pas (une même pièce peut revenir : deux robes). Renvoie la liste relue, ou
-- nil si l'un des trous est illisible
function Coupon.lireTrous(trous, longueur)
	if type(trous) ~= "table" then
		return nil
	end
	local n = 0
	for _ in pairs(trous) do
		n += 1
	end
	if n ~= #trous then
		return nil -- pas une liste
	end
	local essai, out = Coupon.nouveau(longueur), {}
	for _, t in ipairs(trous) do
		if type(t) ~= "table" or type(t.piece) ~= "string" then
			return nil
		end
		local pose = { x = t.x, y = t.y, angle = t.angle }
		local ok, _, contours, cases = place(essai, t.piece, pose)
		if not ok then
			return nil
		end
		prendre(essai, contours, cases, TROU)
		table.insert(out, { piece = t.piece, x = t.x, y = t.y, angle = t.angle })
	end
	return out
end

-- Le bas d'une liste de trous (dm entiers, arrondi au-dessus), sans prendre leurs cases
function Coupon.bas(trous)
	local bas = 0
	for _, t in ipairs(trous) do
		for _, contour in ipairs(Coupon.contoursPoses(t.piece, t)) do
			bas = math.max(bas, Polygone.boite(contour).maxY)
		end
	end
	return math.max(0, math.ceil(bas - EPSILON))
end

-- Retourne ok (bool), erreur (string?), et les contours et cases occupées si ok
function Coupon:verifier(idPiece, placement)
	if Catalogue.piece(idPiece) and self.poses[idPiece] then
		return false, "Cette pièce est déjà coupée."
	end
	return place(self, idPiece, placement)
end

function Coupon:poser(idPiece, placement)
	local ok, erreur, contours, cases = self:verifier(idPiece, placement)
	if not ok then
		return false, erreur
	end
	self.basMax = math.max(self.basMax, prendre(self, contours, cases, idPiece))
	self.poses[idPiece] = { x = placement.x, y = placement.y, angle = placement.angle }
	return true
end

-- Longueur de tissu entamée, trous des robes d'avant compris (dm entiers, arrondie au-dessus)
function Coupon:longueurUtilisee()
	return math.ceil(self.basMax - EPSILON)
end

-- Ce que les pièces de cette robe ajoutent à la bande entamée (dm entiers) : rien si elles tiennent dans ses vides
function Coupon:ajout()
	return math.max(0, self:longueurUtilisee() - math.ceil(self.basTrous - EPSILON))
end

return Coupon
