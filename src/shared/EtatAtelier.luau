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

local EtatAtelier = {}
EtatAtelier.__index = EtatAtelier

EtatAtelier.ARGENT_DEPART = 150
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
EtatAtelier.ACOMPTE = 0.25 -- part de la base versée quand la cliente passe commande
EtatAtelier.PIECES_ACOMPTE = 4 -- la base de l'acompte est celle de la robe la plus simple (quatre pièces)
EtatAtelier.ACHAT_MAX = 100 -- dm par achat
EtatAtelier.TOLERANCE_MESURES = 2 -- mesures de couture en plus ou en moins acceptées (spec §6)
EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
EtatAtelier.ECART_MESURE_MAX = 1.5 -- dm : une mesure plus loin de la vraie est refusée (ruban pas réglé)
local MESURE_INVALIDE = "Mesure invalide : règle chaque ruban au bord de la silhouette."
-- Étapes du plan 3b (le plan 3c ajoute la photo et la livraison après les décorations)
EtatAtelier.ROBES_GARDEES = 10 -- robes livrées gardées, la plus récente en vitrine (spec §6)
EtatAtelier.ETAPES = { "accueil", "mesures", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }

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
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites" }

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
		-- points de prestige, robes livrées, visites (numéro de la dernière, pour savoir qui revient)
		clientes = {},
		prestige = 0,
		livraisons = 0,
		visites = 0,
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

-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts. On prend
-- d'abord ses mesures (étape « mesures ») ; une cliente déjà venue peut les reprendre.
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local id = Clientes.prochaine(self.clientes, Progression.niveauPrestige(self.prestige))
	local fiche = self.clientes[id] or { amitie = 0, vues = 0, derniere = 0 }
	self.clientes[id] = fiche
	self.visites += 1
	fiche.vues += 1
	fiche.derniere = self.visites
	self.commande = Commandes.generer(rng, Clientes.get(id), self)
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
	self.commande.mesures, self.commande.ajustement = copie(fiche.mesures), fiche.ajustement or 1
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
		self.coupons[t] = Coupon.nouveau(math.min(self.stock[t], Recette.LONGUEUR_MAX))
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
-- bornés) ; on facture la différence avec la liste précédente (ce qu'on retire est remboursé).
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
	local difference = EtatAtelier.prixDecorations(recette.pieces, propres) - EtatAtelier.prixDecorations(recette.pieces, self.accessoires)
	if difference > self.argent then
		return refus("Pas assez d'argent pour ces décorations.")
	end
	self.argent -= difference
	self.accessoires = propres
	self.etape = "photo"
	return { ok = true, prix = difference }
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
	fiche.amitie = math.max(plancher, avant + Progression.gainAmitie(reussie, qualite))
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
function EtatAtelier:livrer()
	if self.etape ~= "photo" then
		return refus("Ce n'est pas le moment de livrer.")
	end
	local recette = self:recette()
	local bilan = self:bilan()
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
	if not reussie then
		self.etape = "refus"
		return { ok = true, reussie = false, ratees = ratees, bilan = bilan }
	end
	local avant = { prestige = self.prestige, clientes = {} } -- pour dire ce que la livraison a ouvert
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	local acompte = self.commande.acompte or 0
	local verse = math.max(0, paie - acompte) -- l'acompte est déjà dans la caisse
	self.argent += verse
	local gainAmitie = amitie(self, true, bilan.qualite)
	local niveauAvant = Progression.niveauPrestige(self.prestige)
	local gainPrestige = Progression.prestigeLivraison(paie)
	self.prestige += gainPrestige
	self.livraisons += 1
	local prestige = { gain = gainPrestige, points = self.prestige, niveau = Progression.niveauPrestige(self.prestige), niveauAvant = niveauAvant }
	table.insert(self.robes, 1, recette)
	for k = #self.robes, EtatAtelier.ROBES_GARDEES + 1, -1 do
		self.robes[k] = nil
	end
	terminer(self)
	local nouveaux = Deblocages.nouveaux(avant, self)
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux }
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

-- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
	if self.etape == "mesures" then
		return refus("Il n'y a rien à recommencer.")
	end
	consommer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
	self.etape = "carnet"
	return { ok = true }
end

local function rouleauxExportes(coupons)
	local out = {}
	for idTissu, coupon in pairs(coupons) do
		out[idTissu] = { longueur = coupon.longueur, poses = copie(coupon.poses) }
	end
	return out
end

-- L'état en données simples, sans métatable : ce que le serveur envoie au client après chaque action.
-- Les rouleaux deviennent { longueur, poses }. robes (facultatif) : nombre de robes copiées, les plus
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
	if not pareil(rouleauxExportes(self.coupons), d.coupons) then
		change = true
		self.coupons = {}
		for idTissu, r in pairs(d.coupons) do
			local coupon = Coupon.nouveau(r.longueur)
			for idPiece, pose in pairs(r.poses) do
				coupon:poser(idPiece, pose)
			end
			self.coupons[idTissu] = coupon
		end
	end
	return self, change
end

return EtatAtelier
