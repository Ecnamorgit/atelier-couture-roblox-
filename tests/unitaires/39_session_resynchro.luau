local Session = U.module("Session")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

---------------------------------------------------------------------------
-- EtatAtelier:charger dit si quelque chose a changé
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
local d = e:exporter()
local _, change = e:charger(d)
U.verifier(change == false, "recharger le même état : rien n'a changé")
d.argent += 1
_, change = e:charger(d)
U.verifier(change == true and e.argent == d.argent, "un champ différent : changé")

---------------------------------------------------------------------------
-- Un serveur dont l'appel ou la réponse peuvent se perdre
---------------------------------------------------------------------------
local courante, courant = Session.courante, Commande.courante
local serveur = Commande.nouvelle()
local remote = M.nouvelleInstance("RemoteFunction")
local joueur = M.nouveauJoueur("Resynchro")
M.joueurLocal = joueur
local panne = nil -- "apres" : le serveur agit, la réponse se perd ; "illisible" : état reçu abîmé
remote.OnServerInvoke = function(j, action, ...)
	local r = serveur:traiter(j, action, ...)
	if panne == "apres" then
		error("réponse perdue")
	elseif panne == "illisible" and r.etat then
		r.etat.coupons = "abîmé"
	end
	return r
end
local function cote()
	return serveur:atelier(joueur).etat
end
M.avancer(1)
local session = Session.distante(remote)
local notifications = 0
session:surChangement(function()
	notifications += 1
end)
local attentes = {}
session:surAttente(function(actif)
	table.insert(attentes, actif)
end)

-- L'attente du serveur est signalée (début, fin) : l'interface montre un indicateur si elle dure
M.avancer(1)
U.verifier(session:nouvelleCommande().ok, "nouvelle commande")
U.verifier(#attentes == 2 and attentes[1] == true and attentes[2] == false, "attente signalée : début, puis fin")

-- Réponse perdue : refus passager ; l'état est redemandé au serveur un peu plus tard
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local TISSUS = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
panne = "apres"
M.avancer(1)
local avant = notifications
local r = session:validerCroquis(CROQUIS, TISSUS)
panne = nil
U.verifier(not r.ok and r.passager == true and r.erreur == "Le serveur ne répond pas. Réessaie.", "réponse perdue : refus passager")
U.verifier(session.etat.etape == "carnet" and cote().etape == "achat" and notifications == avant, "le serveur a agi, le client ne le sait pas encore")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.etape == "achat" and notifications == avant + 1, "l'état est redemandé : la copie est réparée, les écrans prévenus")
U.verifier(session.derniere.action == "nouvelleCommande", "la dernière action reste celle du joueur")

-- Réponse illisible : refus passager, sans erreur ; la session n'est pas bloquée
panne = "illisible"
M.avancer(1)
local sansErreur, r2 = pcall(session.acheter, session, "coton_blanc", 5)
panne = nil
U.verifier(sansErreur and not r2.ok and r2.passager == true and not session.enCours, "réponse illisible : refus passager, sans erreur, session libre")
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "l'action suivante passe")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc, "copie réparée après la réponse illisible")

-- Un refus emporte l'état du serveur : une copie fausse est réparée, les écrans prévenus
cote().argent = 4321
M.avancer(1)
avant = notifications
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and r.erreur == "Longueur invalide." and session.etat.argent == 4321 and notifications == avant + 1, "refus : l'état joint répare la copie, les écrans sont prévenus")
M.avancer(1)
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and notifications == avant + 1, "refus sans rien de changé : les écrans ne sont pas dérangés")

-- actualiser prévient les écrans quand l'état a changé
cote().argent = 99
M.avancer(1)
session:actualiser()
U.verifier(session.etat.argent == 99 and notifications == avant + 2, "actualiser : les écrans sont prévenus")

-- Pendant une action, actualiser attend son tour (pas deux appels à la fois)
local pendant
remote.OnServerInvoke = function(j, action, ...)
	pendant = pendant or session:actualiser()
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
session:acheter("coton_blanc", 1)
U.verifier(pendant ~= nil and not pendant.ok and pendant.passager == true and pendant.erreur == Session.OCCUPE, "actualiser pendant une action : « Un instant… »")
Session.courante, Commande.courante = courante, courant
