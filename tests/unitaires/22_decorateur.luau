local Decorateur = U.module("Decorateur")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")
local Notation = U.module("Notation")
local Mercerie = U.module("Mercerie")
local MANQUE_NOEUD = "Plus assez de Nœud de satin dans ta mercerie : achètes-en à la Mercerie."
local MANQUE_RUBAN = "Plus assez de Ruban rose dans ta mercerie : achètes-en à la Mercerie."

local recette = {
	version = 1,
	croquis = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" },
	mesures = { poitrine = 8.8, taille = 7.0, hanches = 9.4 },
	pieces = {
		{ id = "corsage_droit_devant", tissu = "coton_blanc", x = 2.4, y = 2.1, angle = 0, couture = 1 },
		{ id = "corsage_droit_dos", tissu = "coton_blanc", x = 7.2, y = 2.1, angle = 0, couture = 1 },
		{ id = "manche_ballon", tissu = "coton_blanc", x = 5, y = 5, angle = 0, couture = 1 },
		{ id = "jupe_droite_devant", tissu = "coton_blanc", x = 2.5, y = 9, angle = 0, couture = 1 },
		{ id = "jupe_droite_dos", tissu = "coton_blanc", x = 7.5, y = 9, angle = 0, couture = 1 },
	},
	accessoires = {},
}

---------------------------------------------------------------------------
-- Objets
---------------------------------------------------------------------------
local d = Decorateur.nouveau(recette, {}, { noeud_satin = 2 })
U.verifier(#d.liste == 0 and d:usage("noeud_satin") == 0 and d:reste("noeud_satin") == 2 and d.selection == nil, "départ : rien de posé, deux nœuds dans la mercerie")
U.verifier(not d:toucher(1, "unique", 0.5, 0.5).ok, "toucher la robe sans accessoire choisi : rien")
U.verifier(not d:choisir("diamant") and d.choix == nil, "accessoire inconnu refusé")
U.verifier(d:choisir("noeud_satin") and d.choix == "noeud_satin", "nœud choisi dans la palette")
local r = d:toucher(1, "unique", 0.5, 0.3)
U.verifier(r.ok and r.action == "pose" and #d.liste == 1 and d.selection == 1, "le nœud est posé et sélectionné")
local a = d.liste[1]
U.verifier(a.id == "noeud_satin" and a.piece == 1 and a.u == 0.5 and a.v == 0.3 and a.echelle == 1 and a.angle == 0 and a.copie == nil, "nœud : pièce, place, taille 1, angle 0")
d:toucher(3, "droite", 0.4, 0.6)
U.verifier(d.liste[2].copie == "droite", "sur une manche : la copie touchée est gardée")
local pris, dispo = d:usage("noeud_satin")
U.verifier(pris == 2 and dispo == 2 and d:epuise("noeud_satin"), "deux nœuds posés sur deux : épuisé")
local refus = d:toucher(1, "unique", 0.2, 0.2)
U.verifier(not refus.ok and refus.erreur == MANQUE_NOEUD and #d.liste == 2, "un troisième nœud : refusé, la mercerie est vide")
d:majStock({ noeud_satin = 3 })
U.verifier(d:reste("noeud_satin") == 1 and not d:epuise("noeud_satin"), "un achat (trois nœuds en tout) : il en reste un à poser")
d:tourner(45)
d:tourner(170)
U.verifier(d.liste[2].angle == -145, "rotation ramenée entre −180 et 180")
d:redimensionner(0.5)
d:redimensionner(10)
U.verifier(d.liste[2].echelle == Recette.ECHELLE_MAX, "taille bornée à 3")
d:redimensionner(-10)
U.verifier(d.liste[2].echelle == Recette.ECHELLE_MIN, "taille bornée à 0,5")
U.verifier(d:selectionner(1) and d.selection == 1 and not d:selectionner(5), "sélection d'un accessoire posé")
d:supprimer()
U.verifier(#d.liste == 1 and d.liste[1].piece == 3 and d.selection == nil, "accessoire supprimé")
U.verifier(not d:toucher(1, "unique", 1.5, 0.5).ok and not d:toucher(9, "unique", 0.5, 0.5).ok, "touche hors pièce refusée")

---------------------------------------------------------------------------
-- Annuler
---------------------------------------------------------------------------
U.verifier(d:annuler() and #d.liste == 2, "annuler la suppression")
U.verifier(d:annuler() and d.liste[2].echelle == 3, "annuler la dernière taille")
while d:annuler() do
end
U.verifier(#d.liste == 0, "tout annulé")

---------------------------------------------------------------------------
-- Garnitures : point par point, sur une seule pièce
---------------------------------------------------------------------------
local g = Decorateur.nouveau(recette, {}, { dentelle_blanche = EtatAtelier.MERCERIE_MAX_CM, perle = 5 })
g:choisir("dentelle_blanche")
r = g:toucher(4, "unique", 0, 1)
U.verifier(r.ok and r.action == "point" and g.garniture ~= nil and #g.liste == 0, "premier point de la dentelle")
U.verifier(not g:terminerGarniture(), "une garniture a besoin de deux points")
g:toucher(4, "unique", 0.001, 1)
U.verifier(not g:terminerGarniture() and #g.liste == 0, "une garniture de moins de 0,5 dm n'est pas terminée")
U.verifier(g:usage("dentelle_blanche") == 0 and #g:resultat() == 0, "trop courte : rien de pris, rien d'envoyé")
g:annuler()
U.verifier(not g:toucher(5, "unique", 0.5, 1).ok, "une garniture reste sur une seule pièce")
g:toucher(4, "unique", 0.5, 1)
g:toucher(4, "unique", 1, 1)
U.verifier(g:usage("dentelle_blanche") == math.ceil(Notation.longueurGarniture("jupe_droite_devant", g.garniture.trajet) * 10 - 1e-9), "dentelle en cours comptée dans ce que la robe prend")
U.verifier(g:terminerGarniture() and #g.liste == 1 and g.garniture == nil and #g.liste[1].trajet == 3, "dentelle terminée : 3 points")
g:toucher(4, "unique", 0, 0.5)
for k = 1, 63 do
	g:toucher(4, "unique", k / 64, 0.5)
end
U.verifier(not g:toucher(4, "unique", 1, 0.4).ok and #g.garniture.trajet == 64, "64 points au plus")
g:choisir("perle")
U.verifier(g.garniture == nil and #g.liste == 2, "changer d'accessoire termine la garniture en cours")
U.verifier(g:annuler() and #g.liste == 1, "annuler la garniture entière")

---------------------------------------------------------------------------
-- Mercerie : ce qui est déjà pris compte dans ce qu'on a ; liste acceptée par EtatAtelier
---------------------------------------------------------------------------
local payees = { { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 } }
local avec = table.clone(recette)
avec.accessoires = payees
local p = Decorateur.nouveau(avec, payees, {})
pris, dispo = p:usage("noeud_satin")
U.verifier(#p.liste == 1 and pris == 1 and dispo == 1, "un nœud déjà pris (mercerie vide) : un posé sur un")
p:selectionner(1)
p:supprimer()
U.verifier(p:usage("noeud_satin") == 0 and p:reste("noeud_satin") == 1, "retirer un nœud déjà pris : il est de nouveau à poser")
p.liste[1] = nil
U.verifier(#payees == 1, "la liste des décorations prises n'est pas modifiée par l'éditeur")
local final = Decorateur.nouveau(recette, {}, { perle = 1, ruban_rose = 100 })
final:choisir("perle")
final:toucher(2, "unique", 0.5, 0.5)
final:choisir("ruban_rose")
final:toucher(4, "unique", 0.1, 0.9)
final:toucher(4, "unique", 0.9, 0.9)
local liste = final:resultat()
local verif = table.clone(recette)
verif.accessoires = liste
U.verifier(#liste == 2 and Recette.valider(verif), "résultat : garniture en cours terminée, recette valide")
local besoins = EtatAtelier.besoinsMercerie(recette.pieces, liste)
U.verifier(besoins.perle == (final:usage("perle")) and besoins.ruban_rose == (final:usage("ruban_rose")), "ce que la robe prend est ce qu'EtatAtelier prendra à la mercerie")

---------------------------------------------------------------------------
-- Une garniture ne dépasse pas la mercerie : le point de trop est refusé
---------------------------------------------------------------------------
local function cm(trajet)
	return math.ceil(Notation.longueurGarniture("jupe_droite_devant", trajet) * 10 - 1e-9)
end
local court = cm({ { u = 0, v = 1 }, { u = 0.3, v = 1 } })
local long = cm({ { u = 0, v = 1 }, { u = 0.3, v = 1 }, { u = 0.5, v = 1 } })
assert(court >= 5 and long > court + 1, "(la jupe est assez large pour ce test)")
local s = Decorateur.nouveau(recette, {}, { ruban_rose = court + 1 })
s:choisir("ruban_rose")
U.verifier(s:toucher(4, "unique", 0, 1).ok and s:toucher(4, "unique", 0.3, 1).ok, "ruban : de quoi poser le premier bout")
local trop = s:toucher(4, "unique", 0.5, 1)
U.verifier(not trop.ok and trop.erreur == MANQUE_RUBAN and #s.garniture.trajet == 2, "un point qui dépasse la mercerie : refusé, la garniture reste où elle en est")
pris, dispo = s:usage("ruban_rose")
U.verifier(pris == court and dispo == court + 1 and s:reste("ruban_rose") == 1 and s:epuise("ruban_rose"), "il reste 1 cm : trop peu pour une garniture (épuisé)")
local vide = Decorateur.nouveau(recette, {}, { ruban_rose = 4 })
vide:choisir("ruban_rose")
local premier = vide:toucher(4, "unique", 0, 1)
U.verifier(not premier.ok and premier.erreur == MANQUE_RUBAN and vide.garniture == nil, "moins de 5 cm de ruban : pas même un premier point")

---------------------------------------------------------------------------
-- Mercerie : les quantités en clair
---------------------------------------------------------------------------
U.verifier(Mercerie.metres(150) == "1,50" and Mercerie.metres(5) == "0,05" and Mercerie.metres(0) == "0,00", "des cm en mètres, à la française")
U.verifier(Mercerie.stock("perle", 12) == "×12" and Mercerie.stock("perle", nil) == "×0" and Mercerie.stock("ruban_rose", 250) == "2,50 m", "quantités en clair : ×12, ×0, 2,50 m")
