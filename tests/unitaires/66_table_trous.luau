-- Sous-projet 6 : à la table, un rouleau entamé. « Proposer » cherche aussi contre les bords des trous : dans un vide
-- de la bande s'il y en a un assez grand, sinon dessous.
local Session = U.module("Session")
local TableDecoupe = U.module("TableDecoupe")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_montant", jupe = "jupe_droite" }
local function aLaTable(entame, stock)
	local session = Session.nouvelle(21)
	U.commander(session)
	assert(session:validerCroquis(CROQUIS, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", col_montant = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
	session.etat.stock.coton_blanc = stock
	session.etat.entames.coton_blanc = entame
	assert(session:commencerDecoupe().ok)
	return session, TableDecoupe.nouvelle(session.etat)
end

-- Un trou de jupe en haut à gauche : à côté, un vide de 9 dm sur 6 ; dessous, du tissu neuf
local session, t = aLaTable({ bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } }, 30)
U.verifier(t.selection == "jupe_droite_devant" and t:etatPlacement().valide and t.placement.y < 6, "la première jupe est proposée dans le vide, à côté du trou")
local coupees = 0
while t.selection and coupees < 5 do
	local e = t:etatPlacement()
	U.verifier(e.valide, "place proposée valide pour " .. t.selection .. " (" .. tostring(e.erreur) .. ")")
	assert(t:couper(session).ok)
	coupees += 1
end
U.verifier(coupees == 5 and session.etat.etape == "epinglage", "les cinq pièces coupées aux places proposées, sans passer sur le trou")

-- Une bande pleine de trous en haut du rouleau : tout est proposé dessous
local trous = {}
for k = 0, 5 do
	table.insert(trous, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
end
local session2, t2 = aLaTable({ bas = 10, trous = trous }, 40)
U.verifier(t2:etatPlacement().valide and t2.placement.y > 9.6, "sous une bande pleine, la première pièce est proposée dessous")
U.verifier(session2.etat.coupons.coton_blanc:longueurUtilisee() == 10, "(la bande : 10 dm)")
