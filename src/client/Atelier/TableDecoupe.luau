-- TableDecoupe : logique de la table de découpe (sans affichage), testable seule.
-- Garde le tissu en cours, la pièce sélectionnée et sa position (x, y, angle) sur le rouleau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local Coupon = require(Couture:WaitForChild("Coupon"))
local Polygone = require(Couture:WaitForChild("Polygone"))

local TableDecoupe = {}
TableDecoupe.__index = TableDecoupe

-- etat : EtatAtelier à l'étape « decoupe »
function TableDecoupe.nouvelle(etat)
	local self = setmetatable({ etat = etat, tissu = nil, selection = nil, placement = nil }, TableDecoupe)
	self:choisirTissu(etat:tissusUtilises()[1])
	return self
end

-- Ordre de proposition, comme Metrage : les pièces non pliées d'abord, les plus hautes en premier,
-- les pièces pliées à la fin (au milieu du rouleau, elles bloqueraient une pièce plus large)
local function avant(a, b)
	local pa, pb = Catalogue.piece(a).pliee == true, Catalogue.piece(b).pliee == true
	if pa ~= pb then
		return pb
	end
	local _, ha = Metrage.encombrement(a, Catalogue.piece(a).biais and 45 or 0)
	local _, hb = Metrage.encombrement(b, Catalogue.piece(b).biais and 45 or 0)
	if math.abs(ha - hb) > 1e-9 then
		return ha > hb
	end
	return a < b
end

-- Pièces du tissu en cours qui restent à couper, dans l'ordre de proposition
function TableDecoupe:piecesRestantes(idTissu)
	local out = {}
	for _, id in ipairs(self.etat:piecesAPoser()) do
		if self.etat.tissus[id] == (idTissu or self.tissu) then
			table.insert(out, id)
		end
	end
	table.sort(out, avant)
	return out
end

-- Onglets : { { tissu, reste } } pour chaque tissu du croquis
function TableDecoupe:onglets()
	local out = {}
	for _, t in ipairs(self.etat:tissusUtilises()) do
		table.insert(out, { tissu = t, reste = #self:piecesRestantes(t) })
	end
	return out
end

function TableDecoupe:coupon()
	return self.etat.coupons[self.tissu]
end

function TableDecoupe:choisirTissu(idTissu)
	self.tissu = idTissu
	self:selectionner(self:piecesRestantes()[1])
end

-- Sélectionne une pièce et la pose à la place proposée
function TableDecoupe:selectionner(idPiece)
	self.selection = idPiece
	self.placement = nil
	if idPiece then
		self:proposer()
	end
end

-- Place proposée : la première place libre, du haut du rouleau vers le bas puis de gauche à droite,
-- contre les bords des pièces déjà coupées et des trous du tissu entamé, au droit-fil parfait. À défaut : sous tout
-- le reste.
function TableDecoupe:proposer()
	local id = self.selection
	if not id then
		return
	end
	local def = Catalogue.piece(id)
	local angle = def.biais and 45 or 0
	local l, h, dx, dy = Metrage.encombrement(id, angle)
	local coupon = self:coupon()
	local limiteX = def.pliee and Catalogue.PLI - Metrage.MARGE / 2 or Catalogue.LARGEUR_ROULEAU
	local xs, ys = { 0 }, { 0 }
	local bas = 0
	local prises = {}
	for idCoupee, pose in pairs(coupon.poses) do
		table.insert(prises, { idCoupee, pose })
	end
	for _, trou in ipairs(coupon.trous) do
		table.insert(prises, { trou.piece, trou })
	end
	for _, p in ipairs(prises) do
		for _, contour in ipairs(Coupon.contoursPoses(p[1], p[2])) do
			local b = Polygone.boite(contour)
			table.insert(xs, b.maxX + Metrage.MARGE)
			table.insert(ys, b.maxY + Metrage.MARGE)
			bas = math.max(bas, b.maxY + Metrage.MARGE)
		end
	end
	table.sort(xs)
	table.sort(ys)
	if def.pliee then
		table.insert(xs, 1, limiteX - l) -- une pièce pliée se pose d'abord contre le pli
	end
	for _, y in ipairs(ys) do
		for _, x in ipairs(xs) do
			if x + l <= limiteX + 1e-9 then
				local placement = { x = x + dx, y = y + dy, angle = angle }
				if coupon:verifier(id, placement) then
					self.placement = placement
					return
				end
			end
		end
	end
	local x = def.pliee and limiteX - l or 0
	self.placement = { x = x + dx, y = bas + dy, angle = angle }
end

function TableDecoupe:deplacer(x, y)
	if self.placement then
		local longueur = self:coupon().longueur
		self.placement.x = math.clamp(x, 0, Catalogue.LARGEUR_ROULEAU)
		self.placement.y = math.clamp(y, 0, longueur)
	end
end

-- Tourne de « degres » puis aligne sur le droit-fil s'il est à moins de 6°
function TableDecoupe:tourner(degres)
	if self.placement then
		local angle = (self.placement.angle + degres) % 360
		self.placement.angle = Notation.aimanter(angle, self.selection) % 360
	end
end

-- { valide, erreur, droitFil (0 à 1) } pour la pièce sélectionnée à sa place actuelle
function TableDecoupe:etatPlacement()
	if not self.placement then
		return { valide = false, erreur = "Aucune pièce sélectionnée.", droitFil = 0 }
	end
	local ok, erreur = self:coupon():verifier(self.selection, self.placement)
	local def = Catalogue.piece(self.selection)
	local droitFil = Notation.droitFil(Notation.angleFil(self.placement.angle, self.selection), def.biais)
	return { valide = ok, erreur = erreur, droitFil = droitFil }
end

-- Coupe la pièce sélectionnée ; en cas de succès, sélectionne la suivante (ou passe au tissu suivant)
function TableDecoupe:couper(session)
	if not self.placement then
		return { ok = false, erreur = "Aucune pièce sélectionnée." }
	end
	local reponse = session:couper(self.selection, table.clone(self.placement))
	if reponse.ok then
		if self.etat.etape ~= "decoupe" then
			self.selection, self.placement = nil, nil
		elseif #self:piecesRestantes() > 0 then
			self:selectionner(self:piecesRestantes()[1])
		else
			for _, o in ipairs(self:onglets()) do
				if o.reste > 0 then
					self:choisirTissu(o.tissu)
					break
				end
			end
		end
	end
	return reponse
end

return TableDecoupe
