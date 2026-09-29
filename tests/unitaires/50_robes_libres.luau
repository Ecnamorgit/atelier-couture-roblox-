local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Progression = U.module("Progression")
local Clientes = U.module("Clientes")
local Sauvegarde = U.module("Sauvegarde")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- Du carnet à la photo, dans un seul tissu : robe coupée, épinglée, cousue parfaitement, sans décoration
local function jusquALaPhoto(etat, tissu)
	local tissus = {}
	for id in pairs(PLACES) do
		tissus[id] = tissu
	end
	assert(etat:validerCroquis(CROQUIS, tissus).ok)
	assert(etat:acheter(tissu, 12).ok)
	assert(etat:commencerDecoupe().ok)
	for _, id in ipairs(etat:piecesDuCroquis()) do
		assert(etat:couper(id, PLACES[id]).ok)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		assert(etat:epingler(id).ok)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		local _, longueur = Patron.trajetCouture(id)
		assert(etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur).ok)
	end
	assert(etat:decorer({}).ok)
end

-- Ouverte après deux commandes livrées ; une taille standard, pas de cliente, pas d'exigence, droit au carnet
local e = EtatAtelier.nouveau(200)
e.livraisons = 1
local r = e:nouvelleRobeLibre("M")
U.verifier(not r.ok and r.erreur == "Les robes libres s'ouvrent après deux commandes livrées." and e.etape == "accueil", "robe libre fermée avant deux commandes livrées")
e.livraisons = 2
for _, mauvaise in ipairs({ "XL", 3, nil }) do
	U.verifier(not e:nouvelleRobeLibre(mauvaise).ok and e.etape == "accueil", "taille inconnue refusée : " .. tostring(mauvaise))
end
local argentAvant = e.argent
r = e:nouvelleRobeLibre("M")
U.verifier(r.ok and e.etape == "carnet" and e.commande.libre and e.commande.cliente == nil and #e.commande.exigences == 0, "robe libre : au carnet, sans cliente ni exigence")
U.verifier(e.commande.mesures.poitrine == Catalogue.TAILLES.M.poitrine and e.commande.acompte == nil and e.argent == argentAvant, "les mesures de sa taille ; pas d'acompte")

-- Une robe libre ne se livre pas ; elle se vend : (matières + décorations + main d'œuvre) × (0,5 + qualité)
jusquALaPhoto(e, "coton_blanc")
U.verifier(e.commande.matieres ~= nil and e.commande.matieres > 0, "le prix du tissu entamé est noté à la découpe (" .. tostring(e.commande.matieres) .. " po)")
r = e:livrer()
U.verifier(not r.ok and r.erreur == "Une robe libre se vend ou s'offre." and e.etape == "photo", "une robe libre ne se livre pas")
local qualite = e:bilan().qualite
local attendu = math.round((e.commande.matieres + 6 * 4) * (0.5 + qualite))
U.verifier(e:prixVente() == attendu, "prix de vente : (matières + main d'œuvre) × (0,5 + qualité) = " .. attendu)
e.prestige = 530
U.verifier(e:prixVente() == math.round((e.commande.matieres + 24) * (0.5 + qualite) * 1.42), "au prestige 8 : +42 %")
e.prestige = 0
local avant = e.argent
r = e:vendre()
U.verifier(r.ok and r.prix == attendu and e.argent == avant + attendu and e.ventes == 1 and e.etape == "accueil", "vendue : le prix dans la caisse")
U.verifier(r.prestige.gain == Progression.prestigeVente(attendu) and e.prestige == r.prestige.gain and #e.robes == 1, "prestige d'un quinzième du prix ; la robe en vitrine")

-- En toile de jute : gratuite, et pourtant vendue (la main d'œuvre)
e:nouvelleRobeLibre("S")
avant = e.argent
jusquALaPhoto(e, "toile_jute")
U.verifier(e.argent == avant and e.commande.matieres == 0, "toile de jute : rien à payer")
U.verifier(e:prixVente() == math.round(24 * (0.5 + e:bilan().qualite)) and e:prixVente() > 0, "robe de jute : vendue pour sa main d'œuvre")

-- Offrir : seulement à une cliente déjà venue ; l'amitié monte selon son style préféré, le prestige de 2
e.clientes.helene = { amitie = 0, vues = 0, derniere = 0 } -- une fiche, mais jamais venue
U.verifier(not e:offrir("helene").ok and not e:offrir("ines").ok and not e:offrir("personne").ok and not e:offrir(nil).ok and e.etape == "photo", "offrir à une cliente jamais venue ou inconnue : refusé")
e.clientes.colette = { amitie = 6, vues = 1, derniere = 1 }
local bilan = e:bilan()
local score = math.max(bilan.styles.romantique or 0, bilan.styles.mignon or 0)
local prestigeAvant = e.prestige
avant = e.argent
r = e:offrir("colette")
U.verifier(r.ok and r.amitie.gain == Progression.gainCadeau(score) and e.clientes.colette.amitie == 6 + r.amitie.gain, "offerte à Colette : l'amitié selon son style préféré (" .. score .. " points)")
U.verifier(r.prestige.gain == 2 and e.prestige == prestigeAvant + 2 and e.argent == avant and e.etape == "accueil" and #e.robes == 2, "cadeau : +2 de prestige, pas d'argent, la robe en vitrine")
U.verifier(r.amitie.niveau == 2 and r.amitie.niveauAvant == 1 and #r.nouveaux == 1 and r.nouveaux[1].id == "jupe_ample", "le cadeau fait passer Colette au niveau 2 : la jupe ample s'ouvre")

-- Vendre ou offrir hors d'une robe libre : refusé
local c = EtatAtelier.nouveau(200)
U.commander(c, Random.new(1))
jusquALaPhoto(c, "coton_blanc")
U.verifier(not c:vendre().ok and not c:offrir("colette").ok and c.etape == "photo", "une commande ne se vend ni ne s'offre")

-- Sauvegarde : la robe libre en cours et les ventes suivent ; une robe libre abîmée est abandonnée
local l = EtatAtelier.nouveau(200)
l.livraisons = 2
l:nouvelleRobeLibre("L")
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(l)))
U.verifier(relue.etape == "carnet" and relue.commande.libre and relue.commande.taille == "L", "robe libre en cours : relue")
l.ventes = 3
U.verifier(Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(l))).ventes == 3, "robes vendues : sauvegardées")
for _, cas in ipairs({ { "exigences", { { type = "qualite", valeur = 0.5 } } }, { "cliente", "colette" }, { "libre", "oui" }, { "matieres", -5 } }) do
	local p = M.transmettre(Sauvegarde.depuisEtat(l))
	p.enCours.commande[cas[1]] = cas[2]
	U.verifier(Sauvegarde.versEtat(p).etape == "accueil", "robe libre abîmée (" .. cas[1] .. ") : abandonnée")
end
U.verifier(Clientes.get("colette") ~= nil, "(la cliente existe)")
