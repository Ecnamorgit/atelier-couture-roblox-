-- Sous-projet 7 (relecture du plan 19) : une robe à dix pièces, toutes du même tissu. À la découpe et à la couture, la
-- liste des pièces défile, sans passer sur ce qui la suit.
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local EcranDecoupe = U.module("EcranDecoupe")
local EcranCouture = U.module("EcranCouture")

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
