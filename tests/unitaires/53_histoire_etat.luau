local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Histoire = U.module("Histoire")
local Deblocages = U.module("Deblocages")
local Sauvegarde = U.module("Sauvegarde")

-- Une robe simple, coupée, épinglée et cousue, présentée ; la cliente ne demande qu'un peu de qualité
local function robePrete(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
	assert(etat:decorer({}).ok)
	etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end
-- La commande de l'événement, mesurée et livrée ; renvoie la réponse de la livraison
local function robeHistoireLivree(etat)
	assert(etat:commandeHistoire().ok)
	assert(etat:mesurer(Clientes.get(etat.commande.cliente).mesures).ok)
	robePrete(etat)
	return etat:livrer()
end

-- Rien avant trois commandes livrées
local e = EtatAtelier.nouveau(500)
local r = e:commandeHistoire()
U.verifier(not r.ok and r.erreur == "Aucun événement ne s'annonce pour l'instant." and e.etape == "accueil", "aucune commande d'histoire avant trois livraisons")

-- Le bal des lanternes : Colette d'abord, avec la tenue du tableau ; même accueil que la clochette
e.livraisons = 3
local argent = e.argent
r = e:commandeHistoire()
local def = Histoire.commande("lanternes_colette")
U.verifier(r.ok and e.etape == "mesures" and e.commande.cliente == "colette" and e.commande.histoire == "lanternes_colette", "la commande de l'événement : Colette, à mesurer")
U.verifier(#e.commande.exigences == #def.exigences and e.commande.exigences ~= def.exigences and e.commande.exigences[1].style == def.exigences[1].style, "sa tenue : celle du tableau (une copie)")
U.verifier(r.acompte > 0 and e.argent == argent + r.acompte and e.clientes.colette.vues == 1, "elle verse l'acompte ; sa visite est notée")
U.verifier(not e:commandeHistoire().ok, "une commande à la fois")
e:mesurer(Clientes.get("colette").mesures)
robePrete(e)
r = e:livrer()
U.verifier(r.reussie and e.histoire.faites.lanternes_colette and r.evenement == nil, "livrée : faite ; le bal attend encore une robe")

-- Margot : la dernière robe fait avoir lieu le bal (épilogue, souvenir, prestige en plus)
local prestigeAvant = e.prestige
r = robeHistoireLivree(e)
U.verifier(r.reussie and r.evenement ~= nil and r.evenement.id == "lanternes" and r.evenement.souvenir == "lanterne_papier" and r.evenement.epilogue == Histoire.get("lanternes").epilogue, "la dernière robe livrée : le bal des lanternes a lieu")
U.verifier(r.prestige.gain == math.round(r.paie / 10) + Histoire.PRESTIGE_EVENEMENT and e.prestige == prestigeAvant + r.prestige.gain, "prestige de la livraison, et 15 de plus pour l'événement")
local ouvre = false
for _, n in ipairs(r.nouveaux) do
	ouvre = ouvre or n.id == "lanterne_papier"
end
U.verifier(ouvre and Deblocages.ouvert(e, "accessoires", "lanterne_papier"), "le souvenir s'ouvre, et c'est annoncé")
e.prestige = 19
U.verifier(not e:commandeHistoire().ok, "la kermesse attend le prestige 2")

-- Abandonnée, une robe d'histoire reste à faire
e.prestige = 20
assert(e:commandeHistoire().ok)
local id = e.commande.histoire
e:mesurer(Clientes.get(e.commande.cliente).mesures)
e.etape = "refus"
assert(e:abandonner().ok)
U.verifier(not e.histoire.faites[id], "abandonnée : pas faite")
U.verifier(e:commandeHistoire().ok and e.commande.histoire == id, "on la reprend quand on veut")

-- Sauvegarde : l'histoire suit la partie ; ce qui est inconnu est laissé ; la commande d'histoire en cours aussi
local p = M.transmettre(Sauvegarde.depuisEtat(e))
local relue = Sauvegarde.versEtat(p)
U.verifier(relue.histoire.faites.lanternes_colette and relue.histoire.faites.lanternes_margot and relue.commande.histoire == id, "l'histoire et la commande d'histoire en cours sont sauvegardées")
p.histoire.faites.inconnue, p.histoire.faites.kermesse_salome = true, "oui"
relue = Sauvegarde.versEtat(p)
U.verifier(relue.histoire.faites.inconnue == nil and relue.histoire.faites.kermesse_salome == nil and relue.histoire.faites.lanternes_colette, "commandes inconnues ou illisibles : laissées")
p.enCours.commande.histoire = "inconnue"
U.verifier(Sauvegarde.versEtat(p).etape == "accueil", "commande d'une histoire inconnue : abandonnée")
local vieille = M.transmettre(Sauvegarde.depuisEtat(EtatAtelier.nouveau(100)))
vieille.histoire = nil
U.verifier(next(Sauvegarde.versEtat(vieille).histoire.faites) == nil, "partie sans histoire : rien de fait")
