local Scene = U.module("Scene")
local Boutique = U.module("Boutique")
local EtatAtelier = U.module("EtatAtelier")

local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
M.budget.images, M.budget.maillages = 64, 16

-- Deux scènes : l'une à l'origine du monde, l'autre dans une boutique d'en face (tournée d'un demi-tour).
-- Tout ce que la seconde montre est ce que montre la première, déplacé dans la boutique.
local origine = Boutique.emplacement(6)
local function proche(a, b)
	return (a.Position - b.Position).Magnitude < 1e-5 and a.LookVector:Dot(b.LookVector) > 1 - 1e-6 and a.UpVector:Dot(b.UpVector) > 1 - 1e-6
end
local sansControles = function() end
local ici = Scene.nouvelle(Workspace, { etaler = false, controles = sansControles })
local laBas = Scene.nouvelle(Workspace, { etaler = false, controles = sansControles, origine = origine })
U.verifier(proche(ici.cadre, Scene.CADRE) and proche(laBas.cadre, origine * Scene.CADRE), "le cadre de la robe suit l'origine de la boutique")

-- Même commande, jusqu'à la robe épinglée
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local tissus = {}
for _, id in ipairs(ORDRE) do
	tissus[id] = "coton_blanc"
end
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(3))
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, id in ipairs(ORDRE) do
	etat:couper(id, PLACES[id])
end
for _, id in ipairs(ORDRE) do
	etat:epingler(id)
end
ici:synchroniser(etat, nil)
laBas:synchroniser(etat, nil)

-- Chaque pièce (mannequin, robe épinglée, cliente) : la même, déplacée dans la boutique
local function parties(scene)
	local t, n = {}, 0
	for _, d in ipairs(scene.dossier:GetDescendants()) do
		if d:IsA("BasePart") then
			local chemin, i = d.Name, d.Parent
			while i and i ~= scene.dossier do
				chemin = i.Name .. "/" .. chemin
				i = i.Parent
			end
			if not t[chemin] then
				t[chemin] = d
				n += 1
			end
		end
	end
	return t, n
end
local function memeScene(nom)
	local a, na = parties(ici)
	local b, nb = parties(laBas)
	local ecarts = {}
	for chemin, p in pairs(a) do
		if not b[chemin] or not proche(origine * p.CFrame, b[chemin].CFrame) then
			table.insert(ecarts, chemin)
		end
	end
	table.sort(ecarts)
	U.verifier(na == nb and na > 0 and #ecarts == 0, nom .. " : " .. na .. " pièces, écarts : " .. table.concat(ecarts, ", "))
end
U.verifier(laBas.dossier:FindFirstChild("Mannequin") ~= nil and laBas.dossier:FindFirstChild("Cliente") ~= nil and #laBas.robe:GetChildren() == 4, "mannequin, cliente et robe épinglée (mise en place du test)")
memeScene("mannequin, robe épinglée et cliente dans la boutique")

-- Caméra du poste, vue qui tourne, photo
ici:regarder(true)
local vueIci = camera.CFrame
laBas:regarder(true)
U.verifier(proche(camera.CFrame, origine * vueIci) and proche(camera.CFrame, origine * Scene.CAMERA), "caméra du poste dans la boutique")
ici:orbiter(90)
vueIci = camera.CFrame
laBas:orbiter(90)
U.verifier(proche(camera.CFrame, origine * vueIci), "la vue tourne autour du mannequin de la boutique")
ici:orbiter(-90)
laBas:orbiter(-90)
ici:photo({ decor = "bleu", lumiere = "jour", mannequin = "noir" })
laBas:photo({ decor = "bleu", lumiere = "jour", mannequin = "noir" })
memeScene("décor de la photo dans la boutique")
laBas:cadrerPhoto(true)
U.verifier(proche(camera.CFrame, origine * Scene.CAMERA_PHOTO), "vue de la photo dans la boutique")
laBas:cadrerPhoto(false)
ici:finirPhoto()
laBas:finirPhoto()

-- Toucher la robe : la même place sur le patron
local pieceIci, pieceLaBas = ici.robe:GetChildren()[1], nil
for _, p in ipairs(laBas.robe:GetChildren()) do
	if p.Name == pieceIci.Name then
		pieceLaBas = p
	end
end
local point = pieceIci.CFrame * Vector3.new(0.1, 0.2, 0)
M.impacts = { { Instance = pieceIci, Position = point, Normal = Vector3.new(0, 0, -1) } }
local tIci = ici:toucher(Vector3.zero, Vector3.new(0, 0, 1))
M.impacts = { { Instance = pieceLaBas, Position = origine * point, Normal = Vector3.new(0, 0, -1) } }
local tLaBas = laBas:toucher(Vector3.zero, Vector3.new(0, 0, 1))
U.verifier(tIci ~= nil and tLaBas ~= nil and tIci.indicePiece == tLaBas.indicePiece and math.abs(tIci.u - tLaBas.u) < 1e-6 and math.abs(tIci.v - tLaBas.v) < 1e-6, "toucher la robe : la même place sur le patron")

-- La scène ne tient plus de vitrine : c'est le serveur qui les pose dans la rue
U.verifier(laBas.dossier:FindFirstChild("Vitrines") == nil, "pas de vitrine dans la scène (elles sont dans la rue)")
ici:detruire()
laBas:detruire()
