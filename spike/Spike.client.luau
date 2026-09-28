-- SPIKE JETABLE : faisabilité du rendu EditableImage / EditableMesh (sous-projet 1, étape 1).
-- Génère une jupe (devant + dos) en soie fleurie découpée à 45°, mesure temps et mémoire,
-- et essaie chaque API incertaine. Le rapport s'affiche à l'écran et dans la sortie.
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local lignes = {}
local function noter(cle, valeur)
	local texte = cle .. " = " .. tostring(valeur)
	table.insert(lignes, texte)
	print("[Spike] " .. texte)
end
local function essayer(nom, f)
	local ok, resultat = pcall(f)
	noter(nom, ok and "OK" or ("ÉCHEC : " .. tostring(resultat)))
	return ok, resultat
end
local function afficher()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RapportSpike"
	gui.ResetOnSpawn = false
	local texte = Instance.new("TextLabel")
	texte.Size = UDim2.new(0.5, 0, 1, -80)
	texte.Position = UDim2.fromOffset(10, 70)
	texte.BackgroundTransparency = 0.3
	texte.TextXAlignment = Enum.TextXAlignment.Left
	texte.TextYAlignment = Enum.TextYAlignment.Top
	texte.TextSize = 14
	texte.TextWrapped = true
	texte.Font = Enum.Font.Code
	texte.Text = table.concat(lignes, "\n")
	texte.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

noter("plateforme", UserInputService.TouchEnabled and "tactile" or "PC")
noter("memoireTotaleAvantMo", math.floor(Stats:GetTotalMemoryUsageMb()))

---------------------------------------------------------------------------
-- 1. Motif fleuri 256 × 256 (bande sombre tous les 2 dm pour voir le droit-fil)
---------------------------------------------------------------------------
local N, PX = 256, 32
local t0 = os.clock()
local motif = buffer.create(N * N * 4)
for y = 0, N - 1 do
	for x = 0, N - 1 do
		local dx, dy = (x % 64) - 31.5, (y % 64) - 31.5
		local d = math.sqrt(dx * dx + dy * dy)
		local r, g, b = 214, 84, 146
		if d < 8 then
			r, g, b = 255, 230, 120
		elseif d < 22 and math.cos(5 * math.atan2(dy, dx)) > 0.1 then
			r, g, b = 255, 200, 225
		end
		if y % 64 < 3 then
			r, g, b = 60, 20, 40
		end
		buffer.writeu32(motif, (y * N + x) * 4, r + g * 256 + b * 65536 + 255 * 16777216)
	end
end
noter("motif256Ms", math.floor((os.clock() - t0) * 1000))

---------------------------------------------------------------------------
-- 2. Découpe d'une pièce 6 × 6 dm (192 × 192 px) posée à 45° sur le rouleau
---------------------------------------------------------------------------
local W, H = 6, 6
local L = W * PX
local function decouper(angleDeg)
	local a = math.rad(angleDeg)
	local c, s = math.cos(a), math.sin(a)
	local buf = buffer.create(L * L * 4)
	for j = 0, L - 1 do
		for i = 0, L - 1 do
			local x, y = (i + 0.5) / PX - W / 2, (j + 0.5) / PX - H / 2
			local bx, by = 7 + c * x - s * y, 5 + s * x + c * y
			local mx, my = math.floor(bx * PX) % N, math.floor(by * PX) % N
			buffer.writeu32(buf, (j * L + i) * 4, buffer.readu32(motif, (my * N + mx) * 4))
		end
	end
	return buf
end
t0 = os.clock()
local piece = decouper(45)
noter("decoupe192Ms", math.floor((os.clock() - t0) * 1000))

---------------------------------------------------------------------------
-- 3. EditableImage
---------------------------------------------------------------------------
local okImage, image = essayer("CreateEditableImage+WritePixelsBuffer", function()
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(L, L) })
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(L, L), piece)
	return img
end)
if not okImage then
	afficher()
	return
end

---------------------------------------------------------------------------
-- 4. EditableMesh : demi-jupe quadrillée 12 × 16, UV = coordonnées du patron, 1 dm = 0,3 stud
---------------------------------------------------------------------------
local ECHELLE = 0.3
local function demiJupe(cote, doublure)
	local em = AssetService:CreateEditableMesh()
	assert(em, "budget des EditableMesh atteint")
	local NX, NY = 12, 16
	local sommets = {}
	local centre = Vector3.zero
	for jy = 0, NY do
		for ix = 0, NX do
			local u, v = ix / NX, jy / NY
			local phi = cote == "devant" and (2 * math.pi - u * math.pi) or (math.pi - u * math.pi)
			local r = 1.3 + 0.25 * v * 6
			local pos = Vector3.new(r * 1.12 * math.cos(phi), -v * 6, r * 0.88 * math.sin(phi)) * ECHELLE
			centre += pos
			sommets[jy * (NX + 1) + ix] = {
				em:AddVertex(pos),
				em:AddUV(Vector2.new(u, v)),
				em:AddNormal(Vector3.new(math.cos(phi), 0, math.sin(phi))),
			}
		end
	end
	for jy = 0, NY - 1 do
		for ix = 0, NX - 1 do
			local a = sommets[jy * (NX + 1) + ix]
			local b = sommets[jy * (NX + 1) + ix + 1]
			local c = sommets[(jy + 1) * (NX + 1) + ix]
			local d = sommets[(jy + 1) * (NX + 1) + ix + 1]
			local triangles = { { a, c, b }, { b, c, d } }
			if doublure then
				table.insert(triangles, { a, b, c })
				table.insert(triangles, { b, d, c })
			end
			for _, t in ipairs(triangles) do
				local f = em:AddTriangle(t[1][1], t[2][1], t[3][1])
				em:SetFaceUVs(f, { t[1][2], t[2][2], t[3][2] })
				em:SetFaceNormals(f, { t[1][3], t[2][3], t[3][3] })
			end
		end
	end
	return em, centre / ((NX + 1) * (NY + 1))
end

---------------------------------------------------------------------------
-- 5. MeshPart et TextureContent (au 1er passage : SurfaceAppearance.ColorMapContent
--    refusé en jeu, « lacking capability Plugin » → abandonné)
---------------------------------------------------------------------------
local base = CFrame.new(0, 5, -10)
t0 = os.clock()
for _, cote in ipairs({ "devant", "dos" }) do
	local okMesh, em, centre = pcall(demiJupe, cote, true)
	noter("CreateEditableMesh_" .. cote, okMesh and "OK" or ("ÉCHEC : " .. tostring(em)))
	if okMesh then
		local okPart, mp = essayer("CreateMeshPartAsync_" .. cote, function()
			return AssetService:CreateMeshPartAsync(Content.fromObject(em))
		end)
		if okPart then
			mp.Anchored = true
			mp.CanCollide = false
			mp.CFrame = base * CFrame.new(centre)
			noter("tailleMeshPart_" .. cote, mp.Size)
			essayer("TextureContent_" .. cote, function()
				mp.TextureContent = Content.fromObject(image)
			end)
			mp.Parent = workspace
		end
	end
end
noter("jupe2PiecesMs", math.floor((os.clock() - t0) * 1000))

---------------------------------------------------------------------------
-- 6. Budget des maillages modifiables (création à vide, sans taille fixe)
---------------------------------------------------------------------------
local maillages = {}
for k = 1, 64 do
	local em = AssetService:CreateEditableMesh()
	if not em then
		break
	end
	maillages[k] = em
end
noter("budgetMaillagesEnPlus", #maillages)
for _, em in ipairs(maillages) do
	em:Destroy()
end

---------------------------------------------------------------------------
-- 7. Libérer le budget : détruire l'EditableMesh après CreateMeshPartAsync,
--    avec ou sans conversion en contenu statique
---------------------------------------------------------------------------
-- 7a. Sans conversion : la pièce garde-t-elle sa forme ? (à 5 studs à droite)
local okA, emA, centreA = pcall(demiJupe, "devant", true)
if okA then
	local mpA = AssetService:CreateMeshPartAsync(Content.fromObject(emA))
	mpA.Anchored = true
	mpA.CFrame = base * CFrame.new(5, 0, 0) * CFrame.new(centreA)
	mpA.TextureContent = Content.fromObject(image)
	mpA.Parent = workspace
	emA:Destroy()
	task.wait(0.5)
	noter("detruireSansConversion_taille", mpA.Size)
end
-- 7b. Avec conversion en contenu statique (à 5 studs à gauche)
local okB, emB, centreB = pcall(demiJupe, "devant", true)
if okB then
	-- Renvoie deux valeurs : un Enum.CreateContentResult, puis le Content statique
	local okC, resultatM, contenuMaillage = pcall(function()
		return AssetService:CreateDataModelContentAsync(Content.fromObject(emB))
	end)
	noter("CreateDataModelContentAsync(maillage)", okC and tostring(resultatM) or ("ÉCHEC : " .. tostring(resultatM)))
	local okI, resultatI, contenuImage = pcall(function()
		return AssetService:CreateDataModelContentAsync(Content.fromObject(image))
	end)
	noter("CreateDataModelContentAsync(image)", okI and tostring(resultatI) or ("ÉCHEC : " .. tostring(resultatI)))
	if okC then
		local okP, mpB = essayer("CreateMeshPartAsync(contenu statique)", function()
			return AssetService:CreateMeshPartAsync(contenuMaillage)
		end)
		if okP then
			mpB.Anchored = true
			mpB.CFrame = base * CFrame.new(-5, 0, 0) * CFrame.new(centreB)
			if okI then
				mpB.TextureContent = contenuImage
			end
			mpB.Parent = workspace
			emB:Destroy()
			local libres = {}
			for k = 1, 64 do
				local em = AssetService:CreateEditableMesh()
				if not em then
					break
				end
				libres[k] = em
			end
			noter("budgetMaillagesApresConversion", #libres)
			for _, em in ipairs(libres) do
				em:Destroy()
			end
		end
	end
end

---------------------------------------------------------------------------
-- 8. Robe complète : 6 pièces, chacune convertie puis libérée
---------------------------------------------------------------------------
t0 = os.clock()
local okRobe, erreurRobe = pcall(function()
	for k = 1, 6 do
		local img = AssetService:CreateEditableImage({ Size = Vector2.new(L, L) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(L, L), decouper(15 * k))
		local em = demiJupe(k % 2 == 0 and "devant" or "dos", true)
		local _, contenuM = AssetService:CreateDataModelContentAsync(Content.fromObject(em))
		local _, contenuI = AssetService:CreateDataModelContentAsync(Content.fromObject(img))
		local mp = AssetService:CreateMeshPartAsync(contenuM)
		mp.TextureContent = contenuI
		em:Destroy()
		img:Destroy()
	end
end)
noter("robe6PiecesConverties", okRobe and (math.floor((os.clock() - t0) * 1000) .. " ms") or ("ÉCHEC : " .. tostring(erreurRobe)))

---------------------------------------------------------------------------
-- 9. Budget : nombre d'images 256² créables avant refus
---------------------------------------------------------------------------
local reserve = {}
for k = 1, 512 do
	local ok, img = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(256, 256) })
	end)
	if not ok or not img then
		noter("budgetRefus", tostring(img))
		break
	end
	reserve[k] = img
end
noter("budgetImages256", ("%d (≈ %.0f Mo)"):format(#reserve, #reserve * 0.25))
for _, img in ipairs(reserve) do
	img:Destroy()
end
noter("memoireTotaleApresMo", math.floor(Stats:GetTotalMemoryUsageMb()))

afficher()
