local EtatAtelier = U.module("EtatAtelier")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local function tousEn(tissu)
	return {
		corsage_droit_devant = tissu,
		corsage_droit_dos = tissu,
		jupe_droite_devant = tissu,
		jupe_droite_dos = tissu,
	}
end
-- Disposition sans chevauchement des 4 pièces sur un rouleau de 14 dm
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Démarrage et commande
local e = EtatAtelier.nouveau()
U.verifier(e.argent == 150 and e.etape == "accueil", "départ : 150 pièces d'or, à l'accueil")
local r = e:nouvelleCommande(Random.new(3))
U.verifier(r.ok and e.etape == "carnet" and #r.commande.exigences >= 1, "nouvelle commande : direction le carnet")
U.verifier(not e:nouvelleCommande(Random.new(4)).ok, "une seule commande à la fois")
local pauvre = EtatAtelier.nouveau(3)
pauvre:nouvelleCommande(Random.new(1))
U.verifier(pauvre.argent == EtatAtelier.FILET, "filet de sécurité : au moins 20 pièces d'or")

-- Carnet
U.verifier(not e:acheter("coton_blanc", 5).ok, "pas d'achat avant d'avoir validé le croquis")
U.verifier(not e:validerCroquis("x", nil).ok, "croquis qui n'est pas une table refusé")
U.verifier(not e:validerCroquis({ corsage = "corsage_droit" }, {}).ok, "croquis incomplet refusé")
local manque = tousEn("coton_blanc")
manque.jupe_droite_dos = nil
U.verifier(not e:validerCroquis(CROQUIS, manque).ok, "une pièce sans tissu est refusée")
local inconnu = tousEn("coton_blanc")
inconnu.jupe_droite_dos = "papier"
U.verifier(not e:validerCroquis(CROQUIS, inconnu).ok, "un tissu inconnu est refusé")
local choix = tousEn("coton_blanc")
choix.corsage_droit_devant, choix.corsage_droit_dos = "soie_rouge", "soie_rouge"
U.verifier(e:validerCroquis(CROQUIS, choix).ok and e.etape == "achat", "croquis validé : direction l'achat")
local utilises = e:tissusUtilises()
U.verifier(#utilises == 2 and utilises[1] == "soie_rouge" and utilises[2] == "coton_blanc", "tissus utilisés dans l'ordre des pièces")

-- Achat
U.verifier(EtatAtelier.prix("coton_blanc", 12) == 5 and EtatAtelier.prix("soie_rouge", 10) == 16, "prix au mètre, arrondi au-dessus")
for _, mauvais in ipairs({ 0, 1.5, 101, 0 / 0, "a" }) do
	U.verifier(not e:acheter("coton_blanc", mauvais).ok, "longueur invalide refusée : " .. tostring(mauvais))
end
U.verifier(not e:acheter("papier", 5).ok and not e:acheter(nil, 5).ok, "tissu inconnu refusé")
U.verifier(not e:acheter("soie_rouge", 100).ok, "pas assez d'argent")
U.verifier(not e:commencerDecoupe().ok, "découpe impossible sans tissu")
local achat = e:acheter("coton_blanc", 12)
U.verifier(achat.ok and achat.prix == 5 and e.argent == 145 and e.stock.coton_blanc == 12, "achat : argent débité, stock crédité")
U.verifier(e:acheter("soie_rouge", 6).ok and e.argent == 145 - 10, "deuxième tissu acheté")
U.verifier(e:commencerDecoupe().ok, "découpe possible avec du tissu pour chaque pièce")
U.verifier(e.etape == "decoupe" and e.coupons.coton_blanc.longueur == 12 and e.coupons.soie_rouge.longueur == 6, "un rouleau par tissu, de la longueur en stock")

-- Retour au carnet tant que rien n'est coupé
U.verifier(e:retourCarnet().ok and e.etape == "carnet", "retour au carnet avant la première coupe")
U.verifier(e:validerCroquis(CROQUIS, choix).ok and e:commencerDecoupe().ok, "on revient à la découpe")

-- Découpe
U.verifier(not e:couper("manche_longue", { x = 3, y = 3, angle = 0 }).ok, "pièce hors croquis refusée")
U.verifier(not e:couper(123, nil).ok, "pièce invalide refusée")
U.verifier(not e:couper("corsage_droit_devant", { x = 0 / 0, y = 2, angle = 0 }).ok, "position invalide refusée")
local c1 = e:couper("corsage_droit_devant", DISPOSITION.corsage_droit_devant)
U.verifier(c1.ok and c1.reste == 3 and e.coupees.corsage_droit_devant ~= nil, "première pièce coupée")
U.verifier(not e:retourCarnet().ok, "plus de retour au carnet après une coupe")
U.verifier(not e:couper("corsage_droit_dos", { x = 3, y = 2.1, angle = 0 }).ok, "chevauchement refusé")
U.verifier(not e:couper("jupe_droite_devant", { x = 2.5, y = 9.5, angle = 0 }).ok, "la jupe dépasse des 12 dm de coton")
for _, id in ipairs({ "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }) do
	U.verifier(e:couper(id, DISPOSITION[id]).ok, id .. " coupée")
end
U.verifier(e.etape == "epinglage", "toutes les pièces coupées : direction l'épinglage")
U.verifier(e.stock.soie_rouge == 6 - 5 and e.stock.coton_blanc == 12 - 11, "chaque rouleau perd sa longueur entamée (5 et 11 dm)")

-- Rouleau trop court : on rachète pendant la découpe
local e2 = EtatAtelier.nouveau()
e2:nouvelleCommande(Random.new(5))
e2:validerCroquis(CROQUIS, tousEn("coton_blanc"))
e2:acheter("coton_blanc", 10)
e2:commencerDecoupe()
U.verifier(e2:couper("corsage_droit_devant", DISPOSITION.corsage_droit_devant).ok, "corsage devant")
U.verifier(not e2:couper("jupe_droite_devant", DISPOSITION.jupe_droite_devant).ok, "la jupe dépasse des 10 dm achetés")
U.verifier(e2:acheter("coton_blanc", 2).ok and e2.coupons.coton_blanc.longueur == 12, "acheter pendant la découpe déroule le rouleau")
for _, id in ipairs({ "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }) do
	U.verifier(e2:couper(id, DISPOSITION[id]).ok, id .. " coupée")
end
U.verifier(e2.etape == "epinglage" and e2.stock.coton_blanc == 12 - 11, "robe coupée, 11 dm consommés")
U.verifier(not e2:couper("jupe_droite_dos", DISPOSITION.jupe_droite_dos).ok, "plus de découpe après la dernière pièce")

-- Recommencer : le tissu entamé est perdu, la commande reste
local e3 = EtatAtelier.nouveau()
local commande = e3:nouvelleCommande(Random.new(6)).commande
e3:validerCroquis(CROQUIS, tousEn("coton_blanc"))
e3:acheter("coton_blanc", 12)
e3:commencerDecoupe()
e3:couper("jupe_droite_devant", DISPOSITION.jupe_droite_devant)
U.verifier(e3:recommencer().ok and e3.etape == "carnet" and e3.commande == commande, "recommencer : retour au carnet, même commande")
U.verifier(e3.stock.coton_blanc == 12 - 11, "le tissu entamé est perdu")
U.verifier(next(e3.coupees) == nil and e3.croquis == nil, "robe remise à zéro")
U.verifier(not EtatAtelier.nouveau():recommencer().ok, "rien à recommencer sans commande")

-- Filet de sécurité aussi en recommençant : jamais bloqué sans argent ni tissu (spec §3)
local e4 = EtatAtelier.nouveau(20)
e4:nouvelleCommande(Random.new(7))
e4:validerCroquis(CROQUIS, tousEn("soie_rouge"))
U.verifier(e4:acheter("soie_rouge", 12).ok and e4.argent == 0, "tout l'argent dépensé en soie")
e4:commencerDecoupe()
U.verifier(e4:couper("jupe_droite_devant", { x = 2.5, y = 9, angle = 0 }).ok, "jupe coupée en bas du rouleau : les 12 dm sont entamés")
U.verifier(e4:recommencer().ok and e4.stock.soie_rouge == 0, "recommencer : le tissu entamé est perdu")
U.verifier(e4.argent == EtatAtelier.FILET, "recommencer remet le filet de 20 pièces d'or")
U.verifier(e4:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok and e4:acheter("coton_blanc", 12).ok, "de quoi racheter du tissu pour une robe simple")
