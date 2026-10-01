-- Sous-projet 8 (relecture du plan 25) : glisser en tenant « Coudre » fait pivoter le tissu ; mais une souris qui bouge à
-- peine, ou un pouce qui s'écrase en appuyant, ne le fait pas tourner tout seul (une zone morte)
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local EcranCouture = U.module("EcranCouture")
local UIS = M.services.UserInputService

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ids = Patron.piecesDuCroquis(CROQUIS)

-- La même robe (même graine, même tissu qui tire), cousue 0,5 s en tenant « Coudre » à la souris, décalée de dx px
local function rotationApres(dx)
	local session = Session.nouvelle(51)
	U.commander(session)
	local tissus = {}
	for _, id in ipairs(ids) do
		tissus[id] = "coton_blanc"
	end
	assert(session:validerCroquis(CROQUIS, tissus).ok)
	session.etat.argent = 1000
	local placements, longueur = Metrage.disposition(ids)
	assert(session:acheter("coton_blanc", longueur).ok and session:commencerDecoupe().ok)
	for _, id in ipairs(ids) do
		assert(session:couper(id, placements[id]).ok, id)
	end
	for _, id in ipairs(ids) do
		assert(session:epingler(id).ok, id)
	end
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	local fermer = EcranCouture({ UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end })
	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) }
	contenu.Panneau.Coudre.InputBegan:Fire(appui)
	UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(700 + dx, 400, 0) })
	M.avancer(0.5)
	UIS.InputEnded:Fire(appui)
	local rotation = contenu.Plateau.Tissu.Rotation
	fermer()
	return rotation
end

local immobile = rotationApres(0)
local tremble = rotationApres(8)
local glisse = rotationApres(-60)
U.verifier(math.abs(tremble - immobile) < 0.01, ("la souris qui bouge de 8 px ne fait pas pivoter le tissu (%.2f° contre %.2f°)"):format(tremble, immobile))
U.verifier(immobile - glisse > 5, ("glisser de 60 px vers la gauche le fait pivoter, comme ◀ (%.2f° contre %.2f°)"):format(glisse, immobile))
