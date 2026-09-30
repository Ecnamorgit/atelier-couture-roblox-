local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Progression = U.module("Progression")
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
-- Une commande de la clochette, mesurée et livrée ; renvoie la réponse de la livraison
local function commandeLivree(etat, rng)
	assert(etat:nouvelleCommande(rng).ok)
	assert(etat:mesurer(Clientes.get(etat.commande.cliente).mesures).ok)
	robePrete(etat)
	return etat:livrer(rng)
end

-- Le courrier s'ouvre après cinq commandes livrées ; une lettre toutes les deux robes (livrées ou vendues)
local e = EtatAtelier.nouveau(500)
local rng = Random.new(8)
e.livraisons = 3
local r = commandeLivree(e, rng)
U.verifier(r.reussie and e.livraisons == 4 and r.lettre == nil and #e.lettres == 0, "quatre commandes livrées : pas encore de courrier")
r = commandeLivree(e, rng)
U.verifier(e.livraisons == 5 and r.lettre == nil and #e.lettres == 0, "cinquième : pas de lettre (une toutes les deux robes)")
r = commandeLivree(e, rng)
local lettre = e.lettres[1]
U.verifier(e.livraisons == 6 and r.lettre ~= nil and #e.lettres == 1 and lettre == r.lettre, "sixième : une lettre arrive")
U.verifier(e.clientes[lettre.cliente] ~= nil and e.clientes[lettre.cliente].vues > 0 and lettre.commande.cliente == lettre.cliente and #lettre.commande.exigences >= 1, "d'une cliente déjà venue, avec la commande qu'elle passera")
U.verifier(EtatAtelier.nouveau(500):livrer() ~= nil, "(livrer sans commande : refusé, sans erreur)")
local sansTirage = EtatAtelier.nouveau(500)
sansTirage.livraisons = 5
U.verifier(commandeLivree(sansTirage, Random.new(1)).lettre ~= nil, "(le tirage vient de l'appelant)")
sansTirage.livraisons = 7
sansTirage:nouvelleCommande(Random.new(2))
sansTirage:mesurer(Clientes.get(sansTirage.commande.cliente).mesures)
robePrete(sansTirage)
U.verifier(sansTirage:livrer().lettre == nil, "sans tirage : pas de lettre")

-- Trois lettres au plus ; elles n'expirent pas
e.lettres = { lettre, lettre, lettre }
e.livraisons = 7
r = commandeLivree(e, rng)
U.verifier(r.lettre == nil and #e.lettres == 3, "trois lettres au plus")
e.lettres = { lettre }

-- Inviter : la cliente de la lettre vient avec sa commande (mesures, acompte) ; la lettre est retirée
for _, mauvais in ipairs({ 0, 2, 1.5, "1", 0 / 0 }) do
	r = e:inviter(mauvais)
	U.verifier(not r.ok and r.erreur == "Cette lettre n'existe pas." and #e.lettres == 1 and e.etape == "accueil", "lettre inexistante : refusé (" .. tostring(mauvais) .. ")")
end
local fiche = e.clientes[lettre.cliente]
local vues, argentAvant = fiche.vues, e.argent
r = e:inviter(1)
U.verifier(r.ok and e.etape == "mesures" and e.commande == lettre.commande and e.commande.parLettre == true and #e.lettres == 0, "invitée : elle vient avec la commande de sa lettre")
U.verifier(fiche.vues == vues + 1 and r.acompte > 0 and e.argent == argentAvant + r.acompte, "sa visite est notée, elle verse l'acompte")
U.verifier(not e:inviter(1).ok, "une commande à la fois")
-- Livrée et acceptée : un point d'amitié de plus
e:mesurer(Clientes.get(lettre.cliente).mesures)
robePrete(e)
local amitieAvant = fiche.amitie
r = e:livrer(rng)
U.verifier(r.reussie and r.amitie.gain == Progression.gainAmitie(true, r.bilan.qualite) + 1 and fiche.amitie == amitieAvant + r.amitie.gain, "commande venue par lettre : +1 d'amitié de plus")

-- Une robe libre vendue compte aussi pour le courrier
local v = EtatAtelier.nouveau(500)
v.livraisons, v.ventes = 5, 0
v.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
v:nouvelleRobeLibre("M")
robePrete(v)
v.commande.exigences = {}
r = v:vendre(Random.new(3))
U.verifier(r.ok and v.ventes == 1 and r.lettre ~= nil and r.lettre.cliente == "colette", "robe vendue : la sixième robe apporte une lettre")

-- Sauvegarde : les lettres suivent ; illisibles, elles sont laissées ; trois au plus
local s = EtatAtelier.nouveau(100)
s.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
s.lettres = { { cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } } } }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(s)))
U.verifier(#relue.lettres == 1 and relue.lettres[1].cliente == "colette" and relue.lettres[1].commande.exigences[1].style == "romantique", "les lettres sont sauvegardées")
local p = M.transmettre(Sauvegarde.depuisEtat(s))
local bonne = p.lettres[1]
for k, abimee in ipairs({
	{ cliente = "inconnue", commande = { cliente = "inconnue", taille = "M", exigences = { { type = "qualite", valeur = 0.5 } } } },
	{ cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = {} } },
	{ cliente = "colette", commande = { cliente = "margot", taille = "S", exigences = { { type = "qualite", valeur = 0.5 } } } },
	"abîmée",
}) do
	p.lettres = { abimee }
	U.verifier(#Sauvegarde.versEtat(p).lettres == 0, "lettre illisible laissée (" .. k .. ")")
end
p.lettres = { bonne, bonne, bonne, bonne }
relue = Sauvegarde.versEtat(p)
U.verifier(#relue.lettres == 3 and relue.lettres[1].cliente == "colette", "trois lettres au plus")
