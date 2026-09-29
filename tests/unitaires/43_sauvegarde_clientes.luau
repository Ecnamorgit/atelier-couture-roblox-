local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")

---------------------------------------------------------------------------
-- L'état de l'atelier garde les fiches des clientes, le prestige, les livraisons et les visites
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
U.verifier(type(e.clientes) == "table" and next(e.clientes) == nil and e.prestige == 0 and e.livraisons == 0 and e.visites == 0, "départ : aucune cliente, prestige 0, rien livré")
e.clientes.colette = { amitie = 5, vues = 2, derniere = 3, mesures = { poitrine = 9, taille = 7.1, hanches = 9.5 }, ajustement = 0.95 }
e.prestige, e.livraisons, e.visites = 42, 2, 3
local copie = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(copie.clientes.colette.amitie == 5 and copie.clientes.colette.mesures.poitrine == 9 and copie.prestige == 42 and copie.livraisons == 2 and copie.visites == 3, "copie de l'état (client) : fiches et prestige compris")

---------------------------------------------------------------------------
-- Sauvegarde v3 : relue à l'identique
---------------------------------------------------------------------------
U.verifier(Sauvegarde.VERSION == 3, "format v3")
local partie = Sauvegarde.depuisEtat(e)
U.verifier(partie.prestige == 42 and partie.livraisons == 2 and partie.visites == 3 and partie.clientes.colette.amitie == 5, "partie : prestige, livraisons, visites, fiches")
local relue = Sauvegarde.versEtat(M.transmettre(partie))
local f = relue.clientes.colette
U.verifier(relue.prestige == 42 and relue.livraisons == 2 and relue.visites == 3 and f.amitie == 5 and f.vues == 2 and f.derniere == 3 and f.mesures.hanches == 9.5 and f.ajustement == 0.95, "relue : prestige, livraisons, visites et fiche de Colette")

---------------------------------------------------------------------------
-- Fiches abîmées : ce qui est illisible est laissé de côté
---------------------------------------------------------------------------
partie.clientes = {
	colette = { amitie = -4, vues = "deux", derniere = 0 / 0, mesures = { poitrine = 30, taille = 7, hanches = 9 }, ajustement = 3 },
	inconnue = { amitie = 99 },
	margot = "abîmée",
	salome = { amitie = 7.6, vues = 1, derniere = 2, mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 }, ajustement = 0.2 },
}
partie.prestige, partie.livraisons, partie.visites = "beaucoup", -3, 2.5
relue = Sauvegarde.versEtat(partie)
local c = relue.clientes.colette
U.verifier(c ~= nil and c.amitie == 0 and c.vues == 0 and c.derniere == 0 and c.mesures == nil and c.ajustement == nil, "fiche abîmée : nombres remis à zéro, mesures impossibles oubliées")
U.verifier(relue.clientes.inconnue == nil and relue.clientes.margot == nil, "cliente inconnue ou fiche illisible : laissée")
local s = relue.clientes.salome
U.verifier(s.amitie == 7 and s.mesures.poitrine == 9.7 and s.ajustement == 0.5, "fiche de Salomé : amitié entière, ajustement borné")
U.verifier(relue.prestige == 0 and relue.livraisons == 0 and relue.visites == 2, "prestige, livraisons et visites illisibles : 0 (entiers positifs)")

---------------------------------------------------------------------------
-- Migration v2 → v3 : le travail passé compte (20 points de prestige par robe gardée)
---------------------------------------------------------------------------
local v2 = { version = 2, argent = 300, stock = {}, debloques = {}, recettes = { {}, {}, {} } }
local v3 = Sauvegarde.migrer(v2)
U.verifier(v3.version == 3 and v3.prestige == 60 and v3.livraisons == 3 and v3.visites == 0 and next(v3.clientes) == nil and v3.argent == 300, "v2 → v3 : prestige des robes passées, aucune cliente")
U.verifier(Sauvegarde.migrer({ argent = 480 }).version == 3, "v1 → v3 : les migrations s'enchaînent")

---------------------------------------------------------------------------
-- Une commande à l'étape des mesures (pas encore de mesures) se relit ; une cliente inconnue non
---------------------------------------------------------------------------
local enAttente = EtatAtelier.nouveau()
enAttente.commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } }
enAttente.etape = "mesures"
enAttente.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
local p2 = Sauvegarde.depuisEtat(enAttente)
local relue2 = Sauvegarde.versEtat(M.transmettre(p2))
U.verifier(relue2.etape == "mesures" and relue2.commande.cliente == "colette" and relue2.commande.mesures == nil, "commande à mesurer : relue telle quelle")
p2.enCours.commande.cliente = "inconnue"
U.verifier(Sauvegarde.versEtat(p2).etape == "accueil", "commande d'une cliente inconnue : abandonnée")
local p3 = Sauvegarde.depuisEtat(enAttente)
p3.enCours.etape = "carnet" -- au carnet, sans mesures : impossible à jouer
U.verifier(Sauvegarde.versEtat(p3).etape == "accueil", "commande au carnet sans mesures : abandonnée")
U.verifier(Clientes.get("colette") ~= nil, "(la cliente existe)")
