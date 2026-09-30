local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Commandes = U.module("Commandes")
local Deblocages = U.module("Deblocages")
local Catalogue = U.module("Catalogue")

-- Commandes d'un débutant : jamais d'accessoire fermé, un style demandé à 50 au plus, toujours réalisables
-- avec ce qui est ouvert
for n = 1, 30 do
	local e = EtatAtelier.nouveau(1000)
	e.visites, e.clientes.colette = n, { amitie = 0, vues = 1, derniere = n }
	local r = e:nouvelleCommande(Random.new(n))
	local ouverts = Deblocages.ouverts(e)
	U.verifier(r.ok and Commandes.realisable(e.commande.exigences, ouverts), "commande " .. n .. " réalisable avec le catalogue du départ")
	for _, x in ipairs(e.commande.exigences) do
		U.verifier(x.type ~= "min" or x.valeur <= 50, "commande " .. n .. " : style demandé à 50 au plus au prestige 1")
		U.verifier(x.type ~= "accessoire" or ouverts.accessoires[x.id], "commande " .. n .. " : accessoire demandé ouvert")
	end
end
U.verifier(Commandes.plafond(1) == 5 and Commandes.plafond(2) == 6 and Commandes.plafond(4) == 8 and Commandes.plafond(8) == 8, "exigences de style : jusqu'à 50 au prestige 1, 80 au plus à partir du prestige 4")
U.verifier(not Commandes.realisable({ { type = "accessoire", id = "croix_argent" } }, Deblocages.ouverts({ prestige = 0, clientes = {} })), "un accessoire fermé : commande irréalisable")
U.verifier(Commandes.realisable({ { type = "accessoire", id = "croix_argent" } }), "sans restriction : réalisable")

-- Arrondis : un score qui vaut 30 à l'affichage (29,999999999999996) remplit « au moins 30 » ; 0,8 à l'arrondi près
-- vaut le point d'amitié d'une belle robe
local Notation = U.module("Notation")
local Progression = U.module("Progression")
local presque = { styles = { gothique = 30 - 4e-15, chic = 10 + 4e-15 }, qualite = 1, teinte = "noir", accessoires = {} }
U.verifier(Notation.verifierExigences({ { type = "min", style = "gothique", valeur = 30 } }, presque), "au moins 30 : 29,999999999999996 suffit (arrondi)")
U.verifier(Notation.verifierExigences({ { type = "max", style = "chic", valeur = 10 } }, presque), "au plus 10 : 10,000000000000004 passe (arrondi)")
U.verifier(Progression.gainAmitie(true, 0.79999999999999993) == 3, "qualité 0,8 à l'arrondi près : le point d'amitié d'une belle robe")

-- Le repli (après 30 tirages ratés) est lui aussi réalisable avec ce qui est ouvert, pour chaque cliente à son arrivée
local essais = Commandes.ESSAIS
Commandes.ESSAIS = 0
for _, c in ipairs(Clientes.LISTE) do
	local progres = { prestige = Progression.SEUILS_PRESTIGE[c.prestige], clientes = {} }
	local repli = Commandes.generer(Random.new(1), c, progres)
	U.verifier(#repli.exigences == 1 and Commandes.realisable(repli.exigences, Deblocages.ouverts(progres)), c.id .. " : le repli est réalisable dès son arrivée (" .. tostring(repli.exigences[1].style) .. " " .. tostring(repli.exigences[1].valeur) .. ")")
end
Commandes.ESSAIS = essais

-- Chaque cliente, dès son arrivée (son prestige atteint) : ses commandes sont réalisables avec ce qui est ouvert
local SEUILS = Progression.SEUILS_PRESTIGE
for _, c in ipairs(Clientes.LISTE) do
	local progres = { prestige = SEUILS[c.prestige], clientes = {} }
	local ouverts = Deblocages.ouverts(progres)
	local rng = Random.new(3)
	for n = 1, 20 do
		local commande = Commandes.generer(rng, c, progres)
		U.verifier(Commandes.realisable(commande.exigences, ouverts), c.id .. " : commande " .. n .. " réalisable dès son arrivée")
	end
end
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : le tirage trouve une vraie commande (un
-- « au moins » de 30 ou plus dans un de ses styles), réalisable avec ce qui est ouvert, jamais le repli (« au
-- moins » 20 ou 10, ou la qualité seule)
for _, prestige in ipairs({ 260, 380, 530 }) do
	for _, amitie in ipairs({ 0, 25 }) do
		for _, c in ipairs(Clientes.LISTE) do
			local progres = { prestige = prestige, clientes = { [c.id] = { amitie = amitie } } }
			local ouverts = Deblocages.ouverts(progres)
			local rng = Random.new(prestige + amitie)
			local replis = 0
			for _ = 1, 10 do
				local commande = Commandes.generer(rng, c, progres)
				local premiere = commande.exigences[1]
				if not (premiere.type == "min" and premiere.valeur >= 30 and table.find(c.styles, premiere.style) and Commandes.realisable(commande.exigences, ouverts)) then
					replis += 1
				end
			end
			U.verifier(replis == 0, ("%s au prestige %d, amitié %d : de vraies commandes, réalisables, sans repli (%d en défaut)"):format(c.id, prestige, amitie, replis))
		end
	end
end

-- Le carnet refuse une variante ou un tissu fermés ; l'amitié les ouvre
local e = EtatAtelier.nouveau(1000)
e:nouvelleCommande(Random.new(1))
e:mesurer(Clientes.get("colette").mesures)
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_ample" }
local tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_ample_devant = "coton_blanc", jupe_ample_dos = "coton_blanc" }
local r = e:validerCroquis(CROQUIS, tissus)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and e.etape == "carnet", "jupe ample fermée au départ")
e.clientes.colette.amitie = 7
U.verifier(e:validerCroquis(CROQUIS, tissus).ok, "amitié de Colette au niveau 2 : la jupe ample s'ouvre")
r = e:acheter("velours_noir", 5)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Velours noir (Prestige 4)." and e.stock.velours_noir == nil, "velours fermé au prestige 1")
e.prestige = 100
U.verifier(e:acheter("velours_noir", 5).ok, "prestige 4 : le velours s'achète")

-- Un abandon ne fait pas perdre un niveau d'amitié : ce qu'il a ouvert reste ouvert
e.etape = "refus"
r = e:abandonner()
U.verifier(r.ok and e.clientes.colette.amitie == 7 and r.amitie.gain == 0 and Deblocages.ouvert(e, "variantes", "jupe_ample"), "abandon au seuil du niveau 2 : l'amitié reste à 7, la jupe ample reste ouverte")

-- Les décorations fermées sont refusées
local d = EtatAtelier.nouveau(1000)
U.commander(d, Random.new(2))
d.prestige, d.clientes.ines.amitie = 0, 0
d.etape = "decorations"
d.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
d.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
for id in pairs(d.tissus) do
	d.coupees[id] = { x = 0, y = 0, angle = 0 }
	d.epinglees[id] = true
	d.coutures[id] = 1
end
local croix = { { id = "croix_argent", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } }
r = d:decorer(croix)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and d.etape == "decorations", "croix d'argent fermée sans l'amitié d'Inès")
d.clientes.ines.amitie = 18
U.verifier(d:decorer(croix).ok, "amitié d'Inès au niveau 4 : la croix se pose")
U.verifier(Catalogue.accessoire("croix_argent") ~= nil, "(la croix existe)")
