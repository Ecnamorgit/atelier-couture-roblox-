local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local HttpService = M.services.HttpService

---------------------------------------------------------------------------
-- Une partie trop lourde pour le DataStore perd ses plus anciennes robes, jusqu'à tenir
---------------------------------------------------------------------------
local lourd = EtatAtelier.nouveau()
for i = 1, EtatAtelier.ROBES_GARDEES do
	lourd.robes[i] = { numero = i, bourrage = string.rep("x", 1000) }
end
local limite = Sauvegarde.TAILLE_MAX
Sauvegarde.TAILLE_MAX = 4500
local partie = Sauvegarde.depuisEtat(lourd)
Sauvegarde.TAILLE_MAX = limite
U.verifier(#HttpService:JSONEncode(partie) <= 4500 and #partie.recettes >= 1 and #partie.recettes < EtatAtelier.ROBES_GARDEES, "partie trop lourde : " .. #partie.recettes .. " robes gardées, sous la limite")
U.verifier(partie.recettes[1].numero == 1 and partie.recettes[#partie.recettes].numero == #partie.recettes, "les plus récentes sont gardées")
U.verifier(#Sauvegarde.depuisEtat(lourd).recettes == EtatAtelier.ROBES_GARDEES, "sous la limite : toutes les robes")
U.verifier(limite <= 4000000, "la limite laisse de la place sous les 4 Mo d'une clé du DataStore")
-- Chaque robe livrée n'est encodée qu'une fois : une partie énorme ne fige pas le serveur à chaque sauvegarde
local lourde = EtatAtelier.nouveau()
for i = 1, EtatAtelier.ROBES_GARDEES do
	lourde.robes[i] = { numero = i, bourrage = string.rep("y", 1000) }
end
Sauvegarde.TAILLE_MAX = 4500
M.encodages = 0
local premiere = Sauvegarde.depuisEtat(lourde)
local encodagesPremiere = M.encodages
M.encodages = 0
local suivante = Sauvegarde.depuisEtat(lourde)
local encodagesSuivante = M.encodages
Sauvegarde.TAILLE_MAX = limite
U.verifier(#premiere.recettes == #suivante.recettes and #HttpService:JSONEncode(suivante) <= 4500, "même partie d'une sauvegarde à l'autre, sous la limite")
U.verifier(encodagesPremiere <= EtatAtelier.ROBES_GARDEES + 1, "première sauvegarde : chaque robe encodée une fois au plus (" .. encodagesPremiere .. " encodages)")
U.verifier(encodagesSuivante <= 1, "sauvegardes suivantes : les robes déjà mesurées ne sont pas réencodées (" .. encodagesSuivante .. " encodages)")

---------------------------------------------------------------------------
-- Un serveur, son DataStore ; attendre fait passer le temps (et laisse le test agir pendant l'attente)
---------------------------------------------------------------------------
local courant = Commande.courante
local magasin = M.nouveauMagasin()
local temps, attentes = 3000000, 0
local pendant = nil
local function attendre(s)
	attentes += 1
	temps += s
	if pendant then
		pendant()
	end
end
local function horloge()
	return temps
end
local sauvegarde = Sauvegarde.nouvelle({ magasin = magasin, ancien = M.nouveauMagasin(), jobId = "S", horloge = horloge, attendre = attendre })
local serveur = Commande.nouvelle({ sauvegarde = sauvegarde, horloge = horloge, attendre = attendre })
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	return j
end
local function cle(j)
	return "joueur_" .. j.UserId
end

---------------------------------------------------------------------------
-- Une écriture à la fois par joueur : la suivante attend la fin de la précédente
---------------------------------------------------------------------------
local serie = joueurNumero("Serie", 701)
serveur:arrivee(serie)
serveur.ecritures[serie.UserId] = true -- la sauvegarde régulière est en train d'écrire
local ecrituresAvant = magasin.ecritures
local rienPendant = true
attentes = 0
pendant = function()
	rienPendant = rienPendant and magasin.ecritures == ecrituresAvant
	if attentes == 2 then
		serveur:atelier(serie).etat.argent = 777 -- le joueur a joué entre-temps
		serveur.ecritures[serie.UserId] = nil -- l'écriture en cours se termine
	end
end
local statut = serveur:enregistrer(serie, false)
pendant = nil
U.verifier(rienPendant and attentes == 2, "rien n'est écrit tant que l'écriture précédente n'est pas finie")
U.verifier(statut == "ok" and magasin.donnees[cle(serie)].argent == 777 and serveur.ecritures[serie.UserId] == nil, "puis la partie est écrite, avec l'état du moment ; la place est libre")
-- Une erreur en préparant la partie ne bloque pas les écritures suivantes
local vraie = Sauvegarde.depuisEtat
Sauvegarde.depuisEtat = function()
	error("panne simulée")
end
local sansErreur, statutPanne = pcall(serveur.enregistrer, serveur, serie, false)
Sauvegarde.depuisEtat = vraie
U.verifier(sansErreur and statutPanne == "echec" and serveur.ecritures[serie.UserId] == nil, "erreur en préparant la partie : échec, sans bloquer les écritures suivantes")

---------------------------------------------------------------------------
-- De retour sur ce serveur avant la fin de l'écriture de son départ : l'arrivée l'attend
---------------------------------------------------------------------------
serveur:depart(serie)
local retour = joueurNumero("Serie", 701) -- nouvel objet Player, même compte
serveur.ecritures[retour.UserId] = true -- l'écriture du départ n'est pas finie
local lectures = magasin.ecritures
local luPendant = false
attentes = 0
pendant = function()
	luPendant = luPendant or magasin.ecritures ~= lectures
	if attentes == 3 then
		magasin.donnees[cle(retour)].argent = 888 -- l'écriture du départ arrive
		serveur.ecritures[retour.UserId] = nil
	end
end
serveur:arrivee(retour)
pendant = nil
U.verifier(not luPendant and attentes == 3, "la partie n'est pas lue pendant l'écriture du départ")
U.verifier(serveur:atelier(retour).etat.argent == 888, "retour : la partie lue est celle écrite au départ")

---------------------------------------------------------------------------
-- Lecture d'une partie tenue un moment par un autre serveur : le joueur est « en chargement »
---------------------------------------------------------------------------
local lent = joueurNumero("Lent", 703)
magasin.donnees[cle(lent)] = { version = 2, argent = 55, stock = {}, debloques = {}, recettes = {}, verrou = { jobId = "AUTRE", t = temps } }
local pendantLecture = false
pendant = function()
	pendantLecture = pendantLecture or serveur.chargements[lent] == true
end
serveur:arrivee(lent)
pendant = nil
U.verifier(pendantLecture and serveur.chargements[lent] == nil and serveur:atelier(lent).etat.argent == 55, "lecture notée en cours, puis effacée une fois la partie lue")

---------------------------------------------------------------------------
-- Arrêt du serveur pendant la lecture d'une partie : on l'attend ; lue après l'arrêt, elle est rendue
---------------------------------------------------------------------------
local tardif = joueurNumero("Tardif", 702)
serveur.chargements[tardif] = true -- sa partie est en cours de lecture
attentes = 0
pendant = function()
	if attentes == 4 then
		serveur.chargements[tardif] = nil -- la lecture se termine
	end
end
serveur:fermer()
pendant = nil
U.verifier(attentes == 4, "arrêt : on attend la lecture en cours (" .. attentes .. " attentes)")
U.verifier(magasin.donnees[cle(retour)].verrou.t == 0 and magasin.donnees[cle(lent)].verrou.t == 0, "arrêt : les parties des joueurs présents sont écrites et rendues")
serveur:arrivee(tardif)
U.verifier(serveur:atelier(tardif) == nil and magasin.donnees[cle(tardif)] ~= nil and magasin.donnees[cle(tardif)].verrou.t == 0, "lue après l'arrêt : la partie est rendue aussitôt, sans atelier")
U.verifier(serveur.chargements[tardif] == nil, "plus de lecture en cours")

---------------------------------------------------------------------------
-- Une écriture régulière qui attendait la fin du départ, ou qui passe pendant l'arrêt, rend le verrou
---------------------------------------------------------------------------
local serveur2 = Commande.nouvelle({ sauvegarde = sauvegarde, horloge = horloge, attendre = attendre })
local regulier = joueurNumero("Regulier", 704)
serveur2:arrivee(regulier)
serveur2.ecritures[regulier.UserId] = true -- l'écriture du départ est en cours
attentes = 0
pendant = function()
	if attentes == 2 then
		serveur2.ecritures[regulier.UserId] = nil
		serveur2:depart(regulier) -- elle se termine : partie écrite, verrou rendu, atelier retiré
	end
end
serveur2:enregistrer(regulier, false) -- la sauvegarde régulière, lancée pendant l'écriture du départ
pendant = nil
U.verifier(magasin.donnees[cle(regulier)].verrou.t == 0, "écriture régulière passée après le départ : le verrou reste rendu")
local arrete = joueurNumero("Arrete", 705)
serveur2:arrivee(arrete)
serveur2.ecritures[arrete.UserId] = true -- une écriture est en cours
attentes = 0
pendant = function()
	if attentes == 2 then
		serveur2.ecritures[arrete.UserId] = nil
		serveur2:fermer() -- le serveur s'arrête pendant l'attente
	end
end
serveur2:enregistrer(arrete, false)
pendant = nil
U.verifier(magasin.donnees[cle(arrete)].verrou.t == 0, "écriture régulière passée pendant l'arrêt : le verrou reste rendu")
local ecrituresArret = magasin.ecritures
serveur2:enregistrerTout()
U.verifier(magasin.ecritures == ecrituresArret, "serveur arrêté : plus de sauvegarde régulière")
Commande.courante = courant
