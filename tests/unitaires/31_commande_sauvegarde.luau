local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")

-- Des serveurs qui partagent le même DataStore ; horloge simulée ; attendre fait passer le temps
local magasin = M.nouveauMagasin()
local temps, attentes = 2000000, 0
local function sauvegarde(jobId)
	return Sauvegarde.nouvelle({
		magasin = magasin,
		ancien = M.nouveauMagasin(),
		jobId = jobId,
		horloge = function()
			return temps
		end,
		attendre = function(s)
			attentes += 1
			temps += s
		end,
	})
end
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	return j
end
-- Verrou rendu : le serveur qui tenait la partie reste noté, avec un temps nul
local function rendu(verrou)
	return type(verrou) == "table" and verrou.t == 0
end
local function appeler(serveur, joueur, action, ...)
	M.avancer(0.25)
	return serveur:traiter(joueur, action, ...)
end

---------------------------------------------------------------------------
-- Arrivée : l'atelier se prépare le temps de lire la partie
---------------------------------------------------------------------------
local fidele = joueurNumero("Fidele", 501)
local s1 = Commande.nouvelle({ sauvegarde = sauvegarde("S1") })
local r = appeler(s1, fidele, "etat")
U.verifier(not r.ok and r.attente == true and r.erreur == "L'atelier se prépare, réessaie dans un instant.", "avant le chargement : l'atelier se prépare")
s1:arrivee(fidele)
r = appeler(s1, fidele, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and r.avertissement == nil, "partie chargée (neuve), sans avertissement")

-- Une commande jusqu'à la découpe
appeler(s1, fidele, "nouvelleCommande")
appeler(s1, fidele, "mesurer", U.module("Clientes").get(s1:atelier(fidele).etat.commande.cliente).mesures)
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
appeler(s1, fidele, "validerCroquis", CROQUIS, {
	corsage_droit_devant = "coton_blanc",
	corsage_droit_dos = "coton_blanc",
	jupe_droite_devant = "coton_blanc",
	jupe_droite_dos = "coton_blanc",
})
appeler(s1, fidele, "acheter", "coton_blanc", 12)
appeler(s1, fidele, "commencerDecoupe")
r = appeler(s1, fidele, "couper", "corsage_droit_devant", { x = 2.4, y = 2.1, angle = 0 })
U.verifier(r.ok and r.etat.etape == "decoupe", "une pièce coupée (mise en place du test)")
local avant = s1:atelier(fidele).etat:exporter()

---------------------------------------------------------------------------
-- Sauvegarde régulière, départ, retour sur un autre serveur
---------------------------------------------------------------------------
s1:enregistrerTout()
local rangee = magasin.donnees.joueur_501
U.verifier(rangee ~= nil and rangee.enCours.etape == "decoupe" and rangee.verrou.jobId == "S1", "sauvegarde régulière : la commande en cours, verrou tenu")
fidele.Parent = nil
s1:depart(fidele)
U.verifier(rendu(magasin.donnees.joueur_501.verrou) and s1.ateliers[fidele] == nil, "départ : partie écrite, verrou rendu, atelier libéré")
fidele.Parent = M.services.Players
local s2 = Commande.nouvelle({ sauvegarde = sauvegarde("S2") })
attentes = 0
s2:arrivee(fidele)
r = appeler(s2, fidele, "etat")
U.verifier(attentes == 0 and r.ok and r.etat.etape == "decoupe" and r.etat.argent == avant.argent and r.etat.stock.coton_blanc == avant.stock.coton_blanc, "retour : la commande reprend où elle en était")
U.verifier(r.etat.commande.taille == avant.commande.taille and r.etat.coupees.corsage_droit_devant ~= nil, "retour : même commande, pièce déjà coupée")
r = appeler(s2, fidele, "couper", "corsage_droit_dos", { x = 7.2, y = 2.1, angle = 0 })
U.verifier(r.ok, "la découpe continue sur le nouveau serveur")

---------------------------------------------------------------------------
-- Partie prise par un autre serveur : on cesse de l'écrire
---------------------------------------------------------------------------
local s3 = Commande.nouvelle({ sauvegarde = sauvegarde("S3") })
attentes = 0
s3:arrivee(fidele) -- S2 tient encore la partie : S3 attend 15 s, puis prend la main
U.verifier(attentes == Sauvegarde.ESSAI_MAX / Sauvegarde.ESSAI_PAS and magasin.donnees.joueur_501.verrou.jobId == "S3", "un autre serveur prend la main après 15 s")
M.avertissements = {}
local ecritures = magasin.ecritures
U.verifier(s2:enregistrer(fidele) == "perdu" and magasin.ecritures == ecritures and #M.avertissements == 1, "l'ancien serveur ne l'écrase pas, un avertissement")
s2:enregistrerTout()
s2:depart(fidele)
U.verifier(magasin.ecritures == ecritures and magasin.donnees.joueur_501.verrou.jobId == "S3", "il ne l'écrit plus du tout, même au départ")

-- Un serveur figé qui se réveille après que le joueur a joué, puis quitté un autre serveur (verrou rendu
-- entre-temps) n'écrase pas cette partie plus récente
local figee = joueurNumero("Figee", 505)
local sA = Commande.nouvelle({ sauvegarde = sauvegarde("SA") })
sA:arrivee(figee)
local sB = Commande.nouvelle({ sauvegarde = sauvegarde("SB") })
sB:arrivee(figee) -- SA ne répond plus : SB prend la main après 15 s
sB:atelier(figee).etat.argent = 777
sB:depart(figee)
U.verifier(magasin.donnees.joueur_505.argent == 777 and rendu(magasin.donnees.joueur_505.verrou), "le joueur a joué sur SB, qui a rendu sa partie")
ecritures = magasin.ecritures
sA:depart(figee) -- SA se réveille, avec sa vieille copie
U.verifier(magasin.ecritures == ecritures and magasin.donnees.joueur_505.argent == 777, "le serveur figé n'écrase pas la partie plus récente")

---------------------------------------------------------------------------
-- Lecture ratée : partie neuve pour cette fois, jamais écrite, le joueur est prévenu
---------------------------------------------------------------------------
local malchance = joueurNumero("Malchance", 502)
magasin.donnees.joueur_502 = { version = Sauvegarde.VERSION, argent = 900, stock = {}, debloques = {}, recettes = {} }
magasin.panne = Sauvegarde.ESSAIS_LECTURE
s3:arrivee(malchance)
r = appeler(s3, malchance, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and type(r.avertissement) == "string", "lecture ratée : partie neuve, joueur prévenu")
ecritures = magasin.ecritures
appeler(s3, malchance, "nouvelleCommande")
s3:enregistrerTout()
malchance.Parent = nil
s3:depart(malchance)
U.verifier(magasin.donnees.joueur_502.argent == 900 and magasin.ecritures == ecritures + 1, "sa vraie partie n'est jamais écrasée (seule celle de Fidele est écrite)")

---------------------------------------------------------------------------
-- Écriture au départ ou à l'arrêt : une panne passagère est réessayée
---------------------------------------------------------------------------
local tenace = joueurNumero("Tenace", 506)
local s5 = Commande.nouvelle({
	sauvegarde = sauvegarde("S5"),
	attendre = function(s)
		temps += s
	end,
})
s5:arrivee(tenace)
s5:atelier(tenace).etat.argent = 321
magasin.panne = 1
s5:depart(tenace)
U.verifier(magasin.donnees.joueur_506.argent == 321 and rendu(magasin.donnees.joueur_506.verrou) and magasin.panne == 0, "panne passagère au départ : réessai, partie écrite")
s5:arrivee(tenace)
s5:atelier(tenace).etat.argent = 654
magasin.panne = 1
s5:fermer()
U.verifier(magasin.donnees.joueur_506.argent == 654 and rendu(magasin.donnees.joueur_506.verrou), "panne passagère à l'arrêt : réessai, partie écrite")

---------------------------------------------------------------------------
-- Joueur parti pendant le chargement : sa partie est rendue tout de suite, pas d'atelier
---------------------------------------------------------------------------
local presse = joueurNumero("Presse", 503)
presse.Parent = nil
s3:arrivee(presse)
U.verifier(s3.ateliers[presse] == nil and magasin.donnees.joueur_503 ~= nil and rendu(magasin.donnees.joueur_503.verrou), "parti pendant le chargement : partie rendue, pas d'atelier")

---------------------------------------------------------------------------
-- Arrêt du serveur : toutes les parties écrites, verrous rendus
---------------------------------------------------------------------------
s3:fermer()
U.verifier(rendu(magasin.donnees.joueur_501.verrou) and magasin.donnees.joueur_501.enCours.etape == "decoupe", "arrêt du serveur : partie écrite, verrou rendu")

---------------------------------------------------------------------------
-- Sans sauvegarde (lieu non publié) : partie neuve tout de suite, comme avant
---------------------------------------------------------------------------
local libre = Commande.nouvelle()
local visiteuse = joueurNumero("Visiteuse", 504)
r = appeler(libre, visiteuse, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and r.avertissement == nil, "sans sauvegarde : partie neuve, sans attente ni avertissement")
libre:arrivee(visiteuse)
libre:depart(visiteuse)
U.verifier(libre.ateliers[visiteuse] == nil, "sans sauvegarde : départ sans écriture")
