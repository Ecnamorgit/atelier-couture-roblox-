local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Robe coupée, épinglée et cousue parfaitement, en coton blanc ; exigences choisies par le test
local function jusquAuxDecorations(exigences)
	local e = EtatAtelier.nouveau()
	e:nouvelleCommande(Random.new(3))
	e.commande.exigences = exigences
	local tissus = {}
	for _, id in ipairs(PIECES) do
		tissus[id] = "coton_blanc"
	end
	e:validerCroquis(CROQUIS, tissus)
	e:acheter("coton_blanc", 12)
	e:commencerDecoupe()
	for _, id in ipairs(PIECES) do
		e:couper(id, DISPOSITION[id])
	end
	for _, id in ipairs(PIECES) do
		e:epingler(id)
	end
	for _, id in ipairs(PIECES) do
		local _, longueur = Patron.trajetCouture(id)
		local n = math.round(longueur / Catalogue.PAS_MESURE_COUTURE)
		e:rendreCouture(id, table.create(n, 0), longueur / Catalogue.VITESSE_COUTURE_MAX)
	end
	return e
end

local noeud = { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 }
local perle = { id = "perle", piece = 3, u = 0.2, v = 0.8, echelle = 1.5, angle = 30 }
-- Dentelle le long de l'ourlet de la jupe devant (5 dm de large : 5 dm de garniture)
local dentelle = { id = "dentelle_blanche", piece = 3, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } }

---------------------------------------------------------------------------
-- Prix des décorations
---------------------------------------------------------------------------
local e = jusquAuxDecorations({ { type = "accessoire", id = "noeud_satin" } })
U.verifier(e.etape == "decorations" and #e.accessoires == 0, "robe cousue : aux décorations, rien de posé")
local recette = e:recette()
U.verifier(EtatAtelier.prixDecorations(recette.pieces, { noeud, perle }) == 3 + 1, "objets : prix à l'unité")
local longueurDentelle = Notation.longueurGarniture("jupe_droite_devant", dentelle.trajet)
U.verifier(U.proche(longueurDentelle, 5), "dentelle de 5 dm")
U.verifier(EtatAtelier.prixDecorations(recette.pieces, { dentelle }) == math.ceil(2 * 5 - 1e-9), "garniture : prix au dm, arrondi au-dessus")

---------------------------------------------------------------------------
-- Décorer : liste complète, vérifiée, facturée à la différence
---------------------------------------------------------------------------
U.verifier(not EtatAtelier.nouveau():decorer({}).ok, "pas de décorations sans robe cousue")
U.verifier(not e:decorer("x").ok and not e:decorer(nil).ok, "liste qui n'est pas une table refusée")
U.verifier(not e:decorer({ { id = "diamant", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "accessoire inconnu refusé")
U.verifier(not e:decorer({ { id = "perle", piece = 1, u = 1.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "accessoire hors de la pièce refusé")
U.verifier(not e:decorer({ { id = "perle", piece = 9, u = 0.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "pièce inexistante refusée")
local trop = {}
for k = 1, 301 do
	trop[k] = { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 }
end
U.verifier(not e:decorer(trop).ok, "301 décorations refusées")
local longue = { id = "ruban_rose", piece = 3, trajet = {} }
for k = 1, 65 do
	longue.trajet[k] = { u = (k - 1) / 64, v = 0.5 }
end
U.verifier(not e:decorer({ longue }).ok, "garniture de 65 points refusée")
U.verifier(e.etape == "decorations" and #e.accessoires == 0, "rien ne change après un refus")

local argent = e.argent
local r = e:decorer({ noeud, perle, dentelle })
U.verifier(r.ok and r.prix == 3 + 1 + 10 and e.argent == argent - 14, "décorations facturées")
U.verifier(e.etape == "photo" and #e.accessoires == 3, "décorations envoyées : direction la photo")
noeud.u = 0.9
U.verifier(e.accessoires[1].u == 0.5, "la liste gardée est une copie")
noeud.u = 0.5
U.verifier(#e:recette().accessoires == 3 and e:recette().accessoires[3].id == "dentelle_blanche", "la recette porte les décorations")

-- Retour aux décorations, puis retrait de la dentelle : remboursée
U.verifier(e:retourDecorations().ok and e.etape == "decorations", "retour de la photo aux décorations")
r = e:decorer({ noeud, perle })
U.verifier(r.ok and r.prix == -10 and e.argent == argent - 4, "décoration retirée : remboursée")
U.verifier(e:retourDecorations().ok, "encore un retour")
local cheres = {}
for k = 1, 60 do
	cheres[k] = { id = "broche_camee", piece = 1, u = 0.5, v = k / 61, echelle = 1, angle = 0 }
end
U.verifier(not e:decorer(cheres).ok and e.argent == argent - 4 and #e.accessoires == 2, "pas assez d'argent : refusé, rien ne change")

---------------------------------------------------------------------------
-- Livraison : la cliente juge la robe
---------------------------------------------------------------------------
U.verifier(not e:livrer().ok, "on livre depuis la photo seulement")
e:decorer({ perle })
local avant = e.argent
r = e:livrer()
U.verifier(r.ok and not r.reussie and #r.ratees == 1 and e.etape == "refus", "nœud de satin exigé mais absent : robe refusée")
U.verifier(e.argent == avant, "refus : pas de paie")
U.verifier(not e:livrer().ok, "une robe refusée ne se relivre pas sans retouche")
U.verifier(e:retoucher().ok and e.etape == "decorations", "retouche : retour aux décorations")
e:decorer({ perle, noeud })
r = e:livrer()
local bilan = Notation.bilan(e.robes[1])
local paie = Notation.paie(4, 1, bilan.qualite)
U.verifier(r.ok and r.reussie and r.paie == paie and e.argent == avant - 3 + paie, "robe acceptée : paie = base × (0,5 + qualité)")
U.verifier(e.etape == "accueil" and e.commande == nil, "robe livrée : retour à l'accueil")
U.verifier(#e.robes == 1 and #e.robes[1].accessoires == 2 and e.robes[1].pieces[1].couture == 1, "la robe livrée part en vitrine (recette gardée)")
U.verifier(next(e.coupees) == nil and next(e.epinglees) == nil and next(e.coutures) == nil and #e.accessoires == 0, "atelier prêt pour la commande suivante")
U.verifier(e:nouvelleCommande(Random.new(9)).ok, "nouvelle commande possible")

-- Abandon après un refus : pas de paie, pas de vitrine
local e2 = jusquAuxDecorations({ { type = "accessoire", id = "croix_argent" } })
e2:decorer({})
local argent2 = e2.argent
U.verifier(not e2:livrer().reussie and e2:abandonner().ok, "robe refusée puis abandonnée")
U.verifier(e2.etape == "accueil" and e2.commande == nil and #e2.robes == 0 and e2.argent == argent2, "abandon : ni paie ni vitrine")
U.verifier(not e2:abandonner().ok and not e2:retoucher().ok, "abandonner et retoucher seulement après un refus")

-- Les 10 dernières robes seulement, la plus récente en premier
local e3 = jusquAuxDecorations({ { type = "qualite", valeur = 0.5 } })
for k = 1, 11 do
	e3.robes[k] = { marque = k }
end
e3:decorer({})
U.verifier(e3:livrer().reussie and #e3.robes == 10 and e3.robes[1].marque == nil and e3.robes[2].marque == 1, "10 robes gardées, la plus récente en tête")

-- Recommencer depuis les décorations : les décorations posées sont perdues, comme le tissu coupé
local e4 = jusquAuxDecorations({ { type = "qualite", valeur = 0.5 } })
local argent4 = e4.argent
e4:decorer({ noeud })
U.verifier(e4:recommencer().ok and #e4.accessoires == 0 and e4.argent == argent4 - 3, "recommencer : les décorations posées sont perdues")

-- Relecture finale : le rouleau ne dépasse jamais la longueur qu'une recette accepte (100 dm)
local Recette = U.module("Recette")
local e5 = EtatAtelier.nouveau(1000)
e5:nouvelleCommande(Random.new(3))
e5.commande.exigences = { { type = "qualite", valeur = 0.5 } }
local tissus5 = {}
for _, id in ipairs(PIECES) do
	tissus5[id] = "coton_blanc"
end
e5:validerCroquis(CROQUIS, tissus5)
e5:acheter("coton_blanc", 100)
e5:acheter("coton_blanc", 50)
U.verifier(e5:commencerDecoupe().ok and e5.coupons.coton_blanc.longueur == Recette.LONGUEUR_MAX, "150 dm en stock : rouleau limité à 100 dm")
U.verifier(not e5:couper("jupe_droite_devant", { x = 2.5, y = 120, angle = 0 }).ok, "une pièce au-delà de 100 dm est refusée")
e5:acheter("coton_blanc", 10)
U.verifier(e5.coupons.coton_blanc.longueur == Recette.LONGUEUR_MAX, "acheter pendant la découpe ne dépasse pas 100 dm")
