# Cœur de l'atelier — Plan 4c : les boutiques de la rue

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construire la rue commune : 8 emplacements, une boutique par joueur construite par le serveur à son arrivée, l'atelier du joueur dans sa boutique, et sa dernière robe livrée dans sa vitrine sur la rue, visible par tous (spec §2, §5).

**Architecture:**
- **Boutique** (nouveau, partagé) : le plan d'une boutique en coordonnées locales (mannequin, vitrine, entrée, porte, fenêtre) et les 8 emplacements de la rue.
- **Boutiques** (nouveau, serveur) : attribue un emplacement à l'arrivée, construit la boutique (murs, porte et fenêtre, enseigne au nom du joueur, comptoir et clochette, étagère de tissus, table, machine) et le socle de sa vitrine, y expose la dernière robe livrée, place l'avatar à l'entrée et libère tout au départ.
- **Commande** : appelle `vitrine(joueur, recette)` à l'arrivée du joueur et après chaque livraison réussie ; le script du serveur la branche sur `Boutiques`.
- **Client** : `Scene` place l'atelier à l'origine de la boutique du joueur (option `origine`) et ne tient plus de vitrine ; `init.client` lit le numéro de boutique (attribut du joueur) et fait construire les vitrines de la rue proches par le module `Vitrines`.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§2 « Le monde » et module `Boutiques`, §5 « Vitrines et niveaux de détail », §7 Studio « 3 joueurs simultanés »). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan4a-serveur-commande.md`, `…plan4b-sauvegarde.md`.

## Décisions de ce plan

- **La rue** : 8 emplacements, quatre de chaque côté d'une rue de 20 studs (x = −45, −15, 15, 45), façades face à face. Les boutiques d'en face sont tournées d'un demi-tour.
- **Le repère d'une boutique** reprend les positions actuelles de la scène : mannequin en z = 40, caméra du poste en z = 34,6, cliente en (4,6 ; 42). La façade est en z = 30 (porte de x = −9 à −3, fenêtre de x = 4 à 11), le fond en z = 58, la largeur de 24 studs et la hauteur de 12. Il n'y a pas de toit : la lumière entre, et la vitrine se voit de la rue.
  - La vitrine est posée juste derrière la fenêtre, en (7,5 ; 0,5 ; 32,5) ; la robe exposée regarde la rue.
  - L'avatar arrive juste passé la porte, en (−6 ; 3 ; 33), tourné vers l'atelier.
- **Rien ne gêne l'atelier** : le comptoir est contre le mur de gauche et la table et la machine au fond, pour que la caméra du poste, la vue qui tourne autour du mannequin (rayon 5,5 studs), la photo, la cliente et le passage de la porte restent libres. Le test 34 le vérifie point par point.
- **Numéro de boutique côté client** : le serveur le pose sur le joueur (attribut `Boutique`, 0 si la rue est pleine). Le client en déduit l'origine grâce au module partagé `Boutique`, sans attendre la réplication de la boutique construite. Rue pleine : l'atelier reste à l'origine du monde, entre les rangées.
- **Vitrines** : un socle par boutique dans `Workspace.Vitrines`, avec l'attribut `Recette`, suivant le contrat du module `Vitrines` du plan 2. Chaque client construit les robes des vitrines à moins de 60 studs de sa caméra. La scène ne crée plus sa vitrine locale.
- **Faux Roblox** : il gagne l'égalité des CFrame par valeur, comme dans Roblox ; jusqu'ici `==` comparait les objets.
- **Vérifié dans Studio pendant la préparation**, en Play sur le lieu du brouillon :
  - la boutique n° 1, à l'enseigne « L'atelier de <nom du joueur> » ;
  - l'avatar à l'entrée, en (−6 ; 3,2 ; 33) dans le repère de la boutique ;
  - le mannequin et la cliente à leurs places ;
  - une robe posée sur la vitrine par le serveur, construite par le client (13 pièces) ;
  - aucune alerte hors « Lieu non publié ».
- **Non vérifié** : le rendu visuel (captures refusées ou blanches) et l'essai à 3 joueurs en « Clients et serveur » (spec §7), qui demande l'interface de Studio. C'est au commanditaire de les faire, étape 3 de la tâche 5.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `boutiques`, créée depuis `main` (où le plan 4b est fusionné). Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **La rue** (spec §2) : 8 emplacements, une boutique par joueur, construite par le serveur (comptoir avec clochette, étagères de tissus, table de découpe, machine à coudre, mannequin, vitrine), vidée et libérée au départ ; les autres joueurs voient la vitrine (la dernière robe finie).
- **Vitrines** (spec §5) : recette répliquée par le serveur dans un attribut, construite par chaque client près de lui (60 studs), libérée au-delà de 80.

## Review Focus

- **Boutique d'en face (tournée d'un demi-tour).** Attendu : mannequin, robe épinglée, cliente, décor photo, caméra du poste, vue qui tourne et toucher de la robe, exactement comme dans une boutique non tournée. Test : `36_scene_origine`.
- **Meubles et murs.** Attendu : rien ne se trouve sur le chemin de la caméra, de la vue qui tourne, de la photo, de la cliente ni du passage de la porte. Test : `34_boutiques`, « rien ne gêne ».
- **Arrivées et départs à la suite** (rue pleine, puis un joueur qui part). Attendu : pas de boutique pour le 9e joueur (attribut 0) ; au départ, la boutique et la vitrine sont retirées, et l'emplacement revient au suivant. Tests : `34`, « rue pleine » et « départ » ; scénario, « départ du joueur : sa boutique est retirée ».
- **Robe refusée, retour du joueur, vitrine en panne.** Attendu : la vitrine ne change qu'après une livraison réussie ; au retour, la dernière robe sauvegardée y revient ; une panne de la vitrine ne gêne pas l'atelier. Tests : `35_commande_vitrine` ; scénario, « retour : sa boutique est reconstruite ».
- **Vitrines des voisins.** Attendu : chaque client construit les robes exposées près de sa caméra, les siennes comme celles des autres. Tests : scénario, « le client construit la robe exposée » ; `13_vitrines` (plan 2).

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Boutique.luau` | **Nouveau** : plan d'une boutique (repère local), 8 emplacements de la rue |
| `src/server/Boutiques.luau` | **Nouveau** : attribuer, construire, exposer, placer l'avatar, libérer |
| `src/server/Commande.luau` | Option `vitrine`, `Commande:exposer` (à l'arrivée et après une livraison réussie) |
| `src/server/init.server.luau` | La rue : boutique à l'arrivée, avatar à l'entrée, vitrine, libération au départ |
| `src/client/Atelier/Scene.luau` | Option `origine` ; `scene.origine`, `scene.cadre` ; plus de vitrine locale |
| `src/client/Atelier/init.client.luau` | Origine de la boutique du joueur ; vitrines de la rue construites près de la caméra |
| `tests/mock.luau` | Égalité des CFrame par valeur |
| `tests/unitaires/33_boutique.luau`, `34_boutiques.luau`, `35_commande_vitrine.luau`, `36_scene_origine.luau` | Tests unitaires |
| `tests/unitaires/23_scene_decorations.luau` | La vitrine locale n'est plus testée ici (serveur : 34, 35, scénario) |
| `tests/scenario.luau` | La rue, la vitrine sur la rue, la boutique retirée puis reconstruite ; vues dans le repère de la boutique |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Le plan d'une boutique et de la rue

**Files:**
- Create: `src/shared/Boutique.luau`
- Test: `tests/unitaires/33_boutique.luau`

**Interfaces:**
- Consumes: `Catalogue.STUDS_PAR_DM`, `Mannequin.HAUTEUR_TAILLE` (plans 1 et 2).
- Produces: `Boutique.NOMBRE = 8`, `LARGEUR = 24`, `AVANT = 30`, `FOND = 58`, `HAUTEUR = 12`, `PORTE = { -9, -3 }`, `FENETRE = { 4, 11 }`, `DEMI_RUE = 10` ; `Boutique.MANNEQUIN`, `VITRINE`, `ENTREE` (CFrame locales) ; `Boutique.emplacement(i) -> CFrame` (erreur hors de 1 à 8).

- [ ] **Step 1: Écrire le test**

`tests/unitaires/33_boutique.luau` :

```lua
local Boutique = U.module("Boutique")
local Mannequin = U.module("Mannequin")
local Catalogue = U.module("Catalogue")

-- Un point local de la boutique est-il à l'intérieur de ses murs ?
local function dedans(p)
	return math.abs(p.X) < Boutique.LARGEUR / 2 and p.Z > Boutique.AVANT and p.Z < Boutique.FOND and p.Y >= 0 and p.Y < Boutique.HAUTEUR
end

---------------------------------------------------------------------------
-- La rue : 8 emplacements, quatre de chaque côté, façades tournées vers la rue
---------------------------------------------------------------------------
U.verifier(Boutique.NOMBRE == 8, "8 emplacements (spec §2)")
local coins = {}
for i = 1, Boutique.NOMBRE do
	local o = Boutique.emplacement(i)
	-- Les quatre coins au sol de la boutique, dans le monde
	local c = {}
	for _, x in ipairs({ -Boutique.LARGEUR / 2, Boutique.LARGEUR / 2 }) do
		for _, z in ipairs({ Boutique.AVANT, Boutique.FOND }) do
			table.insert(c, (o * CFrame.new(x, 0, z)).Position)
		end
	end
	coins[i] = c
	local facade = (o * CFrame.new(0, 0, Boutique.AVANT)).Position
	local dehors = (o * CFrame.new(0, 0, Boutique.AVANT - 1)).Position
	U.verifier(math.abs(math.abs(facade.Z) - Boutique.DEMI_RUE) < 1e-6, "façade " .. i .. " au bord de la rue")
	U.verifier(math.abs(dehors.Z) < math.abs(facade.Z), "façade " .. i .. " tournée vers la rue")
	U.verifier(math.abs(o.Position.Y) < 1e-9 and math.abs(o.UpVector.Y - 1) < 1e-9, "boutique " .. i .. " posée à plat, au niveau du sol")
end
-- Pas deux boutiques l'une sur l'autre (boîtes au sol disjointes)
local function boite(c)
	local b = { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge }
	for _, p in ipairs(c) do
		b.minX, b.maxX = math.min(b.minX, p.X), math.max(b.maxX, p.X)
		b.minZ, b.maxZ = math.min(b.minZ, p.Z), math.max(b.maxZ, p.Z)
	end
	return b
end
local separees = true
for i = 1, Boutique.NOMBRE do
	for j = i + 1, Boutique.NOMBRE do
		local a, b = boite(coins[i]), boite(coins[j])
		if a.minX < b.maxX and b.minX < a.maxX and a.minZ < b.maxZ and b.minZ < a.maxZ then
			separees = false
		end
	end
end
U.verifier(separees, "aucune boutique ne chevauche une autre")
local ok = pcall(Boutique.emplacement, Boutique.NOMBRE + 1)
U.verifier(not ok, "pas de neuvième emplacement")

---------------------------------------------------------------------------
-- L'intérieur : mannequin, vitrine et entrée à leur place
---------------------------------------------------------------------------
U.verifier(dedans(Boutique.MANNEQUIN.Position) and math.abs(Boutique.MANNEQUIN.Position.Y - Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM) < 1e-9, "mannequin de travail dans la boutique, à la hauteur de la taille")
U.verifier(dedans(Boutique.VITRINE.Position) and Boutique.VITRINE.Position.Z - Boutique.AVANT < 4, "vitrine juste derrière la façade")
U.verifier(Boutique.VITRINE.LookVector.Z < -0.99, "la vitrine donne sur la rue (la robe exposée regarde l'avant du socle, −Z)")
local v = Boutique.VITRINE.Position
U.verifier(v.X - 2 >= Boutique.FENETRE[1] and v.X + 2 <= Boutique.FENETRE[2], "la vitrine est derrière la fenêtre de la façade")
U.verifier(dedans(Boutique.ENTREE.Position) and Boutique.ENTREE.Position.X >= Boutique.PORTE[1] and Boutique.ENTREE.Position.X <= Boutique.PORTE[2], "on entre par la porte")
U.verifier(Boutique.PORTE[2] < Boutique.FENETRE[1], "porte et fenêtre côte à côte, sans se chevaucher")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Boutique n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 3: Écrire le module**

`src/shared/Boutique.luau` :

```lua
-- Boutique : le plan d'une boutique de la rue, en coordonnées locales (le repère de la boutique). Partagé :
-- le serveur la construit à son emplacement, le client y place le mannequin, la caméra et la cliente.
-- Dans ce repère, la façade (sur la rue) est vers −Z, et le mannequin de travail regarde −Z.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Mannequin = require(dossier:WaitForChild("Mannequin"))

local Boutique = {}
Boutique.NOMBRE = 8 -- emplacements dans la rue (spec §2 ; le serveur est limité à 8 joueurs)
Boutique.LARGEUR = 24 -- studs : x de −12 à 12
Boutique.AVANT, Boutique.FOND = 30, 58 -- z de la façade et du mur du fond
Boutique.HAUTEUR = 12
Boutique.PORTE = { -9, -3 } -- x de l'ouverture de la porte, dans la façade
Boutique.FENETRE = { 4, 11 } -- x de la fenêtre de la vitrine, dans la façade
Boutique.DEMI_RUE = 10 -- studs entre le milieu de la rue et chaque rangée de façades
local X_EMPLACEMENTS = { -45, -15, 15, 45 }

-- Le mannequin de travail (le cadre de la robe : sa taille est à la hauteur de la taille du mannequin)
Boutique.MANNEQUIN = CFrame.new(0, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 40)
-- Le socle de la vitrine, juste derrière la fenêtre : la robe exposée regarde la rue
Boutique.VITRINE = CFrame.new(7.5, 0.5, 32.5)
-- Là où l'avatar du joueur apparaît : juste passé la porte, tourné vers l'atelier
Boutique.ENTREE = CFrame.lookAt(Vector3.new(-6, 3, 33), Vector3.new(-6, 3, 40))

-- Repère de la boutique i (1 à 4 : d'un côté de la rue, 5 à 8 : en face, tournées d'un demi-tour)
function Boutique.emplacement(i)
	assert(type(i) == "number" and i == math.floor(i) and i >= 1 and i <= Boutique.NOMBRE, "emplacement inconnu : " .. tostring(i))
	local x = X_EMPLACEMENTS[(i - 1) % 4 + 1]
	if i <= 4 then
		return CFrame.new(x, 0, Boutique.DEMI_RUE - Boutique.AVANT)
	end
	return CFrame.new(x, 0, Boutique.AVANT - Boutique.DEMI_RUE) * CFrame.Angles(0, math.pi, 0)
end

return Boutique
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104944 vérifications
TOUT EST VERT : 311 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Boutique.luau tests/unitaires/33_boutique.luau
git commit -m "Le plan d'une boutique et les 8 emplacements de la rue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le serveur construit la rue

**Files:**
- Create: `src/server/Boutiques.luau`
- Test: `tests/unitaires/34_boutiques.luau`

**Interfaces:**
- Consumes: `Boutique` (tâche 1) ; `Recette.encoder` ; `Catalogue.Tissus` ; `Scene.CAMERA`, `Scene.CAMERA_PHOTO`, `Scene.CADRE`, `Scene.CLIENTE` (plans 3, dans le test).
- Produces: `Boutiques.nouvelles(parent) -> rue` (dossiers `Rue` et `Vitrines` dans `parent`) ; `rue:attribuer(joueur) -> indice?` (attribut `Boutique` du joueur : indice, ou 0) ; `rue:exposer(joueur, recette?)` ; `rue:placer(joueur)` ; `rue:liberer(joueur)`. Boutique : modèle `Rue.Boutique_<i>` (attribut `Proprietaire` = UserId, `PrimaryPart` « Origine » à l'emplacement) ; vitrine : `Vitrines.Vitrine_<i>` (attribut `Recette`).

- [ ] **Step 1: Écrire le test**

`tests/unitaires/34_boutiques.luau` :

```lua
local Boutiques = U.module("Boutiques")
local Boutique = U.module("Boutique")
local Scene = U.module("Scene")
local Recette = U.module("Recette")

local monde = M.nouvelleInstance("Folder")
monde.Name = "MondeTest"
monde.Parent = M.services.Workspace
local rue = Boutiques.nouvelles(monde)
U.verifier(monde:FindFirstChild("Rue") ~= nil and monde:FindFirstChild("Vitrines") ~= nil, "la rue et ses vitrines")
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	rawget(j, "__props").DisplayName = nom
	return j
end
local function proche(a, b)
	return (a.Position - b.Position).Magnitude < 1e-6 and a.LookVector:Dot(b.LookVector) > 1 - 1e-6
end

---------------------------------------------------------------------------
-- Attribution : un emplacement libre par joueur, 8 au plus
---------------------------------------------------------------------------
local joueurs = {}
local suite = true
for k = 1, Boutique.NOMBRE do
	joueurs[k] = joueurNumero("Couturiere" .. k, 700 + k)
	if rue:attribuer(joueurs[k]) ~= k or joueurs[k]:GetAttribute("Boutique") ~= k then
		suite = false
	end
end
U.verifier(suite, "les joueurs reçoivent les emplacements dans l'ordre, notés sur le joueur (attribut « Boutique »)")
local neuvieme = joueurNumero("Neuvieme", 709)
U.verifier(rue:attribuer(neuvieme) == nil and neuvieme:GetAttribute("Boutique") == 0, "rue pleine : pas de boutique (attribut 0)")
U.verifier(rue:attribuer(joueurs[2]) == 2, "un joueur garde sa boutique")

---------------------------------------------------------------------------
-- Construction : à son emplacement, au nom du joueur, meublée
---------------------------------------------------------------------------
local b3 = monde.Rue:FindFirstChild("Boutique_3")
U.verifier(b3 ~= nil and b3:GetAttribute("Proprietaire") == joueurs[3].UserId and proche(b3:GetPivot(), Boutique.emplacement(3)), "boutique 3 à son emplacement, à sa propriétaire")
local meubles = true
for _, nom in ipairs({ "Sol", "MurFond", "MurGauche", "MurDroit", "Vitre", "Comptoir", "Clochette", "Etagere", "TableDecoupe", "Machine", "Enseigne" }) do
	if not b3:FindFirstChild(nom) then
		meubles = false
	end
end
U.verifier(meubles, "sol, murs, vitre, comptoir et clochette, étagère, table de découpe, machine, enseigne")
local surfaceEnseigne = b3.Enseigne:FindFirstChild("SurfaceGui")
local texteEnseigne = surfaceEnseigne and surfaceEnseigne:FindFirstChild("Texte")
U.verifier(texteEnseigne ~= nil and string.find(texteEnseigne.Text, "Couturiere3", 1, true) ~= nil and texteEnseigne.TextSize >= 14, "enseigne au nom de la joueuse")
local rouleaux = 0
for _, p in ipairs(b3:GetChildren()) do
	if p.Name:sub(1, 8) == "Rouleau_" then
		rouleaux += 1
	end
end
U.verifier(rouleaux >= 6, "des rouleaux de tissu sur l'étagère (" .. rouleaux .. ")")

-- Rien ne gêne l'atelier : caméra du poste (même quand elle tourne), photo, cliente, entrée par la porte
local o = Boutique.emplacement(3)
local points = {
	camera = Scene.CAMERA.Position,
	photo = Scene.CAMERA_PHOTO.Position,
	mannequin = Scene.CADRE.Position,
	cliente = Scene.CLIENTE.Position + Vector3.new(0, 2, 0),
	entree = Boutique.ENTREE.Position,
}
for a = 0, 350, 10 do
	local axe = CFrame.new(Scene.CADRE.Position)
	points["orbite" .. a] = (axe * CFrame.Angles(0, math.rad(a), 0) * axe:Inverse() * Scene.CAMERA).Position
end
for z = Boutique.AVANT - 2, Boutique.ENTREE.Position.Z, 0.5 do
	points["porte" .. z] = Vector3.new(Boutique.ENTREE.Position.X, 3, z)
end
local genes = {}
for nomPoint, local_ in pairs(points) do
	local monde_ = o * local_
	for _, p in ipairs(b3:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide and p.Name ~= "Origine" then
			local rel = p.CFrame:PointToObjectSpace(monde_)
			if math.abs(rel.X) <= p.Size.X / 2 and math.abs(rel.Y) <= p.Size.Y / 2 and math.abs(rel.Z) <= p.Size.Z / 2 then
				table.insert(genes, nomPoint .. " dans " .. p.Name)
			end
		end
	end
end
table.sort(genes)
U.verifier(#genes == 0, "rien ne gêne la caméra, la cliente ni l'entrée : " .. table.concat(genes, ", "))

---------------------------------------------------------------------------
-- Vitrine : vide, puis la dernière robe livrée
---------------------------------------------------------------------------
local vitrine = monde.Vitrines:FindFirstChild("Vitrine_3")
U.verifier(vitrine ~= nil and vitrine:IsA("BasePart") and proche(vitrine.CFrame, o * Boutique.VITRINE) and vitrine:GetAttribute("Recette") == nil, "vitrine vide, derrière la fenêtre de la boutique 3")
local robe = { version = 1, mesures = { poitrine = 8.8, taille = 7, hanches = 9.4 }, croquis = {}, pieces = {}, accessoires = {} }
rue:exposer(joueurs[3], robe)
U.verifier(vitrine:GetAttribute("Recette") == Recette.encoder(robe), "la robe livrée part en vitrine")
rue:exposer(joueurs[3], nil)
U.verifier(vitrine:GetAttribute("Recette") == nil, "vitrine vidée")
rue:exposer(neuvieme, robe) -- sans boutique : sans effet, sans erreur

---------------------------------------------------------------------------
-- Arrivée de l'avatar : à l'entrée de sa boutique
---------------------------------------------------------------------------
local avatar = M.nouvelleInstance("Model")
local racine = M.nouvelleInstance("Part")
racine.Name = "HumanoidRootPart"
racine.CFrame = CFrame.new(0, 3, 0)
racine.Parent = avatar
avatar.PrimaryPart = racine
rawget(joueurs[3], "__props").Character = avatar
rue:placer(joueurs[3])
U.verifier(proche(racine.CFrame, o * Boutique.ENTREE), "l'avatar arrive à l'entrée de sa boutique")
rue:placer(neuvieme) -- sans boutique ni avatar : sans effet, sans erreur

---------------------------------------------------------------------------
-- Départ : la boutique est retirée et l'emplacement libéré
---------------------------------------------------------------------------
rue:liberer(joueurs[3])
U.verifier(monde.Rue:FindFirstChild("Boutique_3") == nil and monde.Vitrines:FindFirstChild("Vitrine_3") == nil, "départ : boutique et vitrine retirées")
U.verifier(rue:attribuer(neuvieme) == 3 and monde.Rue.Boutique_3:GetAttribute("Proprietaire") == neuvieme.UserId, "l'emplacement libéré revient au joueur suivant")
rue:liberer(joueurNumero("Inconnue", 799)) -- sans boutique : sans effet, sans erreur
monde:Destroy()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Boutiques n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 3: Écrire le module**

`src/server/Boutiques.luau` :

```lua
-- Boutiques (serveur) : la rue commune (spec §2). À son arrivée, le joueur reçoit un emplacement libre, où
-- le serveur construit sa boutique (plan : module Boutique) : murs, porte et fenêtre sur la rue, enseigne à
-- son nom, comptoir et clochette, étagère de tissus, table de découpe, machine à coudre. Derrière la
-- fenêtre, le socle de sa vitrine porte la recette de sa dernière robe livrée (attribut « Recette ») :
-- chaque client construit les robes des vitrines proches (spec §5). Au départ, tout est retiré.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Recette = require(Couture:WaitForChild("Recette"))
local Boutique = require(Couture:WaitForChild("Boutique"))

local Boutiques = {}
Boutiques.__index = Boutiques

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local MUR, SOL, BOIS, BOIS_CLAIR = rgb(236, 222, 210), rgb(170, 128, 96), rgb(120, 84, 56), rgb(196, 160, 118)

-- parent : où ranger la rue (dossier « Rue ») et les vitrines (dossier « Vitrines », lu par les clients)
function Boutiques.nouvelles(parent)
	local rue = Instance.new("Folder")
	rue.Name = "Rue"
	rue.Parent = parent
	local vitrines = Instance.new("Folder")
	vitrines.Name = "Vitrines"
	vitrines.Parent = parent
	return setmetatable({ rue = rue, vitrines = vitrines, parIndice = {}, parJoueur = {} }, Boutiques)
end

-- Un bloc de la boutique (repère local de la boutique)
local function bloc(modele, origine, nom, position, taille, couleur, options)
	options = options or {}
	local p = Instance.new("Part")
	p.Name = nom
	p.Anchored = true
	p.Size = taille
	p.CFrame = origine * CFrame.new(position)
	p.Color = couleur
	p.Material = options.matiere or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if options.forme then
		p.Shape = options.forme
	end
	if options.decor then -- petit objet décoratif : ni collision, ni rayon
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
	end
	if options.transparence then
		p.Transparency = options.transparence
	end
	p.Parent = modele
	return p
end

local function construire(indice, joueur, parent)
	local origine = Boutique.emplacement(indice)
	local modele = Instance.new("Model")
	modele.Name = "Boutique_" .. indice
	modele:SetAttribute("Proprietaire", joueur.UserId)
	local ancre = bloc(modele, origine, "Origine", Vector3.zero, Vector3.new(1, 1, 1), MUR, { decor = true, transparence = 1 })
	modele.PrimaryPart = ancre
	local L, A, F, H = Boutique.LARGEUR, Boutique.AVANT, Boutique.FOND, Boutique.HAUTEUR
	local P, W = Boutique.PORTE, Boutique.FENETRE
	local profondeur, milieu = F - A, (A + F) / 2
	-- Sol et murs (la façade, en z = AVANT, a une porte et une fenêtre)
	bloc(modele, origine, "Sol", Vector3.new(0, -0.1, milieu), Vector3.new(L, 0.2, profondeur), SOL, { matiere = Enum.Material.WoodPlanks })
	bloc(modele, origine, "MurFond", Vector3.new(0, H / 2, F + 0.5), Vector3.new(L + 2, H, 1), MUR)
	bloc(modele, origine, "MurGauche", Vector3.new(-L / 2 - 0.5, H / 2, milieu), Vector3.new(1, H, profondeur), MUR)
	bloc(modele, origine, "MurDroit", Vector3.new(L / 2 + 0.5, H / 2, milieu), Vector3.new(1, H, profondeur), MUR)
	local zF = A - 0.5
	local hautOuverture = 8
	bloc(modele, origine, "FacadeGauche", Vector3.new((-L / 2 + P[1]) / 2 - 0.5, H / 2, zF), Vector3.new(P[1] + L / 2 + 1, H, 1), MUR)
	bloc(modele, origine, "FacadeDessusPorte", Vector3.new((P[1] + P[2]) / 2, (hautOuverture + H) / 2, zF), Vector3.new(P[2] - P[1], H - hautOuverture, 1), MUR)
	bloc(modele, origine, "FacadeMilieu", Vector3.new((P[2] + W[1]) / 2, H / 2, zF), Vector3.new(W[1] - P[2], H, 1), MUR)
	bloc(modele, origine, "FacadeSousFenetre", Vector3.new((W[1] + W[2]) / 2, 0.5, zF), Vector3.new(W[2] - W[1], 1, 1), MUR)
	bloc(modele, origine, "FacadeDessusFenetre", Vector3.new((W[1] + W[2]) / 2, (hautOuverture + H) / 2, zF), Vector3.new(W[2] - W[1], H - hautOuverture, 1), MUR)
	bloc(modele, origine, "FacadeDroite", Vector3.new((W[2] + L / 2) / 2 + 0.5, H / 2, zF), Vector3.new(L / 2 - W[2] + 1, H, 1), MUR)
	bloc(modele, origine, "Vitre", Vector3.new((W[1] + W[2]) / 2, (1 + hautOuverture) / 2, zF), Vector3.new(W[2] - W[1], hautOuverture - 1, 0.2), rgb(200, 225, 240), { matiere = Enum.Material.Glass, transparence = 0.7 })
	-- Enseigne au nom du joueur, sur la façade (face à la rue)
	local enseigne = bloc(modele, origine, "Enseigne", Vector3.new(-3, 10, A - 1.2), Vector3.new(14, 2.2, 0.3), BOIS)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.PixelsPerStud = 40
	surface.Parent = enseigne
	local texte = Instance.new("TextLabel")
	texte.Name = "Texte"
	texte.Size = UDim2.fromScale(1, 1)
	texte.BackgroundTransparency = 1
	texte.Font = Enum.Font.GothamBold
	texte.TextSize = 48
	texte.TextColor3 = rgb(255, 240, 220)
	local nom = (joueur.DisplayName ~= nil and joueur.DisplayName ~= "") and joueur.DisplayName or joueur.Name
	texte.Text = "L'atelier de " .. nom
	texte.Parent = surface
	-- Comptoir et clochette, contre le mur de gauche
	bloc(modele, origine, "Comptoir", Vector3.new(-9, 1.5, 38), Vector3.new(3, 3, 6), BOIS)
	bloc(modele, origine, "Clochette", Vector3.new(-9, 3.4, 36.5), Vector3.new(0.8, 0.8, 0.8), rgb(230, 190, 70), { forme = Enum.PartType.Ball, matiere = Enum.Material.Metal, decor = true })
	-- Étagère de tissus : un rouleau par tissu (les douze premiers du catalogue)
	bloc(modele, origine, "Etagere", Vector3.new(-11, 3.5, 48), Vector3.new(1.5, 7, 10), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	for k = 1, math.min(12, #Catalogue.Tissus) do
		local t = Catalogue.Tissus[k]
		local c = t.motif.couleurs[1]
		local rangee, colonne = math.floor((k - 1) / 4), (k - 1) % 4
		local rouleau = bloc(modele, origine, "Rouleau_" .. t.id, Vector3.new(-9.9, 1.2 + rangee * 2, 44.5 + colonne * 2.2), Vector3.new(0.9, 0.9, 1.8), rgb(c[1], c[2], c[3]), { forme = Enum.PartType.Cylinder, matiere = Enum.Material.Fabric, decor = true })
		rouleau.CFrame = rouleau.CFrame * CFrame.Angles(0, math.rad(90), 0) -- couché, le long du mur
	end
	-- Table de découpe et machine à coudre, au fond
	bloc(modele, origine, "TableDecoupe", Vector3.new(-6, 1.5, 51), Vector3.new(6, 3, 4), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "Machine", Vector3.new(7, 1.5, 51), Vector3.new(4, 3, 2.5), BOIS, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "CorpsMachine", Vector3.new(7, 3.6, 51), Vector3.new(1.6, 1.2, 0.8), rgb(60, 60, 70), { matiere = Enum.Material.Metal, decor = true })
	modele.Parent = parent
	return modele
end

-- Donne un emplacement libre au joueur (le même s'il en a déjà un) et y construit sa boutique. Renvoie
-- son numéro, ou nil si la rue est pleine. L'attribut « Boutique » du joueur le dit au client (0 : aucune).
function Boutiques:attribuer(joueur)
	local deja = self.parJoueur[joueur]
	if deja then
		return deja.indice
	end
	for indice = 1, Boutique.NOMBRE do
		if not self.parIndice[indice] then
			local modele = construire(indice, joueur, self.rue)
			local vitrine = Instance.new("Part")
			vitrine.Name = "Vitrine_" .. indice
			vitrine.Anchored = true
			vitrine.Size = Vector3.new(4, 1, 4)
			vitrine.CFrame = Boutique.emplacement(indice) * Boutique.VITRINE
			vitrine.Material = Enum.Material.Wood
			vitrine.Color = BOIS
			vitrine.Parent = self.vitrines
			local b = { indice = indice, modele = modele, vitrine = vitrine, joueur = joueur }
			self.parIndice[indice], self.parJoueur[joueur] = b, b
			joueur:SetAttribute("Boutique", indice)
			return indice
		end
	end
	joueur:SetAttribute("Boutique", 0)
	return nil
end

-- Expose une recette dans la vitrine du joueur (nil : vitrine vide)
function Boutiques:exposer(joueur, recette)
	local b = self.parJoueur[joueur]
	if b then
		b.vitrine:SetAttribute("Recette", recette and Recette.encoder(recette) or nil)
	end
end

-- Place l'avatar du joueur à l'entrée de sa boutique
function Boutiques:placer(joueur)
	local b = self.parJoueur[joueur]
	local avatar = joueur.Character
	if b and avatar then
		avatar:PivotTo(Boutique.emplacement(b.indice) * Boutique.ENTREE)
	end
end

-- Départ du joueur : boutique et vitrine retirées, emplacement libéré
function Boutiques:liberer(joueur)
	local b = self.parJoueur[joueur]
	if not b then
		return
	end
	b.modele:Destroy()
	b.vitrine:Destroy()
	self.parIndice[b.indice], self.parJoueur[joueur] = nil, nil
end

return Boutiques
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104959 vérifications
TOUT EST VERT : 311 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Boutiques.luau tests/unitaires/34_boutiques.luau
git commit -m "Le serveur construit les boutiques de la rue et leurs vitrines

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La vitrine suit les livraisons ; le serveur branche la rue

**Files:**
- Modify: `src/server/Commande.luau` (réécrit)
- Modify: `src/server/init.server.luau` (réécrit)
- Test: `tests/unitaires/35_commande_vitrine.luau`, `tests/scenario.luau` (la rue côté serveur)

**Interfaces:**
- Consumes: `Boutiques` (tâche 2) ; `Commande` et `Sauvegarde` (plans 4a, 4b).
- Produces: `Commande.nouvelle({ …, vitrine = function(joueur, recette?) })` ; `Commande:exposer(joueur)` (appelée à la fin de `arrivee` et après un `livrer` réussi ; une erreur de la vitrine donne un avertissement). Script du serveur : `Boutiques.nouvelles(Workspace)`, arrivée (boutique, avatar à l'entrée, partie), départ (partie, boutique).

- [ ] **Step 1: Écrire le test de la vitrine**

`tests/unitaires/35_commande_vitrine.luau` :

```lua
local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

-- La vitrine de chaque joueur, telle que le serveur la montre (false : vide)
local exposees = {}
local function vitrine(joueur, recette)
	exposees[joueur] = recette or false
end
local function appeler(serveur, joueur, action, ...)
	M.avancer(0.25)
	return serveur:traiter(joueur, action, ...)
end

---------------------------------------------------------------------------
-- Sans sauvegarde : vitrine vide à l'arrivée, puis la robe livrée ; un refus ne change rien
---------------------------------------------------------------------------
local serveur = Commande.nouvelle({ vitrine = vitrine })
local joueur = M.nouveauJoueur("Exposante")
serveur:arrivee(joueur)
U.verifier(exposees[joueur] == false, "arrivée : vitrine vide")
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
serveur:atelier(joueur).etat.argent = 1000
appeler(serveur, joueur, "nouvelleCommande")
appeler(serveur, joueur, "validerCroquis", CROQUIS, tissus)
appeler(serveur, joueur, "acheter", "coton_blanc", 12)
appeler(serveur, joueur, "commencerDecoupe")
for _, id in ipairs(ORDRE) do
	appeler(serveur, joueur, "couper", id, PLACES[id])
end
for _, id in ipairs(ORDRE) do
	appeler(serveur, joueur, "epingler", id)
end
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	appeler(serveur, joueur, "rendreCouture", id, table.create(math.round(l / 0.1), 0.02), l)
end
appeler(serveur, joueur, "decorer", {})
local etat = serveur:atelier(joueur).etat
etat.commande.exigences = { { type = "accessoire", id = "croix_argent" } }
local r = appeler(serveur, joueur, "livrer")
U.verifier(r.ok and not r.reussie and exposees[joueur] == false, "robe refusée : la vitrine ne change pas")
appeler(serveur, joueur, "retoucher")
appeler(serveur, joueur, "decorer", {})
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
r = appeler(serveur, joueur, "livrer")
U.verifier(r.ok and r.reussie and exposees[joueur] and Recette.encoder(exposees[joueur]) == Recette.encoder(etat.robes[1]), "robe livrée : elle part en vitrine")

---------------------------------------------------------------------------
-- Avec sauvegarde : à l'arrivée, la dernière robe sauvegardée est en vitrine
---------------------------------------------------------------------------
local magasin = M.nouveauMagasin()
magasin.donnees.joueur_42 = { version = Sauvegarde.VERSION, argent = 300, stock = {}, debloques = {}, recettes = { etat.robes[1] } }
local avecSauvegarde = Commande.nouvelle({
	vitrine = vitrine,
	sauvegarde = Sauvegarde.nouvelle({ magasin = magasin, ancien = M.nouveauMagasin(), jobId = "V" }),
})
local revenue = M.nouveauJoueur("Revenue")
avecSauvegarde:arrivee(revenue)
U.verifier(exposees[revenue] and Recette.encoder(exposees[revenue]) == Recette.encoder(etat.robes[1]), "retour : la dernière robe sauvegardée est en vitrine")

---------------------------------------------------------------------------
-- Une vitrine en panne ne casse pas l'action
---------------------------------------------------------------------------
local fragile = Commande.nouvelle({
	vitrine = function()
		error("vitrine en panne")
	end,
})
local j2 = M.nouveauJoueur("Fragile")
M.avertissements = {}
fragile:arrivee(j2)
U.verifier(appeler(fragile, j2, "etat").ok and #M.avertissements == 1, "vitrine en panne : un avertissement, l'atelier fonctionne")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : arrivée : vitrine vide`

- [ ] **Step 3: La Commande montre la dernière robe**

`src/server/Commande.luau` :

```lua
-- Commande (serveur) : l'atelier de chaque joueur, qui fait foi (spec §2). Chaque action du client
-- passe par Commande:traiter : action connue, limite d'appels, règles d'EtatAtelier. Une réponse
-- acceptée emporte l'état (EtatAtelier:exporter), que le client recharge et affiche.
-- Avec une sauvegarde, la partie est lue à l'arrivée du joueur et écrite régulièrement, à son départ
-- et à l'arrêt du serveur ; sans (lieu non publié), chaque joueur commence une partie neuve.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Limiteur = require(script.Parent:WaitForChild("Limiteur"))
local Sauvegarde = require(script.Parent:WaitForChild("Sauvegarde"))

local Commande = {}
Commande.__index = Commande

Commande.APPELS_PAR_SECONDE = 5 -- par joueur (spec §6)
Commande.PERIODE_SAUVEGARDE = 60 -- s entre deux sauvegardes de toutes les parties (spec §6)
Commande.FERMETURE_MAX = 25 -- s : à l'arrêt du serveur, attente maximale des dernières sauvegardes
Commande.ESSAIS_ECRITURE = 3 -- au départ et à l'arrêt, une panne passagère du DataStore est réessayée
local PREPARATION = "L'atelier se prépare, réessaie dans un instant."
local SANS_SAUVEGARDE = "Ta partie ne peut pas être sauvegardée pour le moment : tes progrès de cette session seront perdus."
-- Les relevés de couture ne sont pas limités : leur propre vraisemblance les borne (spec §6)
local SANS_LIMITE = { rendreCouture = true }

local function refus(message)
	return { ok = false, erreur = message }
end

-- Actions permises : le nom envoyé par le client choisit l'une d'elles, jamais une méthode quelconque
local ACTIONS = {
	-- le client demande l'état (à son arrivée)
	etat = function()
		return { ok = true }
	end,
	-- la commande est tirée par le serveur, avec son propre générateur (l'argument du client est ignoré)
	nouvelleCommande = function(a)
		return a.etat:nouvelleCommande(a.rng)
	end,
	validerCroquis = function(a, croquis, tissus)
		return a.etat:validerCroquis(croquis, tissus)
	end,
	retourCarnet = function(a)
		return a.etat:retourCarnet()
	end,
	acheter = function(a, idTissu, dm)
		return a.etat:acheter(idTissu, dm)
	end,
	commencerDecoupe = function(a)
		return a.etat:commencerDecoupe()
	end,
	couper = function(a, idPiece, placement)
		return a.etat:couper(idPiece, placement)
	end,
	epingler = function(a, idPiece)
		return a.etat:epingler(idPiece)
	end,
	rendreCouture = function(a, idPiece, ecarts, duree, assistance)
		return a.etat:rendreCouture(idPiece, ecarts, duree, assistance)
	end,
	decorer = function(a, liste)
		return a.etat:decorer(liste)
	end,
	retourDecorations = function(a)
		return a.etat:retourDecorations()
	end,
	livrer = function(a)
		return a.etat:livrer()
	end,
	retoucher = function(a)
		return a.etat:retoucher()
	end,
	abandonner = function(a)
		return a.etat:abandonner()
	end,
	recommencer = function(a)
		return a.etat:recommencer()
	end,
}

-- options (facultatif) : { sauvegarde = Sauvegarde, horloge = fonction, attendre = fonction,
-- vitrine = function(joueur, recette?) } (vitrine : montre la dernière robe livrée du joueur, ou rien)
function Commande.nouvelle(options)
	options = options or {}
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
		sauvegarde = options.sauvegarde,
		vitrine = options.vitrine,
		horloge = options.horloge or os.clock,
		attendre = options.attendre or task.wait,
	}, Commande)
	Commande.courante = self -- le serveur en cours (tests du scénario, débogage dans Studio)
	return self
end

-- L'atelier d'un joueur, ou nil tant que sa partie n'est pas lue. Sans sauvegarde, une partie neuve est
-- créée à son premier appel.
function Commande:atelier(joueur)
	local a = self.ateliers[joueur]
	if not a and not self.sauvegarde then
		a = { etat = EtatAtelier.nouveau(), rng = Random.new(), sauvable = false }
		self.ateliers[joueur] = a
	end
	return a
end

-- Montre la dernière robe livrée du joueur dans sa vitrine (une panne de la vitrine ne gêne pas l'atelier)
function Commande:exposer(joueur)
	local a = self.ateliers[joueur]
	if not self.vitrine or not a then
		return
	end
	local ok, erreur = pcall(self.vitrine, joueur, a.etat.robes[1])
	if not ok then
		warn(("[Atelier] %s : vitrine non mise à jour : %s"):format(joueur.Name, tostring(erreur)))
	end
end

-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		self:exposer(joueur)
		return
	end
	local partie, statut = self.sauvegarde:charger(joueur.UserId)
	if joueur.Parent == nil then
		-- parti pendant la lecture : sa partie est rendue tout de suite
		if statut == "ok" then
			self.sauvegarde:enregistrer(joueur.UserId, partie, true)
		end
		return
	end
	if statut ~= "ok" then
		warn(("[Atelier] %s : partie illisible, elle ne sera pas écrite pendant cette session."):format(joueur.Name))
	end
	self.ateliers[joueur] = {
		etat = partie and Sauvegarde.versEtat(partie) or EtatAtelier.nouveau(),
		rng = Random.new(),
		sauvable = statut == "ok",
		debloques = partie and partie.debloques,
	}
	self:exposer(joueur)
end

-- Écrit la partie d'un joueur (et rend son verrou, si liberer), en « essais » tentatives (1 par défaut ;
-- la sauvegarde régulière réessaie d'elle-même 60 s plus tard). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
function Commande:enregistrer(joueur, liberer, essais)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local partie = Sauvegarde.depuisEtat(a.etat, a.debloques)
	local statut
	for essai = 1, essais or 1 do
		statut = self.sauvegarde:enregistrer(joueur.UserId, partie, liberer)
		if statut ~= "echec" or essai == (essais or 1) then
			break
		end
		self.attendre(1)
	end
	if statut == "perdu" then
		a.sauvable = false
		warn(("[Atelier] %s : sa partie est tenue par un autre serveur, elle n'est plus écrite d'ici."):format(joueur.Name))
	elseif statut == "echec" then
		warn(("[Atelier] %s : sauvegarde impossible pour l'instant, on réessaiera."):format(joueur.Name))
	end
	return statut
end

-- Sauvegarde régulière de toutes les parties (chacune dans sa tâche)
function Commande:enregistrerTout()
	for joueur in pairs(self.ateliers) do
		task.spawn(self.enregistrer, self, joueur, false)
	end
end

-- Départ du joueur : partie écrite, verrou rendu, atelier libéré
function Commande:depart(joueur)
	self:enregistrer(joueur, true, Commande.ESSAIS_ECRITURE)
	self:retirer(joueur)
end

-- Atelier libéré, sans écrire
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
end

-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus)
function Commande:fermer()
	local restantes = 0
	for joueur in pairs(self.ateliers) do
		restantes += 1
		task.spawn(function()
			self:enregistrer(joueur, true, Commande.ESSAIS_ECRITURE)
			restantes -= 1
		end)
	end
	local debut = self.horloge()
	while restantes > 0 and self.horloge() - debut < Commande.FERMETURE_MAX do
		self.attendre(0.5)
	end
end

-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	local d = etat:exporter()
	d.robes = { d.robes[1] }
	return d
end

-- Une action d'un joueur. Ne lève jamais d'erreur : une erreur imprévue devient un refus.
function Commande:traiter(joueur, action, ...)
	local faire = type(action) == "string" and ACTIONS[action]
	if not faire then
		return refus("Action inconnue.")
	end
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !")
	end
	local a = self:atelier(joueur)
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true }
	end
	local ok, reponse = pcall(faire, a, ...)
	if not ok then
		warn(("[Atelier] %s : erreur dans « %s » : %s"):format(joueur.Name, action, tostring(reponse)))
		return refus("Action impossible.")
	end
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
		if action == "etat" and self.sauvegarde and not a.sauvable then
			reponse.avertissement = SANS_SAUVEGARDE
		elseif action == "livrer" and reponse.reussie then
			self:exposer(joueur) -- la robe livrée part en vitrine
		end
	end
	return reponse
end

return Commande
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104964 vérifications
TOUT EST VERT : 311 vérifications
```

- [ ] **Step 5: Le scénario regarde la rue**

Dans `tests/scenario.luau` :

1. Juste après `verifier(parties.donnees[cleJoueur].version == 99 and serveur:atelier(joueur) ~= nil and not serveur:atelier(joueur).sauvable, "partie illisible : le joueur joue sans sauvegarde")`, ajouter :

```lua
-- La rue : le serveur a construit la boutique du joueur à l'emplacement qu'il lui a donné
local numeroBoutique = joueur:GetAttribute("Boutique")
local maBoutique = M.services.Workspace.Rue:FindFirstChild("Boutique_" .. tostring(numeroBoutique))
verifier(numeroBoutique == 1 and maBoutique ~= nil and maBoutique:GetAttribute("Proprietaire") == joueur.UserId, "le serveur a construit la boutique du joueur dans la rue")
local maVitrine = M.services.Workspace.Vitrines:FindFirstChild("Vitrine_" .. numeroBoutique)
verifier(maVitrine ~= nil and maVitrine:GetAttribute("Recette") == nil, "sa vitrine, sur la rue, est vide")
```

2. Juste après `verifier(scene.Vitrines.Socle:GetAttribute("Recette") ~= nil, "la robe livrée part en vitrine")`, ajouter :

```lua
verifier(maVitrine:GetAttribute("Recette") == requireModule(dossier.Recette).encoder(serveur:atelier(joueur).etat.robes[1]), "la robe livrée part dans la vitrine de la boutique, sur la rue")
```

3. Dans la dernière partie (« Sauvegarde »), remplacer les deux premières lignes

```lua
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
M.services.Players.PlayerRemoving:Fire(joueur)
```

par :

```lua
local robeLivree = serveur:atelier(joueur).etat.robes[1]
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
M.services.Players.PlayerRemoving:Fire(joueur)
```

4. Remplacer `parties.donnees[cleJoueur] = { version = 2, argent = 5000, stock = {}, debloques = {}, recettes = {} }` par :

```lua
parties.donnees[cleJoueur] = { version = 2, argent = 5000, stock = {}, debloques = {}, recettes = { robeLivree } }
```

5. Juste après `verifier(parties.donnees[cleJoueur].verrou.t == 0 and serveur.ateliers[joueur] == nil, "départ du joueur : partie écrite, verrou rendu")`, ajouter :

```lua
verifier(M.services.Workspace.Rue:FindFirstChild("Boutique_1") == nil and M.services.Workspace.Vitrines:FindFirstChild("Vitrine_1") == nil, "départ du joueur : sa boutique est retirée de la rue")
```

6. Juste après `verifier(serveur:atelier(joueur) ~= nil and serveur:atelier(joueur).etat.etape == "carnet", "retour suivant : la commande reprend")`, ajouter :

```lua
verifier(M.services.Workspace.Rue:FindFirstChild("Boutique_1") ~= nil and M.services.Workspace.Vitrines.Vitrine_1:GetAttribute("Recette") ~= nil, "retour : sa boutique est reconstruite, sa dernière robe en vitrine")
```

- [ ] **Step 6: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Rue n'est pas un membre valide de Workspace « Workspace »` (le serveur ne construit pas encore la rue ; unitaires : 104964 vérifications)

- [ ] **Step 7: Brancher la rue dans le script du serveur**

`src/server/init.server.luau` :

```lua
-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). Les parties sont sauvegardées (Sauvegarde) : lues à l'arrivée du joueur, écrites
-- toutes les 60 s, à son départ et à l'arrêt du serveur. Chaque joueur a sa boutique dans la rue
-- (Boutiques), avec sa dernière robe livrée en vitrine.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Commande = require(script:WaitForChild("Commande"))
local Sauvegarde = require(script:WaitForChild("Sauvegarde"))
local Boutiques = require(script:WaitForChild("Boutiques"))

local boutiques = Boutiques.nouvelles(Workspace)
-- Pas de sauvegarde sur un lieu non publié, ni si le DataStore est indisponible (avertissement)
local commande = Commande.nouvelle({
	sauvegarde = Sauvegarde.pourLeJeu(),
	vitrine = function(joueur, recette)
		boutiques:exposer(joueur, recette)
	end,
})

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

-- Arrivée : une boutique dans la rue (l'avatar apparaît à son entrée), puis la partie
local function arrivee(joueur)
	boutiques:attribuer(joueur)
	joueur.CharacterAdded:Connect(function()
		task.defer(boutiques.placer, boutiques, joueur) -- après la mise en place par Roblox
	end)
	boutiques:placer(joueur)
	commande:arrivee(joueur)
end
Players.PlayerAdded:Connect(arrivee)
for _, joueur in ipairs(Players:GetPlayers()) do
	task.spawn(arrivee, joueur)
end
Players.PlayerRemoving:Connect(function(joueur)
	commande:depart(joueur)
	boutiques:liberer(joueur)
end)

local function sauvegardeReguliere()
	commande:enregistrerTout()
	task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
end
task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
game:BindToClose(function()
	commande:fermer()
end)
```

- [ ] **Step 8: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104964 vérifications
TOUT EST VERT : 316 vérifications
```

- [ ] **Step 9: Commit**

```bash
git add src/server/Commande.luau src/server/init.server.luau tests/unitaires/35_commande_vitrine.luau tests/scenario.luau
git commit -m "La rue branchée sur le serveur : boutique à l'arrivée, dernière robe livrée en vitrine

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: L'atelier du client dans sa boutique

**Files:**
- Modify: `tests/mock.luau` (égalité des CFrame)
- Modify: `src/client/Atelier/Scene.luau` (réécrit)
- Modify: `src/client/Atelier/init.client.luau` (origine de la boutique, vitrines de la rue)
- Modify: `tests/unitaires/23_scene_decorations.luau` (la vitrine locale n'est plus testée ici)
- Test: `tests/unitaires/36_scene_origine.luau`, `tests/scenario.luau` (vues dans le repère de la boutique)

**Interfaces:**
- Consumes: `Boutique.emplacement`, `Boutique.MANNEQUIN` (tâche 1) ; attribut `Boutique` du joueur et dossier `Workspace.Vitrines` (tâches 2 et 3) ; `Vitrines.nouveau(dossier, position)` (plan 2).
- Produces: `Scene.nouvelle(parent, { origine = CFrame, … })` ; `scene.origine`, `scene.cadre` (le cadre de la robe dans le monde) ; `Scene.CADRE = Boutique.MANNEQUIN` ; `Scene.VITRINE`, `scene.socle` et `scene.vitrines` n'existent plus.

- [ ] **Step 1: L'égalité des CFrame dans le faux Roblox**

Dans `tests/mock.luau`, juste avant `CF.__mul = function(a, b)`, ajouter :

```lua
-- Égalité par valeur, comme dans Roblox (position et rotation exactement égales)
CF.__eq = function(a, b)
	if a.p ~= b.p then
		return false
	end
	for i = 1, 9 do
		if a.r[i] ~= b.r[i] then
			return false
		end
	end
	return true
end
```

- [ ] **Step 2: Écrire le test de la scène dans une boutique**

`tests/unitaires/36_scene_origine.luau` :

```lua
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
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `attempt to index nil with 'Position'` (`scene.cadre` n'existe pas encore)

- [ ] **Step 4: La scène se place dans la boutique**

`src/client/Atelier/Scene.luau` :

```lua
-- Scene : l'atelier en 3D, côté client, dans la boutique du joueur. La cliente en personne, le mannequin à
-- ses mesures, les pièces épinglées dessus (le vrai tissu découpé), l'aperçu des décorations, les réglages
-- de la photo, et la caméra fixe des postes autour du mannequin (qui peut tourner pendant les décorations).
-- Les positions ci-dessous sont dans le repère de la boutique (module Boutique) ; la scène les place à
-- l'origine de la boutique du joueur. Les vitrines de la rue sont posées par le serveur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Mannequin = require(Couture:WaitForChild("Mannequin"))
local ConstructeurRobe = require(Couture:WaitForChild("ConstructeurRobe"))
local Boutique = require(Couture:WaitForChild("Boutique"))
local Lighting = game:GetService("Lighting")
local Cliente = require(script.Parent:WaitForChild("Cliente"))

local Scene = {}
Scene.__index = Scene

-- Taille du mannequin (repère de la boutique, studs) ; le devant du corps regarde vers −Z
Scene.CADRE = Boutique.MANNEQUIN
-- Caméra face au mannequin, décalée pour le laisser à gauche de l'écran (le panneau est à droite)
Scene.CAMERA = CFrame.lookAt(Vector3.new(-1.1, 2.6, 34.6), Vector3.new(-1.1, 2.2, 40))
-- Étapes où la caméra montre le mannequin
Scene.POSTES = { epinglage = true, couture = true, decorations = true, photo = true, refus = true }
-- La cliente attend en retrait à côté du mannequin (à gauche à l'écran), tournée vers la caméra ; pieds au sol
Scene.CLIENTE = CFrame.lookAt(Vector3.new(4.6, 0, 42), Vector3.new(-1.1, 0, 34.6))
Scene.DUREE_ADIEU = 3 -- secondes avant qu'elle s'en aille, une fois la commande finie
Scene.PRES_CLIENTE = 3.5 -- studs : la vue qui tourne passe près d'elle, elle s'efface pour ne pas boucher la vue
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

-- Commandes de l'avatar (clavier, stick tactile) : coupées pendant les postes, pour que toucher ou
-- glisser sur la scène ne fasse pas marcher l'avatar. Passe par le PlayerModule de Roblox.
local function controlesDuJoueur(actif)
	local joueur = Players.LocalPlayer
	local scripts = joueur and joueur:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if not module then
		return
	end
	local ok, playerModule = pcall(require, module)
	if ok and type(playerModule) == "table" and playerModule.GetControls then
		local controles = playerModule:GetControls()
		if actif then
			controles:Enable()
		else
			controles:Disable()
		end
	end
end

-- options : { origine = CFrame } l'origine de la boutique du joueur (défaut : l'origine du monde),
-- { etaler = bool } pour la construction des pièces (défaut vrai),
-- { controles = function(actif) } pour remplacer la coupure des commandes de l'avatar (tests)
function Scene.nouvelle(parent, options)
	local origine = options and options.origine or CFrame.new()
	local dossier = Instance.new("Folder")
	dossier.Name = "AtelierLocal"
	local robe = Instance.new("Model")
	robe.Name = "Robe"
	robe.Parent = dossier
	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = dossier
	dossier.Parent = parent or Workspace
	local self = setmetatable({
		dossier = dossier,
		robe = robe,
		decorations = decorations,
		origine = origine,
		cadre = origine * Scene.CADRE, -- le cadre de la robe, dans le monde
		mesures = nil,
		mannequin = nil,
		recette = nil,
		pieces = {},
		cameraFixe = false,
		ouverte = true,
		orbite = 0, -- degrés autour du mannequin (décorations)
		cliente = nil, -- la cliente de la commande en cours
		clienteCommande = nil, -- la commande pour laquelle elle est venue
		partante = nil, -- la cliente précédente, qui salue avant de partir
		lumiereOrigine = nil, -- lumière du jeu, gardée pendant la photo
		couleursMannequin = nil, -- couleurs du mannequin, gardées pendant la photo
		champOrigine = nil, -- champ de la caméra, gardé le temps de la prise de vue
		controles = options and options.controles or controlesDuJoueur,
	}, Scene)
	return self
end

local function memesMesures(a, b)
	return a and b and a.poitrine == b.poitrine and a.taille == b.taille and a.hanches == b.hanches
end

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
		local modele = Cliente.construire(commande, self.origine * Scene.CLIENTE, self.dossier)
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
		fond.CFrame = self.origine * CFrame.new(Scene.CADRE.Position.X, 5, Scene.CADRE.Position.Z + 3.5)
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
		camera.CFrame = self.origine * Scene.CAMERA_PHOTO
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
	-- Mannequin aux mesures de la cliente
	local mesures = etat.commande and etat.commande.mesures
	if not memesMesures(mesures, self.mesures) then
		if self.mannequin then
			self:finirPhoto()
			self.mannequin:Destroy()
			self.mannequin = nil
		end
		self.mesures = mesures and table.clone(mesures)
		if mesures then
			self.mannequin = Mannequin.construire(mesures, self.cadre, self.dossier)
		end
	end
	-- Pièces épinglées
	local recette = etat:recette()
	self.recette = recette
	local voulues = {}
	if recette then
		for _, p in ipairs(recette.pieces) do
			if etat.epinglees[p.id] then
				voulues[p.id] = p
			end
		end
	end
	for id, entree in pairs(self.pieces) do
		if not voulues[id] or entree.mesures ~= self.mesures then
			for _, part in ipairs(entree.parts) do
				part:Destroy()
			end
			self.pieces[id] = nil
		end
	end
	if etat.etape ~= "decorations" then
		self.orbite = 0
	end
	-- Décorations : l'écran des décorations montre la liste qu'il édite ; ailleurs, celles de la recette
	if etat.etape == "photo" or etat.etape == "refus" then
		self:montrerDecorations(recette, recette.accessoires, nil)
	elseif etat.etape ~= "decorations" then
		self:montrerDecorations(nil, {}, nil)
	end
	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
	if not recette then
		return
	end
	for _, p in ipairs(recette.pieces) do
		if voulues[p.id] and not self.pieces[p.id] then
			local entree = { parts = {}, mesures = self.mesures }
			self.pieces[p.id] = entree
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, self.cadre, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.CanQuery = true -- touchée par les rayons des décorations
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				end
			end
		end
	end
end

-- Aperçu des décorations : la liste (format de la recette) et la garniture en cours ; chaque décoration
-- posée garde sa place dans la liste (attribut « Indice ») pour être sélectionnée au toucher.
-- selection (facultatif) : indice de la décoration sélectionnée, surlignée
function Scene:montrerDecorations(recette, liste, garniture, selection)
	self.decorations:ClearAllChildren()
	if not recette then
		return
	end
	local r = table.clone(recette)
	r.accessoires = liste
	local function poser(a, indice)
		local groupe = ConstructeurRobe.accessoire(r, a, self.cadre, self.decorations)
		groupe:SetAttribute("Indice", indice)
		if indice ~= nil and indice == selection then
			local surlignage = Instance.new("Highlight")
			surlignage.Name = "Selection"
			surlignage.FillTransparency = 1
			surlignage.OutlineColor = Color3.fromRGB(255, 220, 60)
			surlignage.Parent = groupe
		end
		for _, d in ipairs(groupe:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanQuery = true
			end
		end
	end
	for i, a in ipairs(liste) do
		poser(a, i)
	end
	if garniture and #garniture.trajet >= 2 then
		poser(garniture, nil)
	end
end

-- Ce que touche un rayon (repère du monde) : une décoration { genre = "decoration", indice },
-- une pièce de la robe { genre = "piece", indicePiece, copie, u, v }, ou nil
function Scene:toucher(origine, direction)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { self.robe, self.decorations }
	local impact = Workspace:Raycast(origine, direction, params)
	local i = impact and impact.Instance
	while i and i.Parent ~= self.decorations and i.Parent ~= self.robe do
		i = i.Parent
	end
	if not i then
		return nil
	end
	if i.Parent == self.decorations then
		local indice = i:GetAttribute("Indice")
		return indice and { genre = "decoration", indice = indice } or nil
	end
	local id, copie = i.Name:match("^Piece_(.+)_(%a+)$")
	if not id or not self.recette then
		return nil
	end
	for k, p in ipairs(self.recette.pieces) do
		if p.id == id then
			local point = self.cadre:PointToObjectSpace(impact.Position) / Catalogue.STUDS_PAR_DM
			local u, v = Patron.versUV(id, copie, point, self.recette.mesures)
			return { genre = "piece", indicePiece = k, copie = copie, u = u, v = v }
		end
	end
	return nil
end

-- Tourne la caméra autour du mannequin (degrés), pendant les décorations
function Scene:orbiter(degres)
	self.orbite = (self.orbite + degres) % 360
	if self.cameraFixe then
		self:regarder(true)
	end
end

-- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:regarder(ouverte and Scene.POSTES[etat.etape] == true)
end

-- Caméra fixe sur le mannequin (actif), ou rendue au joueur
function Scene:regarder(actif)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if actif then
		camera.CameraType = Enum.CameraType.Scriptable
		local vue = self.origine * Scene.CAMERA
		if self.orbite == 0 then
			camera.CFrame = vue
		else
			-- Même vue, tournée autour de l'axe vertical du mannequin
			local axe = CFrame.new(self.cadre.Position)
			camera.CFrame = axe * CFrame.Angles(0, math.rad(self.orbite), 0) * axe:Inverse() * vue
		end
		self.cameraFixe = true
		self.controles(false)
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
		self.controles(true)
	end
	self:effacerCliente()
end

-- La caméra du poste tout près de la cliente (vue qui tourne pendant les décorations) : elle s'efface,
-- comme l'avatar du joueur quand la caméra s'en approche ; visible sinon
function Scene:effacerCliente()
	local camera = Workspace.CurrentCamera
	local racine = self.cliente and self.cliente:FindFirstChild("HumanoidRootPart")
	if not racine then
		return
	end
	local proche = self.cameraFixe and camera ~= nil
		and (camera.CFrame.Position - racine.CFrame.Position).Magnitude < Scene.PRES_CLIENTE
	for _, d in ipairs(self.cliente:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = proche and 1 or 0
		end
	end
end

function Scene:detruire()
	self:finirPhoto()
	self:regarder(false)
	self.pieces = {}
	self.dossier:Destroy()
end

return Scene
```

Dans `tests/unitaires/23_scene_decorations.luau`, supprimer la ligne `local Recette = U.module("Recette")`, et remplacer la fin de la dernière partie (à partir de son titre)

```lua
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
```

par :

```lua
-- Livraison : le mannequin de travail est libéré (la vitrine est posée par le serveur, dans la rue)
---------------------------------------------------------------------------
etat.commande.exigences = { { type = "qualite", valeur = 0.5 } }
U.verifier(etat:livrer().reussie, "robe livrée")
scene:synchroniser(etat)
U.verifier(#scene.robe:GetChildren() == 0 and scene.dossier:FindFirstChild("Mannequin") == nil, "le mannequin de travail est libéré pour la cliente suivante")
scene:detruire()
```

(la ligne de tirets qui précède reste en place.)

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|n'est pas" | head -3`
Expected (tests unitaires verts ; le scénario cherche encore la vitrine locale) :
```
une ligne qui finit par `Vitrines n'est pas un membre valide de Folder « AtelierLocal »`, puis `Unitaires : 104970 vérifications`
```

- [ ] **Step 6: Le scénario regarde depuis la boutique**

Dans `tests/scenario.luau` :

1. Juste après `verifier(maVitrine ~= nil and maVitrine:GetAttribute("Recette") == nil, "sa vitrine, sur la rue, est vide")`, ajouter :

```lua
-- L'atelier du client est dans sa boutique : les vues attendues sont dans le repère de la boutique
local origineBoutique = requireModule(dossier.Boutique).emplacement(numeroBoutique)
```

2. Dans `point3D`, remplacer `return ScenePoste.CADRE * (pos * Catalogue.STUDS_PAR_DM)` par :

```lua
	return origineBoutique * ScenePoste.CADRE * (pos * Catalogue.STUDS_PAR_DM)
```

3. Dans les vérifications de la caméra, remplacer partout `camera.CFrame ~= ScenePoste.CAMERA` par `camera.CFrame ~= origineBoutique * ScenePoste.CAMERA`, `camera.CFrame == ScenePoste.CAMERA` par `camera.CFrame == origineBoutique * ScenePoste.CAMERA` (quatre fois), et `pendant.vue == ScenePoste.CAMERA_PHOTO` par `pendant.vue == origineBoutique * ScenePoste.CAMERA_PHOTO`.

4. Remplacer `verifier(scene.Vitrines.Socle:GetAttribute("Recette") ~= nil, "la robe livrée part en vitrine")` par :

```lua
M.avancer(1)
verifier(maVitrine:FindFirstChild("Exposition") ~= nil, "le client construit la robe exposée dans la vitrine de la rue")
```

- [ ] **Step 7: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le nœud est là où l'on a touché` (le client est encore à l'origine du monde ; unitaires : 104970 vérifications)

- [ ] **Step 8: Le client se place dans sa boutique et voit les vitrines de la rue**

Dans `src/client/Atelier/init.client.luau` :

1. Remplacer

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
```

par :

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Boutique = require(Couture:WaitForChild("Boutique"))
local Vitrines = require(Couture:WaitForChild("Vitrines"))
```

2. Remplacer `local scene = Scene.nouvelle()` par :

```lua
-- L'atelier est dans la boutique du joueur (numéro posé par le serveur à son arrivée ; 0 : rue pleine)
local numero = joueur:GetAttribute("Boutique")
while numero == nil do
	joueur:GetAttributeChangedSignal("Boutique"):Wait()
	numero = joueur:GetAttribute("Boutique")
end
local origine = if numero > 0 then Boutique.emplacement(numero) else CFrame.new()
local scene = Scene.nouvelle(Workspace, { origine = origine })
-- Les vitrines de la rue (la sienne et celles des voisins) : chaque robe est construite près de la caméra
Vitrines.nouveau(Workspace:WaitForChild("Vitrines"), function()
	local camera = Workspace.CurrentCamera
	return camera and camera.CFrame.Position or origine.Position
end)
```

- [ ] **Step 9: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104970 vérifications
TOUT EST VERT : 316 vérifications
```

- [ ] **Step 10: Commit**

```bash
git add tests/mock.luau src/client/Atelier/Scene.luau src/client/Atelier/init.client.luau tests/unitaires/23_scene_decorations.luau tests/unitaires/36_scene_origine.luau tests/scenario.luau
git commit -m "L'atelier du client dans sa boutique ; les vitrines de la rue construites près de la caméra

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: la rue jouable ; le sous-projet 1 n'attend plus que la finition (plan 4d).

- [ ] **Step 1: En Play, la boutique du joueur**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan4cDepot.rbxl`), l'ouvrir dans Studio, lancer Play, attendre 4 s, cliquer `Clochette`. Avec `execute_luau` (Client), lire :
- l'attribut `Boutique` du joueur ;
- `workspace.Rue.Boutique_<n>` et le texte de son enseigne (`Enseigne.SurfaceGui.Texte`) ;
- la position de `HumanoidRootPart` et celles de `workspace.AtelierLocal.Mannequin.Buste` et de `workspace.AtelierLocal.Cliente`, dans le repère `Boutique.emplacement(n)` (`PointToObjectSpace`).

Expected : boutique 1 ; enseigne « L'atelier de <nom du joueur> » ; avatar vers (−6 ; 3,2 ; 33) ; buste vers (0 ; 3,4 ; 40) ; cliente vers (4,6 ; 2,7 ; 42) ; titre « 1. Carnet de croquis ».

- [ ] **Step 2: La vitrine sur la rue**

Avec `execute_luau` (Server), fabriquer une robe livrée (`EtatAtelier` : commande, croquis droit en coton à carreaux, achat, quatre découpes, épinglage, coutures, `decorer({})`, exigence de qualité 0,1, `livrer`), puis `workspace.Vitrines.Vitrine_1:SetAttribute("Recette", Recette.encoder(robe))`. Avec `execute_luau` (Client), attendre 3 s et lire `workspace.Vitrines.Vitrine_1.Exposition`.

Expected : l'exposition existe (mannequin et robe, une douzaine de pièces) ; aucune alerte côté client ; côté serveur, seul « Lieu non publié : les parties ne sont pas sauvegardées. ». Arrêter Play.

- [ ] **Step 3: À faire par le commanditaire**

Ces vérifications demandent l'interface de Studio :
- le rendu de la boutique : vue du poste, vue qui tourne, rue et vitrine vues du dehors ;
- l'essai à 3 joueurs (Test, « Clients et serveur », 3 joueurs) : trois boutiques attribuées, chaque vitrine visible par les autres, et la boutique retirée au départ d'un joueur (spec §7).

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 4: Mettre à jour le README**

Dans `README.md` :

1. Remplacer

```markdown
## État actuel (plan 4b)

Jouable dans Studio, en solo. Le serveur tient l'atelier de chaque joueur et valide chaque action (il fait
foi) ; le client n'affiche qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent,
stock de tissu, dix dernières robes et commande en cours : une déconnexion ne perd pas le travail) :
```

par :

```markdown
## État actuel (plan 4c)

Jouable dans Studio. Une rue de 8 boutiques : à son arrivée, chaque joueur reçoit la sienne, à son nom, et
y travaille ; sa dernière robe livrée est exposée dans sa vitrine, sur la rue, où les autres joueurs la
voient. Le serveur tient l'atelier de chaque joueur et valide chaque action (il fait foi) ; le client n'affiche
qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent, stock de tissu, dix dernières
robes et commande en cours : une déconnexion ne perd pas le travail) :
```

2. Remplacer `9. La suite : boutiques de la rue et vitrines visibles par tous (plan 4c), finition (plan 4d).` par `9. La suite : finition (plan 4d).`

3. Dans le tableau de `src/shared/`, juste après la ligne de `Maillage`, `Mannequin`…, ajouter :

```markdown
  | `Boutique` | Plan d'une boutique (repère local) et les 8 emplacements de la rue |
```

4. Juste après la ligne `  serveur. Rien n'est écrit si la lecture a échoué (le joueur est prévenu), ni sur un lieu non publié.`, ajouter :

```markdown
  `Boutiques` construit la rue : une boutique par joueur (murs, porte et fenêtre, enseigne à son nom,
  comptoir et clochette, étagère de tissus, table, machine), et le socle de sa vitrine, qui porte la
  recette de sa dernière robe livrée (attribut `Recette`) ; chaque client construit les robes proches.
```

5. Remplacer les deux lignes

```markdown
  l'avatar de la cliente et sa bulle ; `Scene` tient la cliente, le mannequin, la robe épinglée, l'aperçu des
  décorations, les réglages de la photo, la vitrine et la caméra du poste ;
```

par :

```markdown
  l'avatar de la cliente et sa bulle ; `Scene` tient, dans la boutique du joueur, la cliente, le mannequin,
  la robe épinglée, l'aperçu des décorations, les réglages de la photo et la caméra du poste ;
```

- [ ] **Step 5: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104970 vérifications
TOUT EST VERT : 316 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4c terminé : les boutiques de la rue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
