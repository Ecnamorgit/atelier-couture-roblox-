-- Sous-projet 6 : la mercerie achetée d'avance. Un stock (à l'unité pour les objets, en cm pour les garnitures) ;
-- les décorations y puisent au lieu de l'argent, ce qu'on retire y revient ; un kit de départ ; cinq souvenirs à
-- chaque événement.
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Deblocages = U.module("Deblocages")
local Notation = U.module("Notation")
local Clientes = U.module("Clientes")
local Histoire = U.module("Histoire")

-- Une robe simple, coupée, épinglée et cousue, aux décorations (sans rien de posé)
local function aDecorer(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
end

-- Le kit de départ : d'environ 60 po, des décorations ouvertes au départ
do
	local e = EtatAtelier.nouveau(100)
	local valeur, fermes, dedans = 0, {}, true
	for id, q in pairs(EtatAtelier.KIT_MERCERIE) do
		local a = Catalogue.accessoire(id)
		valeur += if a.genre == "garniture" then a.prix * q / 10 else a.prix * q
		if not Deblocages.ouvert(e, "accessoires", id) then
			table.insert(fermes, id)
		end
		dedans = dedans and e.mercerie[id] == q
	end
	U.verifier(dedans, "le kit est dans la mercerie d'une partie neuve")
	U.verifier(valeur >= 50 and valeur <= 75 and #fermes == 0, ("un kit d'environ 60 po (%d), ouvert au départ (fermés : %s)"):format(valeur, table.concat(fermes, ", ")))
	U.verifier(e.mercerie ~= EtatAtelier.KIT_MERCERIE, "une copie du kit (deux parties ne partagent pas leur mercerie)")
end

-- Acheter : ce qui est ouvert, de 1 à 99, les garnitures par 50 cm, au prix du catalogue
do
	local e = EtatAtelier.nouveau(100)
	U.toutOuvrir(e)
	e.mercerie = {}
	local r = e:acheterMercerie("perle", 5)
	U.verifier(r.ok and r.prix == 5 and e.argent == 95 and e.mercerie.perle == 5, "5 perles : 5 po, dans le stock")
	r = e:acheterMercerie("dentelle_blanche", 2)
	U.verifier(r.ok and r.prix == 20 and e.argent == 75 and e.mercerie.dentelle_blanche == 100, "deux fois 50 cm de dentelle blanche (2 po/dm) : 20 po, 100 cm")
	U.verifier(not e:acheterMercerie("perle", 0).ok and not e:acheterMercerie("perle", 100).ok and not e:acheterMercerie("perle", 1.5).ok, "de 1 à 99, un nombre entier")
	U.verifier(not e:acheterMercerie("inconnue", 1).ok and not e:acheterMercerie(nil, 1).ok, "un article inconnu : refusé")
	local r2 = EtatAtelier.nouveau(100):acheterMercerie("croix_argent", 1)
	U.verifier(not r2.ok and string.find(r2.erreur, "Pas encore ouvert", 1, true) == 1, "un article fermé : refusé, avec ce qu'il faut pour l'ouvrir (" .. tostring(r2.erreur) .. ")")
	e.argent = 3
	U.verifier(not e:acheterMercerie("fleur_rose", 2).ok and e.argent == 3 and e.mercerie.fleur_rose == nil, "pas assez d'argent : refusé, rien ne change")
	e.argent = 10000
	e.mercerie.perle = EtatAtelier.MERCERIE_MAX_UNITES - 2
	U.verifier(not e:acheterMercerie("perle", 5).ok and e:acheterMercerie("perle", 2).ok and e.mercerie.perle == EtatAtelier.MERCERIE_MAX_UNITES, "999 unités au plus")
	e.mercerie.ruban_rose = EtatAtelier.MERCERIE_MAX_CM - 60
	U.verifier(not e:acheterMercerie("ruban_rose", 2).ok and e:acheterMercerie("ruban_rose", 1).ok, "9 999 cm au plus")
end

-- Décorer puise dans le stock : pas d'argent ; ce qui manque est refusé ; ce qu'on retire revient au stock
do
	local e = EtatAtelier.nouveau(1000)
	U.toutOuvrir(e)
	U.commander(e, Random.new(21))
	aDecorer(e)
	e.mercerie = { perle = 3, ruban_rose = 20 }
	local argent = e.argent
	local function objet(id)
		return { id = id, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 }
	end
	local r = e:decorer({ objet("perle"), objet("perle") })
	U.verifier(r.ok and e.argent == argent and e.mercerie.perle == 1, "deux perles posées : prises au stock (il en reste une), pas d'argent")
	e:retourDecorations()
	r = e:decorer({ objet("perle"), objet("perle"), objet("perle"), objet("perle") })
	U.verifier(not r.ok and r.erreur == "Mercerie insuffisante : il te manque Perle ×1." and e.mercerie.perle == 1, "quatre perles pour trois : refusé, ce qui manque dit (" .. tostring(r.erreur) .. ")")
	r = e:decorer({ objet("perle") })
	U.verifier(r.ok and e.mercerie.perle == 2, "une perle retirée revient au stock")
	e:retourDecorations()
	-- Une garniture : ses cm, arrondis au-dessus, pris au stock
	local pieces = e:recette().pieces
	local court = { { u = 0.4, v = 0.5 }, { u = 0.6, v = 0.5 } }
	local cm = math.ceil(Notation.longueurGarniture(pieces[1].id, court) * 10 - 1e-9)
	r = e:decorer({ objet("perle"), { id = "ruban_rose", piece = 1, trajet = court } })
	U.verifier(r.ok and cm <= 20 and e.mercerie.ruban_rose == 20 - cm, ("une garniture de %d cm, prise au stock de ruban (20 cm)"):format(cm))
	e:retourDecorations()
	local long = { { u = 0, v = 0.2 }, { u = 1, v = 0.2 }, { u = 1, v = 0.8 }, { u = 0, v = 0.8 } }
	local cmLong = math.ceil(Notation.longueurGarniture(pieces[1].id, long) * 10 - 1e-9)
	r = e:decorer({ objet("perle"), { id = "ruban_rose", piece = 1, trajet = long } })
	U.verifier(not r.ok and r.erreur == ("Mercerie insuffisante : il te manque Ruban rose, %d cm."):format(cmLong - 20) and e.mercerie.ruban_rose == 20 - cm, "une garniture trop longue pour le stock : refusée (" .. tostring(r.erreur) .. ")")
	U.verifier(Clientes ~= nil, "(modules chargés)")
end

-- Un événement qui a lieu offre des exemplaires de son souvenir
do
	local e = EtatAtelier.nouveau(1000)
	e.livraisons = 3
	local r
	for _ = 1, #Histoire.EVENEMENTS[1].commandes do
		assert(e:commandeHistoire().ok)
		assert(e:mesurer(Clientes.get(e.commande.cliente).mesures).ok)
		aDecorer(e)
		assert(e:decorer({}).ok)
		e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
		r = e:livrer()
	end
	local souvenir = Histoire.EVENEMENTS[1].souvenir
	U.verifier(r.evenement ~= nil and e.mercerie[souvenir] == EtatAtelier.SOUVENIRS_OFFERTS and EtatAtelier.SOUVENIRS_OFFERTS == 5, ("l'événement a lieu : cinq %s dans la mercerie"):format(souvenir))
end
