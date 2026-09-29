-- Decorateur : logique de l'éditeur de décorations (sans affichage), testable seule.
-- Tient la liste des décorations au format de la recette : objets posés au toucher, garnitures point
-- par point (une seule pièce, 64 points au plus), sélection, rotation, taille, suppression, annulation,
-- et le coût à payer (différence avec ce qui est déjà payé, calculée comme EtatAtelier la facturera).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Recette = require(Couture:WaitForChild("Recette"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Decorateur = {}
Decorateur.__index = Decorateur

local function copier(liste)
	local out = {}
	for i, a in ipairs(liste) do
		local c = table.clone(a)
		if a.trajet then
			c.trajet = {}
			for k, pt in ipairs(a.trajet) do
				c.trajet[k] = { u = pt.u, v = pt.v }
			end
		end
		out[i] = c
	end
	return out
end

local function dans01(n)
	return type(n) == "number" and n == n and n >= 0 and n <= 1
end

-- recette : recette de la robe (etat:recette()), avec les décorations déjà posées ;
-- payees : décorations déjà facturées (etat.accessoires)
function Decorateur.nouveau(recette, payees)
	return setmetatable({
		recette = recette,
		payees = copier(payees),
		liste = copier(recette.accessoires or {}),
		choix = nil, -- identifiant de l'accessoire choisi dans la palette
		selection = nil, -- indice dans la liste
		garniture = nil, -- garniture en cours : { id, piece, copie, trajet }
		historique = {},
	}, Decorateur)
end

local function memoriser(self)
	table.insert(self.historique, copier(self.liste))
end

function Decorateur:terminerGarniture()
	local g = self.garniture
	if not g or #g.trajet < 2 then
		return false
	end
	memoriser(self)
	table.insert(self.liste, g)
	self.garniture = nil
	return true
end

function Decorateur:choisir(idAccessoire)
	if not Catalogue.accessoire(idAccessoire) then
		return false
	end
	if self.garniture and not self:terminerGarniture() then
		self.garniture = nil -- garniture d'un seul point : abandonnée
	end
	self.choix = idAccessoire
	return true
end

-- On touche la robe : pièce (indice dans la recette), copie touchée, place (u, v) sur le patron
function Decorateur:toucher(indicePiece, copie, u, v)
	local p = type(indicePiece) == "number" and self.recette.pieces[indicePiece]
	if not p or not table.find(Patron.copies(p.id), copie) or not dans01(u) or not dans01(v) then
		return { ok = false, erreur = "Touche la robe pour poser la décoration." }
	end
	if not self.choix then
		return { ok = false, erreur = "Choisis d'abord une décoration." }
	end
	if #self.liste >= Recette.MAX_ACCESSOIRES then
		return { ok = false, erreur = "Il y a déjà trop de décorations." }
	end
	local copieGardee = copie ~= Patron.copies(p.id)[1] and copie or nil
	local def = Catalogue.accessoire(self.choix)
	if def.genre == "objet" then
		memoriser(self)
		table.insert(self.liste, { id = self.choix, piece = indicePiece, copie = copieGardee, u = u, v = v, echelle = 1, angle = 0 })
		self.selection = #self.liste
		return { ok = true, action = "pose" }
	end
	local g = self.garniture
	if not g then
		self.garniture = { id = self.choix, piece = indicePiece, copie = copieGardee, trajet = { { u = u, v = v } } }
		return { ok = true, action = "point" }
	end
	if g.piece ~= indicePiece or g.copie ~= copieGardee then
		return { ok = false, erreur = "Une garniture reste sur une seule pièce." }
	end
	if #g.trajet >= Recette.MAX_POINTS_GARNITURE then
		return { ok = false, erreur = "Cette garniture a déjà 64 points." }
	end
	table.insert(g.trajet, { u = u, v = v })
	return { ok = true, action = "point" }
end

function Decorateur:selectionner(indice)
	if self.liste[indice] then
		self.selection = indice
		return true
	end
	return false
end

local function objetSelectionne(self)
	local a = self.selection and self.liste[self.selection]
	return a and not a.trajet and a or nil
end

-- Tourne l'objet sélectionné (angle ramené entre −180 et 180)
function Decorateur:tourner(degres)
	if objetSelectionne(self) then
		memoriser(self)
		local a = objetSelectionne(self)
		a.angle = ((a.angle + degres + 180) % 360) - 180
	end
end

-- Agrandit ou réduit l'objet sélectionné (taille bornée comme dans la recette)
function Decorateur:redimensionner(delta)
	if objetSelectionne(self) then
		memoriser(self)
		local a = objetSelectionne(self)
		a.echelle = math.clamp(a.echelle + delta, Recette.ECHELLE_MIN, Recette.ECHELLE_MAX)
	end
end

function Decorateur:supprimer()
	if self.selection and self.liste[self.selection] then
		memoriser(self)
		table.remove(self.liste, self.selection)
		self.selection = nil
	end
end

-- Annule le dernier point de la garniture en cours, sinon la dernière modification de la liste
function Decorateur:annuler()
	local g = self.garniture
	if g then
		table.remove(g.trajet)
		if #g.trajet == 0 then
			self.garniture = nil
		end
		return true
	end
	local precedente = table.remove(self.historique)
	if not precedente then
		return false
	end
	self.liste = precedente
	self.selection = nil
	return true
end

-- Liste complète, garniture en cours comprise si elle a au moins deux points
local function complete(self)
	local liste = copier(self.liste)
	local g = self.garniture
	if g and #g.trajet >= 2 then
		table.insert(liste, copier({ g })[1])
	end
	return liste
end

-- Pièces d'or à payer (négatif : remboursement)
function Decorateur:cout()
	local pieces = self.recette.pieces
	return EtatAtelier.prixDecorations(pieces, complete(self)) - EtatAtelier.prixDecorations(pieces, self.payees)
end

-- Liste à envoyer (EtatAtelier:decorer)
function Decorateur:resultat()
	return complete(self)
end

return Decorateur
