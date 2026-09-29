local Clientes = U.module("Clientes")
local Progression = U.module("Progression")
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")

---------------------------------------------------------------------------
-- Les six clientes : des données valides, des mesures proches de leur taille
---------------------------------------------------------------------------
U.verifier(#Clientes.LISTE == 6, "six clientes")
local vus = {}
for _, c in ipairs(Clientes.LISTE) do
	U.verifier(not vus[c.id] and Clientes.get(c.id) == c, "identifiant unique : " .. c.id)
	vus[c.id] = true
	local m, t = c.mesures, Catalogue.TAILLES[c.taille]
	U.verifier(t ~= nil and m.poitrine >= Recette.POITRINE[1] and m.poitrine <= Recette.POITRINE[2] and m.taille >= Recette.TAILLE[1] and m.hanches <= Recette.HANCHES[2] and m.taille < m.poitrine and m.taille < m.hanches, c.id .. " : mesures possibles pour une recette")
	U.verifier(math.abs(m.poitrine - t.poitrine) <= 0.3 and math.abs(m.taille - t.taille) <= 0.3 and math.abs(m.hanches - t.hanches) <= 0.3, c.id .. " : mesures proches de la taille " .. c.taille)
	U.verifier(#c.styles == 2 and table.find(Catalogue.STYLES, c.styles[1]) and table.find(Catalogue.STYLES, c.styles[2]) and table.find(Catalogue.TEINTES, c.teinte), c.id .. " : styles et teinte du catalogue")
	for niveau, d in pairs(c.deblocages) do
		U.verifier((niveau == 2 or niveau == 4) and ((d.variante and Catalogue.variante(d.variante)) or (d.accessoire and Catalogue.accessoire(d.accessoire))), c.id .. " : ce que l'amitié ouvre existe")
	end
	for _, cle in ipairs({ "presentation", "arrivee", "merci", "deception" }) do
		U.verifier(type(c.repliques[cle]) == "string" and #c.repliques[cle] > 0, c.id .. " : réplique « " .. cle .. " »")
	end
end
U.verifier(Clientes.get("inconnue") == nil, "cliente inconnue : rien")

---------------------------------------------------------------------------
-- Qui vient à la clochette
---------------------------------------------------------------------------
local fiches = {}
U.verifier(Clientes.prochaine(fiches, 1) == "colette", "première commande : Colette")
fiches.colette = { vues = 1, derniere = 1 }
U.verifier(Clientes.prochaine(fiches, 1) == "margot", "deuxième : Margot")
fiches.margot = { vues = 1, derniere = 2 }
U.verifier(Clientes.prochaine(fiches, 1) == "salome", "troisième : Salomé")
fiches.salome = { vues = 1, derniere = 3 }
U.verifier(Clientes.prochaine(fiches, 1) == "colette", "ensuite, celle qu'on n'a pas vue depuis le plus longtemps")
fiches.colette.derniere = 4
U.verifier(Clientes.prochaine(fiches, 1) == "margot", "… puis la suivante")
U.verifier(Clientes.prochaine(fiches, 2) == "helene", "prestige 2 : Hélène, nouvelle venue, passe avant les autres")
U.verifier(Clientes.prochaine(fiches, 8) == "helene", "plusieurs nouvelles venues possibles : dans l'ordre de la liste")

---------------------------------------------------------------------------
-- Niveaux d'amitié et de prestige, gains
---------------------------------------------------------------------------
U.verifier(Progression.niveauAmitie(0) == 0 and Progression.niveauAmitie(2) == 0 and Progression.niveauAmitie(3) == 1 and Progression.niveauAmitie(24) == 4 and Progression.niveauAmitie(25) == 5 and Progression.niveauAmitie(100) == 5, "niveaux d'amitié 0 à 5")
U.verifier(Progression.niveauPrestige(0) == 1 and Progression.niveauPrestige(19) == 1 and Progression.niveauPrestige(20) == 2 and Progression.niveauPrestige(530) == 8 and Progression.niveauPrestige(9999) == 8, "niveaux de prestige 1 à 8")
U.verifier(Progression.gainAmitie(true, 0.79) == 2 and Progression.gainAmitie(true, 0.8) == 3 and Progression.gainAmitie(false, 1) == -1, "amitié : +2, +1 pour une belle robe, −1 pour un abandon")
U.verifier(Progression.prestigeLivraison(124) == 12 and Progression.prestigeLivraison(125) == 13, "prestige : un dixième de la paie, arrondi")
U.verifier(Progression.prestigeVente(37) == 2 and Progression.prestigeVente(38) == 3, "robe vendue : un quinzième du prix, arrondi")
U.verifier(U.proche(Progression.bonusVente(1), 0) and U.proche(Progression.bonusVente(8), 0.42), "bonus de vente : +6 % par niveau au-delà du premier, +42 % au niveau 8")
U.verifier(Progression.gainCadeau(29) == 1 and Progression.gainCadeau(30) == 2 and Progression.gainCadeau(59) == 2 and Progression.gainCadeau(60) == 3 and Progression.gainCadeau(80) == 4 and Progression.gainCadeau(150) == 4, "cadeau : +1 à +4 selon le score de son style préféré")
U.verifier(Progression.PRESTIGE_CADEAU == 2, "cadeau : +2 de prestige")
