# Cœur de l'atelier — Plan 3d : la cliente en personne et la photo

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire entrer la cliente en personne, un avatar construit en code qui parle et réagit à la robe, et finir l'étape 8 : régler la photo (décor, lumière, couleur du mannequin), la prendre avec la capture officielle de Roblox, puis livrer.

**Architecture:**
- **Cliente** : un nouveau module client, `Cliente`, construit l'avatar avec `Players:CreateHumanoidModelFromDescriptionAsync`. La tenue (couleurs du corps et coiffure) est tirée d'après la commande, et la silhouette suit la taille S, M ou L. Elle parle par une bulle (`BillboardGui`).
- **Scène** : `Scene` fait entrer la cliente avec la commande, la fait parler selon l'étape, puis la fait saluer et partir. Elle applique aussi les réglages de la photo (fond, `Lighting`, couleur du mannequin) et les rétablit quand on quitte l'étape. Enfin, elle cadre la prise de vue.
- **Écran** : `EcranPresentation` devient « 7. Photo et livraison » : réglages, prise de vue (interface cachée le temps de la capture), aperçu, enregistrement dans la galerie du joueur, puis livraison.
- `EtatAtelier` ne change pas : la photo est purement locale. La cliente réagit aux actions de la session (`Session.derniere`).

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§3 « La cliente est un PNJ avatar tiré parmi quelques tenues construites en code », §4 étape 8 « Décor, éclairage, couleur du mannequin, capture », §6 Modération « La photo passe par la capture officielle (`CaptureService`) »). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan3a-postes.md`, `…plan3b-epinglage-couture.md`, `…plan3c-decorations-livraison.md`.

## Décisions de ce plan

- **Avatar en code, sans ressource externe** (spec §3). On part d'une `HumanoidDescription` : couleurs de la peau, du haut et du bas, `WidthScale` et `DepthScale` selon la taille (S 0,9 ; M 1 ; L 1,12). La coiffure est une sphère soudée à la tête. Il y a cinq tenues, et la même commande donne toujours la même tenue (empreinte de la taille et des exigences).
- **Posture et taille**, vérifiées dans Studio pendant la préparation. Un avatar Roblox mesure environ 5,2 studs, contre 4,3 pour le mannequin : on le réduit à 0,85 (`ScaleTo`). Sans animation, il reste bras écartés. Les articulations R15 créées ainsi sont des `AnimationConstraint`, dont `C0` est en lecture seule : on baisse donc les bras par `Transform` des épaules (62°). L'étiquette de nom est masquée.
- **Place** : en retrait, à côté du mannequin (à gauche à l'écran), tournée vers la caméra, pieds au sol. Elle ne gêne ni le panneau à droite ni la robe.
- **Paroles** : au carnet, « Bonjour ! J'aurais besoin d'une robe. » ; silencieuse pendant le travail ; à la photo, « Voyons voir… » ; au refus, « Ce n'est pas tout à fait ce que je voulais. » ; puis « Merci, elle est parfaite ! » si la robe est livrée, « Tant pis… Au revoir. » sinon. Elle part 3 s après la fin de la commande. Une nouvelle clochette fait partir la précédente tout de suite.
- **Construction qui attend** : la création de l'avatar attend Roblox, et `synchroniser` tourne dans une tâche à part. La commande est donc notée avant la construction, pour qu'une synchronisation lancée pendant l'attente n'en crée pas une seconde. Si la commande a pris fin entre-temps, l'avatar construit est détruit.
- **Photo** : décor (rose, bleu, crème, nuit), lumière (jour, doux, soir) et mannequin (crème, noir, bois). Les réglages s'appliquent en direct et reviennent à ceux du jeu dès qu'on quitte l'étape, par n'importe quel chemin. Pendant la capture, on cache l'interface et la bulle, et la vue passe de face, centrée, avec un champ resserré à 42° : sur un écran très large, la robe paraissait petite dans l'aperçu (constaté dans Studio). Si Roblox refuse la capture, un message s'affiche. S'il ne répond pas, l'interface revient au bout de 2 s.
- **Galerie** : « Enregistrer dans la galerie » ouvre l'invite native de Roblox (`PromptSaveCapturesToGallery`) : rien n'est écrit sans l'accord du joueur. Dans Studio, cette invite fait apparaître dans la sortie une erreur interne de Roblox (« Maximum update depth exceeded », CorePackages) : elle ne vient pas de notre code.
- **Tout est local au client**. La cliente et la photo ne concernent que le joueur. Au plan 4, le serveur n'aura rien de plus à vérifier : la photo ne change ni l'argent ni la robe.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `refonte-photo`, créée depuis `corrections-test-studio`, où le plan 3c est fusionné. Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : unité le dm, repère du corps, fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px à l'échelle 1, symboles vérifiés à l'écran, double clic protégé (`UiKit.bouton`), « Recommencer » à confirmer.
- **Aucune ressource externe** (spec §3) : avatar, tenues et coiffure construits en code.
- **Photo** (spec §6) : capture par `CaptureService` uniquement ; aucune écriture dans la galerie du joueur sans son accord (invite native).
- **Étapes** inchangées : `…` → `decorations` → `photo` (« 7. Photo et livraison ») → accueil (acceptée) ou `refus`.

## Review Focus

- **Roblox ne peut pas créer l'avatar** (service indisponible, erreur). Attendu : pas de cliente, aucune erreur, la commande se joue normalement. Test : `25_cliente`, « avatar impossible ».
- **Synchronisations pendant la construction de l'avatar**, par exemple plusieurs actions rapides juste après la clochette, ou une commande terminée avant la fin de la construction. Attendu : une seule cliente, et aucune qui reste sans commande. Test : `26_scene_cliente_photo`, « deux synchronisations pendant la construction » et « commande abandonnée pendant la construction ».
- **Capture refusée ou sans réponse.** Attendu : l'interface, la vue et le champ de la caméra reviennent, avec un message si Roblox a refusé. Test : scénario, « capture refusée » et « capture sans réponse ».
- **Quitter la photo par un autre chemin** que le bouton (retour aux décorations, livraison, refus, mannequin reconstruit, scène détruite). Attendu : la lumière du jeu, la couleur du mannequin et l'absence de décor sont rétablies. Tests : `26`, « quitter la présentation rétablit tout », et scénario, « en quittant la présentation ».
- **Clochette pendant l'adieu de la cliente précédente.** Attendu : une seule cliente à la fois. Test : `26`, « une cliente à la fois ».

Hors simulation, à regarder dans Studio (tâche 4) : cadrage de la photo sur un écran large ; bras, coiffure et pieds de l'avatar réel.

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/client/Atelier/Cliente.luau` | **Nouveau** : tenues, description, construction de l'avatar (échelle, bras, coiffure, pieds au sol), bulle de dialogue |
| `src/client/Atelier/Scene.luau` | + la cliente en personne (`suivreCliente`), les réglages de la photo (`photo`, `finirPhoto`), le cadrage (`cadrerPhoto`) ; `synchroniser(etat, derniere)` |
| `src/client/Atelier/EcranPresentation.luau` | Réécrit : réglages, prise de vue, aperçu, galerie, livraison |
| `src/client/Atelier/init.client.luau` | Titre « 7. Photo et livraison » ; la scène reçoit `session.derniere` |
| `tests/mock.luau`, `tests/gen_api.py` | Faux Roblox : pivot et échelle d'un modèle, avatar R15 simplifié, `Lighting`, `CaptureService`, champ de la caméra |
| `tests/unitaires/25_cliente.luau`, `26_scene_cliente_photo.luau` | Tests unitaires |
| `tests/scenario.luau` | Complété (cliente, photo, capture, adieu) |
| `README.md`, `AtelierCouture.rbxl` | État du jeu, lieu régénéré |

---

### Task 1: La cliente, construite en code

**Files:**
- Modify: `tests/gen_api.py:41` (classes nécessaires)
- Modify: `tests/mock.luau` (après `methodes.ScreenPointToRay` ; liste des services ; propriétés de départ)
- Create: `src/client/Atelier/Cliente.luau`
- Test: `tests/unitaires/25_cliente.luau`

**Interfaces:**
- Consumes: `Commandes.generer(rng)` → `{ taille, mesures, exigences }` (plan 1).
- Produces:
  - `Cliente.TENUES` : liste de `{ nom, peau, haut, bas, cheveux }` (Color3) ; `Cliente.ECHELLE = 0.85`.
  - `Cliente.choisir(commande) -> number` (indice dans `TENUES`, stable pour une commande).
  - `Cliente.description(commande) -> HumanoidDescription`.
  - `Cliente.construire(commande, cadre: CFrame, parent: Instance) -> Model?` : modèle nommé `Cliente`, racine ancrée, pieds à `cadre.Position.Y` ; `nil` si Roblox échoue.
  - `Cliente.dire(modele: Model?, texte: string?)` : bulle `Head.Bulle` (`BillboardGui`) avec le `TextLabel` `Texte` ; `texte = nil` la retire.
  - Faux Roblox : `Model:GetPivot/PivotTo/GetScale/ScaleTo` ; `Players:CreateHumanoidModelFromDescriptionAsync` (`M.echecAvatar` : panne ; `M.pendantAvatar()` : appelé une fois pendant la construction ; `M.derniereDescription`) ; `CaptureService:CaptureScreenshot` (`M.surCapture()` au moment de la prise ; `M.echecCapture` : refus ; `M.captureMuette` : pas de réponse ; `M.captures` : nombre, image `"rbxtemp://capture/<n>"`) ; `CaptureService:PromptSaveCapturesToGallery` (`M.galerie` : captures proposées, toutes acceptées) ; `Lighting` avec les valeurs de départ de Roblox ; `Camera.FieldOfView = 70`.

- [ ] **Step 1: Outiller le faux Roblox**

Dans `tests/gen_api.py`, ajouter `"Lighting","CaptureService"` à la fin de l'ensemble `needed` (ligne 41) :

```python
           "LocalScript","Camera","Humanoid","Part","MeshPart","AssetService","PlayerGui","DataModel","IntValue","RemoteFunction","ServerScriptService","StarterPlayer","StarterPlayerScripts","SpawnLocation","StarterGui","Lighting","CaptureService"}
```

Dans `tests/mock.luau`, juste après la fonction `methodes.ScreenPointToRay` (avant `function methodes.GetMouseLocation`), insérer :

```lua
-- Pivot d'un modèle : sa PrimaryPart, sinon le dernier pivot posé
function methodes.GetPivot(self)
	local principale = rawget(self, "__props").PrimaryPart
	if principale then
		return principale.CFrame
	end
	return rawget(self, "__pivot") or CFrame.new()
end
function methodes.PivotTo(self, cf)
	local ancien = methodes.GetPivot(self)
	for _, d in ipairs(self:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = cf * (ancien:Inverse() * d.CFrame)
		end
	end
	rawset(self, "__pivot", cf)
end
-- Échelle d'un modèle : tailles et positions des pièces autour du pivot
function methodes.GetScale(self)
	return rawget(self, "__echelle") or 1
end
function methodes.ScaleTo(self, echelle)
	local facteur = echelle / methodes.GetScale(self)
	local pivot = methodes.GetPivot(self)
	for _, d in ipairs(self:GetDescendants()) do
		if d:IsA("BasePart") then
			local local_ = pivot:Inverse() * d.CFrame
			d.Size = d.Size * facteur
			d.CFrame = pivot * CFrame.new(local_.Position * facteur) * (CFrame.new(local_.Position):Inverse() * local_)
		end
	end
	rawset(self, "__echelle", echelle)
end
-- Avatar R15 simplifié (racine, torse, tête, Humanoid) ; M.echecAvatar simule une panne de Roblox ;
-- M.pendantAvatar() est appelé une fois pendant la construction (ce qui se passe pendant l'attente)
function methodes.CreateHumanoidModelFromDescriptionAsync(_, description, _rig)
	if M.echecAvatar then
		error("CreateHumanoidModelFromDescriptionAsync : panne simulée")
	end
	local pendant = M.pendantAvatar
	if pendant then
		M.pendantAvatar = nil
		pendant()
	end
	M.derniereDescription = description
	local modele = nouvelleInstance("Model")
	local function partie(nom, taille, y)
		local p = nouvelleInstance("Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = CFrame.new(0, y, 0)
		p.Parent = modele
		return p
	end
	local racine = partie("HumanoidRootPart", Vector3.new(2, 2, 1), 3)
	partie("UpperTorso", Vector3.new(2, 1.6, 1), 3.4)
	partie("Head", Vector3.new(1.2, 1.2, 1.2), 4.8)
	nouvelleInstance("Humanoid").Parent = modele
	modele.PrimaryPart = racine
	return modele
end
-- Captures d'écran : M.surCapture() est appelé au moment de la prise (pour vérifier ce qui est affiché) ;
-- M.echecCapture simule un refus de Roblox, M.captureMuette une capture qui ne répond jamais
function methodes.CaptureScreenshot(_, rappel)
	if M.echecCapture then
		error("CaptureScreenshot : refus simulé")
	end
	if M.captureMuette then
		return
	end
	M.captures = (M.captures or 0) + 1
	if M.surCapture then
		M.surCapture()
	end
	rappel("rbxtemp://capture/" .. M.captures)
end
function methodes.PromptSaveCapturesToGallery(_, captures, rappel)
	M.galerie = captures
	local resultats = {}
	for _, c in ipairs(captures) do
		resultats[c] = true
	end
	rappel(resultats)
end
```

Dans la liste des services créés par `M.initialiser` (elle finit par `"AssetService",` et `"StarterGui",`), ajouter `"Lighting",` et `"CaptureService",` après `"StarterGui",`. Puis, juste après la boucle qui crée les services, remplacer les deux lignes

```lua
	local camera = nouvelleInstance("Camera")
	rawget(camera, "__props").ViewportSize = Vector2.new(1280, 720)
```

par (valeurs de départ de la lumière de Roblox, champ de départ de la caméra) :

```lua
	local lumiere = rawget(M.services.Lighting, "__props")
	lumiere.Ambient, lumiere.OutdoorAmbient = Color3.fromRGB(70, 70, 70), Color3.fromRGB(128, 128, 128)
	lumiere.Brightness, lumiere.ClockTime, lumiere.ExposureCompensation = 2, 14, 0
	local camera = nouvelleInstance("Camera")
	rawget(camera, "__props").ViewportSize = Vector2.new(1280, 720)
	rawget(camera, "__props").FieldOfView = 70
```

- [ ] **Step 2: Écrire le test de la cliente**

`tests/unitaires/25_cliente.luau` :

```lua
local Cliente = U.module("Cliente")
local Commandes = U.module("Commandes")

---------------------------------------------------------------------------
-- Tenue : la même pour une commande donnée, variée d'une commande à l'autre
---------------------------------------------------------------------------
local vues = {}
for g = 1, 40 do
	local commande = Commandes.generer(Random.new(g))
	local k = Cliente.choisir(commande)
	U.verifier(k >= 1 and k <= #Cliente.TENUES and k == Cliente.choisir(commande), "tenue stable pour une commande (" .. g .. ")")
	vues[k] = true
end
local nb = 0
for _ in pairs(vues) do
	nb += 1
end
U.verifier(nb >= 3, "au moins trois tenues différentes sur 40 commandes (" .. nb .. ")")

---------------------------------------------------------------------------
-- Description : couleurs de la tenue, silhouette selon la taille
---------------------------------------------------------------------------
local commande = { taille = "M", mesures = { poitrine = 8.8, taille = 7, hanches = 9.4 }, exigences = { { type = "min", style = "chic", valeur = 20 } } }
local tenue = Cliente.TENUES[Cliente.choisir(commande)]
local d = Cliente.description(commande)
U.verifier(d.TorsoColor == tenue.haut and d.LeftLegColor == tenue.bas and d.HeadColor == tenue.peau and d.LeftArmColor == tenue.peau, "couleurs de la tenue : peau, haut, bas")
local dS = Cliente.description({ taille = "S", exigences = commande.exigences })
local dL = Cliente.description({ taille = "L", exigences = commande.exigences })
U.verifier(dS.WidthScale < d.WidthScale and d.WidthScale < dL.WidthScale, "silhouette : S plus fine que M, M plus fine que L")

---------------------------------------------------------------------------
-- Construction : un avatar immobile, coiffé, à sa place
---------------------------------------------------------------------------
local Workspace = M.services.Workspace
local place = CFrame.new(3, 0, 40) * CFrame.Angles(0, math.rad(-120), 0)
local modele = Cliente.construire(commande, place, Workspace)
U.verifier(modele ~= nil and modele.Name == "Cliente" and modele.Parent == Workspace, "la cliente est dans l'atelier")
U.verifier(modele:FindFirstChild("Humanoid") ~= nil and M.derniereDescription ~= nil and M.derniereDescription.TorsoColor == tenue.haut, "avatar construit d'après sa description")
U.verifier(modele.HumanoidRootPart.Anchored, "elle reste en place")
U.verifier(modele:GetScale() == Cliente.ECHELLE and Cliente.ECHELLE < 1, "réduite à la taille du mannequin (un avatar Roblox est plus grand)")
U.verifier(modele.Humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None, "pas d'étiquette de nom au-dessus d'elle")
local cheveux = modele:FindFirstChild("Cheveux")
U.verifier(cheveux ~= nil and cheveux.Color == tenue.cheveux and not cheveux.CanCollide, "coiffée, aux couleurs de la tenue")
local bas = math.huge
for _, d in ipairs(modele:GetDescendants()) do
	if d:IsA("BasePart") and d.Name ~= "Cheveux" then
		bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
	end
end
local pivot = modele:GetPivot().Position
U.verifier(math.abs(bas - place.Position.Y) < 1e-6 and math.abs(pivot.X - 3) < 1e-6 and math.abs(pivot.Z - 40) < 1e-6, "posée à sa place, les pieds au sol")

---------------------------------------------------------------------------
-- Bulle de dialogue
---------------------------------------------------------------------------
Cliente.dire(modele, "Bonjour !")
local bulle = modele.Head:FindFirstChild("Bulle")
U.verifier(bulle ~= nil and bulle:IsA("BillboardGui") and bulle.Texte.Text == "Bonjour !", "la cliente parle")
U.verifier(bulle.Texte.TextSize >= 14, "texte de bulle lisible (14 px au moins)")
Cliente.dire(modele, "Merci !")
local nbBulles = 0
for _, c in ipairs(modele.Head:GetChildren()) do
	if c.Name == "Bulle" then
		nbBulles += 1
	end
end
U.verifier(nbBulles == 1 and modele.Head.Bulle.Texte.Text == "Merci !", "une seule bulle à la fois")
Cliente.dire(modele, nil)
U.verifier(modele.Head:FindFirstChild("Bulle") == nil, "plus rien à dire : la bulle disparaît")

---------------------------------------------------------------------------
-- Panne de Roblox : pas de cliente, sans erreur
---------------------------------------------------------------------------
M.echecAvatar = true
U.verifier(Cliente.construire(commande, place, Workspace) == nil, "avatar impossible : pas de cliente, sans erreur")
M.echecAvatar = false
modele:Destroy()
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|bloquerait" | head -3`
Expected: échec : une ligne qui finit par `WaitForChild bloquerait : Cliente absent de Couture` (le module n'existe pas encore)

- [ ] **Step 4: Écrire le module `Cliente`**

`src/client/Atelier/Cliente.luau` :

```lua
-- Cliente : la cliente en personne (client). Un avatar Roblox construit en code, sans aucun modèle
-- externe : la tenue est faite des couleurs du corps (peau, haut, bas) et d'une coiffure simple, tirée
-- d'après la commande ; la silhouette suit sa taille (S, M, L). Elle parle par une bulle.
local Players = game:GetService("Players")

local Cliente = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Cliente.TENUES = {
	{ nom = "Rose poudré", peau = rgb(234, 192, 160), haut = rgb(236, 150, 180), bas = rgb(120, 90, 110), cheveux = rgb(90, 60, 40) },
	{ nom = "Marine", peau = rgb(160, 110, 80), haut = rgb(60, 80, 140), bas = rgb(230, 230, 235), cheveux = rgb(30, 25, 25) },
	{ nom = "Tournesol", peau = rgb(250, 214, 180), haut = rgb(245, 200, 70), bas = rgb(90, 120, 80), cheveux = rgb(200, 150, 70) },
	{ nom = "Prune", peau = rgb(110, 75, 55), haut = rgb(120, 60, 110), bas = rgb(40, 35, 45), cheveux = rgb(20, 15, 15) },
	{ nom = "Menthe", peau = rgb(240, 200, 170), haut = rgb(150, 210, 180), bas = rgb(240, 235, 220), cheveux = rgb(160, 50, 40) },
}
local LARGEURS = { S = 0.9, M = 1, L = 1.12 } -- silhouette selon la taille de la cliente
Cliente.ECHELLE = 0.85 -- un avatar Roblox (≈ 5,2 studs) est plus grand que le mannequin (≈ 4,3 studs)
local EPAULES = 62 -- degrés : bras baissés, mains jointes devant (un avatar sans animation reste bras écartés)

-- Tenue tirée d'après la commande : toujours la même pour une commande donnée
function Cliente.choisir(commande)
	local texte = tostring(commande.taille)
	for _, e in ipairs(commande.exigences or {}) do
		texte ..= "|" .. tostring(e.type) .. tostring(e.style or e.teinte or e.id or "") .. tostring(e.valeur or "")
	end
	local h = 0
	for i = 1, #texte do
		h = (h * 31 + string.byte(texte, i)) % 1000003
	end
	return h % #Cliente.TENUES + 1
end

function Cliente.description(commande)
	local t = Cliente.TENUES[Cliente.choisir(commande)]
	local d = Instance.new("HumanoidDescription")
	d.HeadColor, d.LeftArmColor, d.RightArmColor = t.peau, t.peau, t.peau
	d.TorsoColor = t.haut
	d.LeftLegColor, d.RightLegColor = t.bas, t.bas
	d.WidthScale = LARGEURS[commande.taille] or 1
	d.DepthScale = d.WidthScale
	return d
end

local avertie = false

-- Avatar immobile posé à « cadre » (pieds au sol), ou nil si Roblox ne peut pas le créer
function Cliente.construire(commande, cadre, parent)
	local ok, modele = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(Cliente.description(commande), Enum.HumanoidRigType.R15)
	end)
	if not ok or not modele then
		if not avertie then
			avertie = true
			warn("[Atelier] Cliente non affichée : " .. tostring(modele))
		end
		return nil
	end
	modele.Name = "Cliente"
	local humanoide = modele:FindFirstChild("Humanoid")
	if humanoide then
		humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	for nom, signe in pairs({ LeftShoulder = 1, RightShoulder = -1 }) do
		local epaule = modele:FindFirstChild(nom, true)
		if epaule and (epaule:IsA("AnimationConstraint") or epaule:IsA("Motor6D")) then
			epaule.Transform = CFrame.Angles(0, 0, math.rad(EPAULES * signe))
		end
	end
	local racine = modele:FindFirstChild("HumanoidRootPart")
	if racine then
		racine.Anchored = true
	end
	local tete = modele:FindFirstChild("Head")
	if tete then
		local cheveux = Instance.new("Part")
		cheveux.Name = "Cheveux"
		cheveux.Shape = Enum.PartType.Ball
		cheveux.Size = tete.Size * 1.3 -- la tête R15 dépasse sa taille déclarée
		cheveux.Color = Cliente.TENUES[Cliente.choisir(commande)].cheveux
		cheveux.Material = Enum.Material.SmoothPlastic
		cheveux.CanCollide = false
		cheveux.CanQuery = false
		cheveux.CanTouch = false
		cheveux.Massless = true
		cheveux.CFrame = tete.CFrame * CFrame.new(0, tete.Size.Y * 0.22, tete.Size.Z * 0.22) -- dégage le visage
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0, soudure.Part1 = tete, cheveux
		soudure.Parent = cheveux
		cheveux.Parent = modele
	end
	modele:ScaleTo(Cliente.ECHELLE)
	-- Le pivot d'un avatar est sa racine (au niveau des hanches) : on le monte de la hauteur des jambes
	local bas = math.huge
	for _, d in ipairs(modele:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Cheveux" then
			bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
		end
	end
	local hauteur = bas < math.huge and modele:GetPivot().Position.Y - bas or 0
	modele:PivotTo(cadre * CFrame.new(0, hauteur, 0))
	modele.Parent = parent
	return modele
end

-- Bulle de dialogue au-dessus de la tête (texte nil : la bulle disparaît)
function Cliente.dire(modele, texte)
	local tete = modele and modele:FindFirstChild("Head")
	if not tete then
		return
	end
	local ancienne = tete:FindFirstChild("Bulle")
	if ancienne then
		ancienne:Destroy()
	end
	if not texte then
		return
	end
	local bulle = Instance.new("BillboardGui")
	bulle.Name = "Bulle"
	bulle.Size = UDim2.fromOffset(240, 60)
	bulle.StudsOffset = Vector3.new(0, 2.2, 0)
	bulle.AlwaysOnTop = true
	local cadre = Instance.new("TextLabel")
	cadre.Name = "Texte"
	cadre.Size = UDim2.fromScale(1, 1)
	cadre.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cadre.TextColor3 = Color3.fromRGB(58, 36, 48)
	cadre.Font = Enum.Font.GothamBold
	cadre.TextSize = 16
	cadre.TextWrapped = true
	cadre.Text = texte
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0, 12)
	coin.Parent = cadre
	cadre.Parent = bulle
	bulle.Parent = tete
end

return Cliente
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104667 vérifications
TOUT EST VERT : 267 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add tests/gen_api.py tests/mock.luau src/client/Atelier/Cliente.luau tests/unitaires/25_cliente.luau
git commit -m "La cliente en personne : avatar construit en code, tenue tirée d'après la commande, bulle

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: La cliente et la photo dans la scène

**Files:**
- Modify: `src/client/Atelier/Scene.luau` (en-tête, `require`, constantes, champs de `Scene.nouvelle`, nouvelles méthodes avant `synchroniser`, `synchroniser`, `detruire`)
- Test: `tests/unitaires/26_scene_cliente_photo.luau`

**Interfaces:**
- Consumes: `Cliente.construire`, `Cliente.dire` (tâche 1) ; `EtatAtelier` (étapes, `nouvelleCommande`, `livrer`, `retoucher`, `abandonner`, `decorer`) ; `Session.derniere = { action, reponse }` (plan 3c).
- Produces:
  - `Scene.CLIENTE: CFrame`, `Scene.DUREE_ADIEU = 3`, `Scene.PAROLES = { carnet, photo, refus, merci, abandon }`.
  - `Scene.DECORS`, `Scene.LUMIERES`, `Scene.MANNEQUINS` (clés : `rose|bleu|creme|nuit`, `jour|doux|soir`, `creme|noir|bois`).
  - `Scene.CAMERA_PHOTO: CFrame`, `Scene.CHAMP_PHOTO = 42`, `Scene.ATTENTE_CAPTURE = 2`.
  - `scene:suivreCliente(etat, derniere)`, `scene:photo({ decor, lumiere, mannequin })`, `scene:finirPhoto()`, `scene:cadrerPhoto(actif: boolean)`.
  - `scene:synchroniser(etat, derniere)` : `derniere` facultatif (la dernière action réussie de la session).
  - Champ `scene.cliente` : le modèle de la cliente en cours, ou `nil`. Pièces nommées `Cliente` et `Fond` dans `scene.dossier`.

- [ ] **Step 1: Écrire le test de la scène**

`tests/unitaires/26_scene_cliente_photo.luau` :

```lua
local Scene = U.module("Scene")
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")

local Workspace = M.services.Workspace
local Lighting = M.services.Lighting
M.budget.images, M.budget.maillages = 64, 7

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- De la commande jusqu'à la présentation (robe cousue parfaitement, sans décoration)
local function jusquALaPhoto(etat)
	local tissus = {}
	for id in pairs(PLACES) do
		tissus[id] = "coton_blanc"
	end
	etat:validerCroquis(CROQUIS, tissus)
	etat:acheter("coton_blanc", 12)
	etat:commencerDecoupe()
	for _, id in ipairs(etat:piecesDuCroquis()) do
		etat:couper(id, PLACES[id])
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		etat:epingler(id)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		local _, longueur = Patron.trajetCouture(id)
		etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur)
	end
	etat:decorer({})
end
local function bulle(modele)
	local b = modele and modele.Head:FindFirstChild("Bulle")
	return b and b.Texte.Text or nil
end
local function pieds(modele)
	local bas = math.huge
	for _, d in ipairs(modele:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Cheveux" then
			bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
		end
	end
	return bas
end

---------------------------------------------------------------------------
-- La cliente en personne
---------------------------------------------------------------------------
local etat = EtatAtelier.nouveau(1000)
local scene = Scene.nouvelle(Workspace, { etaler = false, controles = function() end })
local function compterClientes()
	local n = 0
	for _, c in ipairs(scene.dossier:GetChildren()) do
		if c.Name == "Cliente" then
			n += 1
		end
	end
	return n
end
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Cliente") == nil, "personne à l'accueil avant la clochette")
etat:nouvelleCommande(Random.new(3))
scene:synchroniser(etat, nil)
local cliente = scene.dossier:FindFirstChild("Cliente")
U.verifier(cliente ~= nil, "la clochette fait entrer la cliente")
U.verifier(math.abs(pieds(cliente) - Scene.CLIENTE.Position.Y) < 1e-6, "elle a les pieds au sol")
U.verifier(bulle(cliente) == Scene.PAROLES.carnet, "au carnet, elle dit ce qu'elle veut")
etat.etape = "achat"
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Cliente") == cliente and bulle(cliente) == nil, "pendant le travail : la même cliente, silencieuse")
etat.etape = "carnet"
jusquALaPhoto(etat)
scene:synchroniser(etat, nil)
U.verifier(etat.etape == "photo" and bulle(cliente) == Scene.PAROLES.photo, "à la présentation, elle regarde la robe")

-- Refus puis livraison acceptée : elle remercie, puis s'en va
etat.commande.exigences = { { type = "accessoire", id = "croix_argent" } }
local r = etat:livrer()
scene:synchroniser(etat, { action = "livrer", reponse = r })
U.verifier(bulle(cliente) == Scene.PAROLES.refus, "robe refusée : elle le dit")
etat:retoucher()
etat.commande.exigences = { { type = "qualite", valeur = 0.5 } }
etat:decorer({})
r = etat:livrer()
scene:synchroniser(etat, { action = "livrer", reponse = r })
U.verifier(r.reussie and bulle(cliente) == Scene.PAROLES.merci and cliente.Parent ~= nil, "robe acceptée : elle remercie")
M.avancer(Scene.DUREE_ADIEU + 0.5)
U.verifier(cliente.Parent == nil and scene.dossier:FindFirstChild("Cliente") == nil, "puis elle s'en va")

-- Nouvelle cliente, abandon : elle s'en va aussi ; une suivante chasse la précédente tout de suite
etat:nouvelleCommande(Random.new(4))
scene:synchroniser(etat, nil)
local deuxieme = scene.dossier:FindFirstChild("Cliente")
U.verifier(deuxieme ~= nil and deuxieme ~= cliente, "nouvelle commande : nouvelle cliente")
etat.etape = "refus"
etat:abandonner()
scene:synchroniser(etat, { action = "abandonner", reponse = { ok = true } })
U.verifier(bulle(deuxieme) == Scene.PAROLES.abandon, "abandon : elle le regrette")
etat:nouvelleCommande(Random.new(5))
scene:synchroniser(etat, nil)
U.verifier(deuxieme.Parent == nil and compterClientes() == 1, "une cliente à la fois : la précédente part dès qu'une autre entre")

-- La construction de l'avatar attend : une autre synchronisation pendant ce temps n'en crée pas une seconde
-- La cliente renonce (robe refusée puis abandonnée) : la commande se termine
local function renoncer()
	etat.etape = "refus"
	local r = etat:abandonner()
	scene:synchroniser(etat, { action = "abandonner", reponse = r })
	return r.ok
end
U.verifier(renoncer() and etat:nouvelleCommande(Random.new(6)).ok, "commande suivante prête")
M.pendantAvatar = function()
	scene:synchroniser(etat, nil)
end
scene:synchroniser(etat, nil)
U.verifier(compterClientes() == 1 and scene.cliente ~= nil and scene.cliente.Parent == scene.dossier, "deux synchronisations pendant la construction : une seule cliente")
-- La commande est abandonnée pendant la construction : l'avatar construit ne reste pas
U.verifier(renoncer(), "elle renonce")
M.avancer(Scene.DUREE_ADIEU + 0.5)
U.verifier(compterClientes() == 0 and etat:nouvelleCommande(Random.new(7)).ok, "elle est partie, commande suivante prête")
M.pendantAvatar = function()
	renoncer()
end
scene:synchroniser(etat, nil)
U.verifier(M.pendantAvatar == nil and compterClientes() == 0 and scene.cliente == nil, "commande abandonnée pendant la construction : personne ne reste")
U.verifier(etat:nouvelleCommande(Random.new(8)).ok, "commande suivante prête")
scene:synchroniser(etat, nil)
U.verifier(compterClientes() == 1, "la cliente suivante entre normalement")

---------------------------------------------------------------------------
-- Photo : décor, lumière, couleur du mannequin, puis tout est rétabli
---------------------------------------------------------------------------
local lumiereAvant = { Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient }
local mannequin = scene.dossier:FindFirstChild("Mannequin")
local busteAvant = mannequin.Buste.Color
scene:photo({ decor = "bleu", lumiere = "soir", mannequin = "noir" })
local fond = scene.dossier:FindFirstChild("Fond")
U.verifier(fond ~= nil and fond.Color == Scene.DECORS.bleu, "décor bleu derrière le mannequin")
U.verifier(fond.CFrame.Position.Z > Scene.CADRE.Position.Z, "le décor est derrière le mannequin (vu de face)")
U.verifier(Lighting.ClockTime == Scene.LUMIERES.soir.ClockTime and Lighting.Brightness == Scene.LUMIERES.soir.Brightness, "lumière du soir")
U.verifier(mannequin.Buste.Color == Scene.MANNEQUINS.noir and mannequin.Pied.Color ~= Scene.MANNEQUINS.noir, "mannequin noir (le pied en bois ne change pas)")
scene:photo({ decor = "rose", lumiere = "jour", mannequin = "creme" })
U.verifier(fond.Color == Scene.DECORS.rose and #scene.dossier:GetChildren() > 0, "changer de décor ne crée pas un second fond")
scene:finirPhoto()
U.verifier(scene.dossier:FindFirstChild("Fond") == nil, "fin de la photo : plus de décor")
U.verifier(Lighting.ClockTime == lumiereAvant[1] and Lighting.Brightness == lumiereAvant[2] and Lighting.Ambient == lumiereAvant[3], "lumière du jeu rétablie")
U.verifier(mannequin.Buste.Color == busteAvant, "mannequin rétabli")
scene:photo({ decor = "nuit", lumiere = "doux", mannequin = "bois" })
etat.etape = "carnet"
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Fond") == nil and Lighting.ClockTime == lumiereAvant[1], "quitter la présentation rétablit tout")
scene:detruire()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : la clochette fait entrer la cliente`

- [ ] **Step 3: La scène fait entrer la cliente et tient la photo**

Dans `src/client/Atelier/Scene.luau` :

1. Remplacer les trois premières lignes de commentaire (`-- Scene : le coin de l'atelier en 3D, côté client. Le mannequin aux mesures…`, jusqu'à `…(qui peut tourner pendant les décorations).`) par :

```lua
-- Scene : le coin de l'atelier en 3D, côté client. La cliente en personne, le mannequin à ses mesures,
-- les pièces épinglées dessus (le vrai tissu découpé), l'aperçu des décorations, les réglages de la photo,
-- la vitrine de la dernière robe livrée, et la caméra fixe des postes autour du mannequin (qui peut
-- tourner pendant les décorations).
```

2. Après `local Vitrines = require(Couture:WaitForChild("Vitrines"))`, ajouter :

```lua
local Lighting = game:GetService("Lighting")
local Cliente = require(script.Parent:WaitForChild("Cliente"))
```

3. Après `Scene.VITRINE = CFrame.new(7, 0.5, 52)`, ajouter :

```lua
-- La cliente attend en retrait à côté du mannequin (à gauche à l'écran), tournée vers la caméra ; pieds au sol
Scene.CLIENTE = CFrame.lookAt(Vector3.new(4.6, 0, 42), Vector3.new(-1.1, 0, 34.6))
Scene.DUREE_ADIEU = 3 -- secondes avant qu'elle s'en aille, une fois la commande finie
Scene.PAROLES = {
	carnet = "Bonjour ! J'aurais besoin d'une robe.",
	photo = "Voyons voir…",
	refus = "Ce n'est pas tout à fait ce que je voulais.",
	merci = "Merci, elle est parfaite !",
	abandon = "Tant pis… Au revoir.",
}

-- Réglages de la photo
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
Scene.DECORS = { rose = rgb(250, 222, 232), bleu = rgb(196, 214, 240), creme = rgb(245, 236, 216), nuit = rgb(38, 38, 58) }
Scene.LUMIERES = {
	jour = { Ambient = rgb(70, 70, 70), OutdoorAmbient = rgb(128, 128, 128), Brightness = 2, ClockTime = 14, ExposureCompensation = 0 },
	doux = { Ambient = rgb(110, 100, 110), OutdoorAmbient = rgb(150, 140, 150), Brightness = 1.5, ClockTime = 16.5, ExposureCompensation = 0.2 },
	soir = { Ambient = rgb(90, 70, 90), OutdoorAmbient = rgb(110, 80, 100), Brightness = 1, ClockTime = 18.3, ExposureCompensation = 0.3 },
}
Scene.MANNEQUINS = { creme = rgb(236, 222, 200), noir = rgb(40, 36, 40), bois = rgb(150, 110, 75) }
local CORPS_MANNEQUIN = { Buste = true, Taille = true, Bassin = true, EpauleDroite = true, EpauleGauche = true, Cou = true }
local PROPRIETES_LUMIERE = { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation" }
-- Vue de la photo : face au mannequin, centrée (l'interface est cachée pendant la prise)
Scene.CAMERA_PHOTO = CFrame.lookAt(Vector3.new(0, 2.7, 34.2), Vector3.new(0, 2.2, 40))
Scene.CHAMP_PHOTO = 42 -- degrés (vertical) : du sol au cou du mannequin, la robe remplit la photo
Scene.ATTENTE_CAPTURE = 2 -- secondes : si la capture ne répond pas, l'interface revient
```

4. Dans `Scene.nouvelle`, après le champ `orbite = 0, -- degrés autour du mannequin (décorations)`, ajouter :

```lua
		cliente = nil, -- la cliente de la commande en cours
		clienteCommande = nil, -- la commande pour laquelle elle est venue
		partante = nil, -- la cliente précédente, qui salue avant de partir
		lumiereOrigine = nil, -- lumière du jeu, gardée pendant la photo
		couleursMannequin = nil, -- couleurs du mannequin, gardées pendant la photo
		champOrigine = nil, -- champ de la caméra, gardé le temps de la prise de vue
```

5. Remplacer l'en-tête de `synchroniser` :

```lua
-- Met la scène d'accord avec l'état de l'atelier. Peut attendre (création des maillages) :
-- l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat)
```

par les nouvelles méthodes, puis le nouvel en-tête (le reste du corps de `synchroniser` ne change pas) :

```lua
-- La cliente en personne : elle entre avec la commande, parle selon l'étape, salue puis s'en va
function Scene:suivreCliente(etat, derniere)
	local commande = etat.commande
	if commande and self.clienteCommande ~= commande then
		-- Notée avant la construction, qui attend Roblox : une synchronisation pendant ce temps ne la refait pas
		self.clienteCommande = commande
		if self.cliente then
			self.cliente:Destroy()
			self.cliente = nil
		end
		if self.partante then
			self.partante:Destroy() -- la précédente part tout de suite
			self.partante = nil
		end
		local modele = Cliente.construire(commande, Scene.CLIENTE, self.dossier)
		if self.clienteCommande ~= commande then
			-- La commande a pris fin (ou changé) pendant la construction
			if modele then
				modele:Destroy()
			end
			return
		end
		self.cliente = modele
	end
	if commande then
		Cliente.dire(self.cliente, Scene.PAROLES[etat.etape])
	elseif self.cliente then
		local reussie = derniere and derniere.action == "livrer" and derniere.reponse.reussie
		Cliente.dire(self.cliente, reussie and Scene.PAROLES.merci or Scene.PAROLES.abandon)
		local partante = self.cliente
		self.partante, self.cliente, self.clienteCommande = partante, nil, nil
		task.delay(Scene.DUREE_ADIEU, function()
			partante:Destroy()
			if self.partante == partante then
				self.partante = nil
			end
		end)
	else
		self.clienteCommande = nil -- pas de commande, personne (ou avatar encore en construction)
	end
end

-- Photo : décor derrière le mannequin, lumière, couleur du mannequin (réglages = { decor, lumiere, mannequin })
function Scene:photo(reglages)
	if not self.lumiereOrigine then
		self.lumiereOrigine = {}
		for _, nom in ipairs(PROPRIETES_LUMIERE) do
			self.lumiereOrigine[nom] = Lighting[nom]
		end
	end
	local fond = self.dossier:FindFirstChild("Fond")
	if not fond then
		fond = Instance.new("Part")
		fond.Name = "Fond"
		fond.Anchored = true
		fond.CanCollide = false
		fond.CanQuery = false
		fond.CanTouch = false
		fond.Material = Enum.Material.SmoothPlastic
		fond.Size = Vector3.new(16, 12, 0.4)
		fond.CFrame = CFrame.new(Scene.CADRE.Position.X, 5, Scene.CADRE.Position.Z + 3.5)
		fond.Parent = self.dossier
	end
	fond.Color = Scene.DECORS[reglages.decor] or Scene.DECORS.creme
	for nom, valeur in pairs(Scene.LUMIERES[reglages.lumiere] or Scene.LUMIERES.jour) do
		Lighting[nom] = valeur
	end
	if self.mannequin then
		self.couleursMannequin = self.couleursMannequin or {}
		for _, p in ipairs(self.mannequin:GetChildren()) do
			if CORPS_MANNEQUIN[p.Name] then
				self.couleursMannequin[p] = self.couleursMannequin[p] or p.Color
				p.Color = Scene.MANNEQUINS[reglages.mannequin] or Scene.MANNEQUINS.creme
			end
		end
	end
end

-- Cadrage de la prise de vue (actif) : vue centrée sur la robe, bulle de la cliente cachée ;
-- sinon retour à la vue du poste
function Scene:cadrerPhoto(actif)
	local bulle = self.cliente and self.cliente:FindFirstChild("Head") and self.cliente.Head:FindFirstChild("Bulle")
	if bulle then
		bulle.Enabled = not actif
	end
	local camera = Workspace.CurrentCamera
	if actif and camera then
		self.champOrigine = self.champOrigine or camera.FieldOfView
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = Scene.CAMERA_PHOTO
		camera.FieldOfView = Scene.CHAMP_PHOTO
	else
		if camera and self.champOrigine then
			camera.FieldOfView = self.champOrigine
			self.champOrigine = nil
		end
		self:regarder(true)
	end
end

-- Fin de la photo : décor retiré, lumière du jeu et couleur du mannequin rétablies
function Scene:finirPhoto()
	local fond = self.dossier:FindFirstChild("Fond")
	if fond then
		fond:Destroy()
	end
	if self.lumiereOrigine then
		for nom, valeur in pairs(self.lumiereOrigine) do
			Lighting[nom] = valeur
		end
		self.lumiereOrigine = nil
	end
	if self.couleursMannequin then
		for p, couleur in pairs(self.couleursMannequin) do
			p.Color = couleur
		end
		self.couleursMannequin = nil
	end
end

-- Met la scène d'accord avec l'état de l'atelier (derniere = dernière action réussie de la session).
-- Peut attendre (création des maillages) : l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat, derniere)
	self:suivreCliente(etat, derniere)
	if etat.etape ~= "photo" then
		self:finirPhoto()
	end
```

6. Dans `synchroniser`, là où le mannequin est reconstruit pour de nouvelles mesures, rétablir d'abord ses couleurs :

```lua
		if self.mannequin then
			self:finirPhoto()
			self.mannequin:Destroy()
			self.mannequin = nil
		end
```

7. Au début de `Scene:detruire()`, avant `self:regarder(false)`, ajouter `self:finirPhoto()`.

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104695 vérifications
TOUT EST VERT : 267 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Scene.luau tests/unitaires/26_scene_cliente_photo.luau
git commit -m "La scène fait entrer, parler et partir la cliente, et tient les réglages de la photo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Photo et livraison à l'écran

**Files:**
- Modify: `src/client/Atelier/EcranPresentation.luau` (réécrit)
- Modify: `src/client/Atelier/init.client.luau:28` (titre) et `:178` (synchronisation)
- Test: `tests/scenario.luau` (présentation et livraison)

**Interfaces:**
- Consumes: `scene:photo`, `scene:cadrerPhoto`, `scene.ATTENTE_CAPTURE`, `Scene.PAROLES`, `Scene.DECORS`, `Scene.LUMIERES`, `Scene.MANNEQUINS`, `Scene.CAMERA_PHOTO`, `Scene.CHAMP_PHOTO`, `Scene.DUREE_ADIEU` (tâche 2) ; `ctx = { session, contenu, fenetre, scene, message, UiKit }` (plan 3c) ; `CaptureService`.
- Produces: boutons `Decor_<clé>`, `Lumiere_<clé>`, `Mannequin_<clé>`, `PrendrePhoto`, `Livrer`, `RetourDecorations`, `Recommencer` ; cadre `Apercu` (image `Image`, boutons `EnregistrerPhoto`, `FermerApercu`) ; titre « 7. Photo et livraison ».

- [ ] **Step 1: Compléter le scénario**

Dans `tests/scenario.luau` :

1. Remplacer `verifier(titre() == "7. Présentation" and argent() == avantDeco - coutRuban, "présenter : décorations payées")` par :

```lua
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco - coutRuban, "présenter : décorations payées")
```

2. Entre `verifierTailles("présentation")` et le `cliquer("RetourDecorations")` qui le suit, insérer :

```lua
-- La cliente en personne regarde la robe
local laCliente = scene:FindFirstChild("Cliente")
verifier(laCliente ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.photo, "la cliente est là et regarde la robe")
-- Photo : décor, lumière, couleur du mannequin
local Lighting = M.services.Lighting
local heureDuJeu = Lighting.ClockTime
cliquer("Decor_bleu")
cliquer("Lumiere_soir")
cliquer("Mannequin_noir")
verifier(scene.Fond.Color == ScenePoste.DECORS.bleu and Lighting.ClockTime == ScenePoste.LUMIERES.soir.ClockTime and scene.Mannequin.Buste.Color == ScenePoste.MANNEQUINS.noir, "décor bleu, lumière du soir, mannequin noir")
verifier(boutonNomme("Decor_bleu").BackgroundColor3 == ACCENT, "le décor choisi est en surbrillance")
-- Capture refusée par Roblox : l'interface revient, avec un message
M.echecCapture = true
cliquer("PrendrePhoto")
M.echecCapture = nil
verifier(gui.Atelier.Enabled and camera.CFrame == ScenePoste.CAMERA and fenetre.Message.Visible and fenetre.Message.Text == "La photo n'a pas pu être prise.", "capture refusée : interface rétablie, message")
verifier(not fenetre.Contenu.Apercu.Visible, "capture refusée : pas d'aperçu")
-- Capture qui ne répond pas : l'interface revient au bout d'un moment
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
verifier(not gui.Atelier.Enabled, "capture en cours : interface cachée")
M.avancer(ScenePoste.ATTENTE_CAPTURE + 0.1)
verifier(gui.Atelier.Enabled and camera.CFrame == ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
-- Prise de vue : sans l'interface, vue centrée sur la robe ; puis aperçu et enregistrement
local pendant = nil
M.surCapture = function()
	pendant = { interface = gui.Atelier.Enabled, vue = camera.CFrame, bulle = laCliente.Head.Bulle.Enabled, champ = camera.FieldOfView }
end
cliquer("PrendrePhoto")
M.surCapture = nil
verifier(pendant ~= nil and pendant.interface == false and pendant.vue == ScenePoste.CAMERA_PHOTO and pendant.bulle == false, "photo prise sans l'interface ni la bulle, vue centrée sur la robe")
verifier(pendant.champ == ScenePoste.CHAMP_PHOTO and ScenePoste.CHAMP_PHOTO < 70, "champ resserré sur la robe pendant la prise")
verifier(gui.Atelier.Enabled and camera.CFrame == ScenePoste.CAMERA and laCliente.Head.Bulle.Enabled and camera.FieldOfView == 70, "après la photo : interface, vue, champ et bulle rétablis")
local apercu = fenetre.Contenu:FindFirstChild("Apercu")
verifier(apercu ~= nil and apercu.Visible and apercu.Image.Image == "rbxtemp://capture/" .. M.captures, "aperçu de la photo")
cliquer("EnregistrerPhoto")
verifier(M.galerie ~= nil and M.galerie[1] == apercu.Image.Image and fenetre.Message.Visible, "photo proposée à la galerie du joueur")
cliquer("FermerApercu")
verifier(not apercu.Visible, "aperçu refermé")
```

puis, juste après ce `cliquer("RetourDecorations")`, insérer :

```lua
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu and scene.Mannequin.Buste.Color ~= ScenePoste.MANNEQUINS.noir, "en quittant la présentation : décor, lumière et mannequin rétablis")
```

3. Après `verifier(#robe:GetChildren() == 0 and #decorations:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "atelier libéré, caméra rendue au joueur")`, insérer :

```lua
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.merci, "la cliente remercie")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil, "puis elle s'en va")
```

puis, juste après le `cliquer("Clochette")` qui suit, insérer :

```lua
verifier(scene:FindFirstChild("Cliente") ~= nil and scene.Cliente ~= laCliente, "la cliente suivante entre")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : présenter : décorations payées` (unitaires : 104695 vérifications)

- [ ] **Step 3: Réécrire l'écran de présentation**

`src/client/Atelier/EcranPresentation.luau` :

```lua
-- Présentation (panneau à droite, la robe décorée sur le mannequin, vue de face) : la cliente regarde
-- la robe. On règle la photo (décor, lumière, couleur du mannequin), on la prend (sans l'interface),
-- on peut l'enregistrer dans la galerie ; puis on livre, ou on retourne aux décorations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))

local CHOIX = {
	{ cle = "decor", nom = "Décor", prefixe = "Decor_", options = { { "rose", "Rose" }, { "bleu", "Bleu" }, { "creme", "Crème" }, { "nuit", "Nuit" } } },
	{ cle = "lumiere", nom = "Lumière", prefixe = "Lumiere_", options = { { "jour", "Jour" }, { "doux", "Doux" }, { "soir", "Soir" } } },
	{ cle = "mannequin", nom = "Mannequin", prefixe = "Mannequin_", options = { { "creme", "Crème" }, { "noir", "Noir" }, { "bois", "Bois" } } },
}

return function(ctx)
	local UiKit, session, contenu, scene = ctx.UiKit, ctx.session, ctx.contenu, ctx.scene
	local C = UiKit.COULEURS
	local etat = session.etat
	local bilan = Notation.bilan(etat:recette())
	local reglages = { decor = "creme", lumiere = "jour", mannequin = "creme" }

	UiKit.texte({ Text = "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Name = "Qualite",
		Text = ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = contenu,
	})
	UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	for i, e in ipairs(etat.commande.exigences) do
		UiKit.texte({ Text = "· " .. UiKit.exigence(e, Catalogue, bilan.styles), TextSize = 14, Position = UDim2.fromOffset(0, 58 + i * 22), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end

	-- Réglages de la photo
	local boutons = {}
	local function rafraichir()
		for cle, liste in pairs(boutons) do
			for valeur, b in pairs(liste) do
				local actif = reglages[cle] == valeur
				b.BackgroundColor3 = actif and C.accent or C.secondaire
				b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
			end
		end
		scene:photo(reglages)
	end
	for ligne, choix in ipairs(CHOIX) do
		local y = 148 + (ligne - 1) * 34
		UiKit.texte({ Text = choix.nom, TextSize = 14, Position = UDim2.fromOffset(0, y + 6), Size = UDim2.fromOffset(84, 20), Parent = contenu })
		boutons[choix.cle] = {}
		local largeur = (UiKit.LARGEUR_PANNEAU - 40 - 84) / #choix.options
		for k, option in ipairs(choix.options) do
			boutons[choix.cle][option[1]] = UiKit.boutonDoux({
				Name = choix.prefixe .. option[1],
				Text = option[2],
				TextSize = 14,
				Position = UDim2.fromOffset(84 + (k - 1) * largeur, y),
				Size = UDim2.fromOffset(largeur - 4, 30),
				Parent = contenu,
			}, function()
				reglages[choix.cle] = option[1]
				rafraichir()
			end)
		end
	end

	-- Aperçu de la photo prise
	local apercu = UiKit.arrondir(UiKit.creer("Frame", { Name = "Apercu", Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
	local image = UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 300), ZIndex = 21, Parent = apercu })
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
		CaptureService:PromptSaveCapturesToGallery({ image.Image }, function(resultats)
			if resultats and resultats[image.Image] then
				ctx.message("Photo enregistrée dans ta galerie.", C.ok)
			end
		end)
	end, 0.4)
	UiKit.boutonDoux({ Name = "FermerApercu", Text = "Fermer", TextSize = 14, Position = UDim2.fromOffset(0, 364), Size = UDim2.new(1, -6, 0, 34), ZIndex = 21, Parent = apercu }, function()
		apercu.Visible = false
	end)

	-- Prise de vue : l'interface est cachée, la vue centrée sur la robe, le temps de la capture.
	-- Si Roblox refuse la capture ou ne répond pas, l'interface revient quand même.
	local interface = ctx.fenetre.Parent
	local enCours = false
	local function retablir()
		if enCours then
			enCours = false
			interface.Enabled = true
			scene:cadrerPhoto(false)
		end
	end
	UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo", TextSize = 16, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, -6, 0, 40), Parent = contenu }, function()
		if enCours then
			return
		end
		enCours = true
		scene:cadrerPhoto(true)
		interface.Enabled = false
		task.delay(scene.ATTENTE_CAPTURE, retablir)
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
				retablir()
				image.Image = capture
				apercu.Visible = true
			end)
		end)
		if not ok then
			retablir()
			ctx.message("La photo n'a pas pu être prise.", C.erreur)
		end
	end, 0.4)

	UiKit.bouton({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 300), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end, 0.4)
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 352), Size = UDim2.new(1, -6, 0, 32), Parent = contenu }, function()
		local r = session:retourDecorations()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	rafraichir()
	return function() end
end
```

- [ ] **Step 4: Brancher le titre et la dernière action**

Dans `src/client/Atelier/init.client.luau` :
- dans `TITRES`, remplacer `photo = "7. Présentation",` par `photo = "7. Photo et livraison",` ;
- dans `afficher`, remplacer `task.spawn(scene.synchroniser, scene, etat) -- la construction des pièces 3D peut prendre un moment` par :

```lua
	task.spawn(scene.synchroniser, scene, etat, session.derniere) -- la construction des pièces 3D peut prendre un moment
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104695 vérifications
TOUT EST VERT : 293 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/EcranPresentation.luau src/client/Atelier/init.client.luau tests/scenario.luau
git commit -m "Photo et livraison : décor, lumière, mannequin, capture sans l'interface, aperçu et galerie

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: la commande complète avec la cliente en personne et la photo. C'est le point de départ du plan 4 (serveur, boutiques, sauvegarde).

- [ ] **Step 1: La cliente entre**

Servir le dépôt avec Rojo (`C:/dev/jeux/roblox-maker/rojo.exe serve --port 34872`), reconnecter le plugin, lancer Play avec le connecteur MCP, puis cliquer `Clochette`.

Expected (capture d'écran) : à gauche du mannequin, en retrait, un avatar de la taille du mannequin, pieds au sol, bras baissés, coiffé, sans étiquette de nom ; bulle « Bonjour ! J'aurais besoin d'une robe. ». Aucune erreur dans la sortie.

- [ ] **Step 2: Jusqu'à la présentation**

Faire une robe en coton à carreaux comme à la tâche 6 du plan 3c (carnet `ToutEnUnTissu` puis `Tissu_coton_bleu_carreaux`, achat, quatre découpes, épinglage, couture en vitesse lapin avec l'assistance), puis cliquer `Presenter`.

Expected : pendant le travail, la cliente est là mais sans bulle ; titre « 7. Photo et livraison » ; bulle « Voyons voir… ».

- [ ] **Step 3: Réglages de la photo**

Cliquer `Decor_bleu`, `Lumiere_soir` et `Mannequin_noir`.

Expected (capture d'écran) : fond bleu derrière le mannequin, lumière de fin de journée, mannequin noir (le pied en bois ne change pas), boutons choisis en surbrillance.

- [ ] **Step 4: Prendre la photo**

Cliquer `PrendrePhoto`.

Expected : l'aperçu montre la robe de face, du bas de la jupe au cou du mannequin, qui remplit la hauteur de l'image, sans interface ni bulle ; la fenêtre, la vue du poste et la bulle reviennent aussitôt.

- [ ] **Step 5: Galerie**

Cliquer `EnregistrerPhoto`.

Expected : l'invite native « Enregistrer les captures » de Roblox. La fermer par « Non merci » : ne rien écrire dans la galerie de l'utilisateur. Seule l'erreur interne de Roblox (« Maximum update depth exceeded », CorePackages) peut apparaître dans la sortie. Puis cliquer `FermerApercu`.

- [ ] **Step 6: Livrer, adieu, cliente suivante**

Cliquer `Livrer`.

Expected : acceptée → bulle « Merci, elle est parfaite ! », puis la cliente disparaît au bout de 3 s ; refusée → bulle « Ce n'est pas tout à fait ce que je voulais. » (retoucher ou abandonner : « Tant pis… Au revoir. »). Puis cliquer `Clochette` : une nouvelle cliente entre (la tenue peut changer d'une commande à l'autre). Arrêter Play.

- [ ] **Step 7: Mettre à jour le README**

Dans `README.md` :

1. Remplacer le titre `## État actuel (plan 3c)` par `## État actuel (plan 3d)`.
2. Remplacer le point 1 (`1. **Commande** : …`, deux lignes) par :

```markdown
1. **Commande** : la clochette fait entrer la cliente en personne (un avatar construit en code, taille S, M ou L)
   avec 1 à 3 exigences de style, de couleur, de qualité ou d'accessoire. Elle parle par une bulle.
```

3. Remplacer les points 8 et 9 (`8. **Présentation et livraison** : …` jusqu'à `…sauvegarde au plan 4.`) par :

```markdown
8. **Photo et livraison** : on règle la photo (décor, lumière, couleur du mannequin) et on la prend
   (capture officielle de Roblox, sans l'interface) ; on peut l'enregistrer dans sa galerie. La cliente juge
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
9. La suite : serveur, boutiques et sauvegarde au plan 4.
```

4. Dans « Architecture », remplacer les deux lignes

```markdown
  de découpe, de la machine à coudre et de l'éditeur de décorations (`Decorateur`) ; `Scene` tient le
  mannequin, la robe épinglée, l'aperçu des décorations, la vitrine et la caméra du poste ;
```

par :

```markdown
  de découpe, de la machine à coudre et de l'éditeur de décorations (`Decorateur`) ; `Cliente` construit
  l'avatar de la cliente et sa bulle ; `Scene` tient la cliente, le mannequin, la robe épinglée, l'aperçu des
  décorations, les réglages de la photo, la vitrine et la caméra du poste ;
```

(La ligne qui précède, `` `Session` fait le lien avec l'état ; `TableDecoupe` et `MachineCoudre` sont la logique pure de la table ``, ne change pas ; la ligne qui suit, `un module `Ecran…` par étape.`, non plus.)

- [ ] **Step 8: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104695 vérifications
TOUT EST VERT : 293 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 3d terminé : la cliente en personne et la photo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
