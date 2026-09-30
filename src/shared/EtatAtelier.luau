-- EtatAtelier : état d'un joueur à l'atelier et étapes de la commande en cours.
-- Logique pure, sans instance Roblox. Le serveur la tient pour chaque joueur et elle y fait foi ;
-- le client en garde une copie, rechargée après chaque action (exporter / charger).
-- Chaque action renvoie { ok = true, ... } ou { ok = false, erreur = "…" } et ne lève jamais d'erreur.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Patron = require(dossier:WaitForChild("Patron"))
local Coupon = require(dossier:WaitForChild("Coupon"))
local Commandes = require(dossier:WaitForChild("Commandes"))
local Notation = require(dossier:WaitForChild("Notation"))
local Recette = require(dossier:WaitForChild("Recette"))
local Clientes = require(dossier:WaitForChild("Clientes"))
local Progression = require(dossier:WaitForChild("Progression"))
local Deblocages = require(dossier:WaitForChild("Deblocages"))
local Histoire = require(dossier:WaitForChild("Histoire"))

local EtatAtelier = {}
EtatAtelier.__index = EtatAtelier

EtatAtelier.ARGENT_DEPART = 150
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
EtatAtelier.ACOMPTE = 0.25 -- part de la base versée quand la cliente passe commande
EtatAtelier.PIECES_ACOMPTE = 4 -- la base de l'acompte est celle de la robe la plus simple (quatre pièces)
EtatAtelier.LIBRES_APRES = 2 -- les robes libres s'ouvrent après deux commandes livrées
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée (par unité de poids : un volant compte moitié), dans le prix de vente d'une robe libre
EtatAtelier.COURRIER_APRES = 5 -- le courrier s'ouvre après cinq commandes livrées
EtatAtelier.LETTRES_MAX = 3
EtatAtelier.ACHAT_MAX = 100 -- dm par achat
EtatAtelier.TOLERANCE_MESURES = 2 -- mesures de couture en plus ou en moins acceptées (spec §6)
EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
EtatAtelier.ECART_MESURE_MAX = 1.5 -- dm : une mesure plus loin de la vraie est refusée (ruban pas réglé)
local MESURE_INVALIDE = "Mesure invalide : tourne chaque molette jusqu'à ce que le mannequin épouse sa silhouette."
-- Étapes du plan 3b (le plan 3c ajoute la photo et la livraison après les décorations)
EtatAtelier.ROBES_GARDEES = 10 -- robes livrées gardées, la plus récente en vitrine (spec §6)
EtatAtelier.ETAPES = { "accueil", "mesures", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
-- Sous-projet 6 : la mercerie, achetée d'avance ([idAccessoire] = unités pour un objet, cm pour une garniture). Toute
-- partie commence avec un kit d'environ 60 po, de décorations ouvertes au départ
EtatAtelier.KIT_MERCERIE = {
	bouton_nacre = 10,
	bouton_dore = 5,
	perle = 10,
	fleur_rose = 3,
	fleur_blanche = 2,
	ruban_rose = 150,
}
EtatAtelier.MERCERIE_MAX_UNITES = 999
EtatAtelier.MERCERIE_MAX_CM = 9999
EtatAtelier.LOT_GARNITURE = 50 -- cm par lot de garniture acheté
EtatAtelier.ACHAT_MERCERIE_MAX = 99 -- unités ou lots par achat
EtatAtelier.SOUVENIRS_OFFERTS = 5 -- exemplaires du souvenir d'un événement qui a lieu
-- Sous-projet 6 : le tissu coupé laisse une bande entamée en haut du rouleau, avec ses trous ; au-delà de 24 trous,
-- elle est jetée d'elle-même
EtatAtelier.TROUS_MAX = 24
EtatAtelier.ENTAME_MAX = 50 -- dm : au-delà, la bande est jetée aussi (sous elle, un rouleau de 10 m garde de quoi couper toute robe)

local function refus(message)
	return { ok = false, erreur = message }
end

-- Refus du premier élément encore fermé (déblocages : prestige ou amitié), ou nil
local function fermes(self, genre, ids)
	for _, id in ipairs(ids) do
		if not Deblocages.ouvert(self, genre, id) then
			return refus(Deblocages.message(genre, id))
		end
	end
	return nil
end

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Copie profonde de données simples (tables, nombres, textes, booléens)
local function copie(v)
	if type(v) ~= "table" then
		return v
	end
	local c = {}
	for k, x in pairs(v) do
		c[k] = copie(x)
	end
	return c
end

-- Égalité profonde de données simples
local function pareil(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, x in pairs(a) do
		if not pareil(x, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- Champs de l'état échangés avec le serveur (les rouleaux à part : ce sont des objets Coupon)
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites", "ventes", "lettres", "histoire", "mercerie", "entames" }

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
		accessoires = {}, -- décorations posées, au format de la recette
		robes = {}, -- recettes des robes livrées, la plus récente en premier
		-- Sous-projet 2 : fiche de chaque cliente venue ([id] = { amitie, vues, derniere, mesures?, ajustement? }),
		-- points de prestige, robes livrées, visites (numéro de la dernière, pour savoir qui revient), robes vendues
		clientes = {},
		prestige = 0,
		livraisons = 0,
		visites = 0,
		ventes = 0,
		lettres = {}, -- le courrier : { { cliente, commande } }, trois au plus
		histoire = { faites = {} }, -- sous-projet 3 : les commandes d'histoire livrées ([idCommande] = true)
		mercerie = table.clone(EtatAtelier.KIT_MERCERIE), -- sous-projet 6
		-- Sous-projet 6 : la bande entamée en haut de chaque rouleau ([idTissu] = { bas = dm, trous = { { piece, x, y,
		-- angle } } }), comptée dans le stock ; absente : un rouleau neuf
		entames = {},
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

-- Le tissu neuf du rouleau déroulé (10 m au plus), sous la bande entamée (dm)
function EtatAtelier:stockNeuf(idTissu)
	local entame = self.entames[idTissu]
	return math.max(0, math.min(self.stock[idTissu] or 0, Recette.LONGUEUR_MAX) - (entame and entame.bas or 0))
end

-- Le tissu neuf de chaque tissu en stock ([idTissu] = dm) : ce que le métrage conseillé compte
function EtatAtelier:stocksNeufs()
	local out = {}
	for idTissu in pairs(self.stock) do
		out[idTissu] = self:stockNeuf(idTissu)
	end
	return out
end

-- Le tissu coupé reste sur le rouleau : les pièces de chaque rouleau deviennent des trous de sa bande entamée, qui
-- descend jusqu'au bas de la plus basse. Au-delà de 24 trous ou de 5 m, la bande est jetée (retirée du stock). Renvoie les bandes
-- jetées ({ { tissu, dm } }), ou nil
local function entamer(self)
	local jetees = {}
	for idTissu, coupon in pairs(self.coupons) do
		if next(coupon.poses) then
			local trous, ids = table.clone(coupon.trous), {}
			for idPiece in pairs(coupon.poses) do
				table.insert(ids, idPiece)
			end
			table.sort(ids) -- (un ordre stable, d'une copie à l'autre)
			for _, idPiece in ipairs(ids) do
				local p = coupon.poses[idPiece]
				table.insert(trous, { piece = idPiece, x = p.x, y = p.y, angle = p.angle })
			end
			local bas = coupon:longueurUtilisee()
			if #trous > EtatAtelier.TROUS_MAX or bas > EtatAtelier.ENTAME_MAX then
				self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - bas)
				self.entames[idTissu] = nil
				table.insert(jetees, { tissu = idTissu, dm = bas })
			else
				self.entames[idTissu] = { bas = bas, trous = trous }
			end
		end
	end
	self.coupons = {}
	table.sort(jetees, function(a, b)
		return a.tissu < b.tissu
	end)
	return if #jetees > 0 then jetees else nil
end

-- Une robe libre (prêt-à-porter) : ni cliente ni exigence ni acompte ; une taille standard, dont le mannequin
-- prend les mesures. On va droit au carnet ; à la photo, on la vend ou on l'offre. Ouverte après deux commandes
-- livrées.
function EtatAtelier:nouvelleRobeLibre(taille)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	if self.livraisons < EtatAtelier.LIBRES_APRES then
		return refus("Les robes libres s'ouvrent après deux commandes livrées.")
	end
	if type(taille) ~= "string" or not Catalogue.TAILLES[taille] then
		return refus("Taille inconnue.")
	end
	self.visites += 1 -- (un numéro pour la reconnaître d'une copie à l'autre)
	self.commande = { libre = true, taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = {}, numero = self.visites }
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "carnet"
	return { ok = true, commande = self.commande }
end

-- Une cliente entre avec sa commande : sa visite est notée, elle verse l'acompte, on prend d'abord ses mesures
-- (étape « mesures ») ; une cliente déjà venue peut les reprendre
local function accueillir(self, id, commande)
	local fiche = self.clientes[id] or { amitie = 0, vues = 0, derniere = 0 }
	self.clientes[id] = fiche
	self.visites += 1
	fiche.vues += 1
	fiche.derniere = self.visites
	self.commande = commande
	self.commande.numero = self.visites -- la reconnaît d'une copie à l'autre (la scène garde la même cliente)
	-- L'acompte : un quart de la base, versé tout de suite, déduit de la paie ; gardé en cas d'abandon
	local acompte = math.floor(EtatAtelier.ACOMPTE * Notation.base(EtatAtelier.PIECES_ACOMPTE, #self.commande.exigences))
	self.commande.acompte = acompte
	self.argent = math.max(self.argent, EtatAtelier.FILET) + acompte
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "mesures"
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1, acompte = acompte }
end

-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local id = Clientes.prochaine(self.clientes, Progression.niveauPrestige(self.prestige))
	return accueillir(self, id, Commandes.generer(rng, Clientes.get(id), self))
end

-- Inviter la cliente d'une lettre (indice dans le courrier) : elle vient avec la commande annoncée ; livrée et
-- acceptée, elle rapporte un point d'amitié de plus
function EtatAtelier:inviter(indice)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local lettre = type(indice) == "number" and self.lettres[indice] or nil
	if not lettre then
		return refus("Cette lettre n'existe pas.")
	end
	table.remove(self.lettres, indice)
	lettre.commande.parLettre = true
	return accueillir(self, lettre.cliente, lettre.commande)
end

-- La commande de l'événement en cours (sous-projet 3) : sa prochaine robe, de la cliente et avec la tenue du
-- tableau de l'histoire (jamais d'un appel du client) ; même accueil que la clochette
function EtatAtelier:commandeHistoire()
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local def = Histoire.prochaine(self)
	if not def then
		return refus("Aucun événement ne s'annonce pour l'instant.")
	end
	local cliente = Clientes.get(def.cliente)
	return accueillir(self, def.cliente, { cliente = def.cliente, taille = cliente.taille, exigences = copie(def.exigences), histoire = def.id })
end

-- Le courrier : après cinq commandes livrées, une lettre arrive toutes les deux robes (livrées ou vendues), d'une
-- cliente déjà venue tirée au hasard, avec la commande qu'elle passera (on en voit la première exigence). Trois
-- lettres au plus ; elles n'expirent pas. Renvoie la lettre arrivée, ou nil
local function courrier(self, rng)
	if not rng or self.livraisons < EtatAtelier.COURRIER_APRES or #self.lettres >= EtatAtelier.LETTRES_MAX or (self.livraisons + self.ventes) % 2 ~= 0 then
		return nil
	end
	local venues = {}
	for _, c in ipairs(Clientes.LISTE) do
		local f = self.clientes[c.id]
		if f and f.vues > 0 then
			table.insert(venues, c)
		end
	end
	if #venues == 0 then
		return nil
	end
	local cliente = venues[rng:NextInteger(1, #venues)]
	local lettre = { cliente = cliente.id, commande = Commandes.generer(rng, cliente, self) }
	table.insert(self.lettres, lettre)
	return lettre
end

-- Mesures prises au ruban (dm) : trois nombres dans les bornes d'une recette, à moins de 1,5 dm des vraies.
-- Le patron et le mannequin suivent les mesures prises ; l'ajustement (Notation) note leur justesse. Elles
-- sont gardées dans la fiche de la cliente pour sa prochaine visite.
function EtatAtelier:mesurer(prises)
	if self.etape ~= "mesures" then
		return refus("Ce n'est pas le moment de mesurer.")
	end
	if type(prises) ~= "table" then
		return refus(MESURE_INVALIDE)
	end
	local cliente = Clientes.get(self.commande.cliente)
	if not cliente then
		return refus("Aucune cliente à mesurer.")
	end
	local propres = {}
	for _, cle in ipairs({ "poitrine", "taille", "hanches" }) do
		local v = prises[cle]
		if not fini(v) or math.abs(v - cliente.mesures[cle]) > EtatAtelier.ECART_MESURE_MAX then
			return refus(MESURE_INVALIDE)
		end
		propres[cle] = math.round(v * 100) / 100
	end
	if propres.poitrine < Recette.POITRINE[1] or propres.poitrine > Recette.POITRINE[2] or propres.taille < Recette.TAILLE[1]
		or propres.taille > Recette.TAILLE[2] or propres.hanches < Recette.HANCHES[1] or propres.hanches > Recette.HANCHES[2]
		or propres.taille > propres.poitrine or propres.taille > propres.hanches then
		return refus(MESURE_INVALIDE)
	end
	local ajustement = Notation.ajustement(cliente.mesures, propres)
	self.commande.mesures, self.commande.ajustement = propres, ajustement
	local fiche = self.clientes[cliente.id] or { amitie = 0, vues = 1, derniere = self.visites }
	self.clientes[cliente.id] = fiche
	fiche.mesures, fiche.ajustement = copie(propres), ajustement
	self.etape = "carnet"
	return { ok = true, ajustement = ajustement }
end

-- Une cliente déjà mesurée : ses mesures de la dernière fois, d'un clic
function EtatAtelier:reprendreMesures()
	if self.etape ~= "mesures" then
		return refus("Ce n'est pas le moment de mesurer.")
	end
	local fiche = self.clientes[self.commande.cliente]
	if not fiche or not fiche.mesures then
		return refus("Ses mesures n'ont jamais été prises.")
	end
	-- (l'ajustement est recalculé : il ne dépend que des mesures gardées et des vraies)
	self.commande.mesures = copie(fiche.mesures)
	self.commande.ajustement = Notation.ajustement(Clientes.get(self.commande.cliente).mesures, fiche.mesures)
	self.etape = "carnet"
	return { ok = true, ajustement = self.commande.ajustement }
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
	local variantes, tissusChoisis = {}, {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		table.insert(variantes, croquis[famille])
	end
	for _, id in ipairs(pieces) do
		table.insert(tissusChoisis, choix[id])
	end
	local ferme = fermes(self, "variantes", variantes) or fermes(self, "tissus", tissusChoisis)
	if ferme then
		return ferme
	end
	-- Seules les quatre familles sont gardées : un champ en trop envoyé par le client ne reste pas sur le
	-- serveur (ni dans chaque réponse, ni plus tard dans la sauvegarde)
	local propre = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		propre[famille] = croquis[famille]
	end
	self.croquis = propre
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
	local ferme = fermes(self, "tissus", { idTissu })
	if ferme then
		return ferme
	end
	local prix = EtatAtelier.prix(idTissu, dm)
	if prix > self.argent then
		return refus("Pas assez d'argent.")
	end
	self.argent -= prix
	self.stock[idTissu] = (self.stock[idTissu] or 0) + dm
	local coupon = self.coupons[idTissu]
	if coupon then
		-- le rouleau se déroule plus loin pendant la découpe, jusqu'à la longueur qu'une recette accepte
		coupon.longueur = math.min(coupon.longueur + dm, Recette.LONGUEUR_MAX)
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
		local entame = self.entames[t]
		self.coupons[t] = Coupon.nouveau(math.min(self.stock[t], Recette.LONGUEUR_MAX), entame and entame.trous)
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
	local jetees
	if #self:piecesAPoser() == 0 then
		if self.commande.libre then
			-- le prix des matières d'une robe libre : ce qu'elle ajoute à la bande entamée de chaque rouleau
			local matieres = 0
			for idTissu, c in pairs(self.coupons) do
				matieres += EtatAtelier.prix(idTissu, c:ajout())
			end
			self.commande.matieres = matieres
		end
		jetees = entamer(self)
		self.etape = "epinglage"
	end
	return { ok = true, reste = #self:piecesAPoser(), jetees = jetees }
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

-- Copie propre d'une décoration déjà validée (seulement les champs connus)
local function copieAccessoire(a)
	local c = { id = a.id, piece = a.piece, copie = a.copie }
	if a.trajet then
		c.trajet = {}
		for k, pt in ipairs(a.trajet) do
			c.trajet[k] = { u = pt.u, v = pt.v }
		end
	else
		c.u, c.v, c.echelle, c.angle = a.u, a.v, a.echelle, a.angle
	end
	return c
end

-- Prix de décorations posées sur les pièces d'une recette : objets à l'unité, garnitures au dm
-- (arrondi au-dessus, par garniture)
function EtatAtelier.prixDecorations(pieces, accessoires)
	local total = 0
	for _, a in ipairs(accessoires) do
		local def = Catalogue.accessoire(a.id)
		if def.genre == "garniture" then
			total += math.ceil(def.prix * Notation.longueurGarniture(pieces[a.piece].id, a.trajet) - 1e-9)
		else
			total += def.prix
		end
	end
	return total
end

-- Ce que des décorations prennent à la mercerie : [id] = unités (un objet) ou cm (une garniture, arrondis au-dessus)
function EtatAtelier.besoinsMercerie(pieces, accessoires)
	local out = {}
	for _, a in ipairs(accessoires) do
		local def = Catalogue.accessoire(a.id)
		local q = if def.genre == "garniture" then math.ceil(Notation.longueurGarniture(pieces[a.piece].id, a.trajet) * 10 - 1e-9) else 1
		out[a.id] = (out[a.id] or 0) + q
	end
	return out
end

-- Acheter de la mercerie : ce qui est ouvert, de 1 à 99 unités (un objet) ou lots de 50 cm (une garniture), au prix
-- du catalogue ; 999 unités ou 9 999 cm au plus en stock
function EtatAtelier:acheterMercerie(id, quantite)
	local def = type(id) == "string" and Catalogue.accessoire(id)
	if not def then
		return refus("Article inconnu.")
	end
	if type(quantite) ~= "number" or quantite ~= math.floor(quantite) or quantite < 1 or quantite > EtatAtelier.ACHAT_MERCERIE_MAX then
		return refus("Quantité invalide.")
	end
	local ferme = fermes(self, "accessoires", { id })
	if ferme then
		return ferme
	end
	local garniture = def.genre == "garniture"
	local ajout = if garniture then quantite * EtatAtelier.LOT_GARNITURE else quantite
	local prix = if garniture then def.prix * ajout / 10 else def.prix * quantite
	if (self.mercerie[id] or 0) + ajout > (if garniture then EtatAtelier.MERCERIE_MAX_CM else EtatAtelier.MERCERIE_MAX_UNITES) then
		return refus("Ta mercerie n'a plus de place pour cet article.")
	end
	if prix > self.argent then
		return refus("Pas assez d'argent.")
	end
	self.argent -= prix
	self.mercerie[id] = (self.mercerie[id] or 0) + ajout
	return { ok = true, prix = prix, quantite = ajout }
end

-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture, décorations),
-- ou nil tant que toutes les pièces ne sont pas coupées
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
		accessoires = (function()
			local out = {}
			for i, a in ipairs(self.accessoires) do
				out[i] = copieAccessoire(a)
			end
			return out
		end)(),
	}
end

-- Décorations : la liste complète, envoyée quand on quitte le poste (spec §6). Vérifiée comme une
-- recette (identifiants, 300 objets et 64 points au plus, u et v dans [0 ; 1], échelle et angle
-- bornés). Sous-projet 6 : la différence avec la liste précédente est prise à la mercerie (ce qu'on retire y
-- revient) ; ce qui manque est refusé.
function EtatAtelier:decorer(liste)
	if self.etape ~= "decorations" then
		return refus("Ce n'est pas le moment de décorer.")
	end
	if type(liste) ~= "table" then
		return refus("Décorations invalides.")
	end
	local recette = self:recette()
	recette.accessoires = liste
	local ok, erreur = Recette.valider(recette)
	if not ok then
		return refus(erreur)
	end
	local ids = {}
	for _, a in ipairs(liste) do
		table.insert(ids, a.id)
	end
	local ferme = fermes(self, "accessoires", ids)
	if ferme then
		return ferme
	end
	local propres = {}
	for i, a in ipairs(liste) do
		propres[i] = copieAccessoire(a)
	end
	local avant = EtatAtelier.besoinsMercerie(recette.pieces, self.accessoires)
	local apres = EtatAtelier.besoinsMercerie(recette.pieces, propres)
	local manque, variations = {}, {}
	for _, def in ipairs(Catalogue.Accessoires) do -- (dans l'ordre du catalogue : un message stable)
		local variation = (apres[def.id] or 0) - (avant[def.id] or 0)
		local stock = self.mercerie[def.id] or 0
		if variation > stock then
			table.insert(manque, if def.genre == "garniture" then ("%s, %d cm"):format(def.nom, variation - stock) else ("%s ×%d"):format(def.nom, variation - stock))
		elseif variation ~= 0 then
			variations[def.id] = variation
		end
	end
	if #manque > 0 then
		return refus("Mercerie insuffisante : il te manque " .. table.concat(manque, " ; ") .. ".")
	end
	for id, variation in pairs(variations) do
		local reste = (self.mercerie[id] or 0) - variation
		self.mercerie[id] = if reste > 0 then reste else nil
	end
	self.accessoires = propres
	self.etape = "photo"
	return { ok = true, prix = 0 }
end

-- De la photo, on peut revenir ajuster les décorations
function EtatAtelier:retourDecorations()
	if self.etape ~= "photo" then
		return refus("Ce n'est pas le moment.")
	end
	self.etape = "decorations"
	return { ok = true }
end

-- Bilan de la robe en cours (styles, qualité, teinte, accessoires) ; la qualité tient compte de l'ajustement aux
-- mesures de la cliente
function EtatAtelier:bilan()
	local bilan = Notation.bilan(self:recette())
	bilan.ajustement = self.commande and self.commande.ajustement or 1
	bilan.qualite *= bilan.ajustement
	return bilan
end

-- L'amitié de la cliente de la commande change (robe acceptée ou abandonnée) ; renvoie le détail pour le bilan.
-- Un abandon ne fait jamais perdre un niveau : ce qu'il a ouvert reste ouvert
local function amitie(self, reussie, qualite)
	local id = self.commande and self.commande.cliente
	local fiche = id and self.clientes[id]
	if not fiche then
		return nil
	end
	local avant = fiche.amitie
	local plancher = Progression.SEUILS_AMITIE[Progression.niveauAmitie(avant) + 1]
	local lettre = if reussie and self.commande.parLettre then Progression.BONUS_LETTRE else 0
	fiche.amitie = math.max(plancher, avant + Progression.gainAmitie(reussie, qualite) + lettre)
	return { cliente = id, gain = fiche.amitie - avant, points = fiche.amitie, niveau = Progression.niveauAmitie(fiche.amitie), niveauAvant = Progression.niveauAmitie(avant) }
end

-- Fin de la commande : l'atelier est prêt pour la suivante
local function terminer(self)
	self.commande, self.croquis = nil, nil
	self.tissus, self.coupees, self.coupons = {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "accueil"
end

-- Livraison : la cliente juge la robe (styles, qualité, couleur, accessoires) d'après sa recette.
-- Acceptée : paie = base × (0,5 + qualité), la robe part en vitrine. Refusée : retouche ou abandon.
-- rng (facultatif) : de quoi tirer une lettre, si le courrier en apporte une
function EtatAtelier:livrer(rng)
	if self.etape ~= "photo" then
		return refus("Ce n'est pas le moment de livrer.")
	end
	if self.commande.libre then
		return refus("Une robe libre se vend ou s'offre.")
	end
	local recette = self:recette()
	local bilan = self:bilan()
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
	if not reussie then
		self.etape = "refus"
		return { ok = true, reussie = false, ratees = ratees, bilan = bilan }
	end
	local avant = { prestige = self.prestige, clientes = {}, histoire = { faites = table.clone(self.histoire.faites) } } -- pour dire ce que la livraison a ouvert
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	-- Une robe d'histoire livrée : faite ; la dernière de son événement le fait avoir lieu (épilogue, souvenir,
	-- prestige en plus)
	local evenement
	local histoireFaite = self.commande.histoire
	if self.commande.histoire then
		self.histoire.faites[self.commande.histoire] = true
		local _, ev = Histoire.commande(self.commande.histoire)
		if ev and Histoire.aEuLieu(self, ev.id) then
			evenement = { id = ev.id, nom = ev.nom, epilogue = ev.epilogue, souvenir = ev.souvenir }
			-- (sous-projet 6) des exemplaires du souvenir, dans la mercerie
			self.mercerie[ev.souvenir] = math.min((self.mercerie[ev.souvenir] or 0) + EtatAtelier.SOUVENIRS_OFFERTS, EtatAtelier.MERCERIE_MAX_UNITES)
		end
	end
	local paie = Notation.paie(Notation.poids(recette.pieces), #self.commande.exigences, bilan.qualite)
	local acompte = self.commande.acompte or 0
	local verse = math.max(0, paie - acompte) -- l'acompte est déjà dans la caisse
	self.argent += verse
	local gainAmitie = amitie(self, true, bilan.qualite)
	local niveauAvant = Progression.niveauPrestige(self.prestige)
	local gainPrestige = Progression.prestigeLivraison(paie) + (if evenement then Histoire.PRESTIGE_EVENEMENT else 0)
	self.prestige += gainPrestige
	self.livraisons += 1
	local prestige = { gain = gainPrestige, points = self.prestige, niveau = Progression.niveauPrestige(self.prestige), niveauAvant = niveauAvant }
	table.insert(self.robes, 1, recette)
	for k = #self.robes, EtatAtelier.ROBES_GARDEES + 1, -1 do
		self.robes[k] = nil
	end
	terminer(self)
	local nouveaux = Deblocages.nouveaux(avant, self)
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux, lettre = courrier(self, rng), evenement = evenement, histoireFaite = histoireFaite }
end

-- Robes libres : le prestige et les amitiés avant la vente ou le cadeau (pour dire ce qui s'ouvre), le prestige
-- gagné, la robe gardée en vitrine
local function progres(self)
	local avant = { prestige = self.prestige, clientes = {}, histoire = { faites = table.clone(self.histoire.faites) } }
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	return avant
end
local function gagnerPrestige(self, gain)
	local niveauAvant = Progression.niveauPrestige(self.prestige)
	self.prestige += gain
	return { gain = gain, points = self.prestige, niveau = Progression.niveauPrestige(self.prestige), niveauAvant = niveauAvant }
end
local function garderRobe(self, recette)
	table.insert(self.robes, 1, recette)
	for k = #self.robes, EtatAtelier.ROBES_GARDEES + 1, -1 do
		self.robes[k] = nil
	end
end

-- Prix de vente d'une robe libre : (matières + décorations + main d'œuvre) × (0,5 + qualité), plus le bonus de
-- prestige (6 % par niveau au-delà du premier)
function EtatAtelier:prixVente()
	local recette = self:recette()
	local base = (self.commande.matieres or 0) + EtatAtelier.prixDecorations(recette.pieces, self.accessoires) + EtatAtelier.MAIN_OEUVRE * Notation.poids(recette.pieces)
	local bonus = Progression.bonusVente(Progression.niveauPrestige(self.prestige))
	return math.round(base * (0.5 + self:bilan().qualite) * (1 + bonus))
end

-- Vendre la robe libre : le prix, du prestige ; elle part en vitrine. Le prestige vient de la main d'œuvre
-- seule (ce qu'elle rapporterait sans matières ni décorations, / 15) : il ne s'achète pas en décorant.
-- rng : de quoi tirer une lettre, comme pour livrer
function EtatAtelier:vendre(rng)
	if self.etape ~= "photo" or not self.commande.libre then
		return refus("Seule une robe libre se vend, une fois présentée.")
	end
	local avant = progres(self)
	local recette, bilan, prix = self:recette(), self:bilan(), self:prixVente()
	self.argent += prix
	self.ventes += 1
	local bonus = Progression.bonusVente(Progression.niveauPrestige(self.prestige))
	local mainOeuvre = math.round(EtatAtelier.MAIN_OEUVRE * Notation.poids(recette.pieces) * (0.5 + bilan.qualite) * (1 + bonus))
	local prestige = gagnerPrestige(self, Progression.prestigeVente(mainOeuvre))
	garderRobe(self, recette)
	terminer(self)
	return { ok = true, prix = prix, bilan = bilan, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self), lettre = courrier(self, rng) }
end

-- Offrir la robe libre à une cliente déjà venue : son amitié monte selon le score de son style préféré le plus
-- haut (+1 à +4), le prestige de 2 ; pas d'argent. La robe part en vitrine
function EtatAtelier:offrir(idCliente)
	if self.etape ~= "photo" or not self.commande.libre then
		return refus("Seule une robe libre s'offre, une fois présentée.")
	end
	local cliente = type(idCliente) == "string" and Clientes.get(idCliente)
	local fiche = cliente and self.clientes[cliente.id]
	if not fiche or fiche.vues == 0 then
		return refus("On n'offre une robe qu'à une cliente déjà venue.")
	end
	local avant = progres(self)
	local recette, bilan = self:recette(), self:bilan()
	local score = 0
	for _, style in ipairs(cliente.styles) do
		score = math.max(score, bilan.styles[style] or 0)
	end
	local amitieAvant = fiche.amitie
	fiche.amitie += Progression.gainCadeau(score)
	local gainAmitie = { cliente = cliente.id, gain = fiche.amitie - amitieAvant, points = fiche.amitie, niveau = Progression.niveauAmitie(fiche.amitie), niveauAvant = Progression.niveauAmitie(amitieAvant) }
	local prestige = gagnerPrestige(self, Progression.PRESTIGE_CADEAU)
	garderRobe(self, recette)
	terminer(self)
	return { ok = true, cliente = cliente.id, bilan = bilan, amitie = gainAmitie, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self) }
end

-- Après un refus : retoucher (retour aux décorations) ou abandonner (ni paie ni vitrine)
function EtatAtelier:retoucher()
	if self.etape ~= "refus" then
		return refus("Il n'y a rien à retoucher.")
	end
	self.etape = "decorations"
	return { ok = true }
end

function EtatAtelier:abandonner()
	if self.etape ~= "refus" then
		return refus("Il n'y a rien à abandonner.")
	end
	local perte = amitie(self, false, 0)
	terminer(self)
	return { ok = true, amitie = perte }
end

-- Abandonne la robe en cours (les pièces déjà coupées deviennent des trous de la bande entamée), garde la commande
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
	if self.etape == "mesures" then
		return refus("Il n'y a rien à recommencer.")
	end
	local jetees = entamer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
	self.etape = "carnet"
	return { ok = true, jetees = jetees }
end

-- Une pièce de ce tissu est-elle déjà coupée pour la robe en cours ?
function EtatAtelier:coupeDans(idTissu)
	for idPiece in pairs(self.coupees) do
		if self.tissus[idPiece] == idTissu then
			return true
		end
	end
	return false
end

-- Jette la bande entamée d'un rouleau (elle quitte le stock) : à l'achat, ou à la table tant qu'aucune pièce de ce
-- tissu n'est coupée pour la robe en cours (le rouleau repart neuf)
function EtatAtelier:jeterEntame(idTissu)
	if self.etape ~= "achat" and self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment de jeter du tissu.")
	end
	if type(idTissu) ~= "string" or not Catalogue.tissu(idTissu) then
		return refus("Tissu inconnu.")
	end
	local entame = self.entames[idTissu]
	if not entame then
		return refus("Ce rouleau n'est pas entamé.")
	end
	if self:coupeDans(idTissu) then
		return refus("Des pièces de ce tissu sont déjà coupées pour cette robe.")
	end
	local coupon = self.coupons[idTissu]
	self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - entame.bas)
	self.entames[idTissu] = nil
	if coupon then
		self.coupons[idTissu] = Coupon.nouveau(math.min(self.stock[idTissu], Recette.LONGUEUR_MAX))
	end
	return { ok = true, dm = entame.bas }
end

local function rouleauxExportes(coupons)
	local out = {}
	for idTissu, coupon in pairs(coupons) do
		out[idTissu] = { longueur = coupon.longueur, poses = copie(coupon.poses), trous = copie(coupon.trous) }
	end
	return out
end

-- L'état en données simples, sans métatable : ce que le serveur envoie au client après chaque action.
-- Les rouleaux deviennent { longueur, poses, trous }. robes (facultatif) : nombre de robes copiées, les plus
-- récentes (toutes par défaut)
function EtatAtelier:exporter(robes)
	local d = {}
	for _, cle in ipairs(CHAMPS) do
		if cle ~= "robes" then
			d[cle] = copie(self[cle])
		end
	end
	d.robes = {}
	for i = 1, math.min(#self.robes, robes or #self.robes) do
		d.robes[i] = copie(self.robes[i])
	end
	d.coupons = rouleauxExportes(self.coupons)
	return d
end

-- Remplace l'état par un état exporté, sur place : les écrans gardent le même objet. Ce qui n'a pas
-- changé garde sa table (la scène reconnaît ainsi la même commande d'une action à l'autre).
-- Renvoie l'état et si quelque chose a changé.
function EtatAtelier:charger(d)
	local change = false
	for _, cle in ipairs(CHAMPS) do
		if not pareil(self[cle], d[cle]) then
			self[cle] = copie(d[cle])
			change = true
		end
	end
	local exportes = rouleauxExportes(self.coupons)
	if not pareil(exportes, d.coupons) then
		change = true
		local rouleaux = {}
		for idTissu, r in pairs(d.coupons) do
			if self.coupons[idTissu] and pareil(exportes[idTissu], r) then
				rouleaux[idTissu] = self.coupons[idTissu] -- (inchangé : pas reconstruit, ses trous coûtent à prendre)
			else
				local coupon = Coupon.nouveau(r.longueur, r.trous)
				for idPiece, pose in pairs(r.poses) do
					coupon:poser(idPiece, pose)
				end
				rouleaux[idTissu] = coupon
			end
		end
		self.coupons = rouleaux
	end
	return self, change
end

return EtatAtelier
