local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")
local Clientes = U.module("Clientes")

local serveur = Commande.nouvelle()
U.verifier(Commande.courante == serveur, "le serveur en cours est connu (scénario, débogage)")
local joueur = M.nouveauJoueur("Couturiere")
-- Un appel du client, espacé comme un joueur (sous la limite de 5 par seconde) ; chaque réponse doit
-- pouvoir passer par le réseau
local function appeler(qui, action, ...)
	M.avancer(0.25)
	local reponse = serveur:traiter(qui, action, ...)
	local ok, erreur = pcall(M.transmettre, reponse)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return reponse
end
local function etatDe(qui)
	return serveur:atelier(qui).etat
end

---------------------------------------------------------------------------
-- Arrivée : l'état de départ, envoyé au client
---------------------------------------------------------------------------
local r = appeler(joueur, "etat")
U.verifier(r.ok and r.etat.etape == "accueil" and r.etat.argent == EtatAtelier.ARGENT_DEPART, "le client reçoit l'état de départ")

---------------------------------------------------------------------------
-- Actions inconnues, dans le désordre, ou aux arguments farfelus : refusées, sans rien changer
---------------------------------------------------------------------------
for _, action in ipairs({ "voler", "nouveau", "charger", "exporter", "__index", 42, true }) do
	r = appeler(joueur, action)
	U.verifier(not r.ok and r.erreur == "Action inconnue." and r.etat == nil, "action inconnue refusée : " .. tostring(action))
end
r = appeler(joueur)
U.verifier(not r.ok and r.erreur == "Action inconnue.", "appel sans action refusé")
r = appeler(joueur, "livrer")
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat ~= nil and r.etat.etape == "accueil", "livrer sans commande : refusé (avec l'état du serveur)")
U.verifier(etatDe(joueur).argent == EtatAtelier.ARGENT_DEPART and etatDe(joueur).etape == "accueil", "rien n'a changé")

---------------------------------------------------------------------------
-- Une commande menée par le serveur ; chaque réponse emporte l'état
---------------------------------------------------------------------------
r = appeler(joueur, "nouvelleCommande", { NextInteger = "tricherie" })
U.verifier(r.ok and r.etat.etape == "mesures" and r.etat.commande ~= nil and r.etat.commande.cliente == "colette", "nouvelle commande tirée par le serveur (l'argument du client est ignoré) : Colette, à mesurer")
for _, prises in ipairs({ "tout", { poitrine = 99, taille = 7.1, hanches = 9.5 }, { poitrine = 8.9, taille = 7.1, hanches = 0 / 0 } }) do
	r = appeler(joueur, "mesurer", prises)
	U.verifier(not r.ok and r.erreur == "Mesure invalide : tourne chaque molette jusqu'à épouser sa silhouette." and etatDe(joueur).etape == "mesures", "mesures farfelues refusées par le serveur")
end
U.verifier(appeler(joueur, "mesurer", Clientes.get("colette").mesures).ok and etatDe(joueur).etape == "carnet", "mesures prises : au carnet")
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
-- Déblocages (sous-projet 2) : le serveur refuse une variante ou un tissu encore fermés
local fermee = table.clone(CROQUIS)
fermee.jupe = "jupe_evasee"
local tissusFermee = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_evasee_devant = "coton_blanc", jupe_evasee_dos = "coton_blanc" }
r = appeler(joueur, "validerCroquis", fermee, tissusFermee)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Jupe longue évasée (Amitié de Victoire : 2)." and etatDe(joueur).etape == "carnet", "variante fermée refusée par le serveur")
local enSoie = table.clone(tissus)
enSoie.jupe_droite_dos = "soie_rouge"
r = appeler(joueur, "validerCroquis", CROQUIS, enSoie)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Soie rouge (Prestige 5)." and etatDe(joueur).etape == "carnet", "tissu fermé refusé par le serveur")
-- Un croquis avec un champ en trop : seules les quatre familles sont gardées sur le serveur (et renvoyées)
local bourre = table.clone(CROQUIS)
bourre.bourrage = string.rep("x", 1000)
r = appeler(joueur, "validerCroquis", bourre, tissus)
U.verifier(r.ok and etatDe(joueur).croquis.bourrage == nil and r.etat.croquis.bourrage == nil and etatDe(joueur).croquis.jupe == CROQUIS.jupe, "croquis : les champs en trop ne sont pas gardés")
U.verifier(appeler(joueur, "validerCroquis", CROQUIS, tissus).ok, "croquis validé")
-- Achats refusés : longueur farfelue, argent insuffisant
for _, dm in ipairs({ 0, -5, 2.5, 1e9, "10" }) do
	r = appeler(joueur, "acheter", "coton_blanc", dm)
	U.verifier(not r.ok and r.erreur == "Longueur invalide.", "achat refusé : " .. tostring(dm) .. " dm")
end
r = appeler(joueur, "acheter", "soie_rouge", 5)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Soie rouge (Prestige 5)." and etatDe(joueur).stock.soie_rouge == nil, "achat d'un tissu fermé refusé")
etatDe(joueur).argent = 5
r = appeler(joueur, "acheter", "lin_noir", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent." and etatDe(joueur).argent == 5, "achat trop cher refusé")
etatDe(joueur).argent = 1000
r = appeler(joueur, "acheter", "coton_blanc", 12)
U.verifier(r.ok and r.etat.stock.coton_blanc == 12 and r.etat.argent == 1000 - r.prix, "achat : stock et argent dans l'état renvoyé")
U.verifier(appeler(joueur, "commencerDecoupe").ok, "découpe commencée")
-- Découpe : hors du rouleau, position farfelue, pièce hors du croquis, pièce coupée deux fois
r = appeler(joueur, "couper", ORDRE[1], { x = -3, y = 2, angle = 0 })
U.verifier(not r.ok and r.erreur == "La pièce dépasse du tissu.", "découpe hors du rouleau refusée")
r = appeler(joueur, "couper", ORDRE[1], { x = "2", y = 2, angle = 0 })
U.verifier(not r.ok and r.erreur == "Position invalide.", "position farfelue refusée")
r = appeler(joueur, "couper", "manche_longue", PLACES[ORDRE[1]])
U.verifier(not r.ok and r.erreur == "Cette pièce n'est pas dans le croquis.", "pièce hors du croquis refusée")
U.verifier(appeler(joueur, "couper", ORDRE[1], PLACES[ORDRE[1]]).ok, "première pièce coupée")
r = appeler(joueur, "couper", ORDRE[1], PLACES[ORDRE[3]])
U.verifier(not r.ok and r.erreur == "Cette pièce est déjà coupée.", "pièce coupée deux fois refusée")
r = appeler(joueur, "couper", ORDRE[2], PLACES[ORDRE[1]])
U.verifier(not r.ok and r.erreur == "La pièce chevauche une autre pièce.", "découpe superposée refusée")
for k = 2, 4 do
	r = appeler(joueur, "couper", ORDRE[k], PLACES[ORDRE[k]])
end
U.verifier(r.ok and r.etat.etape == "epinglage", "toutes les pièces coupées : épinglage")
for _, id in ipairs(ORDRE) do
	r = appeler(joueur, "epingler", id)
end
U.verifier(r.ok and r.etat.etape == "couture", "pièces épinglées : couture")
-- Couture : trop rapide, mauvais nombre de mesures ; pas de limite d'appels (sa propre vraisemblance)
local _, longueur = Patron.trajetCouture(ORDRE[1])
local releve = table.create(math.round(longueur / 0.1), 0.02)
r = appeler(joueur, "rendreCouture", ORDRE[1], releve, 0.01)
U.verifier(not r.ok and r.erreur == "Couture trop rapide.", "couture trop rapide refusée")
r = appeler(joueur, "rendreCouture", ORDRE[1], table.create(#releve + 5, 0), longueur)
U.verifier(not r.ok and r.erreur == "Relevé de couture incomplet.", "mauvais nombre de mesures refusé")
local limitees = 0
for _ = 1, 10 do
	r = serveur:traiter(joueur, "rendreCouture", ORDRE[1], releve, 0.01) -- dix appels au même instant
	if r.erreur == "Doucement !" then
		limitees += 1
	end
end
U.verifier(limitees == 0, "« rendreCouture » n'est pas soumise à la limite d'appels")
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	r = appeler(joueur, "rendreCouture", id, table.create(math.round(l / 0.1), 0.02), l)
end
U.verifier(r.ok and r.etat.etape == "decorations", "robe cousue : décorations")
-- Arguments farfelus (une Instance, une table mixte, un texte, NaN…) : refusés proprement, jamais d'erreur.
-- Le message n'est vérifié que lorsqu'il ne dépend pas de la conversion faite par le réseau de Roblox
-- (le faux Roblox passe une Instance ou une table mixte telle quelle ; Roblox les convertit).
local FARFELUS = {
	{ M.services.Workspace },
	{ { 1, 2, x = 3 } },
	{ "tout", "Décorations invalides." },
	{ { { id = "bouton_nacre", piece = 1, copie = "unique", u = 0 / 0, v = 0.5, echelle = 1, angle = 0 } }, "Accessoire mal placé." },
	{ { { id = "bouton_nacre", piece = 99, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } }, "Accessoire sur une pièce inexistante." },
}
for k, cas in ipairs(FARFELUS) do
	M.avancer(0.25)
	r = serveur:traiter(joueur, "decorer", cas[1])
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and (cas[2] == nil or r.erreur == cas[2]), "décorations farfelues refusées proprement (" .. k .. ") : " .. tostring(r.erreur))
end
-- 301 décorations : refusées, rien n'est facturé
local trop = {}
for k = 1, 301 do
	trop[k] = { id = "bouton_nacre", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 }
end
local argentAvant = etatDe(joueur).argent
r = appeler(joueur, "decorer", trop)
U.verifier(not r.ok and etatDe(joueur).argent == argentAvant and etatDe(joueur).etape == "decorations", "301 décorations refusées, rien facturé")
r = appeler(joueur, "decorer", { { id = "croix_argent", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } })
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and etatDe(joueur).etape == "decorations", "accessoire fermé refusé par le serveur")
U.verifier(appeler(joueur, "decorer", {}).ok, "robe présentée")
etatDe(joueur).commande.exigences = { { type = "qualite", valeur = 0.1 } }
r = appeler(joueur, "livrer")
U.verifier(r.ok and r.reussie and r.paie > 0 and r.etat.etape == "accueil" and #r.etat.robes == 1, "robe livrée et payée")

-- L'état envoyé ne garde que la robe en vitrine (le serveur garde les dix dernières)
table.insert(etatDe(joueur).robes, 1, table.clone(etatDe(joueur).robes[1]))
r = appeler(joueur, "etat")
U.verifier(#etatDe(joueur).robes == 2 and #r.etat.robes == 1, "seule la robe en vitrine part chez le client")

---------------------------------------------------------------------------
-- Rafale : au plus 5 appels par seconde et par joueur
---------------------------------------------------------------------------
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	r = serveur:traiter(joueur, "etat")
	if r.ok then
		acceptes += 1
	else
		U.verifier(r.erreur == "Doucement !", "rafale : message « Doucement ! »")
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale : " .. acceptes .. " appels acceptés sur 8 au même instant")
local autre = M.nouveauJoueur("Voisine")
U.verifier(serveur:traiter(autre, "etat").ok, "la rafale d'un joueur ne gêne pas les autres")
M.avancer(1.01)
U.verifier(serveur:traiter(joueur, "etat").ok, "une seconde plus tard, c'est de nouveau permis")

---------------------------------------------------------------------------
-- Erreur imprévue dans une action : refus propre, avertissement, le serveur continue
---------------------------------------------------------------------------
local vraie = EtatAtelier.nouvelleCommande
EtatAtelier.nouvelleCommande = function()
	error("panne simulée")
end
M.avertissements = {}
r = appeler(joueur, "nouvelleCommande")
EtatAtelier.nouvelleCommande = vraie
U.verifier(not r.ok and r.erreur == "Action impossible." and #M.avertissements == 1, "erreur imprévue : refus propre et un avertissement")
U.verifier(appeler(joueur, "nouvelleCommande").ok, "le serveur continue après l'erreur")

---------------------------------------------------------------------------
-- Départ du joueur : son atelier est libéré
---------------------------------------------------------------------------
serveur:retirer(joueur)
U.verifier(serveur.ateliers[joueur] == nil, "atelier libéré au départ")
r = appeler(joueur, "etat")
U.verifier(r.ok and r.etat.etape == "accueil" and r.etat.argent == EtatAtelier.ARGENT_DEPART, "un joueur qui revient repart de zéro (la sauvegarde arrive au plan 4b)")
