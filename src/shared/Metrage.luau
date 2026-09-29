-- Metrage : disposition simple des pièces sur un rouleau (rangées de gauche à droite)
-- pour conseiller une longueur de tissu à l'achat. Le joueur reste libre de mieux ranger ses pièces.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Metrage = {}

local MARGE = 0.1 -- dm entre deux pièces
Metrage.MARGE = MARGE

-- Boîte de la pièce posée à l'angle donné : largeur, hauteur, et décalage entre le coin haut gauche
-- de la boîte et le point de pose (centre du patron)
function Metrage.encombrement(idPiece, angle)
	local def = Catalogue.piece(idPiece)
	local pose = Polygone.poser(def.contour, { x = 0, y = 0, angle = angle }, Polygone.centre(def.contour))
	local b = Polygone.boite(pose)
	return b.maxX - b.minX, b.maxY - b.minY, -b.minX, -b.minY
end

-- ids : pièces à couper dans un même tissu. Retourne { [id] = { x, y, angle } } et la longueur utilisée (dm entiers).
function Metrage.disposition(ids)
	local items = {}
	for _, id in ipairs(ids) do
		local def = Catalogue.piece(id)
		local angle = def.biais and 45 or 0 -- droit-fil parfait
		local l, h, dx, dy = Metrage.encombrement(id, angle)
		table.insert(items, { id = id, angle = angle, l = l, h = h, dx = dx, dy = dy, pliee = def.pliee })
	end
	table.sort(items, function(a, b)
		if a.h ~= b.h then
			return a.h > b.h
		end
		return a.id < b.id
	end)
	local placements = {}
	local y, hauteurRangee, x, bas = 0, 0, 0, 0
	local function nouvelleRangee()
		if hauteurRangee > 0 then
			y += hauteurRangee + MARGE
		end
		hauteurRangee, x = 0, 0
	end
	for _, it in ipairs(items) do
		if it.pliee then
			-- Pièce pliée : contre le pli, sur sa propre rangée (son symétrique occupe l'autre côté)
			nouvelleRangee()
			placements[it.id] = { x = Catalogue.PLI - MARGE / 2 - it.l + it.dx, y = y + it.dy, angle = it.angle }
			hauteurRangee = it.h
			bas = math.max(bas, y + it.h)
			nouvelleRangee()
		else
			if x + it.l > Catalogue.LARGEUR_ROULEAU then
				nouvelleRangee()
			end
			placements[it.id] = { x = x + it.dx, y = y + it.dy, angle = it.angle }
			x += it.l + MARGE
			hauteurRangee = math.max(hauteurRangee, it.h)
			bas = math.max(bas, y + it.h)
		end
	end
	return placements, math.ceil(bas - 1e-9)
end

-- Longueur conseillée (dm) pour couper ces pièces dans un même tissu
function Metrage.conseil(ids)
	local _, longueur = Metrage.disposition(ids)
	return longueur
end

-- Tissu à acheter pour un croquis : pieces = ses pièces (dans l'ordre), tissus = { [idPiece] = idTissu }
-- (les pièces sans tissu ne comptent pas), stock = { [idTissu] = dm }. Renvoie { { tissu, conseil, manque } }
-- par tissu, dans l'ordre des pièces, et le total manquant (dm).
function Metrage.aAcheter(pieces, tissus, stock)
	local ordre, parTissu = {}, {}
	for _, id in ipairs(pieces) do
		local t = tissus[id]
		if t then
			if not parTissu[t] then
				parTissu[t] = {}
				table.insert(ordre, t)
			end
			table.insert(parTissu[t], id)
		end
	end
	local liste, total = {}, 0
	for _, t in ipairs(ordre) do
		local conseil = Metrage.conseil(parTissu[t])
		local manque = math.max(0, conseil - (stock[t] or 0))
		table.insert(liste, { tissu = t, conseil = conseil, manque = manque })
		total += manque
	end
	return liste, total
end

return Metrage
