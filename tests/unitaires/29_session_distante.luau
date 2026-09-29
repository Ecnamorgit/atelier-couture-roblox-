local Session = U.module("Session")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

-- Un serveur et sa RemoteFunction, comme dans le jeu (le faux Roblox copie tout ce qui passe le réseau)
local serveur = Commande.nouvelle()
local remote = M.nouvelleInstance("RemoteFunction")
remote.Name = "Atelier"
local function brancher()
	remote.OnServerInvoke = function(joueur, action, ...)
		return serveur:traiter(joueur, action, ...)
	end
end
brancher()
local joueur = M.nouveauJoueur("Distante")
M.joueurLocal = joueur
local function cote()
	return serveur:atelier(joueur).etat
end

---------------------------------------------------------------------------
-- Arrivée : la session demande l'état au serveur
---------------------------------------------------------------------------
cote().argent = 321 -- (au plan 4b, l'argent viendra de la sauvegarde)
M.avancer(1)
local session = Session.distante(remote)
U.verifier(Session.courante == session, "la session du joueur est connue")
U.verifier(session.etat.argent == 321 and session.etat.etape == "accueil", "l'état vient du serveur dès l'arrivée")
U.verifier(typeof(session.rng) == "Random", "hasard local gardé pour la machine à coudre (le serveur ne s'en sert pas)")

---------------------------------------------------------------------------
-- Une action : le serveur décide, le client recharge l'état sur place
---------------------------------------------------------------------------
local notifications = 0
session:surChangement(function()
	notifications += 1
end)
local objet = session.etat
M.avancer(1)
local r = session:nouvelleCommande()
U.verifier(r.ok and notifications == 1, "nouvelle commande acceptée, l'interface prévenue une fois")
U.verifier(session.etat == objet and session.etat.etape == "carnet", "même objet d'état (les écrans le gardent), à jour")
U.verifier(session.etat.commande ~= nil and session.etat.commande.taille == cote().commande.taille, "la commande est celle du serveur")
U.verifier(session.derniere.action == "nouvelleCommande" and session.derniere.reponse.ok, "dernière action retenue (accueil, cliente)")
local commande = session.etat.commande
M.avancer(1)
session:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "coton_blanc",
	corsage_droit_dos = "coton_blanc",
	jupe_droite_devant = "coton_blanc",
	jupe_droite_dos = "coton_blanc",
})
M.avancer(1)
r = session:acheter("coton_blanc", 10)
U.verifier(r.ok and session.etat.stock.coton_blanc == 10 and session.etat.argent == cote().argent, "achat : stock et argent du serveur")
U.verifier(session.etat.commande == commande, "la commande garde sa table d'une action à l'autre (la scène garde sa cliente)")

---------------------------------------------------------------------------
-- Refus du serveur : message, rien ne change, l'interface n'est pas prévenue
---------------------------------------------------------------------------
local avant = notifications
M.avancer(1)
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and r.erreur == "Longueur invalide." and notifications == avant and session.etat.stock.coton_blanc == 10, "refus : message, état inchangé")

---------------------------------------------------------------------------
-- Le client ne peut rien s'accorder : l'état local n'est qu'une copie
---------------------------------------------------------------------------
cote().argent = 5
session.etat.argent = 99999
M.avancer(1)
r = session:acheter("soie_rouge", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent.", "argent modifié chez le client : le serveur refuse quand même")
cote().argent = 500
session:actualiser()
U.verifier(session.etat.argent == 500, "actualiser : l'état revient à celui du serveur")

---------------------------------------------------------------------------
-- Une action à la fois : un second appui pendant que le serveur répond est refusé
---------------------------------------------------------------------------
local appelsServeur, pendant = 0, nil
remote.OnServerInvoke = function(j, action, ...)
	appelsServeur += 1
	if appelsServeur == 1 then
		pendant = session:acheter("coton_blanc", 1) -- le joueur appuie encore pendant l'attente
	end
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
r = session:acheter("coton_blanc", 2)
brancher()
U.verifier(r.ok and appelsServeur == 1, "le premier achat passe, un seul appel au serveur")
U.verifier(pendant ~= nil and not pendant.ok and pendant.erreur == "Un instant…" and pendant.passager == true, "le second appui attend : « Un instant… » (refus passager)")
U.verifier(session.etat.stock.coton_blanc == 12, "un seul achat compté")

---------------------------------------------------------------------------
-- Serveur injoignable : message, pas d'erreur ; la session repart ensuite
---------------------------------------------------------------------------
remote.OnServerInvoke = function()
	error("coupure simulée")
end
r = session:acheter("coton_blanc", 1)
U.verifier(not r.ok and r.erreur == "Le serveur ne répond pas. Réessaie." and r.passager == true, "serveur injoignable : message (refus passager)")
brancher()
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "la session repart quand le serveur répond")
local autre = Session.distante((function()
	local muet = M.nouvelleInstance("RemoteFunction")
	muet.OnServerInvoke = function()
		error("coupure simulée")
	end
	return muet
end)())
U.verifier(autre.etat.etape == "accueil" and autre.etat.argent == EtatAtelier.ARGENT_DEPART, "serveur injoignable à l'arrivée : état de départ, sans erreur")
U.verifier(autre.avertissement == Session.PAS_PRETE, "serveur injoignable à l'arrivée : le joueur est prévenu")
Session.courante = session
