local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")
local Patron = U.module("Patron")

-- Deux serveurs (A et B) qui partagent le même DataStore ; horloge simulée ; attendre fait passer le temps
local magasin, ancien = M.nouveauMagasin(), M.nouveauMagasin()
local temps, attentes = 1000000, 0
local function horloge()
	return temps
end
local function attendre(s)
	attentes += 1
	temps += s
end
local A = Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = "A", horloge = horloge, attendre = attendre })
local B = Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = "B", horloge = horloge, attendre = attendre })

---------------------------------------------------------------------------
-- Nouvelle joueuse, ancienne sauvegarde (v1 → v2), migrations
---------------------------------------------------------------------------
local partie, statut = A:charger(7)
U.verifier(statut == "ok" and partie.version == Sauvegarde.VERSION and partie.argent == EtatAtelier.ARGENT_DEPART, "nouvelle partie : argent de départ")
U.verifier(partie.enCours == nil and #partie.recettes == 0 and next(partie.stock) == nil and type(partie.debloques) == "table", "nouvelle partie : ni commande, ni robe, ni stock")
U.verifier(magasin.donnees.joueur_7.verrou.jobId == "A" and magasin.donnees.joueur_7.verrou.t == temps, "verrou pris par le serveur A")
U.verifier(partie.verrou == nil, "la partie rendue ne contient pas le verrou")

ancien.donnees.joueur_8 = { argent = 480.7, reputation = 12 }
partie = A:charger(8)
U.verifier(partie.argent == 480 and partie.reputation == nil and partie.version == Sauvegarde.VERSION, "v1 → v2 : argent repris, réputation laissée")
ancien.donnees.joueur_8 = { argent = 9999 }
A:enregistrer(8, partie, true)
U.verifier(A:charger(8).argent == 480, "l'ancienne sauvegarde n'est reprise qu'une fois")
U.verifier(Sauvegarde.migrer({ argent = "beaucoup" }).argent == EtatAtelier.ARGENT_DEPART, "argent v1 illisible : argent de départ")
U.verifier(Sauvegarde.migrer({ argent = -50 }).argent == 0, "argent v1 négatif : 0")
U.verifier(Sauvegarde.migrer({ version = Sauvegarde.VERSION + 1 }) == nil, "partie d'une version plus récente : pas migrée")

---------------------------------------------------------------------------
-- Une partie en cours (une robe livrée, la suivante au milieu de la découpe) : sauvée, relue à l'identique
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local tissus = {}
for _, id in ipairs(ORDRE) do
	tissus[id] = "coton_blanc"
end
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(2))
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 24)
etat:commencerDecoupe()
for _, id in ipairs(ORDRE) do
	etat:couper(id, PLACES[id])
end
for _, id in ipairs(ORDRE) do
	etat:epingler(id)
end
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l)
end
etat:decorer({})
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
U.verifier(etat:livrer().reussie, "une robe livrée (mise en place du test)")
etat:nouvelleCommande(Random.new(3))
etat:validerCroquis(CROQUIS, tissus)
etat:commencerDecoupe()
etat:couper(ORDRE[1], PLACES[ORDRE[1]])
U.verifier(etat.etape == "decoupe" and #etat:piecesAPoser() == 3, "la suivante au milieu de la découpe (mise en place du test)")

local p = Sauvegarde.depuisEtat(etat)
U.verifier(p.enCours ~= nil and p.enCours.etape == "decoupe" and p.enCours.coupons.coton_blanc ~= nil and #p.recettes == 1, "la commande en cours et les robes sont dans la partie")
U.verifier(pcall(M.transmettre, p), "la partie se range dans le DataStore")
U.verifier(A:enregistrer(7, p) == "ok" and magasin.donnees.joueur_7.verrou.jobId == "A", "partie enregistrée, verrou gardé")
temps += 60
A:enregistrer(7, p)
U.verifier(magasin.donnees.joueur_7.verrou.t == temps, "verrou rafraîchi à chaque sauvegarde")
A:enregistrer(7, p, true)
U.verifier(magasin.donnees.joueur_7.verrou.jobId == "A" and magasin.donnees.joueur_7.verrou.t == 0, "verrou rendu au départ (A reste noté comme dernier serveur)")
attentes = 0
local relue = Sauvegarde.versEtat(B:charger(7))
U.verifier(attentes == 0 and magasin.donnees.joueur_7.verrou.jobId == "B", "verrou rendu : B prend la partie sans attendre")
U.verifier(relue.etape == "decoupe" and relue.argent == etat.argent and relue.stock.coton_blanc == etat.stock.coton_blanc, "relue : étape, argent, stock")
U.verifier(relue.commande.taille == etat.commande.taille and #relue:piecesAPoser() == 3 and Recette.encoder(relue.robes[1]) == Recette.encoder(etat.robes[1]), "relue : commande, pièces coupées, robe livrée")
U.verifier(relue:couper(ORDRE[2], PLACES[ORDRE[2]]).ok, "la découpe continue")
local accueil = Sauvegarde.depuisEtat(EtatAtelier.nouveau())
U.verifier(accueil.enCours == nil, "à l'accueil, pas de commande en cours")

---------------------------------------------------------------------------
-- Verrou tenu par un serveur vivant : essais toutes les 3 s, puis on prend la main après 15 s
---------------------------------------------------------------------------
attentes = 0
local debut = temps
partie, statut = A:charger(7)
U.verifier(statut == "ok" and temps - debut == Sauvegarde.ESSAI_MAX and attentes == Sauvegarde.ESSAI_MAX / Sauvegarde.ESSAI_PAS, "partie tenue ailleurs : essais toutes les 3 s, prise après 15 s")
U.verifier(magasin.donnees.joueur_7.verrou.jobId == "A", "A a pris la main")
local ecritures = magasin.ecritures
U.verifier(B:enregistrer(7, p) == "perdu" and magasin.ecritures == ecritures, "B a perdu la partie : il ne l'écrase plus")
temps += Sauvegarde.VERROU_VIVANT + 1
attentes = 0
partie, statut = B:charger(7)
U.verifier(statut == "ok" and attentes == 0 and magasin.donnees.joueur_7.verrou.jobId == "B", "verrou périmé (plus de 90 s) : pris sans attendre")

---------------------------------------------------------------------------
-- Protections : lecture ratée, version plus récente, écriture impossible
---------------------------------------------------------------------------
magasin.panne = 1
ecritures = magasin.ecritures
partie, statut = A:charger(9)
U.verifier(partie == nil and statut == "echec" and magasin.ecritures == ecritures, "lecture ratée : échec, rien écrit")
ancien.panne = 1
partie, statut = A:charger(10)
U.verifier(partie == nil and statut == "echec" and magasin.donnees.joueur_10 == nil, "ancienne sauvegarde illisible : échec, rien écrit")
magasin.donnees.joueur_11 = { version = Sauvegarde.VERSION + 1, argent = 5000 }
partie, statut = A:charger(11)
U.verifier(statut == "echec" and magasin.donnees.joueur_11.argent == 5000 and magasin.donnees.joueur_11.verrou == nil, "version plus récente : ni chargée, ni touchée")
U.verifier(A:enregistrer(11, accueil) == "perdu" and magasin.donnees.joueur_11.argent == 5000, "version plus récente : jamais écrasée")
magasin.donnees.joueur_12 = "illisible"
partie, statut = A:charger(12)
U.verifier(statut == "echec" and magasin.donnees.joueur_12 == "illisible", "partie illisible : ni chargée, ni touchée")
magasin.panne = 1
U.verifier(B:enregistrer(7, p) == "echec", "écriture impossible : échec signalé (on réessaiera)")

---------------------------------------------------------------------------
-- Partie abîmée : ce qui est illisible est laissé, le reste est gardé
---------------------------------------------------------------------------
local abimee = Sauvegarde.depuisEtat(etat)
abimee.enCours.croquis = { corsage = "inconnu", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
M.avertissements = {}
local e = Sauvegarde.versEtat(abimee)
U.verifier(e.etape == "accueil" and e.commande == nil and e.argent == etat.argent and e.stock.coton_blanc == etat.stock.coton_blanc and #e.robes == 1, "commande en cours illisible : abandonnée, le reste gardé")
U.verifier(#M.avertissements == 1, "un avertissement")
local s = Sauvegarde.depuisEtat(EtatAtelier.nouveau())
s.argent = 0 / 0
s.stock = { coton_blanc = 12, inconnu = 5, soie_rouge = "x", lin_bleu = -3 }
s.recettes = { etat.robes[1], { version = 1, bidon = true } }
e = Sauvegarde.versEtat(s)
U.verifier(e.argent == EtatAtelier.ARGENT_DEPART, "argent illisible : argent de départ")
U.verifier(e.stock.coton_blanc == 12 and e.stock.inconnu == nil and e.stock.soie_rouge == nil and e.stock.lin_bleu == nil, "stock abîmé : seules les entrées valides restent")
U.verifier(#e.robes == 1, "robe illisible laissée de côté")

---------------------------------------------------------------------------
-- Dans le jeu : pas de DataStore sur un lieu non publié
---------------------------------------------------------------------------
M.avertissements = {}
U.verifier(Sauvegarde.pourLeJeu() == nil and #M.avertissements == 1, "lieu non publié : pas de sauvegarde, un avertissement")
rawget(M.game, "__props").PlaceId = 4242
rawget(M.game, "__props").JobId = "serveur-test"
M.magasins = {}
local jeu = Sauvegarde.pourLeJeu()
U.verifier(jeu ~= nil and jeu.jobId == "serveur-test" and jeu.magasin == M.magasins.AtelierCouture_v2 and jeu.ancien == M.magasins.AtelierCouture_v1, "lieu publié : DataStore v2, et v1 pour la reprise")
M.magasins = nil
rawget(M.game, "__props").PlaceId = 0
rawget(M.game, "__props").JobId = ""
