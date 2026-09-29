# Cœur de l'atelier — Plan 1 : test de faisabilité et fondations

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Valider dans Roblox Studio (et sur téléphone) le rendu EditableImage / EditableMesh, puis écrire et tester toute la logique pure du sous-projet 1 : géométrie des pièces, catalogue, rouleau de découpe, notation, commandes et découpe des images de tissu.

**Architecture:** Le sous-projet 1 est découpé en 4 plans. Celui-ci (plan 1) couvre les étapes 1 et 2 de la spec (§8) : le test de faisabilité et les fondations. Les fondations sont 7 modules partagés dans `src/shared/`, sans aucune instance Roblox (seulement des tables, des nombres, des `buffer` et `Vector3`). Ils sont testés par la simulation existante (`tests/lancer.sh`), étendue pour charger tous les modules partagés et exécuter des fichiers de tests unitaires. Les plans 2 (chaîne de rendu et vitrines), 3 (postes de jeu) et 4 (serveur, sauvegarde et finition) seront écrits après ce plan, avec les mesures du test de faisabilité.

**Tech Stack:** Luau (Roblox), Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`, Python 3), Roblox Studio piloté par le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`

## Global Constraints

- Dépôt `C:\dev\jeux\atelier-couture`, branche `refonte-dressmaker`. Ne rien pousser sur GitHub sans demande.
- Rojo : `C:/dev/jeux/roblox-maker/rojo.exe` (7.7.0-rc.1), il n'est pas dans le PATH.
- Unité de longueur : le décimètre (dm). Rouleau de 14 dm de large, pli à x = 7 dm, 32 px par dm, motif de 256 × 256 px (8 dm).
- Repère du corps : origine au centre de la taille, Y vers le haut, devant vers −Z, droite du personnage vers +X.
- Valeur de couture 0,15 dm ; mesure d'écart tous les 0,1 dm ; aimantation du droit-fil à 6° ; assistance couture plafonnée à 0,85.
- Droit-fil : 100 % à 0°, 60 % à 45°, 75 % à 90° (pièce normale) ; 100 % à 45° et 135°, 70 % à 0° et 90° (pièce en biais) ; interpolation linéaire.
- Couture : `clamp(1 − (|écart| − 0,05) / 0,25, 0, 1)` par mesure, moyenne des mesures.
- Style : `clamp(1·Σ variantes + 2·Σ(tissu × part de surface) + 0,5·Σ accessoires, 0, 100)` ; une garniture compte par tranche de 5 dm entamée.
- Paie : `base = 20 + 10 × pièces + 15 × exigences` ; paie = `floor(base × (0,5 + qualité) + 0,5)`.
- Une robe compte 4 à 6 pièces à poser.
- Les modules partagés n'utilisent aucune instance Roblox. Ils se chargent entre eux par `require(script.Parent:WaitForChild("Nom"))`.
- Style du code : français, tabulations, commentaires courts en français comme dans `src/`.
- L'ancien jeu (`CoutureData`, `Rendu3D`, `AtelierClient`, `AtelierServer`) reste en place et son scénario doit rester vert (`TOUT EST VERT : 181072 vérifications`) jusqu'au plan 3.
- Fins de ligne LF : ne jamais réécrire un fichier en CRLF.
- Commits en français, terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- Nombres non finis (NaN, ±inf) venus d'un client dans un angle ou un écart de couture : la note doit valoir 0 et jamais NaN ni 100 % (tests dans la tâche 7).
- Croquis incomplet ou mal formé (famille manquante, variante d'une autre famille, pas une table) : erreur franche que le serveur pourra intercepter par `pcall` (tests dans la tâche 5).
- Rouleau trop court ou de longueur nulle : toute pièce est refusée sans erreur Lua (test dans la tâche 6).
- Recette qui cite un tissu ou un accessoire inconnu : erreur franche plutôt qu'un calcul silencieux (tests dans la tâche 7).
- Garniture réduite à un seul point : longueur nulle, aucun point de style, pas d'erreur (test dans la tâche 7).

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `spike/default.project.json`, `spike/Spike.client.luau`, `spike/.gitignore` | Test de faisabilité jetable (lieu Studio séparé) |
| `docs/superpowers/spikes/2026-09-28-rendu-editable.md` | Mesures et décisions du test de faisabilité |
| `tests/build.py` (modifié) | Charge automatiquement tous les modules de `src/shared/` et exécute `tests/unitaires/*.luau` avant le scénario |
| `tests/unitaires/00_outillage.luau` … `07_pixels.luau` | Tests unitaires, un fichier par module |
| `src/shared/Polygone.luau` | Géométrie 2D : aire, boîte, point dedans, étendue d'une ligne, pose (translation + rotation), miroir, arête décalée |
| `src/shared/Catalogue.luau` | Données : constantes, pièces de patron, variantes, tissus, matières, accessoires |
| `src/shared/Patron.luau` | Pièces d'un croquis, copies, surface, trajet de couture, coordonnées (u, v), enroulement 3D |
| `src/shared/Coupon.luau` | Rouleau de découpe : pose, chevauchement (grille de 0,1 dm), pli, longueur consommée |
| `src/shared/Notation.luau` | Droit-fil, aimantation, couture, qualité, styles, fourchette du carnet, bilan, exigences, paie |
| `src/shared/Commandes.luau` | Génération de commandes réalisables et recherche d'une robe témoin |
| `src/shared/Pixels.luau` | Motifs de tissu en buffer RVBA et image exacte d'une pièce découpée |
| `README.md` (modifié) | Section « Refonte en cours » |

Commande de test (depuis la racine du dépôt) : `bash tests/lancer.sh`. La sortie affiche `Unitaires : N vérifications`, puis la fin du scénario de l'ancien jeu, `TOUT EST VERT : 181072 vérifications`. Une vérification ratée arrête l'exécution avec `ÉCHEC : <message>`.

---

### Task 1: Test de faisabilité du rendu Editable (spike)

Ce test n'est pas du TDD : il mesure le comportement réel de Roblox. Son produit est un rapport chiffré et des décisions. Le code est jetable.

**Files:**
- Create: `spike/default.project.json`
- Create: `spike/Spike.client.luau`
- Create: `spike/.gitignore`
- Create: `docs/superpowers/spikes/2026-09-28-rendu-editable.md`

**Interfaces:**
- Consumes: rien.
- Produces: le rapport `docs/superpowers/spikes/2026-09-28-rendu-editable.md`, lu par l'auteur du plan 2. Aucun code réutilisé.

- [ ] **Step 1: Créer le projet Rojo du spike**

`spike/default.project.json` :

```json
{
  "name": "spike-rendu-editable",
  "tree": {
    "$className": "DataModel",
    "Workspace": {
      "Baseplate": {
        "$className": "Part",
        "$properties": {
          "Anchored": true,
          "Size": [128, 2, 128],
          "CFrame": [0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1],
          "Color": [0.388, 0.373, 0.384]
        }
      },
      "SpawnLocation": {
        "$className": "SpawnLocation",
        "$properties": {
          "Anchored": true,
          "Size": [6, 1, 6],
          "CFrame": [0, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]
        }
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Spike": {
          "$path": "Spike.client.luau"
        }
      }
    }
  }
}
```

`spike/.gitignore` :

```
*.rbxl
*.lock
```

- [ ] **Step 2: Écrire le script du spike**

`spike/Spike.client.luau` :

```lua
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
-- 5. MeshPart, TextureContent et SurfaceAppearance
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
			-- Copie décalée de 5 studs avec une SurfaceAppearance à la place de TextureContent
			essayer("SurfaceAppearance.ColorMapContent_" .. cote, function()
				local copie = mp:Clone()
				copie.TextureContent = Content.none
				copie.CFrame = base * CFrame.new(5, 0, 0) * CFrame.new(centre)
				local sa = Instance.new("SurfaceAppearance")
				sa.ColorMapContent = Content.fromObject(image)
				sa.Parent = copie
				copie.Parent = workspace
			end)
		end
	end
end
noter("jupeComplete2PiecesMs", math.floor((os.clock() - t0) * 1000))

---------------------------------------------------------------------------
-- 6. Robe complète simulée : 6 images 192² + 6 maillages
---------------------------------------------------------------------------
t0 = os.clock()
local images = {}
for k = 1, 6 do
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(L, L) })
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(L, L), decouper(15 * k))
	table.insert(images, img)
	demiJupe(k % 2 == 0 and "devant" or "dos", true)
end
noter("robe6PiecesMs", math.floor((os.clock() - t0) * 1000))

---------------------------------------------------------------------------
-- 7. Conversion en contenu statique
---------------------------------------------------------------------------
essayer("CreateDataModelContentAsync(image)", function()
	return AssetService:CreateDataModelContentAsync(Content.fromObject(image))
end)

---------------------------------------------------------------------------
-- 8. Budget : nombre d'images 256² créables avant refus
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
```

- [ ] **Step 3: Construire le lieu et vérifier la syntaxe**

Run: `C:/dev/jeux/roblox-maker/rojo.exe build spike/default.project.json -o spike/Spike.rbxl`
Expected: `Built project to spike/Spike.rbxl`

- [ ] **Step 4: Jouer dans Studio sur PC**

1. Ouvrir `spike/Spike.rbxl` dans Roblox Studio (`Start-Process` en PowerShell). Si Studio reste bloqué sur l'écran de démarrage, l'analyse HTTPS d'Avast doit être désactivée pour Studio (voir la spec, §10).
2. Avec le connecteur MCP Studio : `list_roblox_studios`, puis `start_stop_play` (is_start = true) sur l'instance `Spike.rbxl`.
3. Si le débogueur se met en pause sur une exception (fenêtre « Exception touchée »), cliquer sur « Reprendre les scripts ».
4. Lire les lignes `[Spike]` avec `get_console_output`.
5. Faire une capture d'écran de la jupe, à 10 studs devant le point d'apparition, et de sa copie avec SurfaceAppearance, 5 studs à droite.

Expected: une ligne `[Spike]` par mesure. Les API qui échouent affichent `ÉCHEC : <message>` au lieu d'arrêter le script (sauf l'échec de `CreateEditableImage`, qui arrête le test).

- [ ] **Step 5: Vérifier visuellement**

Noter pour le rapport :
- les deux moitiés (devant et dos) se rejoignent-elles sur les côtés ? Si elles sont décalées, `CreateMeshPartAsync` ne recentre pas le maillage comme supposé : noter l'écart observé ;
- l'imprimé est-il visible de l'extérieur et de l'intérieur (doublure) ?
- les bandes sombres du motif sont-elles inclinées à 45° (la découpe tournée apparaît bien sur la robe) ?
- la copie avec SurfaceAppearance est-elle texturée ? Comment rend-elle par rapport à `TextureContent` ?

- [ ] **Step 6: Mesures sur téléphone (fait par le commanditaire)**

Demander au commanditaire de :
1. publier `spike/Spike.rbxl` comme lieu **privé** avec un compte vérifié pour les API Editable ;
2. le lancer sur son téléphone ;
3. envoyer une capture du rapport affiché à gauche de l'écran.

S'il ne peut pas le faire maintenant, remplir la colonne « Téléphone » avec « non mesuré ». Les décisions ci-dessous s'appliquent alors aux valeurs PC divisées par 3 pour les temps et par 4 pour le budget.

- [ ] **Step 7: Écrire le rapport et les décisions**

`docs/superpowers/spikes/2026-09-28-rendu-editable.md`, avec les valeurs mesurées :

```markdown
# Spike — rendu EditableImage / EditableMesh (sous-projet 1, étape 1)

- Date : AAAA-MM-JJ
- Lieu : `spike/Spike.rbxl` (code jetable, `spike/Spike.client.luau`)

## Mesures

| Mesure | PC (Studio) | Téléphone |
|---|---|---|
| motif256Ms | | |
| decoupe192Ms | | |
| CreateEditableImage+WritePixelsBuffer | | |
| CreateEditableMesh_devant / _dos | | |
| CreateMeshPartAsync_devant / _dos | | |
| TextureContent | | |
| SurfaceAppearance.ColorMapContent | | |
| jupeComplete2PiecesMs | | |
| robe6PiecesMs | | |
| CreateDataModelContentAsync(image) | | |
| budgetImages256 (Mo) | | |
| memoireTotaleAvantMo / ApresMo | | |

## Observations visuelles

- Les moitiés devant et dos se rejoignent : oui / non (écart observé : …)
- Imprimé visible à l'extérieur et à l'intérieur (doublure) : …
- Bandes du motif inclinées à 45° : oui / non
- SurfaceAppearance comparée à TextureContent : …

## Mesures complémentaires

- Découpe réelle (`Pixels.imagePiece`, trapèze à 45°) dans Studio : … ms

## Décisions (règles fixées avant la mesure)

| Si… | Alors… | Décision retenue |
|---|---|---|
| `CreateEditableImage` ou `CreateEditableMesh` échoue dans Studio | Arrêter et revenir vers le commanditaire (repli : approche C, panneaux plats texturés) | |
| `SurfaceAppearance.ColorMapContent` échoue ou rend mal | Utiliser `MeshPart.TextureContent` et une `Material` proche (spec §5) | |
| Budget téléphone < 32 Mo (budgetImages256 × 0,25) | Plafond des pièces 256 → 192 px, vitrines 128 → 64 px | |
| `decoupe192Ms` téléphone > 30 ms | Passer à 24 px/dm et découper sur plusieurs images (`task.wait()` entre les pièces) | |
| `robe6PiecesMs` téléphone > 600 ms | Générer une pièce par image et afficher une animation de couture pendant la génération | |
| `CreateDataModelContentAsync` fonctionne | L'utiliser pour les robes finies (vitrines) | |
| `CreateDataModelContentAsync` échoue | Garder la régénération par chaque client (spec §5, par défaut) | |
| Les moitiés ne se rejoignent pas | Noter le comportement de pivot de `CreateMeshPartAsync` et le compenser au plan 2 | |
```

- [ ] **Step 8: Commit**

```bash
git add spike/default.project.json spike/Spike.client.luau spike/.gitignore docs/superpowers/spikes/2026-09-28-rendu-editable.md
git commit -m "Spike : faisabilité du rendu EditableImage/EditableMesh

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Outillage des tests unitaires

**Files:**
- Modify: `tests/build.py` (réécriture complète)
- Create: `tests/unitaires/00_outillage.luau`

**Interfaces:**
- Consumes: `tests/mock.luau` (`M.initialiser`, `M.nouvelleInstance`, `M.services`, `M.env`), inchangé.
- Produces, dans chaque fichier `tests/unitaires/*.luau` :
  - `U.verifier(condition: boolean, message: string)` : compte la vérification et arrête avec `ÉCHEC : message` si elle est fausse ;
  - `U.proche(a: number, b: number, tol: number?) -> boolean` (tolérance 1e-6 par défaut) ;
  - `U.module(nom: string) -> table` : charge `src/shared/<nom>.luau` comme un ModuleScript du dossier `ReplicatedStorage.Couture` ;
  - `NOMS_MODULES: {string}` : noms de tous les modules de `src/shared/` ;
  - `Random`, `Vector3`, `buffer` utilisables comme dans Roblox.

- [ ] **Step 1: Écrire le test de l'outillage**

`tests/unitaires/00_outillage.luau` :

```lua
-- Vérifie que l'outillage des tests unitaires charge bien les modules partagés
U.verifier(table.find(NOMS_MODULES, "CoutureData") ~= nil, "les modules de src/shared sont découverts")
U.verifier(U.module("CoutureData").LARGEUR_COUPON == 12, "U.module charge un module partagé")
```

- [ ] **Step 2: Vérifier qu'il n'est pas encore exécuté**

Run: `bash tests/lancer.sh 2>&1 | grep -c "Unitaires"`
Expected: `0` (l'ancien `build.py` ignore `tests/unitaires/`).

- [ ] **Step 3: Réécrire `tests/build.py`**

```python
import sys, glob, os
S, SRC = sys.argv[1], sys.argv[2]
ICI = os.path.dirname(os.path.abspath(__file__))
sim = S + "/sim/"
def lire(p): return open(p, encoding="utf-8").read()
def nom(chemin): return os.path.basename(chemin)[: -len(".luau")]
ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn =
	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir
"""
OUTILS_UNITAIRES = """local U = { compte = 0 }
function U.verifier(condition, message)
	U.compte += 1
	if not condition then
		error("ÉCHEC : " .. message, 2)
	end
end
function U.proche(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end
local dossierUnitaires
function U.module(nomModule)
	if not dossierUnitaires then
		M.initialiser()
		dossierUnitaires = M.nouvelleInstance("Folder")
		dossierUnitaires.Name = "Couture"
		dossierUnitaires.Parent = M.services.ReplicatedStorage
		for _, n in ipairs(NOMS_MODULES) do
			local ms = M.nouvelleInstance("ModuleScript")
			ms.Name = n
			ms.Parent = dossierUnitaires
		end
	end
	return requireModule(dossierUnitaires[nomModule])
end
"""
out = []
out.append("local APIDB = (function()\n" + lire(sim + "apidb.luau") + "\nend)()")
out.append("local M = (function()\n" + lire(sim + "mock.luau") + "\nend)()")
out.append("local G = M.env")
out.append("local function avertir(...) table.insert(M.avertissements, table.concat({ ... }, ' ')) end")
out.append("local MODULES, cache, requireModule = {}, {}, nil")
out.append("""requireModule = function(ms)
	local nom = ms.Name
	if cache[nom] == nil then
		cache[nom] = MODULES[nom](ms)
	end
	return cache[nom]
end""")
# Tous les modules partagés sont chargés automatiquement
modules = sorted(glob.glob(SRC + "/shared/*.luau"))
for chemin in modules:
    out.append(f"MODULES[\"{nom(chemin)}\"] = function(script)\n" + ENTETE + lire(chemin) + "\nend")
out.append("local NOMS_MODULES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules) + " }")
out.append("local SCRIPTS = {}")
for nomScript, chemin in [("AtelierServer", "server/AtelierServer.server.luau"),
                          ("AtelierClient", "client/AtelierClient.client.luau")]:
    out.append(f"SCRIPTS[\"{nomScript}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
# Tests unitaires (tests/unitaires/*.luau), exécutés avant le scénario
out.append(OUTILS_UNITAIRES)
for f in sorted(glob.glob(ICI + "/unitaires/*.luau")):
    out.append("do\n" + ENTETE + lire(f) + "\nend")
out.append("print((\"Unitaires : %d vérifications\"):format(U.compte))")
out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 2 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add tests/build.py tests/unitaires/00_outillage.luau
git commit -m "Tests : charge tous les modules partagés et exécute les tests unitaires

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Module `Polygone` (géométrie 2D)

**Files:**
- Create: `src/shared/Polygone.luau`
- Test: `tests/unitaires/01_polygone.luau`

**Interfaces:**
- Consumes: rien.
- Produces (point = `{ x: number, y: number }` en dm, y vers le bas) :
  - `Polygone.aireSignee(points) -> number`, `Polygone.aire(points) -> number`
  - `Polygone.boite(points) -> { minX, minY, maxX, maxY }`, `Polygone.centre(points) -> point` (centre de la boîte)
  - `Polygone.contient(points, x, y) -> boolean`
  - `Polygone.etendueLigne(points, y) -> (xmin: number?, xmax: number?)`
  - `Polygone.poserPoint(p, placement, centre) -> point` et `Polygone.poser(points, placement, centre) -> points`, avec placement = `{ x, y, angle }` (degrés). Le centre va en (x, y), puis la pièce tourne : x' = c·dx − s·dy, y' = s·dx + c·dy.
  - `Polygone.miroir(points, axe) -> points` (symétrie par rapport à x = axe)
  - `Polygone.areteDecalee(points, i, d) -> { a: point, b: point }` : arête i décalée de d vers l'intérieur
  - `Polygone.longueur(segment) -> number`

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/01_polygone.luau` :

```lua
local Polygone = U.module("Polygone")

local carre = { { x = 0, y = 0 }, { x = 4, y = 0 }, { x = 4, y = 2 }, { x = 0, y = 2 } }
local trapeze = { { x = 1, y = 0 }, { x = 5, y = 0 }, { x = 6, y = 6 }, { x = 0, y = 6 } }

-- Aire et boîte
U.verifier(U.proche(Polygone.aire(carre), 8), "aire d'un rectangle 4 × 2")
U.verifier(U.proche(Polygone.aire(trapeze), 30), "aire du trapèze (4 + 6) / 2 × 6")
local b = Polygone.boite(trapeze)
U.verifier(b.minX == 0 and b.maxX == 6 and b.minY == 0 and b.maxY == 6, "boîte englobante")

-- Point dans le polygone
U.verifier(Polygone.contient(carre, 2, 1), "le centre est dedans")
U.verifier(not Polygone.contient(carre, 5, 1), "un point à droite est dehors")
U.verifier(not Polygone.contient(trapeze, 0.2, 0.5), "le coin coupé du trapèze est dehors")

-- Étendue d'une ligne
local x0, x1 = Polygone.etendueLigne(trapeze, 3)
U.verifier(U.proche(x0, 0.5) and U.proche(x1, 5.5), "étendue du trapèze à mi-hauteur")
U.verifier(Polygone.etendueLigne(carre, 5) == nil, "ligne hors du polygone")
local v = { { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 2 }, { x = 3, y = 0 }, { x = 4, y = 0 }, { x = 4, y = 4 }, { x = 0, y = 4 } }
local a0, a1 = Polygone.etendueLigne(v, 1)
U.verifier(U.proche(a0, 0) and U.proche(a1, 4), "une encoche en V ne réduit pas l'étendue extérieure")

-- Pose : translation et rotation autour du centre
local centre = Polygone.centre(carre)
local pose = Polygone.poser(carre, { x = 10, y = 20, angle = 90 }, centre)
local p = pose[1] -- (0,0) : décalage (−2, −1) → tourné de 90° → (1, −2)
U.verifier(U.proche(p.x, 11) and U.proche(p.y, 18), "rotation de 90° : (0,0) va en (11, 18)")
U.verifier(U.proche(Polygone.aire(pose), 8), "la pose conserve l'aire")

-- Miroir
local m = Polygone.miroir(carre, 7)
local bm = Polygone.boite(m)
U.verifier(U.proche(bm.minX, 10) and U.proche(bm.maxX, 14), "miroir par rapport à x = 7")
U.verifier(U.proche(Polygone.aire(m), 8), "le miroir conserve l'aire")

-- Arête décalée vers l'intérieur, dans les deux sens de parcours
local haut = Polygone.areteDecalee(carre, 1, 0.15)
U.verifier(U.proche(haut.a.y, 0.15) and U.proche(haut.b.y, 0.15), "arête du haut décalée vers le bas (intérieur)")
local inverse = { carre[4], carre[3], carre[2], carre[1] }
local bas = Polygone.areteDecalee(inverse, 1, 0.15) -- (0,2) → (4,2)
U.verifier(U.proche(bas.a.y, 1.85), "sens inverse : arête du bas décalée vers le haut")
U.verifier(U.proche(Polygone.longueur(haut), 4), "longueur d'un segment")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Polygone` (le module n'existe pas).

- [ ] **Step 3: Écrire le module**

`src/shared/Polygone.luau` :

```lua
-- Polygone : géométrie 2D des pièces de patron.
-- Un polygone est une liste de points { x = number, y = number } en décimètres
-- (x vers la droite, y vers le bas, comme sur la table de découpe).
local Polygone = {}

-- Aire signée (formule du lacet) : son signe dépend du sens de parcours
function Polygone.aireSignee(points)
	local s = 0
	for i, a in ipairs(points) do
		local b = points[i % #points + 1]
		s += a.x * b.y - b.x * a.y
	end
	return s / 2
end

function Polygone.aire(points)
	return math.abs(Polygone.aireSignee(points))
end

function Polygone.boite(points)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, p in ipairs(points) do
		minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
		minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
	end
	return { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

function Polygone.centre(points)
	local b = Polygone.boite(points)
	return { x = (b.minX + b.maxX) / 2, y = (b.minY + b.maxY) / 2 }
end

-- Point dans le polygone (règle pair-impair)
function Polygone.contient(points, x, y)
	local dedans = false
	local n = #points
	local j = n
	for i = 1, n do
		local a, b = points[i], points[j]
		if (a.y > y) ~= (b.y > y) then
			local xi = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)
			if x < xi then
				dedans = not dedans
			end
		end
		j = i
	end
	return dedans
end

-- Extrémités gauche et droite du contour sur la ligne horizontale y (nil si la ligne ne coupe pas)
function Polygone.etendueLigne(points, y)
	local xmin, xmax = math.huge, -math.huge
	local n = #points
	for i = 1, n do
		local a, b = points[i], points[i % n + 1]
		if y >= math.min(a.y, b.y) and y <= math.max(a.y, b.y) then
			if a.y == b.y then
				xmin, xmax = math.min(xmin, a.x, b.x), math.max(xmax, a.x, b.x)
			else
				local x = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)
				xmin, xmax = math.min(xmin, x), math.max(xmax, x)
			end
		end
	end
	if xmin > xmax then
		return nil, nil
	end
	return xmin, xmax
end

-- Pose d'une pièce : le point « centre » du patron va en (placement.x, placement.y),
-- puis la pièce tourne de placement.angle degrés autour de ce point.
-- Rotation : x' = c·dx − s·dy, y' = s·dx + c·dy (sens horaire à l'écran, y vers le bas).
function Polygone.poserPoint(p, placement, centre)
	local a = math.rad(placement.angle or 0)
	local c, s = math.cos(a), math.sin(a)
	local dx, dy = p.x - centre.x, p.y - centre.y
	return { x = placement.x + c * dx - s * dy, y = placement.y + s * dx + c * dy }
end

function Polygone.poser(points, placement, centre)
	local out = {}
	for i, p in ipairs(points) do
		out[i] = Polygone.poserPoint(p, placement, centre)
	end
	return out
end

-- Symétrique par rapport à la droite verticale x = axe (sens de parcours inversé)
function Polygone.miroir(points, axe)
	local out = {}
	for i = #points, 1, -1 do
		local p = points[i]
		table.insert(out, { x = 2 * axe - p.x, y = p.y })
	end
	return out
end

-- Arête i (du point i au point i+1) décalée de d vers l'intérieur : { a = point, b = point }
function Polygone.areteDecalee(points, i, d)
	local a, b = points[i], points[i % #points + 1]
	local dx, dy = b.x - a.x, b.y - a.y
	local longueur = math.sqrt(dx * dx + dy * dy)
	-- Normale à gauche du parcours ; l'intérieur est à gauche si l'aire signée est positive
	local signe = Polygone.aireSignee(points) > 0 and 1 or -1
	local nx, ny = -dy / longueur * signe, dx / longueur * signe
	return {
		a = { x = a.x + nx * d, y = a.y + ny * d },
		b = { x = b.x + nx * d, y = b.y + ny * d },
	}
end

function Polygone.longueur(segment)
	local dx, dy = segment.b.x - segment.a.x, segment.b.y - segment.a.y
	return math.sqrt(dx * dx + dy * dy)
end

return Polygone
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 18 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Polygone.luau tests/unitaires/01_polygone.luau
git commit -m "Ajoute Polygone : géométrie 2D des pièces de patron

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Module `Catalogue` (données)

**Files:**
- Create: `src/shared/Catalogue.luau`
- Test: `tests/unitaires/02_catalogue.luau`

**Interfaces:**
- Consumes: `Polygone` (dans les tests uniquement).
- Produces :
  - constantes `LARGEUR_ROULEAU = 14`, `PLI = 7`, `PX_PAR_DM = 32`, `TAILLE_MOTIF = 256`, `VALEUR_COUTURE = 0.15`, `PAS_MESURE_COUTURE = 0.1`, `K = { pieces = 1, tissu = 2, accessoires = 0.5 }`, `PLAFOND_ASSISTANCE = 0.85` ;
  - `STYLES: {string}`, `NOMS_STYLES`, `TEINTES: {string}`, `TAILLES = { S|M|L = { poitrine, taille, hanches } }`, `FAMILLES = { "corsage", "manches", "col", "jupe" }` ;
  - `Pieces[id] = { nom, contour, coutures: {int}, enroulement = { type, cote?, evasement?, fronces?, bouffant?, forme? }, pliee?, biais? }` ;
  - `Variantes = { { id, famille, nom, pieces: {idPiece}, style } }`, `Tissus = { { id, nom, matiere, teinte, prix, motif = { type, couleurs, periode?, largeur?, rayon? }, style } }`, `MATIERES[matiere] = { rugosite, reflet }`, `Accessoires = { { id, nom, genre = "objet"|"garniture", prix, style } }` ;
  - accès : `Catalogue.piece(id)`, `Catalogue.variante(id)`, `Catalogue.tissu(id)`, `Catalogue.accessoire(id)` (nil si inconnu), `Catalogue.variantesDe(famille) -> {variante}`.

- [ ] **Step 1: Écrire les tests d'intégrité**

`tests/unitaires/02_catalogue.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")

local styles = {}
for _, s in ipairs(Catalogue.STYLES) do
	styles[s] = true
end
local function stylesValides(t, ou)
	for cle, valeur in pairs(t) do
		U.verifier(styles[cle] == true, ou .. " : style inconnu " .. tostring(cle))
		U.verifier(type(valeur) == "number", ou .. " : points non numériques")
	end
end

-- Pièces
for id, piece in pairs(Catalogue.Pieces) do
	U.verifier(#piece.contour >= 3 and Polygone.aire(piece.contour) > 0.5, id .. " : contour valide")
	local b = Polygone.boite(piece.contour)
	U.verifier(U.proche(b.minX, 0) and U.proche(b.minY, 0), id .. " : contour calé en (0, 0)")
	local largeurMax = piece.pliee and Catalogue.PLI or Catalogue.LARGEUR_ROULEAU
	U.verifier(b.maxX <= largeurMax and b.maxY <= largeurMax, id .. " : tient dans le rouleau (ou sa moitié si pliée)")
	U.verifier(#piece.coutures >= 1, id .. " : au moins une couture")
	for _, i in ipairs(piece.coutures) do
		U.verifier(i >= 1 and i <= #piece.contour, id .. " : indice de couture valide")
	end
	local e = piece.enroulement
	U.verifier(e.type == "corsage" or e.type == "jupe" or e.type == "manche" or e.type == "col", id .. " : enroulement connu")
	if e.type == "corsage" or e.type == "jupe" then
		U.verifier(e.cote == "devant" or e.cote == "dos", id .. " : côté devant ou dos")
		U.verifier(not piece.pliee, id .. " : devant/dos ne sont pas coupés pliés")
	else
		U.verifier(piece.pliee == true, id .. " : manches et cols se coupent pliés")
	end
end

-- Variantes
local ids = {}
for _, v in ipairs(Catalogue.Variantes) do
	U.verifier(not ids[v.id], "variante en double : " .. v.id)
	ids[v.id] = true
	U.verifier(table.find(Catalogue.FAMILLES, v.famille) ~= nil, v.id .. " : famille connue")
	for _, p in ipairs(v.pieces) do
		U.verifier(Catalogue.piece(p) ~= nil, v.id .. " : pièce " .. p .. " définie")
	end
	stylesValides(v.style, v.id)
end
-- Corsage : un devant et un dos de même hauteur (les coutures de côté se rejoignent)
for _, v in ipairs(Catalogue.variantesDe("corsage")) do
	local h1 = Polygone.boite(Catalogue.piece(v.pieces[1]).contour).maxY
	local h2 = Polygone.boite(Catalogue.piece(v.pieces[2]).contour).maxY
	U.verifier(U.proche(h1, h2), v.id .. " : devant et dos de même hauteur")
end
-- Chaque robe possible compte 4 à 6 pièces à poser
local minimum, maximum = math.huge, 0
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local n = #c.pieces + #m.pieces + #k.pieces + #j.pieces
				minimum, maximum = math.min(minimum, n), math.max(maximum, n)
			end
		end
	end
end
U.verifier(minimum == 4 and maximum == 6, ("4 à 6 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))

-- Tissus
local teintes = {}
for _, t in ipairs(Catalogue.TEINTES) do
	teintes[t] = true
end
local vus = {}
U.verifier(#Catalogue.Tissus == 24, "24 tissus")
for _, t in ipairs(Catalogue.Tissus) do
	U.verifier(not vus[t.id], "tissu en double : " .. t.id)
	vus[t.id] = true
	U.verifier(teintes[t.teinte] == true, t.id .. " : teinte connue")
	U.verifier(t.prix >= 4 and t.prix <= 20, t.id .. " : prix entre 4 et 20")
	U.verifier(Catalogue.MATIERES[t.matiere] ~= nil, t.id .. " : matière connue")
	stylesValides(t.style, t.id)
	for _, c in ipairs(t.motif.couleurs) do
		U.verifier(#c == 3 and c[1] >= 0 and c[1] <= 255 and c[2] >= 0 and c[2] <= 255 and c[3] >= 0 and c[3] <= 255,
			t.id .. " : couleur RVB valide")
	end
	if t.motif.periode then
		local px = t.motif.periode * Catalogue.PX_PAR_DM
		U.verifier(px == math.floor(px) and Catalogue.TAILLE_MOTIF % px == 0, t.id .. " : période qui divise le motif (raccord)")
	end
end

-- Accessoires
U.verifier(#Catalogue.Accessoires == 15, "15 accessoires")
for _, a in ipairs(Catalogue.Accessoires) do
	U.verifier(a.genre == "objet" or a.genre == "garniture", a.id .. " : genre connu")
	U.verifier(a.prix > 0, a.id .. " : prix positif")
	stylesValides(a.style, a.id)
end
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Catalogue`.

- [ ] **Step 3: Écrire le catalogue**

`src/shared/Catalogue.luau` :

```lua
-- Catalogue : données du jeu (pièces de patron, variantes, tissus, accessoires, constantes).
-- Données seulement : aucune logique ici. Longueurs en décimètres (dm).
local Catalogue = {}

---------------------------------------------------------------------------
-- Constantes
---------------------------------------------------------------------------
Catalogue.LARGEUR_ROULEAU = 14 -- 140 cm
Catalogue.PLI = 7 -- pli au milieu du rouleau pour les pièces coupées pliées
Catalogue.PX_PAR_DM = 32
Catalogue.TAILLE_MOTIF = 256 -- pixels, soit 8 dm de tissu
Catalogue.VALEUR_COUTURE = 0.15 -- décalage du trajet de couture vers l'intérieur
Catalogue.PAS_MESURE_COUTURE = 0.1 -- une mesure d'écart tous les 0,1 dm de trajet
Catalogue.K = { pieces = 1, tissu = 2, accessoires = 0.5 } -- poids des jauges de style
Catalogue.PLAFOND_ASSISTANCE = 0.85

Catalogue.STYLES = { "elegant", "mignon", "romantique", "gothique", "chic", "decontracte" }
Catalogue.NOMS_STYLES = {
	elegant = "Élégant",
	mignon = "Mignon",
	romantique = "Romantique",
	gothique = "Gothique",
	chic = "Chic",
	decontracte = "Décontracté",
}
Catalogue.TEINTES = { "rose", "rouge", "bleu", "vert", "jaune", "violet", "noir", "blanc", "brun" }

-- Mensurations (tours en dm) des tailles proposées par les clientes anonymes
Catalogue.TAILLES = {
	S = { poitrine = 8.2, taille = 6.4, hanches = 8.8 },
	M = { poitrine = 8.8, taille = 7.0, hanches = 9.4 },
	L = { poitrine = 9.6, taille = 7.8, hanches = 10.2 },
}

Catalogue.FAMILLES = { "corsage", "manches", "col", "jupe" }

---------------------------------------------------------------------------
-- Pièces de patron
-- contour : polygone (dm), y = 0 en haut de la pièce telle que dessinée
-- coutures : indices des arêtes à coudre (arête i = point i → point i+1)
-- enroulement : comment la pièce entoure le corps (voir Patron)
-- pliee : coupée dans le tissu plié → deux copies miroir (gauche, droite)
-- biais : prévue pour être coupée à 45°
---------------------------------------------------------------------------
local function rectangle(l, h)
	return { { x = 0, y = 0 }, { x = l, y = 0 }, { x = l, y = h }, { x = 0, y = h } }
end

local CORSAGE_V = {
	{ x = 0, y = 0 }, { x = 1.3, y = 0 }, { x = 2.4, y = 2.0 }, { x = 3.5, y = 0 },
	{ x = 4.8, y = 0 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 },
}
local CORSAGE_BRETELLES = {
	{ x = 0.6, y = 0 }, { x = 1.4, y = 0 }, { x = 1.6, y = 1.6 }, { x = 3.2, y = 1.6 }, { x = 3.4, y = 0 },
	{ x = 4.2, y = 0 }, { x = 4.8, y = 1.8 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 }, { x = 0, y = 1.8 },
}
local TRAPEZE = { { x = 1, y = 0 }, { x = 5, y = 0 }, { x = 6, y = 6 }, { x = 0, y = 6 } }
local EVASEE = { { x = 2.4, y = 0 }, { x = 6.4, y = 0 }, { x = 8.8, y = 9 }, { x = 0, y = 9 } }
local MANCHE_BALLON = {
	{ x = 0, y = 0.6 }, { x = 0.8, y = 0.1 }, { x = 1.6, y = 0 }, { x = 2.4, y = 0.1 },
	{ x = 3.2, y = 0.6 }, { x = 3.2, y = 1.8 }, { x = 0, y = 1.8 },
}
local MANCHE_LONGUE = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 2.8, y = 5.6 }, { x = 0.4, y = 5.6 } }
local COL_CLAUDINE = { { x = 0, y = 0 }, { x = 2, y = 0 }, { x = 2.4, y = 0.4 }, { x = 2.2, y = 1.2 }, { x = 1, y = 1.4 }, { x = 0, y = 1.2 } }

Catalogue.Pieces = {
	corsage_droit_devant = { nom = "Corsage devant", contour = rectangle(4.8, 4.2), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_droit_dos = { nom = "Corsage dos", contour = rectangle(4.8, 4.2), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "dos" } },
	corsage_v_devant = { nom = "Corsage devant (V)", contour = CORSAGE_V, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bretelles_devant = { nom = "Corsage devant (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bretelles_dos = { nom = "Corsage dos (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "dos" } },
	manche_ballon = { nom = "Manche ballon", contour = MANCHE_BALLON, coutures = { 1, 2, 3, 4, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0.25 } },
	manche_longue = { nom = "Manche longue", contour = MANCHE_LONGUE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	col_claudine = { nom = "Col Claudine", contour = COL_CLAUDINE, coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "claudine" } },
	col_montant = { nom = "Col montant", contour = rectangle(2, 0.6), coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "montant" } },
	jupe_droite_devant = { nom = "Jupe devant", contour = rectangle(5, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.03, fronces = 0 } },
	jupe_droite_dos = { nom = "Jupe dos", contour = rectangle(5, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.03, fronces = 0 } },
	jupe_trapeze_devant = { nom = "Jupe trapèze devant", contour = TRAPEZE, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.25, fronces = 0 } },
	jupe_trapeze_dos = { nom = "Jupe trapèze dos", contour = TRAPEZE, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.25, fronces = 0 } },
	jupe_ample_devant = { nom = "Jupe ample devant", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.3, fronces = 0.25 } },
	jupe_ample_dos = { nom = "Jupe ample dos", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.3, fronces = 0.25 } },
	jupe_evasee_devant = { nom = "Jupe évasée devant", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "devant", evasement = 0.45, fronces = 0 } },
	jupe_evasee_dos = { nom = "Jupe évasée dos", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "dos", evasement = 0.45, fronces = 0 } },
}

---------------------------------------------------------------------------
-- Variantes du carnet de croquis (points de style par variante)
---------------------------------------------------------------------------
Catalogue.Variantes = {
	{ id = "corsage_droit", famille = "corsage", nom = "Droit",
		pieces = { "corsage_droit_devant", "corsage_droit_dos" }, style = { chic = 6, decontracte = 6 } },
	{ id = "corsage_v", famille = "corsage", nom = "Décolleté en V",
		pieces = { "corsage_v_devant", "corsage_droit_dos" }, style = { elegant = 8, romantique = 4 } },
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 } },
	{ id = "manches_sans", famille = "manches", nom = "Sans manches", pieces = {}, style = { decontracte = 3 } },
	{ id = "manches_ballon", famille = "manches", nom = "Ballon", pieces = { "manche_ballon" },
		style = { mignon = 8, romantique = 4 } },
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 } },
	{ id = "col_sans", famille = "col", nom = "Sans col", pieces = {}, style = {} },
	{ id = "col_claudine", famille = "col", nom = "Claudine", pieces = { "col_claudine" }, style = { mignon = 6, chic = 2 } },
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 } },
	{ id = "jupe_droite", famille = "jupe", nom = "Droite",
		pieces = { "jupe_droite_devant", "jupe_droite_dos" }, style = { chic = 8 } },
	{ id = "jupe_trapeze", famille = "jupe", nom = "Trapèze",
		pieces = { "jupe_trapeze_devant", "jupe_trapeze_dos" }, style = { decontracte = 5, mignon = 4 } },
	{ id = "jupe_ample", famille = "jupe", nom = "Ample froncée",
		pieces = { "jupe_ample_devant", "jupe_ample_dos" }, style = { romantique = 8, mignon = 4 } },
	{ id = "jupe_evasee", famille = "jupe", nom = "Longue évasée",
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 } },
}

---------------------------------------------------------------------------
-- Tissus (prix pour 1 m = 10 dm). motif.periode en dm, doit diviser 8 dm (taille du motif).
-- Couleurs : { rouge, vert, bleu } de 0 à 255.
---------------------------------------------------------------------------
local function tissu(id, nom, matiere, teinte, prix, motif, style)
	return { id = id, nom = nom, matiere = matiere, teinte = teinte, prix = prix, motif = motif, style = style }
end
local BLANC, NOIR = { 246, 242, 234 }, { 34, 30, 38 }

Catalogue.Tissus = {
	tissu("coton_blanc", "Coton blanc", "coton", "blanc", 4, { type = "uni", couleurs = { BLANC } },
		{ decontracte = 10, mignon = 4 }),
	tissu("coton_rose_pois", "Coton rose à pois", "coton", "rose", 6,
		{ type = "pois", couleurs = { { 240, 160, 190 }, BLANC }, periode = 1, rayon = 0.2 }, { mignon = 16, decontracte = 6 }),
	tissu("coton_bleu_carreaux", "Vichy bleu", "coton", "bleu", 6,
		{ type = "carreaux", couleurs = { BLANC, { 90, 130, 200 } }, periode = 0.5 }, { decontracte = 14, mignon = 4 }),
	tissu("coton_jaune_fleurs", "Coton jaune fleuri", "coton", "jaune", 7,
		{ type = "fleurs", couleurs = { { 240, 206, 90 }, BLANC, { 230, 120, 60 } }, periode = 2 }, { mignon = 12, romantique = 8 }),
	tissu("lin_naturel", "Lin naturel", "lin", "brun", 6, { type = "uni", couleurs = { { 200, 180, 150 } } },
		{ decontracte = 16, chic = 4 }),
	tissu("lin_vert_rayures", "Lin rayé vert", "lin", "vert", 7,
		{ type = "rayures", couleurs = { { 226, 234, 214 }, { 90, 140, 90 } }, periode = 1, largeur = 0.3 }, { decontracte = 12, chic = 6 }),
	tissu("lin_bleu", "Lin bleu", "lin", "bleu", 6, { type = "uni", couleurs = { { 110, 150, 200 } } },
		{ decontracte = 10, chic = 8 }),
	tissu("lin_noir", "Lin noir", "lin", "noir", 7, { type = "uni", couleurs = { NOIR } }, { chic = 10, gothique = 6 }),
	tissu("laine_brune_carreaux", "Tweed brun", "laine", "brun", 9,
		{ type = "carreaux", couleurs = { { 150, 110, 80 }, { 100, 70, 50 } }, periode = 1 }, { chic = 14, elegant = 4 }),
	tissu("laine_bordeaux", "Laine bordeaux", "laine", "rouge", 9, { type = "uni", couleurs = { { 120, 30, 50 } } },
		{ gothique = 10, chic = 8 }),
	tissu("laine_verte_carreaux", "Tartan vert", "laine", "vert", 9,
		{ type = "carreaux", couleurs = { { 40, 90, 60 }, { 20, 40, 70 } }, periode = 2 }, { decontracte = 8, chic = 10 }),
	tissu("laine_noire", "Laine noire", "laine", "noir", 8, { type = "uni", couleurs = { NOIR } }, { gothique = 12, chic = 8 }),
	tissu("soie_rose_fleurs", "Soie rose fleurie", "soie", "rose", 16,
		{ type = "fleurs", couleurs = { { 214, 84, 146 }, { 255, 200, 225 }, { 255, 230, 120 } }, periode = 2 },
		{ romantique = 20, elegant = 10 }),
	tissu("soie_ivoire", "Soie ivoire", "soie", "blanc", 15, { type = "uni", couleurs = { { 250, 244, 226 } } },
		{ elegant = 20, romantique = 8 }),
	tissu("soie_bleue_degrade", "Soie bleue dégradée", "soie", "bleu", 17,
		{ type = "degrade", couleurs = { { 40, 70, 160 }, { 160, 200, 240 } } }, { elegant = 16, romantique = 6 }),
	tissu("soie_rouge", "Soie rouge", "soie", "rouge", 16, { type = "uni", couleurs = { { 200, 30, 50 } } },
		{ romantique = 16, elegant = 12 }),
	tissu("velours_violet", "Velours violet", "velours", "violet", 14, { type = "uni", couleurs = { { 90, 40, 120 } } },
		{ gothique = 14, elegant = 12 }),
	tissu("velours_noir", "Velours noir", "velours", "noir", 14, { type = "uni", couleurs = { NOIR } },
		{ gothique = 22, elegant = 6 }),
	tissu("velours_vert", "Velours émeraude", "velours", "vert", 13, { type = "uni", couleurs = { { 20, 110, 80 } } },
		{ elegant = 12, chic = 8 }),
	tissu("velours_rouge", "Velours rubis", "velours", "rouge", 14, { type = "uni", couleurs = { { 150, 20, 40 } } },
		{ elegant = 12, romantique = 10, gothique = 4 }),
	tissu("satin_rose", "Satin rose", "satin", "rose", 12, { type = "uni", couleurs = { { 244, 170, 200 } } },
		{ romantique = 14, mignon = 10 }),
	tissu("satin_noir_rayures", "Satin noir rayé", "satin", "noir", 13,
		{ type = "rayures", couleurs = { NOIR, { 120, 110, 130 } }, periode = 0.5, largeur = 0.1 }, { gothique = 16, chic = 8 }),
	tissu("satin_or_degrade", "Satin or dégradé", "satin", "jaune", 18,
		{ type = "degrade", couleurs = { { 200, 150, 40 }, { 250, 230, 160 } } }, { elegant = 18, chic = 6 }),
	tissu("satin_violet_pois", "Satin violet à pois", "satin", "violet", 12,
		{ type = "pois", couleurs = { { 120, 70, 160 }, { 230, 210, 250 } }, periode = 0.5, rayon = 0.1 }, { mignon = 10, gothique = 8 }),
}

-- Rendu 3D par matière (utilisé au sous-projet de rendu)
Catalogue.MATIERES = {
	coton = { rugosite = 0.9, reflet = 0 },
	lin = { rugosite = 1, reflet = 0 },
	laine = { rugosite = 1, reflet = 0 },
	soie = { rugosite = 0.35, reflet = 0.1 },
	velours = { rugosite = 0.8, reflet = 0 },
	satin = { rugosite = 0.25, reflet = 0.15 },
}

---------------------------------------------------------------------------
-- Accessoires : objets (prix à l'unité) et garnitures (prix au dm, points par tranche de 5 dm)
---------------------------------------------------------------------------
local function objet(id, nom, prix, style)
	return { id = id, nom = nom, genre = "objet", prix = prix, style = style }
end
local function garniture(id, nom, prix, style)
	return { id = id, nom = nom, genre = "garniture", prix = prix, style = style }
end

Catalogue.Accessoires = {
	objet("bouton_nacre", "Bouton nacré", 1, { chic = 2, elegant = 1 }),
	objet("bouton_dore", "Bouton doré", 2, { elegant = 2, chic = 1 }),
	objet("noeud_satin", "Nœud de satin", 3, { mignon = 4, romantique = 2 }),
	objet("noeud_velours", "Nœud de velours", 4, { gothique = 3, elegant = 2 }),
	objet("fleur_rose", "Fleur rose", 3, { romantique = 4, mignon = 2 }),
	objet("fleur_blanche", "Fleur blanche", 3, { romantique = 3, elegant = 2 }),
	objet("broche_camee", "Broche camée", 8, { elegant = 5, gothique = 2 }),
	objet("perle", "Perle", 1, { elegant = 2, romantique = 1 }),
	objet("etoile_brodee", "Étoile brodée", 2, { mignon = 3 }),
	objet("croix_argent", "Croix d'argent", 5, { gothique = 5 }),
	garniture("dentelle_blanche", "Dentelle blanche", 2, { romantique = 3, elegant = 2 }),
	garniture("dentelle_noire", "Dentelle noire", 2, { gothique = 4, elegant = 1 }),
	garniture("ruban_rose", "Ruban rose", 1, { mignon = 3 }),
	garniture("galon_dore", "Galon doré", 3, { elegant = 3, chic = 2 }),
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }),
}

---------------------------------------------------------------------------
-- Accès par identifiant
---------------------------------------------------------------------------
local function index(liste)
	local t = {}
	for _, e in ipairs(liste) do
		t[e.id] = e
	end
	return t
end
local VARIANTES, TISSUS, ACCESSOIRES = index(Catalogue.Variantes), index(Catalogue.Tissus), index(Catalogue.Accessoires)

function Catalogue.piece(id)
	return Catalogue.Pieces[id]
end
function Catalogue.variante(id)
	return VARIANTES[id]
end
function Catalogue.tissu(id)
	return TISSUS[id]
end
function Catalogue.accessoire(id)
	return ACCESSOIRES[id]
end
function Catalogue.variantesDe(famille)
	local out = {}
	for _, v in ipairs(Catalogue.Variantes) do
		if v.famille == famille then
			table.insert(out, v)
		end
	end
	return out
end

return Catalogue
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 605 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau tests/unitaires/02_catalogue.luau
git commit -m "Ajoute le catalogue : pièces, variantes, tissus et accessoires

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Module `Patron` (pièces, couture, enroulement 3D)

**Files:**
- Create: `src/shared/Patron.luau`
- Test: `tests/unitaires/03_patron.luau`

**Interfaces:**
- Consumes: `Catalogue.piece`, `Catalogue.variante`, `Catalogue.FAMILLES`, `Catalogue.VALEUR_COUTURE` ; `Polygone.aire`, `boite`, `etendueLigne`, `areteDecalee`, `longueur`.
- Produces :
  - `Patron.def(id) -> pieceDef` (erreur si inconnue)
  - `Patron.copies(id) -> { "unique" } | { "gauche", "droite" }`
  - `Patron.aire(id) -> number` (dm², toutes copies)
  - `Patron.piecesDuCroquis(croquis) -> {idPiece}`, avec croquis = `{ corsage, manches, col, jupe }` (identifiants de variantes). Erreur si incomplet ou incohérent.
  - `Patron.trajetCouture(id) -> (segments: { {a, b} }, longueur: number)`
  - `Patron.uv(id, x, y) -> (u, v, boite)`
  - `Patron.point(id, copie, x, y, mesures) -> (position: Vector3, dehors: Vector3)`, en dm dans le repère du corps. La copie « gauche » est le miroir en X de la « droite ».

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/03_patron.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")

local function fini(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Pièces d'un croquis, dans l'ordre des familles
local liste = Patron.piecesDuCroquis({ corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_ample" })
U.verifier(#liste == 5 and liste[1] == "corsage_v_devant" and liste[2] == "corsage_droit_dos" and liste[3] == "manche_ballon"
	and liste[4] == "jupe_ample_devant" and liste[5] == "jupe_ample_dos", "pièces du croquis dans l'ordre des familles")
U.verifier(not pcall(Patron.piecesDuCroquis, { corsage = "jupe_droite", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }),
	"une variante de la mauvaise famille est refusée")
U.verifier(not pcall(Patron.piecesDuCroquis, { corsage = "corsage_droit", jupe = "jupe_droite" }), "un croquis incomplet est refusé")
U.verifier(not pcall(Patron.piecesDuCroquis, "texte"), "un croquis qui n'est pas une table est refusé")

-- Copies et surface
U.verifier(#Patron.copies("manche_ballon") == 2 and Patron.copies("jupe_droite_devant")[1] == "unique", "copies d'une pièce pliée")
U.verifier(U.proche(Patron.aire("manche_ballon"), 2 * Polygone.aire(Catalogue.piece("manche_ballon").contour)),
	"la surface d'une pièce pliée compte les deux copies")

-- Trajet de couture : côtés + taille d'un rectangle 4,8 × 4,2
local segments, longueur = Patron.trajetCouture("corsage_droit_devant")
U.verifier(#segments == 3 and U.proche(longueur, 4.2 + 4.8 + 4.2), "trajet de couture du corsage droit")
for _, s in ipairs(segments) do
	local milieu = { x = (s.a.x + s.b.x) / 2, y = (s.a.y + s.b.y) / 2 }
	U.verifier(Polygone.contient(Catalogue.piece("corsage_droit_devant").contour, milieu.x, milieu.y),
		"le trajet de couture est à l'intérieur de la pièce")
end

-- Coordonnées (u, v)
local u, v = Patron.uv("jupe_trapeze_devant", 1, 0)
U.verifier(U.proche(u, 0) and U.proche(v, 0), "coin haut gauche du trapèze : u = 0, v = 0")
u, v = Patron.uv("jupe_trapeze_devant", 6, 6)
U.verifier(U.proche(u, 1) and U.proche(v, 1), "coin bas droit du trapèze : u = 1, v = 1")

-- Toutes les pièces, toutes les copies, toutes les tailles : positions finies et direction unitaire
for id, def in pairs(Catalogue.Pieces) do
	local b = Polygone.boite(def.contour)
	for _, taille in pairs(Catalogue.TAILLES) do
		for _, copie in ipairs(Patron.copies(id)) do
			for i = 0, 8 do
				for j = 0, 8 do
					local x = b.minX + (b.maxX - b.minX) * i / 8
					local y = b.minY + (b.maxY - b.minY) * j / 8
					if Polygone.contient(def.contour, x, y) then
						local p, d = Patron.point(id, copie, x, y, taille)
						U.verifier(fini(p.X) and fini(p.Y) and fini(p.Z), id .. " : position finie")
						U.verifier(U.proche(d.Magnitude, 1, 1e-6), id .. " : direction extérieure unitaire")
						if copie == "droite" then
							U.verifier(p.X > -1e-6, id .. " : la copie droite est du côté +X")
						elseif copie == "gauche" then
							U.verifier(p.X < 1e-6, id .. " : la copie gauche est du côté −X")
						end
					end
				end
			end
		end
	end
end

-- Les coutures de côté du devant et du dos se rejoignent (écart < 0,05 dm)
local function bordsJoints(idDevant, idDos, mesures)
	local cD = Catalogue.piece(idDevant).contour
	local cA = Catalogue.piece(idDos).contour
	local b = Polygone.boite(cD)
	for k = 0, 10 do
		local y = b.minY + (b.maxY - b.minY) * k / 10
		local d0, d1 = Polygone.etendueLigne(cD, y)
		local a0, a1 = Polygone.etendueLigne(cA, y)
		local pD1 = Patron.point(idDevant, "unique", d1, y, mesures)
		local pA0 = Patron.point(idDos, "unique", a0, y, mesures)
		local pD0 = Patron.point(idDevant, "unique", d0, y, mesures)
		local pA1 = Patron.point(idDos, "unique", a1, y, mesures)
		if (pD1 - pA0).Magnitude > 0.05 or (pD0 - pA1).Magnitude > 0.05 then
			return false
		end
	end
	return true
end
for _, taille in pairs(Catalogue.TAILLES) do
	for _, j in ipairs(Catalogue.variantesDe("jupe")) do
		U.verifier(bordsJoints(j.pieces[1], j.pieces[2], taille), j.id .. " : coutures de côté jointives")
	end
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		U.verifier(bordsJoints(c.pieces[1], c.pieces[2], taille), c.id .. " : coutures de côté jointives")
	end
end

-- La jupe passe hors des jambes (cylindres de 0,6 dm de rayon à ±0,55 dm) sous la ligne des hanches
for _, taille in pairs(Catalogue.TAILLES) do
	for _, j in ipairs(Catalogue.variantesDe("jupe")) do
		for _, id in ipairs(j.pieces) do
			local def = Catalogue.piece(id)
			local b = Polygone.boite(def.contour)
			for k = 0, 20 do
				local y = b.minY + (b.maxY - b.minY) * k / 20
				local x0, x1 = Polygone.etendueLigne(def.contour, y)
				for l = 0, 10 do
					local p = Patron.point(id, "unique", x0 + (x1 - x0) * l / 10, y, taille)
					if p.Y <= -1.8 then
						local horizontale = math.sqrt(p.X * p.X + p.Z * p.Z)
						U.verifier(horizontale > 1.15, id .. " : la jupe ne traverse pas les jambes")
					end
				end
			end
		end
	end
end

-- La jupe recouvre le bas du corsage à la taille
local M = Catalogue.TAILLES.M
local pJupe = Patron.point("jupe_droite_devant", "unique", 2.5, 0, M)
local pCorsage = Patron.point("corsage_droit_devant", "unique", 2.4, 4.2, M)
U.verifier(U.proche(pJupe.Y, 0) and U.proche(pCorsage.Y, 0), "jupe et corsage se rejoignent à la taille")
U.verifier(pJupe.Magnitude > pCorsage.Magnitude, "la jupe passe par-dessus le corsage")

-- Les manches partent de l'épaule, au bord du corsage
local pManche = Patron.point("manche_longue", "droite", 1.6, 0, M)
U.verifier(pManche.Y > 3.5 and pManche.Y < 4.5, "le haut de la manche est à hauteur d'épaule")
local pManche2 = Patron.point("manche_longue", "gauche", 1.6, 0, M)
U.verifier(U.proche(pManche2.X, -pManche.X) and U.proche(pManche2.Y, pManche.Y), "la manche gauche est le miroir de la droite")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Patron`.

- [ ] **Step 3: Écrire le module**

`src/shared/Patron.luau` :

```lua
-- Patron : pièces à poser pour un croquis, trajets de couture, et enroulement 3D des pièces
-- autour du corps. Repère du corps (en dm) : origine au centre de la taille, Y vers le haut,
-- devant vers −Z, droite du personnage vers +X (comme un avatar Roblox).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Patron = {}

-- Ellipse du buste et des hanches : plus large que profonde
local EX, EZ = 1.12, 0.88
local LIGNE_HANCHES = 1.8 -- dm sous la taille
local LIGNE_POITRINE = 2.4 -- dm au-dessus de la taille
local HAUTEUR_EPAULE = 4.0
local HAUTEUR_COU, RAYON_COU = 4.3, 0.62
local INCLINAISON_BRAS = math.rad(12)

local function lisse(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Patron.def(id)
	local def = Catalogue.piece(id)
	assert(def, "pièce inconnue : " .. tostring(id))
	return def
end

-- Copies obtenues à la découpe : { "gauche", "droite" } si coupée pliée, sinon { "unique" }
function Patron.copies(id)
	return Patron.def(id).pliee and { "gauche", "droite" } or { "unique" }
end

-- Surface de tissu d'une pièce, toutes copies comprises (dm²)
function Patron.aire(id)
	local def = Patron.def(id)
	return Polygone.aire(def.contour) * #Patron.copies(id)
end

-- croquis = { corsage = idVariante, manches = …, col = …, jupe = … }
-- Retourne la liste ordonnée des identifiants de pièces à poser.
function Patron.piecesDuCroquis(croquis)
	local pieces = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local variante = Catalogue.variante(croquis[famille])
		assert(variante and variante.famille == famille, "variante invalide pour " .. famille)
		for _, id in ipairs(variante.pieces) do
			table.insert(pieces, id)
		end
	end
	return pieces
end

-- Trajet de couture : liste de segments { a, b } décalés de la valeur de couture, et sa longueur totale
function Patron.trajetCouture(id)
	local def = Patron.def(id)
	local segments, longueur = {}, 0
	for _, i in ipairs(def.coutures) do
		local s = Polygone.areteDecalee(def.contour, i, Catalogue.VALEUR_COUTURE)
		table.insert(segments, s)
		longueur += Polygone.longueur(s)
	end
	return segments, longueur
end

-- Coordonnées normalisées (u, v) d'un point du patron : v suit la hauteur de la pièce,
-- u va d'un bord à l'autre de la ligne (les bords de côté tombent toujours sur les coutures).
function Patron.uv(id, x, y)
	local def = Patron.def(id)
	local b = Polygone.boite(def.contour)
	local v = (y - b.minY) / (b.maxY - b.minY)
	local x0, x1 = Polygone.etendueLigne(def.contour, math.clamp(y, b.minY, b.maxY))
	local u = 0.5
	if x0 and x1 - x0 > 1e-9 then
		u = math.clamp((x - x0) / (x1 - x0), 0, 1)
	end
	return u, v, b
end

---------------------------------------------------------------------------
-- Enroulements : (u, v) → position et direction « vers l'extérieur »
---------------------------------------------------------------------------
local function angleCote(cote, u)
	-- Devant : de +X (u = 0) à −X (u = 1) en passant par −Z ; dos : de −X à +X par +Z.
	-- Les coutures de côté du devant et du dos tombent donc au même endroit.
	if cote == "devant" then
		return 2 * math.pi - u * math.pi
	end
	return math.pi - u * math.pi
end

local function jupe(e, u, v, hauteur, m)
	local yd = v * hauteur
	local rT = m.taille / (2 * math.pi) + 0.12
	local rH = m.hanches / (2 * math.pi) + 0.15
	local phi = angleCote(e.cote, u)
	local r = rT + (rH - rT) * lisse(yd / LIGNE_HANCHES) + e.evasement * math.max(0, yd - LIGNE_HANCHES)
	r += e.fronces * v * 0.5 * (0.5 + 0.5 * math.sin(phi * 16))
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), -yd, r * EZ * math.sin(phi)), dehors
end

local function corsage(e, u, v, hauteur, m)
	local h = (1 - v) * hauteur -- hauteur au-dessus de la taille
	local rT = m.taille / (2 * math.pi) + 0.08
	local rP = m.poitrine / (2 * math.pi) + 0.1
	local rE = rP * 0.92
	local r
	if h <= LIGNE_POITRINE then
		r = rT + (rP - rT) * lisse(h / LIGNE_POITRINE)
	else
		r = rP + (rE - rP) * lisse((h - LIGNE_POITRINE) / math.max(0.1, hauteur - LIGNE_POITRINE))
	end
	local phi = angleCote(e.cote, u)
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), h, r * EZ * math.sin(phi)), dehors
end

-- Manche droite (+X) ; la gauche est son symétrique
local function manche(e, u, v, hauteur, m)
	local epaule = Vector3.new((m.poitrine / (2 * math.pi) + 0.1) * EX + 0.35, HAUTEUR_EPAULE, 0)
	local axe = Vector3.new(math.sin(INCLINAISON_BRAS), -math.cos(INCLINAISON_BRAS), 0)
	local n1 = Vector3.new(0, 0, 1)
	local n2 = axe:Cross(n1).Unit
	local rayon = 0.55 - 0.12 * v + e.bouffant * math.sin(math.pi * v)
	local theta = 2 * math.pi * u
	local dehors = n1 * math.cos(theta) + n2 * math.sin(theta)
	return epaule + axe * (v * hauteur) + dehors * rayon, dehors
end

-- Col, moitié droite (+X) : du milieu devant (u = 0) au milieu dos (u = 1)
local function col(e, u, v, hauteur, _m)
	local phi = -math.pi / 2 + u * math.pi
	local rayon, y
	if e.forme == "claudine" then
		rayon, y = RAYON_COU + v * hauteur * 0.9, HAUTEUR_COU - v * hauteur * 0.35
	else
		rayon, y = RAYON_COU + 0.05, HAUTEUR_COU + v * hauteur
	end
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(rayon * math.cos(phi), y, rayon * math.sin(phi)), dehors
end

local ENROULEMENTS = { jupe = jupe, corsage = corsage, manche = manche, col = col }

-- Point du patron (x, y en dm) → position 3D (Vector3, dm) et direction extérieure (Vector3 unitaire).
-- copie : "unique", "gauche" ou "droite". mesures : { poitrine, taille, hanches }.
function Patron.point(id, copie, x, y, mesures)
	local def = Patron.def(id)
	local u, v, b = Patron.uv(id, x, y)
	local position, dehors = ENROULEMENTS[def.enroulement.type](def.enroulement, u, v, b.maxY - b.minY, mesures)
	if copie == "gauche" then
		position = Vector3.new(-position.X, position.Y, position.Z)
		dehors = Vector3.new(-dehors.X, dehors.Y, dehors.Z)
	end
	return position, dehors
end

return Patron
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 12948 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Patron.luau tests/unitaires/03_patron.luau
git commit -m "Ajoute Patron : pièces d'un croquis, trajets de couture et enroulement 3D

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Module `Coupon` (rouleau de découpe)

**Files:**
- Create: `src/shared/Coupon.luau`
- Test: `tests/unitaires/04_coupon.luau`

**Interfaces:**
- Consumes: `Catalogue.piece`, `LARGEUR_ROULEAU`, `PLI` ; `Polygone.poser`, `centre`, `miroir`, `boite`, `contient`.
- Produces :
  - `Coupon.nouveau(longueur: number) -> coupon`
  - `Coupon.contoursPoses(idPiece, placement) -> { contour, contourMiroir? }`
  - `coupon:verifier(idPiece, placement) -> (ok: boolean, erreur: string?, contours?, cases?)`. Messages d'erreur : `Pièce inconnue.`, `Cette pièce est déjà coupée.`, `Position invalide.`, `La pièce dépasse du tissu.`, `Une pièce pliée doit tenir d'un côté du pli.`, `La pièce chevauche une autre pièce.`
  - `coupon:poser(idPiece, placement) -> (ok, erreur?)` ; `coupon.poses[idPiece] = { x, y, angle }`
  - `coupon:longueurUtilisee() -> integer` (dm arrondis au-dessus)

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/04_coupon.luau` :

```lua
local Coupon = U.module("Coupon")

-- Une jupe droite (5 × 6) centrée en (2.5, 3) occupe [0, 5] × [0, 6]
local c = Coupon.nouveau(20)
U.verifier(c:poser("jupe_droite_devant", { x = 2.5, y = 3, angle = 0 }), "pose valide dans le coin")
U.verifier(c:longueurUtilisee() == 6, "6 dm consommés")

-- Chevauchement, sortie du rouleau, pièce déjà coupée
local ok, erreur = c:verifier("jupe_droite_dos", { x = 4, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("chevauche") ~= nil, "chevauchement refusé")
ok, erreur = c:verifier("jupe_droite_dos", { x = 12, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("dépasse") ~= nil, "sortie à droite du rouleau refusée")
ok = c:verifier("jupe_droite_dos", { x = 7.5, y = 18, angle = 0 })
U.verifier(not ok, "sortie en bas de la longueur déroulée refusée")
ok, erreur = c:verifier("jupe_droite_devant", { x = 8, y = 10, angle = 0 })
U.verifier(not ok and erreur:find("déjà") ~= nil, "une pièce ne se coupe qu'une fois")
U.verifier(c:poser("jupe_droite_dos", { x = 7.6, y = 3, angle = 0 }), "pièce voisine collée sans chevauchement")

-- Valeurs invalides (exploit)
for _, mauvais in ipairs({ { x = 0 / 0, y = 3, angle = 0 }, { x = math.huge, y = 3, angle = 0 }, { x = 3, y = 3 }, "texte" }) do
	U.verifier(not c:verifier("corsage_droit_dos", mauvais), "placement invalide refusé")
end
U.verifier(not c:verifier("inconnue", { x = 3, y = 12, angle = 0 }), "pièce inconnue refusée")

-- Rotation de 90° : la jupe 5 × 6 devient 6 × 5
local r = Coupon.nouveau(10)
U.verifier(r:poser("jupe_droite_devant", { x = 3, y = 2.5, angle = 90 }), "pièce tournée de 90° qui tient")
U.verifier(r:longueurUtilisee() == 5, "la rotation change la longueur consommée")

-- Pièce pliée : elle occupe aussi son symétrique de l'autre côté du pli (x = 7)
local p = Coupon.nouveau(10)
ok, erreur = p:verifier("manche_longue", { x = 8, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("pli") ~= nil, "une pièce pliée doit tenir d'un côté du pli")
U.verifier(p:poser("manche_longue", { x = 5, y = 3, angle = 0 }), "manche posée contre le pli")
ok, erreur = p:verifier("jupe_droite_devant", { x = 9.5, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("chevauche") ~= nil, "le symétrique de la manche occupe le tissu")

-- Tolérance aux arrondis : une pièce exactement au bord est acceptée
local e = Coupon.nouveau(6)
U.verifier(e:poser("jupe_droite_devant", { x = 11.5, y = 3, angle = 0 }), "pièce au ras du bord droit acceptée")

-- Rouleau vide : toute pièce est refusée
local vide = Coupon.nouveau(0)
U.verifier(not vide:verifier("col_montant", { x = 1, y = 0.3, angle = 0 }), "rouleau de longueur nulle : pièce refusée")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Coupon`.

- [ ] **Step 3: Écrire le module**

`src/shared/Coupon.luau` :

```lua
-- Coupon : un rouleau de tissu sur la table de découpe (14 dm de large, droit-fil le long de y).
-- Vérifie qu'une pièce posée tient dans le rouleau sans chevaucher les pièces déjà coupées.
-- Le chevauchement est détecté sur une grille de cases de 0,1 dm (le centre de chaque case).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Coupon = {}
Coupon.__index = Coupon

local PAS = 0.1
local EPSILON = 1e-6
local COLONNES = math.floor(Catalogue.LARGEUR_ROULEAU / PAS + 0.5)

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- longueur : longueur déroulée disponible (dm)
function Coupon.nouveau(longueur)
	return setmetatable({ longueur = longueur, cellules = {}, poses = {}, basMax = 0 }, Coupon)
end

-- Contours posés sur le rouleau : la pièce, et son symétrique par rapport au pli si elle est pliée.
-- placement = { x, y, angle } : le centre de la boîte du patron va en (x, y), puis rotation de angle degrés.
function Coupon.contoursPoses(idPiece, placement)
	local def = Catalogue.piece(idPiece)
	local pose = Polygone.poser(def.contour, placement, Polygone.centre(def.contour))
	if def.pliee then
		return { pose, Polygone.miroir(pose, Catalogue.PLI) }
	end
	return { pose }
end

local function cellulesDe(contour)
	local b = Polygone.boite(contour)
	local out = {}
	for colonne = math.max(0, math.floor(b.minX / PAS)), math.ceil(b.maxX / PAS) - 1 do
		for ligne = math.max(0, math.floor(b.minY / PAS)), math.ceil(b.maxY / PAS) - 1 do
			if Polygone.contient(contour, (colonne + 0.5) * PAS, (ligne + 0.5) * PAS) then
				table.insert(out, ligne * COLONNES + colonne)
			end
		end
	end
	return out
end

-- Retourne ok (bool), erreur (string?), et les contours et cases occupées si ok
function Coupon:verifier(idPiece, placement)
	local def = Catalogue.piece(idPiece)
	if not def then
		return false, "Pièce inconnue."
	end
	if self.poses[idPiece] then
		return false, "Cette pièce est déjà coupée."
	end
	if type(placement) ~= "table" or not fini(placement.x) or not fini(placement.y) or not fini(placement.angle) then
		return false, "Position invalide."
	end
	local contours = Coupon.contoursPoses(idPiece, placement)
	local limiteX = def.pliee and Catalogue.PLI or Catalogue.LARGEUR_ROULEAU
	local b = Polygone.boite(contours[1])
	if b.minX < -EPSILON or b.maxX > limiteX + EPSILON or b.minY < -EPSILON or b.maxY > self.longueur + EPSILON then
		return false, def.pliee and "Une pièce pliée doit tenir d'un côté du pli." or "La pièce dépasse du tissu."
	end
	local cases = {}
	for _, contour in ipairs(contours) do
		for _, cle in ipairs(cellulesDe(contour)) do
			if self.cellules[cle] or cases[cle] then
				return false, "La pièce chevauche une autre pièce."
			end
			cases[cle] = true
		end
	end
	return true, nil, contours, cases
end

function Coupon:poser(idPiece, placement)
	local ok, erreur, contours, cases = self:verifier(idPiece, placement)
	if not ok then
		return false, erreur
	end
	for cle in pairs(cases) do
		self.cellules[cle] = idPiece
	end
	self.poses[idPiece] = { x = placement.x, y = placement.y, angle = placement.angle }
	for _, contour in ipairs(contours) do
		self.basMax = math.max(self.basMax, Polygone.boite(contour).maxY)
	end
	return true
end

-- Longueur de tissu consommée (dm entiers, arrondie au-dessus)
function Coupon:longueurUtilisee()
	return math.ceil(self.basMax - EPSILON)
end

return Coupon
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 12967 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Coupon.luau tests/unitaires/04_coupon.luau
git commit -m "Ajoute Coupon : pose des pièces sur le rouleau, pli et chevauchements

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Module `Notation`

**Files:**
- Create: `src/shared/Notation.luau`
- Test: `tests/unitaires/05_notation.luau`

**Interfaces:**
- Consumes: `Catalogue` (pièces, variantes, tissus, accessoires, `K`, `STYLES`, `FAMILLES`, `PLAFOND_ASSISTANCE`) ; `Polygone.boite` ; `Patron.aire`, `Patron.piecesDuCroquis`.
- Produces :
  - `Notation.droitFil(theta, biais) -> number` (0 si theta n'est pas fini)
  - `Notation.angleFil(angle, idPiece) -> number`, `Notation.aimanter(angle, idPiece) -> number`
  - `Notation.noteCouture(ecarts: {number}, assistance: boolean) -> number` (une mesure non finie compte 0)
  - `Notation.qualite({ { aire, droitFil, couture } }) -> number`
  - `Notation.longueurGarniture(idPiece, trajet: { {u, v} }) -> number`
  - `Notation.styles({ croquis, tissus = { [idTissu] = aire }, accessoires = { { id, longueur? } } }) -> { [style] = 0..100 }`
  - `Notation.fourchette(croquis, choix: { [idPiece] = idTissu? }) -> { [style] = { acquis, min, max } }`
  - `Notation.bilan(recette) -> { styles, qualite, teinte, accessoires = { [id] = n }, nbPieces }`, avec recette = `{ croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { { id, piece, u, v, echelle, angle } | { id, piece, trajet } } }`. **La recette de la spec §2 gagne le champ `croquis`**, nécessaire pour compter les points des variantes.
  - `Notation.verifierExigences(exigences, bilan) -> (ok, ratees: {int})`, avec exigence = `{ type = "min"|"max", style, valeur }` | `{ type = "qualite", valeur }` | `{ type = "teinte", teinte }` | `{ type = "accessoire", id }`
  - `Notation.base(nbPieces, nbExigences) -> number`, `Notation.paie(nbPieces, nbExigences, qualite) -> integer`

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/05_notation.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Notation = U.module("Notation")

-- Droit-fil aux angles de référence
local attendus = { { 0, 1 }, { 45, 0.6 }, { 90, 0.75 }, { 135, 0.6 }, { 180, 1 }, { -90, 0.75 }, { 22.5, 0.8 }, { 360, 1 } }
for _, a in ipairs(attendus) do
	U.verifier(U.proche(Notation.droitFil(a[1], false), a[2]), ("droit-fil à %g° = %g"):format(a[1], a[2]))
end
local biais = { { 45, 1 }, { 135, 1 }, { 0, 0.7 }, { 90, 0.7 }, { 22.5, 0.85 } }
for _, a in ipairs(biais) do
	U.verifier(U.proche(Notation.droitFil(a[1], true), a[2]), ("pièce en biais à %g° = %g"):format(a[1], a[2]))
end

-- Aimantation à 6°
U.verifier(U.proche(Notation.aimanter(4, "jupe_droite_devant"), 0), "4° s'aimante à 0°")
U.verifier(U.proche(Notation.aimanter(-5, "jupe_droite_devant"), 0), "−5° s'aimante à 0°")
U.verifier(U.proche(Notation.aimanter(177, "jupe_droite_devant"), 180), "177° s'aimante à 180°")
U.verifier(U.proche(Notation.aimanter(7, "jupe_droite_devant"), 7), "7° ne s'aimante pas")
U.verifier(U.proche(Notation.aimanter(41, "jupe_evasee_devant"), 45), "pièce en biais : 41° s'aimante à 45°")
U.verifier(U.proche(Notation.aimanter(2, "jupe_evasee_devant"), 2), "pièce en biais : 2° ne s'aimante pas à 0°")

-- Couture : 100 % jusqu'à 0,05 dm, 0 % à 0,30 dm
U.verifier(U.proche(Notation.noteCouture({ 0, 0.05, -0.05 }, false), 1), "couture parfaite")
U.verifier(U.proche(Notation.noteCouture({ 0.3 }, false), 0), "0,30 dm d'écart = 0 %")
U.verifier(U.proche(Notation.noteCouture({ 0.175, -0.175 }, false), 0.5), "0,175 dm d'écart = 50 %")
U.verifier(U.proche(Notation.noteCouture({ 0, 2 }, false), 0.5), "moyenne des mesures")
U.verifier(U.proche(Notation.noteCouture({ 0, 0 }, true), 0.85), "assistance plafonnée à 85 %")
U.verifier(Notation.noteCouture({}, false) == 0, "aucune mesure = 0")

-- Qualité pondérée par la surface
local q = Notation.qualite({ { aire = 30, droitFil = 1, couture = 1 }, { aire = 10, droitFil = 0.6, couture = 0.5 } })
U.verifier(U.proche(q, (30 + 10 * 0.3) / 40), "qualité pondérée par la surface")

-- Styles : croquis tout simple + un seul tissu + un accessoire
local croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local s = Notation.styles({ croquis = croquis, tissus = { coton_blanc = 50 }, accessoires = { { id = "noeud_satin" } } })
-- décontracté : variantes 6 + 3 = 9 ; tissu 2 × 10 = 20 ; accessoire 0 → 29
U.verifier(U.proche(s.decontracte, 29), "décontracté = 9 (variantes) + 20 (tissu)")
-- mignon : tissu 2 × 4 = 8 ; nœud 0,5 × 4 = 2 → 10
U.verifier(U.proche(s.mignon, 10), "mignon = 8 (tissu) + 2 (nœud)")
U.verifier(s.gothique == 0, "aucun point gothique")
-- Évasée : décontracté −4 sur la variante, borné à 0
local s2 = Notation.styles({ croquis = { corsage = "corsage_v", manches = "manches_longues", col = "col_montant", jupe = "jupe_evasee" },
	tissus = { velours_noir = 1 }, accessoires = {} })
U.verifier(s2.decontracte == 0, "score borné à 0")
local beaucoup = {}
for _ = 1, 300 do
	table.insert(beaucoup, { id = "croix_argent" })
end
U.verifier(Notation.styles({ croquis = croquis, tissus = {}, accessoires = beaucoup }).gothique == 100, "score borné à 100")

-- Garniture : points par tranche de 5 dm entamée
U.verifier(U.proche(Notation.longueurGarniture("jupe_droite_devant", { { u = 0, v = 1 }, { u = 1, v = 1 } }), 5), "garniture de 5 dm")
local g = Notation.styles({ croquis = croquis, tissus = {}, accessoires = { { id = "ruban_rose", longueur = 5.5 } } })
U.verifier(U.proche(g.mignon, 0.5 * 3 * 2), "5,5 dm de ruban = 2 tranches")

-- Fourchette du carnet
local f = Notation.fourchette(croquis, {})
for _, st in ipairs(Catalogue.STYLES) do
	U.verifier(f[st].min <= f[st].max, st .. " : min ≤ max")
end
U.verifier(U.proche(f.decontracte.acquis, 9), "acquis = points des variantes")
local pieces = Patron.piecesDuCroquis(croquis)
local tous = {}
for _, id in ipairs(pieces) do
	tous[id] = "coton_blanc"
end
local f2 = Notation.fourchette(croquis, tous)
U.verifier(U.proche(f2.decontracte.min, 29) and U.proche(f2.decontracte.max, 29), "tous les tissus choisis : fourchette réduite au score")

-- Bilan d'une recette complète
local recette = {
	croquis = croquis,
	pieces = {
		{ id = "corsage_droit_devant", tissu = "soie_rouge", x = 3, y = 3, angle = 0, couture = 1 },
		{ id = "corsage_droit_dos", tissu = "soie_rouge", x = 9, y = 3, angle = 90, couture = 1 },
		{ id = "jupe_droite_devant", tissu = "coton_blanc", x = 3, y = 3, angle = 0, couture = 0.5 },
		{ id = "jupe_droite_dos", tissu = "coton_blanc", x = 9, y = 3, angle = 0, couture = 1 },
	},
	accessoires = {
		{ id = "bouton_nacre", piece = 1, u = 0.5, v = 0.2, echelle = 1, angle = 0 },
		{ id = "dentelle_blanche", piece = 3, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } },
	},
}
local bilan = Notation.bilan(recette)
local aC, aJ = Patron.aire("corsage_droit_devant"), Patron.aire("jupe_droite_devant")
local attendue = (aC * 1 + aC * 0.75 + aJ * 0.5 + aJ * 1) / (2 * aC + 2 * aJ)
U.verifier(U.proche(bilan.qualite, attendue), "qualité du bilan (dos du corsage en travers, jupe mal cousue)")
U.verifier(bilan.teinte == "blanc", "teinte dominante = la plus grande surface (jupe blanche)")
U.verifier(bilan.accessoires.bouton_nacre == 1 and bilan.accessoires.dentelle_blanche == 1, "accessoires comptés")
U.verifier(bilan.nbPieces == 4, "4 pièces")

-- Exigences
local ok, ratees = Notation.verifierExigences({
	{ type = "min", style = "decontracte", valeur = 10 },
	{ type = "max", style = "gothique", valeur = 10 },
	{ type = "qualite", valeur = 0.95 },
	{ type = "teinte", teinte = "rouge" },
	{ type = "accessoire", id = "bouton_nacre" },
}, bilan)
U.verifier(not ok and #ratees == 2 and ratees[1] == 3 and ratees[2] == 4, "qualité et teinte ratées, le reste rempli")

-- Paie
U.verifier(Notation.base(4, 1) == 75 and Notation.base(6, 3) == 125, "base de 75 à 125")
U.verifier(Notation.paie(4, 1, 1) == 113 and Notation.paie(4, 1, 0) == 38, "paie = base × (0,5 + qualité), arrondie")

-- Valeurs invalides venues d'un client : jamais de NaN, jamais 100 %
U.verifier(Notation.droitFil(0 / 0, false) == 0 and Notation.droitFil(math.huge, true) == 0, "angle non fini = droit-fil 0")
local n = Notation.noteCouture({ 0 / 0, 0, math.huge }, false)
U.verifier(n == n and U.proche(n, 1 / 3), "écart non fini = mesure ratée, note jamais NaN")
-- Recette qui cite un tissu ou un accessoire inconnu : erreur franche (le serveur valide avant)
local mauvaise = { croquis = croquis, pieces = { { id = "jupe_droite_devant", tissu = "inconnu", x = 0, y = 0, angle = 0, couture = 1 } } }
U.verifier(not pcall(Notation.bilan, mauvaise), "tissu inconnu : erreur")
U.verifier(not pcall(Notation.styles, { croquis = croquis, tissus = {}, accessoires = { { id = "inconnu" } } }), "accessoire inconnu : erreur")
-- Garniture d'un seul point : longueur nulle, aucun point, pas d'erreur
U.verifier(Notation.longueurGarniture("jupe_droite_devant", { { u = 0.5, v = 0.5 } }) == 0, "garniture d'un point : longueur 0")
local g0 = Notation.styles({ croquis = croquis, tissus = {}, accessoires = { { id = "ruban_rose", longueur = 0 } } })
U.verifier(U.proche(g0.mignon, 0), "garniture de longueur nulle : aucun point")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Notation`.

- [ ] **Step 3: Écrire le module**

`src/shared/Notation.luau` :

```lua
-- Notation : droit-fil, couture, qualité, jauges de style, exigences des commandes et paie.
-- Utilisé par le serveur (qui fait foi) et par le client (affichage en direct).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Notation = {}

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

---------------------------------------------------------------------------
-- Droit-fil
---------------------------------------------------------------------------
-- Points de référence (angle modulo 180° → note), interpolés linéairement
local FIL_NORMAL = { { 0, 1 }, { 45, 0.6 }, { 90, 0.75 }, { 135, 0.6 }, { 180, 1 } }
local FIL_BIAIS = { { 0, 0.7 }, { 45, 1 }, { 90, 0.7 }, { 135, 1 }, { 180, 0.7 } }
local AIMANTATION = 6 -- degrés

-- theta : angle (degrés) entre la flèche de droit-fil de la pièce et la chaîne du tissu
function Notation.droitFil(theta, biais)
	if not fini(theta) then
		return 0 -- valeur invalide : jamais 100 %
	end
	local t = theta % 180
	local points = biais and FIL_BIAIS or FIL_NORMAL
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if t <= b[1] then
			return a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])
		end
	end
	return points[#points][2]
end

-- Angle de la flèche de droit-fil sur le rouleau pour une pièce posée à « angle »
function Notation.angleFil(angle, idPiece)
	return angle + (Catalogue.piece(idPiece).droitFil or 0)
end

-- Aligne exactement la pièce sur un angle à 100 % si elle en est à moins de 6°
function Notation.aimanter(angle, idPiece)
	local def = Catalogue.piece(idPiece)
	local theta = Notation.angleFil(angle, idPiece)
	for _, cible in ipairs(def.biais and { 45, 135 } or { 0 }) do
		local ecart = (theta - cible + 90) % 180 - 90
		if math.abs(ecart) <= AIMANTATION then
			return angle - ecart
		end
	end
	return angle
end

---------------------------------------------------------------------------
-- Couture et qualité
---------------------------------------------------------------------------
-- ecarts : écarts (dm) de l'aiguille à la ligne, une mesure tous les 0,1 dm de trajet
function Notation.noteCouture(ecarts, assistance)
	if #ecarts == 0 then
		return 0
	end
	local somme = 0
	for _, e in ipairs(ecarts) do
		if fini(e) then -- une mesure invalide compte comme ratée
			somme += math.clamp(1 - (math.abs(e) - 0.05) / 0.25, 0, 1)
		end
	end
	local note = somme / #ecarts
	if assistance then
		note = math.min(note, Catalogue.PLAFOND_ASSISTANCE)
	end
	return note
end

-- pieces = { { aire, droitFil, couture } } → qualité de la robe (moyenne pondérée par la surface)
function Notation.qualite(pieces)
	local total, aires = 0, 0
	for _, p in ipairs(pieces) do
		total += p.aire * p.droitFil * p.couture
		aires += p.aire
	end
	return aires > 0 and total / aires or 0
end

---------------------------------------------------------------------------
-- Style
---------------------------------------------------------------------------
-- Longueur (dm) d'une garniture posée sur une pièce : trajet = { { u, v } } dans la boîte du patron
function Notation.longueurGarniture(idPiece, trajet)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local total = 0
	for i = 2, #trajet do
		local du, dv = (trajet[i].u - trajet[i - 1].u) * l, (trajet[i].v - trajet[i - 1].v) * h
		total += math.sqrt(du * du + dv * dv)
	end
	return total
end

local function pointsAccessoire(a)
	local def = Catalogue.accessoire(a.id)
	assert(def, "accessoire inconnu : " .. tostring(a.id))
	if def.genre == "garniture" then
		return def.style, math.ceil((a.longueur or 0) / 5 - 1e-9)
	end
	return def.style, 1
end

-- entree = { croquis, tissus = { [idTissu] = aire }, accessoires = { { id, longueur? } } }
-- Retourne { [style] = score de 0 à 100 }
function Notation.styles(entree)
	local K = Catalogue.K
	local brut = {}
	for _, s in ipairs(Catalogue.STYLES) do
		brut[s] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for s, pts in pairs(Catalogue.variante(entree.croquis[famille]).style) do
			brut[s] += K.pieces * pts
		end
	end
	local aireTotale = 0
	for _, aire in pairs(entree.tissus) do
		aireTotale += aire
	end
	if aireTotale > 0 then
		for idTissu, aire in pairs(entree.tissus) do
			for s, pts in pairs(Catalogue.tissu(idTissu).style) do
				brut[s] += K.tissu * pts * aire / aireTotale
			end
		end
	end
	for _, a in ipairs(entree.accessoires or {}) do
		local style, fois = pointsAccessoire(a)
		for s, pts in pairs(style) do
			brut[s] += K.accessoires * pts * fois
		end
	end
	local scores = {}
	for s, v in pairs(brut) do
		scores[s] = math.clamp(v, 0, 100)
	end
	return scores
end

-- Jauges du carnet : choix = { [idPiece] = idTissu ou nil }.
-- Retourne { [style] = { acquis, min, max } } : acquis = points des variantes seules,
-- min / max = fourchette possible selon les tissus encore à choisir.
function Notation.fourchette(croquis, choix)
	local K = Catalogue.K
	local pieces = Patron.piecesDuCroquis(croquis)
	local aireTotale = 0
	for _, id in ipairs(pieces) do
		aireTotale += Patron.aire(id)
	end
	local base = Notation.styles({ croquis = croquis, tissus = {}, accessoires = {} })
	local out = {}
	for _, s in ipairs(Catalogue.STYLES) do
		local mini, maxi = math.huge, -math.huge
		for _, t in ipairs(Catalogue.Tissus) do
			mini, maxi = math.min(mini, t.style[s] or 0), math.max(maxi, t.style[s] or 0)
		end
		local bas, haut = 0, 0
		for _, id in ipairs(pieces) do
			local part = Patron.aire(id) / aireTotale
			local idTissu = choix[id]
			if idTissu then
				local pts = Catalogue.tissu(idTissu).style[s] or 0
				bas += K.tissu * pts * part
				haut += K.tissu * pts * part
			else
				bas += K.tissu * mini * part
				haut += K.tissu * maxi * part
			end
		end
		local brutAcquis = 0
		for _, famille in ipairs(Catalogue.FAMILLES) do
			brutAcquis += K.pieces * (Catalogue.variante(croquis[famille]).style[s] or 0)
		end
		out[s] = {
			acquis = base[s],
			min = math.clamp(brutAcquis + bas, 0, 100),
			max = math.clamp(brutAcquis + haut, 0, 100),
		}
	end
	return out
end

---------------------------------------------------------------------------
-- Bilan d'une recette, exigences, paie
---------------------------------------------------------------------------
-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
function Notation.bilan(recette)
	local tissus, piecesNotees = {}, {}
	local teinte, aireMax = nil, -1
	for _, p in ipairs(recette.pieces) do
		assert(Catalogue.tissu(p.tissu), "tissu inconnu : " .. tostring(p.tissu))
		local aire = Patron.aire(p.id)
		tissus[p.tissu] = (tissus[p.tissu] or 0) + aire
		local df = Notation.droitFil(Notation.angleFil(p.angle, p.id), Catalogue.piece(p.id).biais)
		table.insert(piecesNotees, { aire = aire, droitFil = df, couture = p.couture or 0 })
	end
	for _, p in ipairs(recette.pieces) do
		if tissus[p.tissu] > aireMax then
			teinte, aireMax = Catalogue.tissu(p.tissu).teinte, tissus[p.tissu]
		end
	end
	local accessoires, comptes = {}, {}
	for _, a in ipairs(recette.accessoires or {}) do
		local entree = { id = a.id }
		if a.trajet then
			entree.longueur = Notation.longueurGarniture(recette.pieces[a.piece].id, a.trajet)
		end
		table.insert(accessoires, entree)
		comptes[a.id] = (comptes[a.id] or 0) + 1
	end
	return {
		styles = Notation.styles({ croquis = recette.croquis, tissus = tissus, accessoires = accessoires }),
		qualite = Notation.qualite(piecesNotees),
		teinte = teinte,
		accessoires = comptes,
		nbPieces = #recette.pieces,
	}
end

-- exigences : { { type = "min"|"max", style, valeur } | { type = "qualite", valeur }
--              | { type = "teinte", teinte } | { type = "accessoire", id } }
-- Retourne ok, et la liste des indices des exigences ratées
function Notation.verifierExigences(exigences, bilan)
	local ratees = {}
	for i, e in ipairs(exigences) do
		local ok
		if e.type == "min" then
			ok = bilan.styles[e.style] >= e.valeur
		elseif e.type == "max" then
			ok = bilan.styles[e.style] <= e.valeur
		elseif e.type == "qualite" then
			ok = bilan.qualite >= e.valeur - 1e-9
		elseif e.type == "teinte" then
			ok = bilan.teinte == e.teinte
		elseif e.type == "accessoire" then
			ok = (bilan.accessoires[e.id] or 0) > 0
		else
			error("exigence inconnue : " .. tostring(e.type))
		end
		if not ok then
			table.insert(ratees, i)
		end
	end
	return #ratees == 0, ratees
end

function Notation.base(nbPieces, nbExigences)
	return 20 + 10 * nbPieces + 15 * nbExigences
end

function Notation.paie(nbPieces, nbExigences, qualite)
	return math.floor(Notation.base(nbPieces, nbExigences) * (0.5 + qualite) + 0.5)
end

return Notation
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 13021 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Notation.luau tests/unitaires/05_notation.luau
git commit -m "Ajoute Notation : droit-fil, couture, qualité, styles, exigences et paie

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Module `Commandes` (commandes réalisables)

**Files:**
- Create: `src/shared/Commandes.luau`
- Test: `tests/unitaires/06_commandes.luau`

**Interfaces:**
- Consumes: `Catalogue.variantesDe`, `Tissus`, `Accessoires`, `STYLES`, `TAILLES` ; `Notation.styles`, `Notation.verifierExigences`.
- Produces :
  - `Commandes.realisable(exigences) -> (ok, temoin?)`, avec temoin = `{ croquis, tissu, accessoire? }` : une robe d'un seul tissu qui remplit les exigences
  - `Commandes.generer(rng: Random) -> { taille: "S"|"M"|"L", mesures, exigences }` (1 à 3 exigences, toujours réalisables, qualité demandée ≤ 0,9)

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/06_commandes.luau` :

```lua
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
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Commandes`.

- [ ] **Step 3: Écrire le module**

`src/shared/Commandes.luau` :

```lua
-- Commandes : génère des commandes de clientes anonymes, toujours réalisables avec le catalogue.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Notation = require(dossier:WaitForChild("Notation"))

local Commandes = {}

local NOMS_TAILLES = { "S", "M", "L" }
local ESSAIS = 30

-- Toutes les combinaisons de variantes du carnet (3 × 3 × 3 × 4 = 108)
local function croquisPossibles()
	local out = {}
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		for _, m in ipairs(Catalogue.variantesDe("manches")) do
			for _, k in ipairs(Catalogue.variantesDe("col")) do
				for _, j in ipairs(Catalogue.variantesDe("jupe")) do
					table.insert(out, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				end
			end
		end
	end
	return out
end
local CROQUIS = croquisPossibles()

-- Cherche une robe simple (un seul tissu, au plus l'accessoire imposé) qui remplit les exigences.
-- La qualité est supposée atteignable (≤ 0,9). Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local bilan = {
				styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }),
				qualite = 1,
				teinte = t.teinte,
				accessoires = accessoireImpose and { [accessoireImpose] = 1 } or {},
			}
			if Notation.verifierExigences(exigences, bilan) then
				return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
			end
		end
	end
	return false
end

local function tirer(liste, rng)
	return liste[rng:NextInteger(1, #liste)]
end

local function tirerExigences(rng)
	local exigences = {}
	local styleMin = tirer(Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, 7) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin
			table.insert(exigences, { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 })
		elseif genre == "qualite" then
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 })
		elseif genre == "teinte" then
			table.insert(exigences, { type = "teinte", teinte = tirer(Catalogue.Tissus, rng).teinte })
		else
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" then
					table.insert(objets, a.id)
				end
			end
			table.insert(exigences, { type = "accessoire", id = tirer(objets, rng) })
		end
	end
	return exigences
end

-- rng : un objet Random. Retourne { taille, mesures, exigences }
function Commandes.generer(rng)
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng)
		if Commandes.realisable(candidat) then
			exigences = candidat
			break
		end
	end
	exigences = exigences or { { type = "min", style = "decontracte", valeur = 20 } }
	local taille = tirer(NOMS_TAILLES, rng)
	return { taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = exigences }
end

return Commandes
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 13828 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau tests/unitaires/06_commandes.luau
git commit -m "Ajoute Commandes : commandes de clientes toujours réalisables

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Module `Pixels` (motifs et découpe exacte)

**Files:**
- Create: `src/shared/Pixels.luau`
- Test: `tests/unitaires/07_pixels.luau`

**Interfaces:**
- Consumes: `Catalogue.tissu`, `piece`, `TAILLE_MOTIF`, `PX_PAR_DM`, `PLI` ; `Polygone.boite`, `centre`, `poserPoint`.
- Produces (buffer RVBA, 4 octets par pixel, ligne par ligne, alpha 255, directement utilisable par `EditableImage:WritePixelsBuffer`) :
  - `Pixels.empaqueter(r, g, b) -> number` et `Pixels.lire(buf, largeur, x, y) -> (r, g, b)`
  - `Pixels.motif(idTissu) -> buffer` (256 × 256, répétable)
  - `Pixels.taillePiece(idPiece, plafond?) -> (largeur, hauteur, boite)` (32 px/dm, plafond de 256 par défaut)
  - `Pixels.surRouleau(idPiece, placement, copie, x, y) -> point`
  - `Pixels.pixelMotif(bx, by) -> (mx, my)`
  - `Pixels.imagePiece(motif, idPiece, placement, copie, plafond?) -> (buffer, largeur, hauteur)`. Copie « unique » ou « gauche » = la pièce posée ; « droite » = son symétrique au pli.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/07_pixels.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Pixels = U.module("Pixels")

-- Motifs : bonne taille, raccord bord à bord
local N = Catalogue.TAILLE_MOTIF
for _, t in ipairs(Catalogue.Tissus) do
	local buf = Pixels.motif(t.id)
	U.verifier(buffer.len(buf) == N * N * 4, t.id .. " : motif de 256 × 256")
	local r, g, b = Pixels.lire(buf, N, 0, 0)
	U.verifier(r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255, t.id .. " : couleur valide")
end
local uni = Pixels.motif("coton_blanc")
local r, g, b = Pixels.lire(uni, N, 100, 7)
U.verifier(r == 246 and g == 242 and b == 234, "un tissu uni a sa couleur partout")
-- Rayures : parallèles au droit-fil → la couleur ne dépend que de x
local rayures = Pixels.motif("lin_vert_rayures")
U.verifier(select(1, Pixels.lire(rayures, N, 3, 0)) == select(1, Pixels.lire(rayures, N, 3, 200)), "les rayures suivent la longueur")
U.verifier(select(1, Pixels.lire(rayures, N, 0, 0)) ~= select(1, Pixels.lire(rayures, N, 20, 0)), "deux bandes de couleurs différentes")
-- Dégradé : il se raccorde en haut et en bas du carreau
local degrade = Pixels.motif("soie_bleue_degrade")
U.verifier(select(3, Pixels.lire(degrade, N, 5, 0)) == 160 and select(3, Pixels.lire(degrade, N, 5, 128)) == 240,
	"dégradé : couleur 1 en haut, couleur 2 au milieu")

-- Taille de l'image d'une pièce : 32 px/dm, plafonnée
local l, h = Pixels.taillePiece("jupe_droite_devant")
U.verifier(l == 160 and h == 192, "jupe droite 5 × 6 dm → 160 × 192 px")
l, h = Pixels.taillePiece("jupe_evasee_devant")
U.verifier(math.max(l, h) == 256, "pièce de 9 dm plafonnée à 256 px")
l, h = Pixels.taillePiece("jupe_droite_devant", 128)
U.verifier(math.max(l, h) == 128, "plafond de vitrine à 128 px")

-- Exactitude de la découpe : le pixel de la pièce = le pixel du motif sous ce point sur la table
local motif = Pixels.motif("soie_rose_fleurs")
local cas = {
	{ id = "jupe_trapeze_devant", placement = { x = 4, y = 5, angle = 0 }, copie = "unique" },
	{ id = "jupe_trapeze_devant", placement = { x = 6.3, y = 7.1, angle = 45 }, copie = "unique" },
	{ id = "jupe_droite_dos", placement = { x = 5, y = 4, angle = 90 }, copie = "unique" },
	{ id = "corsage_v_devant", placement = { x = 3, y = 3, angle = 180 }, copie = "unique" },
	{ id = "manche_ballon", placement = { x = 3, y = 2, angle = 0 }, copie = "gauche" },
	{ id = "manche_ballon", placement = { x = 3, y = 2, angle = 0 }, copie = "droite" },
}
local rng = Random.new(7)
for _, c in ipairs(cas) do
	local img, largeur, hauteur = Pixels.imagePiece(motif, c.id, c.placement, c.copie)
	local bo = Polygone.boite(Catalogue.piece(c.id).contour)
	for _ = 1, 50 do
		local i, j = rng:NextInteger(0, largeur - 1), rng:NextInteger(0, hauteur - 1)
		-- Calcul indépendant : centre du pixel → patron → table → motif
		local x = bo.minX + (i + 0.5) / largeur * (bo.maxX - bo.minX)
		local y = bo.minY + (j + 0.5) / hauteur * (bo.maxY - bo.minY)
		local centre = { x = (bo.minX + bo.maxX) / 2, y = (bo.minY + bo.maxY) / 2 }
		local a = math.rad(c.placement.angle)
		local bx = c.placement.x + math.cos(a) * (x - centre.x) - math.sin(a) * (y - centre.y)
		local by = c.placement.y + math.sin(a) * (x - centre.x) + math.cos(a) * (y - centre.y)
		if c.copie == "droite" then
			bx = 14 - bx
		end
		local mx, my = math.floor(bx * 32) % 256, math.floor(by * 32) % 256
		local r1, g1, b1 = Pixels.lire(img, largeur, i, j)
		local r2, g2, b2 = Pixels.lire(motif, 256, mx, my)
		U.verifier(r1 == r2 and g1 == g2 and b1 == b2, ("%s à %g° (%s) : pixel (%d, %d) exact"):format(c.id, c.placement.angle, c.copie, i, j))
	end
end
-- Une rotation change vraiment l'image (le motif fleuri n'est pas symétrique par rotation de 45°)
local a0 = Pixels.imagePiece(motif, "jupe_droite_devant", { x = 4, y = 4, angle = 0 }, "unique")
local a45 = Pixels.imagePiece(motif, "jupe_droite_devant", { x = 4, y = 4, angle = 45 }, "unique")
local differents = 0
for k = 0, 160 * 192 - 1, 37 do
	if buffer.readu32(a0, k * 4) ~= buffer.readu32(a45, k * 4) then
		differents += 1
	end
end
U.verifier(differents > 50, "la rotation de la pièce change l'image découpée")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | tail -5`
Expected: arrêt avec une erreur mentionnant `Pixels`.

- [ ] **Step 3: Écrire le module**

`src/shared/Pixels.luau` :

```lua
-- Pixels : images RVBA en buffer (4 octets par pixel, ligne par ligne), sans objet Roblox.
-- Dessine le motif répétable d'un tissu et « découpe » l'image d'une pièce posée sur le rouleau.
-- Le client copie ensuite ces buffers dans des EditableImage (WritePixelsBuffer).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Pixels = {}

local N = Catalogue.TAILLE_MOTIF -- 256
local PX = Catalogue.PX_PAR_DM -- 32
local TAILLE_MAX_PIECE = 256

local function empaqueter(r, g, b)
	return r + g * 256 + b * 65536 + 255 * 16777216
end
Pixels.empaqueter = empaqueter

function Pixels.lire(buf, largeur, x, y)
	local v = buffer.readu32(buf, (y * largeur + x) * 4)
	return v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256
end

local function melanger(a, b, t)
	return {
		math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
		math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
		math.floor(a[3] + (b[3] - a[3]) * t + 0.5),
	}
end

-- Couleur du motif au pixel (px, py) du carreau de 256 × 256
local MOTIFS = {}
function MOTIFS.uni(m, _px, _py)
	return m.couleurs[1]
end
function MOTIFS.rayures(m, px, _py)
	-- Rayures parallèles au droit-fil (elles suivent la longueur du rouleau)
	local p = m.periode * PX
	return (px % p) < m.largeur * PX and m.couleurs[2] or m.couleurs[1]
end
function MOTIFS.carreaux(m, px, py)
	local p = m.periode * PX
	local n = ((px % p) < p / 2 and 1 or 0) + ((py % p) < p / 2 and 1 or 0)
	if n == 0 then
		return m.couleurs[1]
	elseif n == 1 then
		return melanger(m.couleurs[1], m.couleurs[2], 0.5)
	end
	return m.couleurs[2]
end
function MOTIFS.pois(m, px, py)
	local p = m.periode * PX
	local ligne = math.floor(py / p)
	local dx = ((px + (ligne % 2) * p / 2) % p) - p / 2 + 0.5
	local dy = (py % p) - p / 2 + 0.5
	return (dx * dx + dy * dy) <= (m.rayon * PX) ^ 2 and m.couleurs[2] or m.couleurs[1]
end
function MOTIFS.fleurs(m, px, py)
	local p = m.periode * PX
	local ligne = math.floor(py / p)
	local dx = ((px + (ligne % 2) * p / 2) % p) - p / 2 + 0.5
	local dy = (py % p) - p / 2 + 0.5
	local d = math.sqrt(dx * dx + dy * dy)
	if d < p * 0.12 then
		return m.couleurs[3]
	elseif d < p * 0.34 and math.cos(5 * math.atan2(dy, dx)) > 0.1 then
		return m.couleurs[2]
	end
	return m.couleurs[1]
end
function MOTIFS.degrade(m, _px, py)
	-- Aller-retour sur la hauteur du carreau : le haut et le bas se raccordent
	local t = py / N
	return melanger(m.couleurs[1], m.couleurs[2], 1 - math.abs(2 * t - 1))
end

-- Buffer 256 × 256 du motif d'un tissu (répétable dans les deux sens)
function Pixels.motif(idTissu)
	local tissu = Catalogue.tissu(idTissu)
	assert(tissu, "tissu inconnu : " .. tostring(idTissu))
	local dessiner = MOTIFS[tissu.motif.type]
	local buf = buffer.create(N * N * 4)
	for py = 0, N - 1 do
		for px = 0, N - 1 do
			local c = dessiner(tissu.motif, px, py)
			buffer.writeu32(buf, (py * N + px) * 4, empaqueter(c[1], c[2], c[3]))
		end
	end
	return buf
end

-- Dimensions (pixels) de l'image d'une pièce : 32 px par dm, plafonnées à « plafond » par côté
function Pixels.taillePiece(idPiece, plafond)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local echelle = math.min(PX, (plafond or TAILLE_MAX_PIECE) / math.max(l, h))
	return math.max(1, math.ceil(l * echelle)), math.max(1, math.ceil(h * echelle)), b
end

-- Position sur le rouleau (dm) du point (x, y) du patron, pour une copie de pièce posée
function Pixels.surRouleau(idPiece, placement, copie, x, y)
	local def = Catalogue.piece(idPiece)
	local p = Polygone.poserPoint({ x = x, y = y }, placement, Polygone.centre(def.contour))
	if copie == "droite" then
		p.x = 2 * Catalogue.PLI - p.x -- copie symétrique, de l'autre côté du pli
	end
	return p
end

-- Pixel du motif sous un point du rouleau (répétition du carreau)
function Pixels.pixelMotif(bx, by)
	return math.floor(bx * PX) % N, math.floor(by * PX) % N
end

-- Image de la pièce découpée : chaque pixel reprend le pixel du motif qui était dessous sur la table.
-- La copie « gauche » (ou « unique ») est la pièce posée ; la « droite » est son symétrique au pli.
-- Retourne buffer, largeur, hauteur.
function Pixels.imagePiece(motif, idPiece, placement, copie, plafond)
	local largeur, hauteur, b = Pixels.taillePiece(idPiece, plafond)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local buf = buffer.create(largeur * hauteur * 4)
	for j = 0, hauteur - 1 do
		local y = b.minY + (j + 0.5) / hauteur * h
		for i = 0, largeur - 1 do
			local x = b.minX + (i + 0.5) / largeur * l
			local p = Pixels.surRouleau(idPiece, placement, copie, x, y)
			local mx, my = Pixels.pixelMotif(p.x, p.y)
			buffer.writeu32(buf, (j * largeur + i) * 4, buffer.readu32(motif, (my * N + mx) * 4))
		end
	end
	return buf, largeur, hauteur
end

return Pixels
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 14184 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Pixels.luau tests/unitaires/07_pixels.luau
git commit -m "Ajoute Pixels : motifs de tissu et découpe exacte des pièces

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: README, vérification dans Studio et clôture du plan 1

**Files:**
- Modify: `README.md` (ajout d'une section en fin de fichier)
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tous les modules des tâches 3 à 9.
- Produces: une branche où les fondations sont testées et chargeables dans Studio. C'est le point de départ du plan 2.

- [ ] **Step 1: Ajouter la section au README**

Ajouter à la fin de `README.md` :

```markdown
## Refonte en cours : le cœur de l'atelier

La refonte inspirée de *Dressmaker* est décrite dans `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`.
Le plan 1 (`docs/superpowers/plans/2026-09-28-coeur-plan1-fondations.md`) ajoute les fondations, testées
mais pas encore branchées sur le jeu :

| Module (`src/shared/`) | Rôle |
|---|---|
| `Polygone` | Géométrie 2D des pièces de patron |
| `Catalogue` | Pièces, variantes, tissus, accessoires et constantes |
| `Patron` | Pièces d'un croquis, trajets de couture, enroulement 3D autour du corps |
| `Coupon` | Rouleau de découpe : pose, pli, chevauchements, longueur consommée |
| `Notation` | Droit-fil, couture, qualité, jauges de style, exigences et paie |
| `Commandes` | Commandes de clientes toujours réalisables |
| `Pixels` | Motifs de tissu et découpe exacte de l'image d'une pièce |

Les tests unitaires sont dans `tests/unitaires/` et tournent avec `bash tests/lancer.sh`, avant le scénario de l'ancien jeu.
Le test de faisabilité du rendu 3D est dans `spike/`, et ses mesures dans `docs/superpowers/spikes/`.
```

- [ ] **Step 2: Vérifier que les modules se chargent dans Studio**

1. Construire : `C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl`
2. Ouvrir `AtelierCouture.rbxl` dans Studio et exécuter en mode Edit avec `execute_luau` :

```lua
local d = game.ReplicatedStorage.Couture
local noms = { "Polygone", "Catalogue", "Patron", "Coupon", "Notation", "Commandes", "Pixels" }
local out = {}
for _, n in ipairs(noms) do
	local ok, err = pcall(require, d:WaitForChild(n))
	table.insert(out, n .. "=" .. (ok and "ok" or tostring(err)))
end
local Commandes = require(d.Commandes)
local c = Commandes.generer(Random.new(1))
table.insert(out, "commande=" .. c.taille .. "/" .. #c.exigences)
local Pixels = require(d.Pixels)
local t0 = os.clock()
Pixels.imagePiece(Pixels.motif("soie_rose_fleurs"), "jupe_trapeze_devant", { x = 4, y = 4, angle = 45 }, "unique")
table.insert(out, ("decoupeMs=%.1f"):format((os.clock() - t0) * 1000))
return table.concat(out, " ")
```

Expected: les 7 modules à `ok`, une commande générée, et le temps de découpe du motif et de la pièce. Reporter ce temps dans le rapport du spike, section « Mesures complémentaires ».

- [ ] **Step 3: Lancer toute la suite**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 14184 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 4: Commit**

```bash
git add README.md AtelierCouture.rbxl docs/superpowers/spikes/2026-09-28-rendu-editable.md
git commit -m "Plan 1 terminé : fondations testées du cœur de l'atelier

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
