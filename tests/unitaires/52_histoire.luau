local Histoire = U.module("Histoire")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Commandes = U.module("Commandes")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

-- Le tableau : huit événements, deux à quatre robes chacun, des clientes connues, des répliques, un souvenir
U.verifier(#Histoire.EVENEMENTS == 8, "huit événements")
local ids, faites = {}, {}
local precedent = 0
for rang, ev in ipairs(Histoire.EVENEMENTS) do
	U.verifier(Histoire.get(ev.id) == ev and ev.rang == rang and ev.nom ~= "" and ev.epilogue ~= "", ev.id .. " : nom et épilogue")
	U.verifier(ev.prestige >= precedent and ev.prestige <= 8, ev.id .. " : prestige croissant")
	precedent = ev.prestige
	U.verifier(#ev.commandes >= 2 and #ev.commandes <= 4, ev.id .. " : deux à quatre robes")
	local souvenir = Catalogue.accessoire(ev.souvenir)
	U.verifier(souvenir ~= nil and souvenir.genre == "objet" and Deblocages.CONDITIONS.accessoires[ev.souvenir].evenement == ev.id, ev.id .. " : son souvenir, ouvert par lui")
	-- Chaque robe est réalisable avec ce qui est ouvert au prestige de l'événement, amitiés à zéro, les
	-- événements d'avant ayant eu lieu (leurs souvenirs ouverts)
	local progres = { prestige = Progression.SEUILS_PRESTIGE[ev.prestige], clientes = {}, histoire = { faites = table.clone(faites) } }
	local ouverts = Deblocages.ouverts(progres)
	for _, c in ipairs(ev.commandes) do
		U.verifier(not ids[c.id], c.id .. " : identifiant unique")
		ids[c.id] = true
		local cliente = Clientes.get(c.cliente)
		U.verifier(cliente ~= nil and cliente.prestige <= ev.prestige, c.id .. " : une cliente arrivée à ce prestige")
		U.verifier(#c.exigences >= 1 and #c.exigences <= 3 and Commandes.realisable(c.exigences, ouverts), c.id .. " : tenue réalisable avec ce qui est ouvert")
		U.verifier(c.repliques.demande ~= "" and c.repliques.detail ~= "" and c.repliques.merci ~= "", c.id .. " : ses répliques")
		local commande, evenement = Histoire.commande(c.id)
		U.verifier(commande == c and evenement == ev, c.id .. " : retrouvée par son identifiant")
	end
	for _, c in ipairs(ev.commandes) do
		faites[c.id] = true
	end
end
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")

-- La progression : le premier événement après trois livraisons ; dans l'ordre ; le suivant à son prestige
local etat = { prestige = 0, livraisons = 0, histoire = { faites = {} } }
local ev, ouvert = Histoire.enCours(etat)
U.verifier(ev.id == "lanternes" and not ouvert and Histoire.prochaine(etat) == nil, "au départ : le bal des lanternes, pas encore ouvert")
etat.livraisons = 3
ev, ouvert = Histoire.enCours(etat)
local suivante = Histoire.prochaine(etat)
U.verifier(ouvert and suivante.id == "lanternes_colette", "trois livraisons : il s'annonce, Colette d'abord")
etat.histoire.faites.lanternes_colette = true
U.verifier(Histoire.prochaine(etat).id == "lanternes_margot" and select(1, Histoire.avancee(etat, "lanternes")) == 1, "puis Margot ; une robe sur deux")
U.verifier(not Deblocages.ouvert(etat, "accessoires", "lanterne_papier") and Deblocages.raison("accessoires", "lanterne_papier") == "Souvenir : Le bal des lanternes", "souvenir fermé tant que l'événement n'a pas eu lieu")
etat.histoire.faites.lanternes_margot = true
U.verifier(Histoire.aEuLieu(etat, "lanternes") and Histoire.eus(etat) == 1 and Deblocages.ouvert(etat, "accessoires", "lanterne_papier"), "les deux robes livrées : le bal a lieu, la lanterne s'ouvre")
ev, ouvert = Histoire.enCours(etat)
U.verifier(ev.id == "kermesse" and not ouvert, "la kermesse attend le prestige 2")
etat.prestige = 20
ev, ouvert = Histoire.enCours(etat)
U.verifier(ouvert and Histoire.prochaine(etat).id == "kermesse_margot", "prestige 2 : la kermesse s'annonce")
local tout = { prestige = 530, livraisons = 99, histoire = { faites = faites } }
U.verifier(Histoire.enCours(tout) == nil and Histoire.prochaine(tout) == nil and Histoire.eus(tout) == 8, "tout a eu lieu : plus d'événement")

-- « Tout ouvert » (équilibrage) ne compte pas les souvenirs, qui viennent de l'histoire
local progresTout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	progresTout.clientes[c.id] = { amitie = 25 }
end
U.verifier(Deblocages.toutOuvert(progresTout) and not Deblocages.ouvert(progresTout, "accessoires", "flocon_argent"), "tout ouvert par le prestige et l'amitié, sans les souvenirs")
