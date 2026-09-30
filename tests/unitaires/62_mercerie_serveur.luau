-- Sous-projet 6 : la mercerie dans la sauvegarde (format v4, kit offert aux parties existantes) et sur le serveur
-- (achat limité comme les autres actions, décorations vérifiées contre le stock).
local Sauvegarde = U.module("Sauvegarde")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

-- Une robe simple, coupée, épinglée et cousue, aux décorations (sans rien de posé)
local function aDecorer(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
end
local function perle(v)
	return { id = "perle", piece = 1, copie = "unique", u = 0.5, v = v or 0.5, echelle = 1, angle = 0 }
end

---------------------------------------------------------------------------
-- Sauvegarde v4 : la mercerie, relue à l'identique
---------------------------------------------------------------------------
U.verifier(Sauvegarde.VERSION == 4, "format v4")
local e = EtatAtelier.nouveau(300)
e.mercerie = { perle = 12, ruban_rose = 250 }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(e)))
U.verifier(relue.mercerie.perle == 12 and relue.mercerie.ruban_rose == 250 and relue.mercerie.bouton_nacre == nil, "mercerie sauvée, relue telle quelle")

-- Mercerie abîmée : ce qui est illisible est laissé de côté ; au-delà du plafond, ramené au plafond
local partie = Sauvegarde.depuisEtat(e)
partie.mercerie = { perle = -3, bouton_nacre = 2.5, fleur_rose = "trois", inconnu = 4, bouton_dore = 5000, dentelle_blanche = 20000, noeud_satin = 0 / 0, fleur_blanche = 4, etoile_brodee = 0 }
local m = Sauvegarde.versEtat(partie).mercerie
U.verifier(m.perle == nil and m.bouton_nacre == nil and m.fleur_rose == nil and m.inconnu == nil and m.noeud_satin == nil and m.etoile_brodee == nil and m.fleur_blanche == 4, "quantités négatives, nulles, fractionnaires ou illisibles, articles inconnus : laissés")
U.verifier(m.bouton_dore == EtatAtelier.MERCERIE_MAX_UNITES and m.dentelle_blanche == EtatAtelier.MERCERIE_MAX_CM, "au-delà du plafond : ramené à 999 unités ou 9 999 cm")
partie.mercerie = "abîmée"
U.verifier(next(Sauvegarde.versEtat(partie).mercerie) == nil, "mercerie illisible : vide")
partie.mercerie = nil
U.verifier(next(Sauvegarde.versEtat(partie).mercerie) == nil, "une partie v4 sans mercerie : vide (le kit vient de la migration, pas de la lecture)")

---------------------------------------------------------------------------
-- Migration v3 → v4 : le kit de mercerie offert ; une robe en cours garde ses décorations
---------------------------------------------------------------------------
local v3 = { version = 3, argent = 300, stock = {}, debloques = {}, recettes = {}, prestige = 0, livraisons = 0, visites = 0, clientes = {} }
local v4 = Sauvegarde.migrer(v3)
local kit = true
for id, q in pairs(EtatAtelier.KIT_MERCERIE) do
	kit = kit and v4.mercerie[id] == q
end
U.verifier(v4.version == 4 and kit and v4.argent == 300 and v4.mercerie ~= EtatAtelier.KIT_MERCERIE, "v3 → v4 : une copie du kit de mercerie, rien d'autre ne change")
U.verifier(Sauvegarde.migrer({ argent = 480 }).mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "v1 → v4 : les migrations s'enchaînent jusqu'au kit")
local enCours = EtatAtelier.nouveau(1000)
U.commander(enCours, Random.new(8))
aDecorer(enCours)
enCours.mercerie = { perle = 1 }
assert(enCours:decorer({ perle() }).ok)
local p3 = Sauvegarde.depuisEtat(enCours)
p3.version, p3.mercerie = 3, nil -- (une partie d'avant la mercerie)
local reprise = Sauvegarde.versEtat(M.transmettre(Sauvegarde.migrer(p3)))
U.verifier(reprise.etape == "photo" and #reprise.accessoires == 1 and reprise.accessoires[1].id == "perle" and reprise.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "une robe en cours garde ses décorations, et reçoit le kit entier")

---------------------------------------------------------------------------
-- Serveur : l'achat, limité comme les autres actions ; les arguments farfelus refusés proprement
---------------------------------------------------------------------------
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Merciere")
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	local ok, erreur = pcall(M.transmettre, r)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return r
end
local r = appeler("etat")
U.verifier(r.ok and r.etat.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "le client reçoit la mercerie (le kit)")
r = appeler("acheterMercerie", "perle", 3)
U.verifier(r.ok and r.prix == 3 and r.quantite == 3 and r.etat.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle + 3 and r.etat.argent == EtatAtelier.ARGENT_DEPART - 3, "achat à la mercerie, sur le serveur : l'état suit")
local perles = serveur:atelier(joueur).etat.mercerie.perle
for k, cas in ipairs({ { "perle", "trois" }, { "perle", 0 / 0 }, { "perle", math.huge }, { M.services.Workspace, 1 }, { { "perle" }, 1 }, { "croix_argent", 1 } }) do
	r = appeler("acheterMercerie", cas[1], cas[2])
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and serveur:atelier(joueur).etat.mercerie.perle == perles and serveur:atelier(joueur).etat.argent == EtatAtelier.ARGENT_DEPART - 3, "achat farfelu refusé proprement (" .. k .. ") : " .. tostring(r.erreur))
end
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	if serveur:traiter(joueur, "acheterMercerie", "bouton_nacre", 1).ok then
		acceptes += 1
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale d'achats : limitée comme les autres actions (" .. acceptes .. " sur 8)")

---------------------------------------------------------------------------
-- Serveur : des décorations au-delà du stock sont refusées (le client ne peut pas tricher)
---------------------------------------------------------------------------
M.avancer(2)
local a = serveur:atelier(joueur).etat
U.commander(a, Random.new(5))
aDecorer(a)
a.argent, a.mercerie = 1000, { perle = 1 }
r = appeler("decorer", { perle(0.4), perle(0.6) })
U.verifier(not r.ok and r.erreur == "Mercerie insuffisante : il te manque Perle ×1." and a.etape == "decorations" and a.mercerie.perle == 1 and a.argent == 1000, "décorations au-delà du stock : refusées par le serveur, rien ne change (" .. tostring(r.erreur) .. ")")
r = appeler("decorer", { perle() })
U.verifier(r.ok and a.mercerie.perle == nil and r.etat.mercerie.perle == nil and a.argent == 1000, "une perle posée : prise au stock du serveur, pas d'argent")
