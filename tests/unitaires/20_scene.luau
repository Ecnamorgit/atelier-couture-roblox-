local Scene = U.module("Scene")
local Vignettes = U.module("Vignettes")
local ConstructeurRobe = U.module("ConstructeurRobe")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Mannequin = U.module("Mannequin")

local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
M.budget.images, M.budget.maillages = 64, 7

---------------------------------------------------------------------------
-- Une pièce seule (épinglage)
---------------------------------------------------------------------------
local manche = { id = "manche_ballon", tissu = "soie_rose_fleurs", x = 3, y = 2, angle = 0 }
local part = ConstructeurRobe.piece(manche, "droite", Catalogue.TAILLES.M, CFrame.new(0, 10, 0), "robe")
U.verifier(part ~= nil and part.Name == "Piece_manche_ballon_droite" and part.Parent == nil, "pièce seule, sans parent")
U.verifier(part.TextureContent ~= nil and part.TextureContent.statique and part.Anchored and not part.CanCollide, "pièce seule : texture statique, ancrée")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "pièce seule : objets modifiables détruits")
part:Destroy()

---------------------------------------------------------------------------
-- Aperçu d'une pièce découpée
---------------------------------------------------------------------------
local place = { x = 3, y = 2, angle = 0 }
local apercu = Vignettes.piece("manche_ballon", "soie_rose_fleurs", place)
U.verifier(apercu ~= nil and apercu.statique, "aperçu de la pièce découpée en contenu statique")
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3, y = 2, angle = 0 }) == apercu, "aperçu en cache")
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3.5, y = 2, angle = 0 }) ~= apercu, "autre place sur le rouleau : autre aperçu")
M.budget.images = 0
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 4, y = 2, angle = 0 }) == nil, "mémoire des images pleine : pas d'aperçu, sans erreur")
M.budget.images = 64
-- Commande finie : les images des pièces découpées sont oubliées (mémoire), pas celles des tissus
local motifSoie = Vignettes.motif("soie_rose_fleurs")
Vignettes.oublierPieces()
local refait = Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3, y = 2, angle = 0 })
U.verifier(refait ~= nil and refait ~= apercu, "images des pièces oubliées : refaites à la demande")
U.verifier(motifSoie ~= nil and Vignettes.motif("soie_rose_fleurs") == motifSoie, "les motifs des tissus restent en cache")

---------------------------------------------------------------------------
-- Scène : mannequin de la cliente, pièces épinglées, caméra fixe
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local etat = EtatAtelier.nouveau()
local scene = Scene.nouvelle(Workspace)
U.verifier(scene.dossier.Name == "AtelierLocal" and scene.dossier.Parent == Workspace, "dossier de la scène dans le Workspace")
camera.CameraType = Enum.CameraType.Custom
scene:synchroniser(etat)
U.verifier(scene.dossier:FindFirstChild("Mannequin") == nil, "pas de mannequin sans commande")
U.verifier(camera.CameraType == Enum.CameraType.Custom, "à l'accueil, la caméra suit le joueur")

etat:nouvelleCommande(Random.new(3))
etat.commande.mesures = table.clone(Catalogue.TAILLES.S)
local tissus = {}
for _, id in ipairs(PIECES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, id in ipairs(PIECES) do
	etat:couper(id, DISPOSITION[id])
end
scene:synchroniser(etat)
local mannequin = scene.dossier:FindFirstChild("Mannequin")
U.verifier(mannequin ~= nil, "mannequin posé dès qu'il y a une commande")
local buste = Mannequin.formes(Catalogue.TAILLES.S)[1]
U.verifier(U.proche((mannequin.Buste.Size - buste.taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), "mannequin aux mesures de la cliente")
U.verifier(U.proche((mannequin.Buste.CFrame.Position - (Scene.CADRE * CFrame.new(buste.centre * Catalogue.STUDS_PAR_DM)).Position).Magnitude, 0), "mannequin à sa place dans l'atelier")
U.verifier(#scene.robe:GetChildren() == 0, "rien d'épinglé")
U.verifier(camera.CameraType == Enum.CameraType.Scriptable and camera.CFrame == Scene.CAMERA, "épinglage : caméra fixe sur le mannequin")

etat:epingler("corsage_droit_devant")
scene:synchroniser(etat)
local corsage = scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique")
U.verifier(corsage ~= nil and #scene.robe:GetChildren() == 1, "la pièce épinglée apparaît sur le mannequin")
U.verifier((corsage.CFrame.Position - Scene.CADRE.Position).Magnitude < 3, "pièce posée sur le mannequin")
scene:synchroniser(etat)
U.verifier(scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique") == corsage, "une pièce déjà posée n'est pas reconstruite")
for i = 2, 4 do
	etat:epingler(PIECES[i])
end
scene:synchroniser(etat)
U.verifier(#scene.robe:GetChildren() == 4 and etat.etape == "couture", "robe entièrement épinglée")
U.verifier(camera.CameraType == Enum.CameraType.Scriptable, "couture : caméra toujours fixe")

-- Recommencer : la robe disparaît, le mannequin reste, la caméra revient au joueur
etat:recommencer()
scene:synchroniser(etat)
U.verifier(#scene.robe:GetChildren() == 0 and scene.dossier:FindFirstChild("Mannequin") == mannequin, "recommencer : robe retirée, même mannequin")
U.verifier(camera.CameraType == Enum.CameraType.Custom, "carnet : la caméra suit de nouveau le joueur")

-- Autre cliente : le mannequin change de taille
etat.commande.mesures = table.clone(Catalogue.TAILLES.L)
scene:synchroniser(etat)
local grand = scene.dossier:FindFirstChild("Mannequin")
U.verifier(grand ~= mannequin and mannequin.Parent == nil, "nouvelles mesures : nouveau mannequin")
U.verifier(U.proche((grand.Buste.Size - Mannequin.formes(Catalogue.TAILLES.L)[1].taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), "mannequin taille L")

-- Mémoire des maillages pleine : la pièce n'apparaît pas, sans erreur
local etat2 = EtatAtelier.nouveau()
etat2:nouvelleCommande(Random.new(3))
etat2:validerCroquis(CROQUIS, tissus)
etat2:acheter("coton_blanc", 12)
etat2:commencerDecoupe()
for _, id in ipairs(PIECES) do
	etat2:couper(id, DISPOSITION[id])
end
etat2:epingler(PIECES[1])
local scene2 = Scene.nouvelle(Workspace)
M.budget.maillages = 0
scene2:synchroniser(etat2)
M.budget.maillages = 7
U.verifier(#scene2.robe:GetChildren() == 0 and scene2.dossier:FindFirstChild("Mannequin") ~= nil, "mémoire pleine : pièce absente, scène intacte")
scene2:synchroniser(etat2)
U.verifier(scene2.robe:FindFirstChild("Piece_" .. PIECES[1] .. "_unique") ~= nil, "mémoire libérée : la pièce ratée est construite à la synchronisation suivante")

scene2:detruire()
scene:detruire()
U.verifier(scene.dossier.Parent == nil and camera.CameraType == Enum.CameraType.Custom, "scène détruite, caméra rendue")
