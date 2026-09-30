-- Sous-projet 7 (relecture du plan 19) : une robe à dix pièces, toutes du même tissu. À la découpe et à la couture, la
-- liste des pièces défile, sans passer sur ce qui la suit.
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local EcranDecoupe = U.module("EcranDecoupe")
local EcranCouture = U.module("EcranCouture")
local EcranEpinglage = U.module("EcranEpinglage")

local DIX = { corsage = "corsage_basque", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_volant" }
local ids = Patron.piecesDuCroquis(DIX)
local session = Session.nouvelle(19)
U.commander(session)
local tissus = {}
for _, id in ipairs(ids) do
	tissus[id] = "coton_blanc"
end
assert(#ids == 10 and session:validerCroquis(DIX, tissus).ok)
session.etat.argent = 1000
local placements, longueur = Metrage.disposition(ids)
assert(session:acheter("coton_blanc", longueur).ok and session:commencerDecoupe().ok)
local function contexte()
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
end

-- La table de découpe : dix pièces à couper dans le coton
local ctx = contexte()
local fermer = EcranDecoupe(ctx)
local panneau = ctx.contenu.Panneau
local liste = panneau.ListePieces
local lignes = 0
for _, e in ipairs(liste:GetChildren()) do
	lignes += if e.Name:sub(1, 6) == "Piece_" then 1 else 0
end
U.verifier(lignes == 10 and liste:IsA("ScrollingFrame") and (liste.CanvasSize and liste.CanvasSize.Y.Offset or 0) >= 10 * 26 and liste.Position.Y.Offset + liste.Size.Y.Offset <= panneau.DroitFil.Position.Y.Offset, ("découpe, dix pièces : la liste défile, au-dessus du droit-fil (%d lignes)"):format(lignes))
fermer()

-- La couture : dix pièces à coudre
for _, id in ipairs(ids) do
	assert(session:couper(id, placements[id]).ok, id)
end

-- (plan 20) L'épinglage : les couches (basque, volant) en fin de liste, elles se posent par-dessus les autres pièces
local ctx3 = contexte()
local fermer3 = EcranEpinglage(ctx3)
local cartes = {}
for _, c in ipairs(ctx3.contenu.Liste:GetChildren()) do
	if c.Name:sub(1, 9) == "Epingler_" then
		table.insert(cartes, c)
	end
end
table.sort(cartes, function(a, b)
	return a.Position.Y.Offset < b.Position.Y.Offset
end)
local ordre = {}
for _, c in ipairs(cartes) do
	table.insert(ordre, (c.Name:gsub("^Epingler_", "")))
end
U.verifier(table.concat(ordre, ",") == "corsage_droit_devant,corsage_droit_dos,manche_ballon,col_claudine,jupe_droite_devant,jupe_droite_dos,basque_devant,basque_dos,volant_devant,volant_dos", "épinglage : les pièces du dessous dans l'ordre du croquis, puis les couches (" .. table.concat(ordre, ", ") .. ")")
fermer3()
-- (relecture du plan 20) Une robe sans couche : l'ordre du croquis
do
	local SIX = { corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_trapeze" }
	local s6 = Session.nouvelle(20)
	U.commander(s6)
	local ids6, t6 = Patron.piecesDuCroquis(SIX), {}
	for _, id in ipairs(ids6) do
		t6[id] = "coton_blanc"
	end
	assert(s6:validerCroquis(SIX, t6).ok)
	s6.etat.argent = 1000
	local places6, long6 = Metrage.disposition(ids6)
	assert(s6:acheter("coton_blanc", long6).ok and s6:commencerDecoupe().ok)
	for _, id in ipairs(ids6) do
		assert(s6:couper(id, places6[id]).ok, id)
	end
	local c6 = contexte()
	c6.session = s6
	local f6 = EcranEpinglage(c6)
	local cartes6 = {}
	for _, c in ipairs(c6.contenu.Liste:GetChildren()) do
		if c.Name:sub(1, 9) == "Epingler_" then
			table.insert(cartes6, c)
		end
	end
	table.sort(cartes6, function(a, b)
		return a.Position.Y.Offset < b.Position.Y.Offset
	end)
	local ordre6 = {}
	for _, c in ipairs(cartes6) do
		table.insert(ordre6, (c.Name:gsub("^Epingler_", "")))
	end
	U.verifier(table.concat(ordre6, ",") == table.concat(ids6, ","), "robe sans couche : l'épinglage garde l'ordre du croquis (" .. table.concat(ordre6, ", ") .. ")")
	f6()
end
for _, id in ipairs(ids) do
	assert(session:epingler(id).ok, id)
end
assert(session.etat.etape == "couture")
local ctx2 = contexte()
local fermer2 = EcranCouture(ctx2)
local panneau2 = ctx2.contenu.Panneau
local pieces = panneau2.Pieces
local lignes2 = 0
for _, e in ipairs(pieces:GetChildren()) do
	lignes2 += if e.Name:sub(1, 5) == "Ligne" then 1 else 0
end
U.verifier(lignes2 == 10 and pieces:IsA("ScrollingFrame") and (pieces.CanvasSize and pieces.CanvasSize.Y.Offset or 0) >= 10 * 24 and pieces.Position.Y.Offset + pieces.Size.Y.Offset <= panneau2.Note.Position.Y.Offset, ("couture, dix pièces : la liste défile, au-dessus de la note (%d lignes)"):format(lignes2))
fermer2()
