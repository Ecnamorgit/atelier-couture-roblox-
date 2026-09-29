local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Notation = U.module("Notation")
local Commandes = U.module("Commandes")

-- Impossible : au moins 100 partout à la fois
U.verifier(not Commandes.realisable({ { type = "min", style = "gothique", valeur = 100 }, { type = "min", style = "mignon", valeur = 100 } }),
	"des exigences contradictoires sont détectées")
U.verifier(not Commandes.realisable({ { type = "qualite", valeur = 0.95 } }), "une qualité au-dessus de 0,9 n'est jamais demandée")

-- 200 commandes générées : chacune est réalisable, et le témoin est vérifié par une vraie recette
local rng = Random.new(42)
local genres = {}
for n = 1, 200 do
	local commande = Commandes.generer(rng)
	U.verifier(Catalogue.TAILLES[commande.taille] ~= nil, "taille connue")
	U.verifier(#commande.exigences >= 1 and #commande.exigences <= 3, "1 à 3 exigences")
	for _, e in ipairs(commande.exigences) do
		genres[e.type] = true
	end
	local ok, temoin = Commandes.realisable(commande.exigences)
	U.verifier(ok, "commande " .. n .. " réalisable")
	-- Construit la robe témoin : toutes les pièces dans le tissu témoin, droit-fil et couture parfaits
	local recette = { croquis = temoin.croquis, pieces = {}, accessoires = {} }
	for _, id in ipairs(Patron.piecesDuCroquis(temoin.croquis)) do
		table.insert(recette.pieces, { id = id, tissu = temoin.tissu, x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0, couture = 1 })
	end
	if temoin.accessoire then
		table.insert(recette.accessoires, { id = temoin.accessoire, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	U.verifier(Notation.verifierExigences(commande.exigences, Notation.bilan(recette)), "la robe témoin remplit la commande " .. n)
end
for _, g in ipairs({ "min", "max", "qualite", "teinte", "accessoire" }) do
	U.verifier(genres[g] == true, "le générateur produit des exigences « " .. g .. " »")
end

-- Commandes d'une cliente (sous-projet 2) : toujours réalisables, tirées de ses goûts ; ses mesures seront prises
local Clientes = U.module("Clientes")
for _, cliente in ipairs(Clientes.LISTE) do
	local rngCliente = Random.new(7)
	for n = 1, 40 do
		local c = Commandes.generer(rngCliente, cliente)
		U.verifier(c.cliente == cliente.id and c.taille == cliente.taille and c.mesures == nil, cliente.id .. " : sa commande, sans mesures (elles seront prises)")
		U.verifier(Commandes.realisable(c.exigences) and #c.exigences >= 1 and #c.exigences <= 3, cliente.id .. " : commande " .. n .. " réalisable")
		U.verifier(c.exigences[1].type == "min" and table.find(cliente.styles, c.exigences[1].style) ~= nil, cliente.id .. " : elle demande un de ses styles")
		for _, e in ipairs(c.exigences) do
			U.verifier(e.type ~= "max" or table.find(cliente.styles, e.style) == nil, cliente.id .. " : jamais « au plus » dans ses styles")
			U.verifier(e.type ~= "teinte" or e.teinte == cliente.teinte, cliente.id .. " : sa teinte")
		end
	end
end
