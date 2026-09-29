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
M.avancer(1)
U.verifier(session:mesurer(U.module("Clientes").get(session.etat.commande.cliente).mesures).ok, "mesures prises")

-- Réponse perdue : refus passager ; l'état est redemandé au serveur un peu plus tard
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local TISSUS = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
panne = "apres"
M.avancer(1)
local avant = notifications
local r = session:validerCroquis(CROQUIS, TISSUS)
panne = nil
U.verifier(not r.ok and r.passager == true and r.erreur == Session.INJOIGNABLE, "réponse perdue : refus passager")
U.verifier(string.find(r.erreur, "Réessaie", 1, true) == nil, "le message n'invite pas à refaire une action que le serveur a peut-être faite")
U.verifier(session.etat.etape == "carnet" and cote().etape == "achat" and notifications == avant, "le serveur a agi, le client ne le sait pas encore")
-- Tant que l'état n'est pas revenu, les actions attendent : rien n'est fait deux fois
M.avancer(0.5)
r = session:validerCroquis(CROQUIS, TISSUS)
U.verifier(not r.ok and r.passager == true and r.erreur == Session.VERIFICATION and cote().etape == "achat", "pendant la vérification, les actions attendent")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.etape == "achat" and notifications == avant + 1, "l'état est redemandé : la copie est réparée, les écrans prévenus")
U.verifier(session.derniere.action == "mesurer", "la dernière action reste celle du joueur")

-- Réponse illisible : refus passager, sans erreur ; la session n'est pas bloquée
panne = "illisible"
M.avancer(1)
local sansErreur, r2 = pcall(session.acheter, session, "coton_blanc", 5)
panne = nil
U.verifier(sansErreur and not r2.ok and r2.passager == true and not session.enCours, "réponse illisible : refus passager, sans erreur, session libre")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc, "copie réparée après la réponse illisible")
U.verifier(session:acheter("coton_blanc", 1).ok, "l'action suivante passe")

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

-- « Action impossible. » (erreur du serveur) : l'action a pu être faite ; l'état est redemandé
local vraie = Commande.instantane
local unefois = true
Commande.instantane = function(etat)
	if unefois then
		unefois = false
		error("panne simulée")
	end
	return vraie(etat)
end
remote.OnServerInvoke = function(j, action, ...)
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
local stockAvant = session.etat.stock.coton_blanc
r = session:acheter("coton_blanc", 1)
Commande.instantane = vraie
U.verifier(not r.ok and r.erreur == "Action impossible." and r.passager == true and session.etat.stock.coton_blanc == stockAvant, "erreur du serveur après l'achat : refus passager, copie pas encore à jour")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc and cote().stock.coton_blanc == stockAvant + 1, "l'état est redemandé : l'achat fait par le serveur apparaît")

-- Un indicateur d'attente qui lève une erreur ne bloque pas la session
session:surAttente(function()
	error("indicateur en panne")
end)
M.avancer(1)
local sansErreurAttente, r3 = pcall(session.acheter, session, "coton_blanc", 1)
U.verifier(sansErreurAttente and r3.ok and not session.enCours, "indicateur en panne : l'action passe, la session reste libre")
session:surAttente(function() end)

-- Serveur toujours injoignable : la vérification échoue aussi, et les actions ne restent pas bloquées
remote.OnServerInvoke = function()
	error("coupure simulée")
end
M.avancer(1)
session:acheter("coton_blanc", 1)
M.avancer(Session.RESYNCHRO + 0.1) -- la vérification échoue
local r4 = session:acheter("coton_blanc", 1)
U.verifier(not r4.ok and r4.erreur == Session.INJOIGNABLE, "vérification ratée elle aussi : l'action suivante est tentée, rien ne reste bloqué")
remote.OnServerInvoke = function(j, action, ...)
	return serveur:traiter(j, action, ...)
end
Session.courante, Commande.courante = courante, courant
