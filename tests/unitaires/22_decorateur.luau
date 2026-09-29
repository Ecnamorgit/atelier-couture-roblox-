local Decorateur = U.module("Decorateur")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")

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
local d = Decorateur.nouveau(recette, {})
U.verifier(#d.liste == 0 and d:cout() == 0 and d.selection == nil, "départ : rien de posé, rien à payer")
U.verifier(not d:toucher(1, "unique", 0.5, 0.5).ok, "toucher la robe sans accessoire choisi : rien")
U.verifier(not d:choisir("diamant") and d.choix == nil, "accessoire inconnu refusé")
U.verifier(d:choisir("noeud_satin") and d.choix == "noeud_satin", "nœud choisi dans la palette")
local r = d:toucher(1, "unique", 0.5, 0.3)
U.verifier(r.ok and r.action == "pose" and #d.liste == 1 and d.selection == 1, "le nœud est posé et sélectionné")
local a = d.liste[1]
U.verifier(a.id == "noeud_satin" and a.piece == 1 and a.u == 0.5 and a.v == 0.3 and a.echelle == 1 and a.angle == 0 and a.copie == nil, "nœud : pièce, place, taille 1, angle 0")
d:toucher(3, "droite", 0.4, 0.6)
U.verifier(d.liste[2].copie == "droite", "sur une manche : la copie touchée est gardée")
U.verifier(d:cout() == 6, "deux nœuds : 6 po")
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
local g = Decorateur.nouveau(recette, {})
g:choisir("dentelle_blanche")
r = g:toucher(4, "unique", 0, 1)
U.verifier(r.ok and r.action == "point" and g.garniture ~= nil and #g.liste == 0, "premier point de la dentelle")
U.verifier(not g:terminerGarniture(), "une garniture a besoin de deux points")
g:toucher(4, "unique", 0.001, 1)
U.verifier(not g:terminerGarniture() and #g.liste == 0, "une garniture de moins de 0,5 dm n'est pas terminée")
U.verifier(g:cout() == 0 and #g:resultat() == 0, "trop courte : ni coût ni envoi")
g:annuler()
U.verifier(not g:toucher(5, "unique", 0.5, 1).ok, "une garniture reste sur une seule pièce")
g:toucher(4, "unique", 0.5, 1)
g:toucher(4, "unique", 1, 1)
U.verifier(g:cout() == 10, "dentelle en cours comptée dans le coût (5 dm à 2 po)")
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
-- Coût : différence avec ce qui est déjà payé ; liste acceptée par EtatAtelier
---------------------------------------------------------------------------
local payees = { { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 } }
local avec = table.clone(recette)
avec.accessoires = payees
local p = Decorateur.nouveau(avec, payees)
U.verifier(#p.liste == 1 and p:cout() == 0, "décorations déjà payées : rien de plus à payer")
p:selectionner(1)
p:supprimer()
U.verifier(p:cout() == -3, "retirer un nœud payé : remboursé")
p.liste[1] = nil
U.verifier(#payees == 1, "la liste payée n'est pas modifiée par l'éditeur")
local final = Decorateur.nouveau(recette, {})
final:choisir("perle")
final:toucher(2, "unique", 0.5, 0.5)
final:choisir("ruban_rose")
final:toucher(4, "unique", 0.1, 0.9)
final:toucher(4, "unique", 0.9, 0.9)
local liste = final:resultat()
local verif = table.clone(recette)
verif.accessoires = liste
U.verifier(#liste == 2 and Recette.valider(verif), "résultat : garniture en cours terminée, recette valide")
U.verifier(EtatAtelier.prixDecorations(recette.pieces, liste) == final:cout(), "le coût affiché est celui que facturera EtatAtelier")
