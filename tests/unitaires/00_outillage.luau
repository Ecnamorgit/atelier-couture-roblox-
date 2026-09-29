-- Vérifie que l'outillage des tests unitaires charge bien les modules partagés et ceux du client
U.verifier(table.find(NOMS_MODULES, "Catalogue") ~= nil, "les modules de src/shared sont découverts")
U.verifier(table.find(NOMS_MODULES, "UiKit") ~= nil, "les modules de src/client/Atelier sont découverts")
U.verifier(U.module("Catalogue").LARGEUR_ROULEAU == 14, "U.module charge un module partagé")
