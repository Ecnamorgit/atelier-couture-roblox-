-- Vérifie que l'outillage des tests unitaires charge bien les modules partagés
U.verifier(table.find(NOMS_MODULES, "CoutureData") ~= nil, "les modules de src/shared sont découverts")
U.verifier(U.module("CoutureData").LARGEUR_COUPON == 12, "U.module charge un module partagé")
