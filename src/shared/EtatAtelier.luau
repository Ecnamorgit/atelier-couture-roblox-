-- EtatAtelier : état d'un joueur à l'atelier et étapes de la commande en cours.
-- Logique pure, sans instance Roblox : le client s'en sert en local (plan 3),
-- puis le serveur la reprend derrière les échanges réseau (plan 4), où elle fait foi.
-- Chaque action renvoie { ok = true, ... } ou { ok = false, erreur = "…" } et ne lève jamais d'erreur.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Patron = require(dossier:WaitForChild("Patron"))
local Coupon = require(dossier:WaitForChild("Coupon"))
local Commandes = require(dossier:WaitForChild("Commandes"))
local Notation = require(dossier:WaitForChild("Notation"))
local Recette = require(dossier:WaitForChild("Recette"))

local EtatAtelier = {}
EtatAtelier.__index = EtatAtelier

EtatAtelier.ARGENT_DEPART = 150
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
EtatAtelier.ACHAT_MAX = 100 -- dm par achat
EtatAtelier.TOLERANCE_MESURES = 2 -- mesures de couture en plus ou en moins acceptées (spec §6)
EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
-- Étapes du plan 3b (le plan 3c ajoute la photo et la livraison après les décorations)
EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations" }

local function refus(message)
	return { ok = false, erreur = message }
end

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function EtatAtelier.nouveau(argent)
	return setmetatable({
		argent = argent or EtatAtelier.ARGENT_DEPART,
		stock = {}, -- [idTissu] = dm
		etape = "accueil",
		commande = nil,
		croquis = nil,
		tissus = {}, -- [idPiece] = idTissu
		coupons = {}, -- [idTissu] = Coupon (pendant la découpe)
		coupees = {}, -- [idPiece] = { x, y, angle }
		epinglees = {}, -- [idPiece] = true
		coutures = {}, -- [idPiece] = note de couture (0 à 1)
	}, EtatAtelier)
end

-- Prix en pièces d'or de « dm » décimètres d'un tissu (prix au mètre, arrondi au-dessus)
function EtatAtelier.prix(idTissu, dm)
	return math.ceil(Catalogue.tissu(idTissu).prix * dm / 10 - 1e-9)
end

function EtatAtelier:piecesDuCroquis()
	return self.croquis and Patron.piecesDuCroquis(self.croquis) or {}
end

function EtatAtelier:piecesAPoser()
	local out = {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		if not self.coupees[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- Pièces du croquis pas encore épinglées, dans l'ordre du croquis
function EtatAtelier:piecesAEpingler()
	local out = {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		if not self.epinglees[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- Pièces du croquis pas encore cousues, dans l'ordre du croquis
function EtatAtelier:piecesACoudre()
	local out = {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		if self.coutures[id] == nil then
			table.insert(out, id)
		end
	end
	return out
end

-- Tissus utilisés par le croquis, dans l'ordre d'apparition
function EtatAtelier:tissusUtilises()
	local vus, out = {}, {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		local t = self.tissus[id]
		if t and not vus[t] then
			vus[t] = true
			table.insert(out, t)
		end
	end
	return out
end

-- Le tissu déjà coupé est perdu : on retire du stock la longueur entamée de chaque rouleau
local function consommer(self)
	for idTissu, coupon in pairs(self.coupons) do
		self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - coupon:longueurUtilisee())
	end
	self.coupons = {}
end

function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	self.commande = Commandes.generer(rng)
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures = {}, {}
	self.etape = "carnet"
	return { ok = true, commande = self.commande }
end

-- croquis = { corsage, manches, col, jupe } ; tissus = { [idPiece] = idTissu } pour chaque pièce du croquis
function EtatAtelier:validerCroquis(croquis, tissus)
	if self.etape ~= "carnet" and self.etape ~= "achat" then
		return refus("Le croquis ne peut plus être modifié.")
	end
	local ok, pieces = pcall(Patron.piecesDuCroquis, croquis)
	if not ok or type(tissus) ~= "table" then
		return refus("Croquis invalide.")
	end
	local choix = {}
	for _, id in ipairs(pieces) do
		local t = tissus[id]
		if type(t) ~= "string" or not Catalogue.tissu(t) then
			return refus("Choisis un tissu pour chaque pièce.")
		end
		choix[id] = t
	end
	self.croquis = table.clone(croquis)
	self.tissus = choix
	self.etape = "achat"
	return { ok = true }
end

-- Retour au carnet, possible tant qu'aucune pièce n'est coupée
function EtatAtelier:retourCarnet()
	if self.etape ~= "achat" and not (self.etape == "decoupe" and next(self.coupees) == nil) then
		return refus("Des pièces sont déjà coupées.")
	end
	self.coupons = {}
	self.etape = "carnet"
	return { ok = true }
end

function EtatAtelier:acheter(idTissu, dm)
	if self.etape ~= "achat" and self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment d'acheter du tissu.")
	end
	if type(idTissu) ~= "string" or not Catalogue.tissu(idTissu) then
		return refus("Tissu inconnu.")
	end
	if not fini(dm) or dm ~= math.floor(dm) or dm < 1 or dm > EtatAtelier.ACHAT_MAX then
		return refus("Longueur invalide.")
	end
	local prix = EtatAtelier.prix(idTissu, dm)
	if prix > self.argent then
		return refus("Pas assez d'argent.")
	end
	self.argent -= prix
	self.stock[idTissu] = (self.stock[idTissu] or 0) + dm
	local coupon = self.coupons[idTissu]
	if coupon then
		coupon.longueur += dm -- le rouleau se déroule plus loin pendant la découpe
	end
	return { ok = true, prix = prix }
end

-- Passe à la table de découpe : un rouleau par tissu, de la longueur en stock
function EtatAtelier:commencerDecoupe()
	if self.etape ~= "achat" then
		return refus("Ce n'est pas le moment de découper.")
	end
	for _, t in ipairs(self:tissusUtilises()) do
		if (self.stock[t] or 0) < 1 then
			return refus("Il te manque du tissu : " .. Catalogue.tissu(t).nom .. ".")
		end
	end
	self.coupons = {}
	for _, t in ipairs(self:tissusUtilises()) do
		self.coupons[t] = Coupon.nouveau(self.stock[t])
	end
	self.etape = "decoupe"
	return { ok = true }
end

-- placement = { x, y, angle } sur le rouleau du tissu choisi pour la pièce
function EtatAtelier:couper(idPiece, placement)
	if self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment de découper.")
	end
	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
		return refus("Cette pièce n'est pas dans le croquis.")
	end
	local coupon = self.coupons[self.tissus[idPiece]]
	local ok, erreur = coupon:poser(idPiece, placement)
	if not ok then
		return refus(erreur)
	end
	self.coupees[idPiece] = coupon.poses[idPiece]
	if #self:piecesAPoser() == 0 then
		consommer(self)
		self.etape = "epinglage"
	end
	return { ok = true, reste = #self:piecesAPoser() }
end

-- Épingle une pièce coupée sur le mannequin ; la dernière mène à la couture
function EtatAtelier:epingler(idPiece)
	if self.etape ~= "epinglage" then
		return refus("Ce n'est pas le moment d'épingler.")
	end
	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
		return refus("Cette pièce n'est pas dans le croquis.")
	end
	if self.epinglees[idPiece] then
		return refus("Cette pièce est déjà épinglée.")
	end
	self.epinglees[idPiece] = true
	local reste = #self:piecesAEpingler()
	if reste == 0 then
		self.etape = "couture"
	end
	return { ok = true, reste = reste }
end

-- Relevé de couture d'une pièce : ecarts = écarts (dm) de l'aiguille au pointillé, un tous les
-- 0,1 dm de trajet ; duree = secondes passées à coudre ; assistance = vrai si elle a servi.
-- Rien ne prouve qu'un relevé est honnête (limite assumée, spec §6) : on vérifie qu'il est vraisemblable.
function EtatAtelier:rendreCouture(idPiece, ecarts, duree, assistance)
	if self.etape ~= "couture" then
		return refus("Ce n'est pas le moment de coudre.")
	end
	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
		return refus("Cette pièce n'est pas dans le croquis.")
	end
	if self.coutures[idPiece] ~= nil then
		return refus("Cette pièce est déjà cousue.")
	end
	if type(ecarts) ~= "table" or (assistance ~= nil and type(assistance) ~= "boolean") then
		return refus("Relevé de couture invalide.")
	end
	local _, longueur = Patron.trajetCouture(idPiece)
	local n = #ecarts
	if math.abs(n - math.round(longueur / Catalogue.PAS_MESURE_COUTURE)) > EtatAtelier.TOLERANCE_MESURES then
		return refus("Relevé de couture incomplet.")
	end
	for i = 1, n do
		if not fini(ecarts[i]) or math.abs(ecarts[i]) > Catalogue.ECART_MAX_COUTURE then
			return refus("Relevé de couture invalide.")
		end
	end
	if not fini(duree) or duree < EtatAtelier.DUREE_MIN * longueur / Catalogue.VITESSE_COUTURE_MAX then
		return refus("Couture trop rapide.")
	end
	local note = Notation.noteCouture(ecarts, assistance == true)
	self.coutures[idPiece] = note
	local reste = #self:piecesACoudre()
	if reste == 0 then
		self.etape = "decorations"
	end
	return { ok = true, note = note, reste = reste }
end

-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture ; les accessoires
-- arrivent au plan 3c), ou nil tant que toutes les pièces ne sont pas coupées
function EtatAtelier:recette()
	if not self.commande or not self.croquis or #self:piecesAPoser() > 0 then
		return nil
	end
	local pieces = {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		local p = self.coupees[id]
		table.insert(pieces, { id = id, tissu = self.tissus[id], x = p.x, y = p.y, angle = p.angle, couture = self.coutures[id] or 0 })
	end
	return {
		version = Recette.VERSION,
		mesures = table.clone(self.commande.mesures),
		croquis = table.clone(self.croquis),
		pieces = pieces,
		accessoires = {},
	}
end

-- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
	consommer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.epinglees, self.coutures = {}, {}
	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
	self.etape = "carnet"
	return { ok = true }
end

return EtatAtelier
