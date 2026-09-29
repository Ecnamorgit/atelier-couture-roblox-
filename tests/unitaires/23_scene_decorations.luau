local Scene = U.module("Scene")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
M.budget.images, M.budget.maillages = 64, 7
local E = Catalogue.STUDS_PAR_DM

-- Robe coupée, épinglée et cousue (corsage droit, manches ballon, jupe droite), aux décorations
local CROQUIS = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 9.6, y = 2.1, angle = 0 },
	manche_ballon = { x = 5.35, y = 6.5, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 12, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 12, angle = 0 },
}
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(3))
local tissus = {}
for id in pairs(PLACES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 20)
etat:commencerDecoupe()
for _, id in ipairs(etat:piecesDuCroquis()) do
	assert(etat:couper(id, PLACES[id]).ok, id)
end
for _, id in ipairs(etat:piecesDuCroquis()) do
	etat:epingler(id)
end
for _, id in ipairs(etat:piecesDuCroquis()) do
	local _, longueur = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur)
end
U.verifier(etat.etape == "decorations", "robe prête à décorer")

local scene = Scene.nouvelle(Workspace, { etaler = false })
scene:synchroniser(etat)
local corsage = scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique")
local mancheDroite = scene.robe:FindFirstChild("Piece_manche_ballon_droite")
U.verifier(corsage ~= nil and corsage.CanQuery and mancheDroite ~= nil and mancheDroite.CanQuery, "les pièces de la robe se touchent (rayons)")

---------------------------------------------------------------------------
-- Toucher la robe : pièce, copie et place sur le patron
---------------------------------------------------------------------------
local function surLaRobe(id, copie, u, v)
	local b = Catalogue.piece(id).contour
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, p in ipairs(b) do
		minX, maxX, minY, maxY = math.min(minX, p.x), math.max(maxX, p.x), math.min(minY, p.y), math.max(maxY, p.y)
	end
	local pos = Patron.point(id, copie, minX + u * (maxX - minX), minY + v * (maxY - minY), etat.commande.mesures)
	return Scene.CADRE * (pos * E), pos
end
local ou, voulu = surLaRobe("manche_ballon", "droite", 0.4, 0.5)
M.impacts = { { Instance = mancheDroite, Position = ou, Normal = Vector3.new(0, 0, -1) } }
local t = scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50))
U.verifier(t ~= nil and t.genre == "piece" and t.indicePiece == 3 and t.copie == "droite", "touche sur la manche droite : 3e pièce du croquis, copie droite")
local b = Catalogue.piece("manche_ballon").contour
local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
for _, p in ipairs(b) do
	minX, maxX, minY, maxY = math.min(minX, p.x), math.max(maxX, p.x), math.min(minY, p.y), math.max(maxY, p.y)
end
local retrouve = Patron.point("manche_ballon", "droite", minX + t.u * (maxX - minX), minY + t.v * (maxY - minY), etat.commande.mesures)
U.verifier((retrouve - voulu).Magnitude < 0.05, "la place touchée est retrouvée sur le patron")
local params = M.dernierRayon.params
U.verifier(params.FilterType == Enum.RaycastFilterType.Include and table.find(params.FilterDescendantsInstances, scene.robe) ~= nil, "le rayon ne vise que la robe et ses décorations")
U.verifier(scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50)) == nil, "rien touché : rien")
M.impacts = { { Instance = Workspace, Position = Vector3.new(0, 0, 0), Normal = Vector3.new(0, 1, 0) } }
U.verifier(scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50)) == nil, "impact hors de la robe : rien")

---------------------------------------------------------------------------
-- Aperçu des décorations
---------------------------------------------------------------------------
local recette = etat:recette()
local liste = {
	{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 },
	{ id = "perle", piece = 3, copie = "droite", u = 0.4, v = 0.5, echelle = 1, angle = 0 },
}
scene:montrerDecorations(recette, liste, { id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } })
local enfants = scene.decorations:GetChildren()
U.verifier(#enfants == 3, "deux décorations posées et la garniture en cours")
local perle = enfants[2]
U.verifier(perle.Name == "Accessoire_perle" and perle:GetAttribute("Indice") == 2 and enfants[3]:GetAttribute("Indice") == nil, "chaque décoration posée connaît sa place dans la liste")
local partPerle = perle:GetChildren()[1]
U.verifier(partPerle.CanQuery, "une décoration se touche (pour la sélectionner)")
M.impacts = { { Instance = partPerle, Position = partPerle.CFrame.Position, Normal = Vector3.new(0, 0, -1) } }
t = scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50))
U.verifier(t ~= nil and t.genre == "decoration" and t.indice == 2, "touche sur la perle : décoration n° 2")
scene:montrerDecorations(recette, { liste[1] }, nil)
U.verifier(#scene.decorations:GetChildren() == 1, "l'aperçu suit la liste")
scene:montrerDecorations(nil, {}, nil)
U.verifier(#scene.decorations:GetChildren() == 0, "sans robe : aucun aperçu")

---------------------------------------------------------------------------
-- Caméra qui tourne autour du mannequin (décorations)
---------------------------------------------------------------------------
U.verifier(camera.CFrame == Scene.CAMERA, "départ : caméra de face")
local centre = Scene.CADRE.Position
local function distanceAxe(p)
	return Vector3.new(p.X - centre.X, 0, p.Z - centre.Z).Magnitude
end
scene:orbiter(90)
local oeil = camera.CFrame.Position
U.verifier(math.abs(distanceAxe(oeil) - distanceAxe(Scene.CAMERA.Position)) < 1e-6 and math.abs(oeil.Y - Scene.CAMERA.Position.Y) < 1e-6, "la caméra tourne autour du mannequin, à la même distance")
U.verifier((oeil - Scene.CAMERA.Position).Magnitude > 1, "la caméra a bien tourné")
scene:orbiter(-90)
U.verifier((camera.CFrame.Position - Scene.CAMERA.Position).Magnitude < 1e-6, "retour de face")
scene:orbiter(45)
etat:decorer({})
scene:synchroniser(etat)
U.verifier(camera.CFrame == Scene.CAMERA, "en quittant les décorations, la caméra revient de face")

---------------------------------------------------------------------------
-- Vitrine : la dernière robe livrée
---------------------------------------------------------------------------
U.verifier(scene.socle ~= nil and scene.socle:GetAttribute("Recette") == nil, "vitrine vide avant la première livraison")
etat.commande.exigences = { { type = "qualite", valeur = 0.5 } }
U.verifier(etat:livrer().reussie, "robe livrée")
scene:synchroniser(etat)
U.verifier(scene.socle:GetAttribute("Recette") == Recette.encoder(etat.robes[1]), "la robe livrée part en vitrine")
U.verifier(#scene.robe:GetChildren() == 0 and scene.dossier:FindFirstChild("Mannequin") == nil, "le mannequin de travail est libéré pour la cliente suivante")
M.avancer(1)
U.verifier(scene.socle:FindFirstChild("Exposition") ~= nil, "la vitrine se construit quand on est près")
scene:detruire()
U.verifier(scene.dossier.Parent == nil, "scène détruite")
