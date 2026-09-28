-- Coupon : un rouleau de tissu sur la table de découpe (14 dm de large, droit-fil le long de y).
-- Vérifie qu'une pièce posée tient dans le rouleau sans chevaucher les pièces déjà coupées.
-- Le chevauchement est détecté sur une grille de cases de 0,1 dm (le centre de chaque case).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Coupon = {}
Coupon.__index = Coupon

local PAS = 0.1
local EPSILON = 1e-6
local ANGLE_MAX = 3600 -- au-delà, le modulo perd sa précision : un client pourrait fausser le droit-fil
local COLONNES = math.floor(Catalogue.LARGEUR_ROULEAU / PAS + 0.5)

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- longueur : longueur déroulée disponible (dm)
function Coupon.nouveau(longueur)
	return setmetatable({ longueur = longueur, cellules = {}, poses = {}, basMax = 0 }, Coupon)
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

-- Retourne ok (bool), erreur (string?), et les contours et cases occupées si ok
function Coupon:verifier(idPiece, placement)
	local def = Catalogue.piece(idPiece)
	if not def then
		return false, "Pièce inconnue."
	end
	if self.poses[idPiece] then
		return false, "Cette pièce est déjà coupée."
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
			if self.cellules[cle] or cases[cle] then
				return false, "La pièce chevauche une autre pièce."
			end
			cases[cle] = true
		end
	end
	return true, nil, contours, cases
end

function Coupon:poser(idPiece, placement)
	local ok, erreur, contours, cases = self:verifier(idPiece, placement)
	if not ok then
		return false, erreur
	end
	for cle in pairs(cases) do
		self.cellules[cle] = idPiece
	end
	self.poses[idPiece] = { x = placement.x, y = placement.y, angle = placement.angle }
	for _, contour in ipairs(contours) do
		self.basMax = math.max(self.basMax, Polygone.boite(contour).maxY)
	end
	return true
end

-- Longueur de tissu consommée (dm entiers, arrondie au-dessus)
function Coupon:longueurUtilisee()
	return math.ceil(self.basMax - EPSILON)
end

return Coupon
