local Commande = U.module("Commande")

local courant = Commande.courante
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Reponses")
-- Un appel du client, espacé comme un joueur ; chaque réponse doit pouvoir passer par le réseau
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	U.verifier(pcall(M.transmettre, r), "réponse transmissible : " .. tostring(action))
	return r
end
local etat = serveur:atelier(joueur).etat

---------------------------------------------------------------------------
-- Un refus des règles emporte l'état : le client répare sa copie (réponse perdue, partie arrivée tard)
---------------------------------------------------------------------------
etat.argent = 432
local r = appeler("livrer")
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat ~= nil and r.etat.argent == 432 and r.etat.etape == "accueil", "refus des règles : l'état du serveur est joint")
U.verifier(not r.passager, "un refus des règles n'est pas passager (réessayer n'y changerait rien)")
r = appeler("voler")
U.verifier(not r.ok and r.etat == nil and not r.passager, "action inconnue : ni état, ni réessai")

---------------------------------------------------------------------------
-- Refus passagers (réessayer plus tard) : trop d'appels, atelier en préparation
---------------------------------------------------------------------------
M.avancer(1.01)
for _ = 1, Commande.APPELS_PAR_SECONDE do
	serveur:traiter(joueur, "etat")
end
r = serveur:traiter(joueur, "etat")
U.verifier(not r.ok and r.erreur == "Doucement !" and r.passager == true and r.etat == nil, "trop d'appels : refus passager, sans état")
local lent = Commande.nouvelle({ sauvegarde = {} }) -- partie pas encore lue
r = lent:traiter(M.nouveauJoueur("Patiente"), "etat")
U.verifier(not r.ok and r.attente and r.passager == true, "atelier en préparation : refus passager")

---------------------------------------------------------------------------
-- Relevés de couture (non limités) : un refus n'emporte l'état que dans la limite des appels
---------------------------------------------------------------------------
M.avancer(1.01)
local avecEtat = 0
for _ = 1, 10 do
	r = serveur:traiter(joueur, "rendreCouture", "corsage_droit_devant", {}, 1) -- dix relevés au même instant
	U.verifier(not r.ok and r.erreur ~= "Doucement !", "relevé refusé par les règles, jamais limité")
	if r.etat then
		avecEtat += 1
	end
end
U.verifier(avecEtat == Commande.APPELS_PAR_SECONDE, "relevés refusés en rafale : l'état n'est joint qu'aux " .. avecEtat .. " premiers")

---------------------------------------------------------------------------
-- L'état renvoyé : préparé à l'abri des erreurs, sans parcourir les anciennes robes
---------------------------------------------------------------------------
M.avancer(1.01)
local vrai = Commande.instantane
Commande.instantane = function()
	error("panne simulée")
end
local sansErreur, r2 = pcall(serveur.traiter, serveur, joueur, "etat")
Commande.instantane = vrai
U.verifier(sansErreur and not r2.ok and r2.erreur == "Action impossible.", "erreur en préparant l'état renvoyé : refus, pas d'erreur")
-- Une ancienne robe qui se contient elle-même : la copier ne finirait jamais
local boucle = {}
boucle.moi = boucle
etat.robes = { { numero = 1 }, boucle }
local copie = select(2, pcall(Commande.instantane, etat))
U.verifier(type(copie) == "table" and #copie.robes == 1 and copie.robes[1].numero == 1 and copie.robes[1] ~= etat.robes[1], "l'état renvoyé copie la robe en vitrine, sans parcourir les anciennes")
local d = etat:exporter(1)
U.verifier(#d.robes == 1 and d.robes[1].numero == 1, "exporter(1) : une seule robe")
etat.robes = { { numero = 1 }, { numero = 2 } }
U.verifier(#etat:exporter().robes == 2, "exporter() : toutes les robes (sauvegarde)")
Commande.courante = courant
