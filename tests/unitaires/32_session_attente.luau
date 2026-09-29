local Session = U.module("Session")
local EtatAtelier = U.module("EtatAtelier")

-- Un serveur qui se prépare pendant « pret - 1 » appels, puis répond (avec un avertissement)
local remote = M.nouvelleInstance("RemoteFunction")
local appels, pret = 0, 3
local AVERTISSEMENT = "Ta partie ne peut pas être sauvegardée pour le moment."
remote.OnServerInvoke = function()
	appels += 1
	if appels < pret then
		return { ok = false, erreur = "L'atelier se prépare, réessaie dans un instant.", attente = true }
	end
	return { ok = true, etat = EtatAtelier.nouveau(777):exporter(), avertissement = AVERTISSEMENT }
end
M.joueurLocal = M.nouveauJoueur("Patiente")
local courante = Session.courante

local attendu = 0
local session = Session.distante(remote, function(s)
	attendu += s
end)
U.verifier(appels == 3 and attendu == 2 and session.etat.argent == 777, "la session attend que le serveur ait lu la partie (un essai par seconde)")
U.verifier(session.avertissement == AVERTISSEMENT, "l'avertissement du serveur est gardé pour l'interface")

-- Un serveur qui ne finit jamais de se préparer : abandon après Session.ESSAIS_ARRIVEE essais, sans erreur
appels, pret = 0, math.huge
local lasse = Session.distante(remote, function() end)
U.verifier(appels == Session.ESSAIS_ARRIVEE and lasse.etat.etape == "accueil", "serveur jamais prêt : abandon après " .. tostring(Session.ESSAIS_ARRIVEE) .. " essais, état de départ")
U.verifier(lasse.avertissement == Session.PAS_PRETE and string.find(Session.PAS_PRETE, "pas encore", 1, true) ~= nil, "serveur jamais prêt : le joueur est prévenu que sa partie n'est pas encore là")

-- Un autre refus n'est pas une attente : pas de nouvel essai
appels = 0
remote.OnServerInvoke = function()
	appels += 1
	return { ok = false, erreur = "Doucement !" }
end
Session.distante(remote, function()
	error("ne doit pas attendre")
end)
U.verifier(appels == 1, "un refus qui n'est pas une attente : pas de nouvel essai")
Session.courante = courante
