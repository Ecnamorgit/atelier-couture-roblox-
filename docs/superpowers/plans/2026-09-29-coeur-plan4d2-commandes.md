# Cœur de l'atelier — Plan 4d-2 : les commandes et affichages du §4, et les gênes restantes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner à chaque poste les commandes et affichages que le tableau de la spec §4 prévoit et qui manquent encore, et régler les gênes du joueur reportées par la relecture du plan 4d-1.

**Architecture:**
- **Carnet** : `Metrage.aAcheter` (nouveau, partagé) calcule le tissu à acheter pour un croquis ; le carnet l'affiche en direct avec son coût.
- **Achat** : toucher l'échantillon d'un tissu ouvre l'aperçu du rouleau conseillé (`Metrage.disposition`).
- **Découpe** : molette sur la pièce pour tourner, A et D pour dérouler (liées par `ContextActionService` tant que la fenêtre est ouverte), tissu entamé affiché et marqué.
- **Accueil et photo** : la touche E sonne la clochette ; une prise de vue sans réponse prévient le joueur ; « Fermer » de l'aperçu passe hors des boutons.
- **Réponse perdue** :
  - le client ne dit plus « Réessaie » : il vérifie d'abord l'état auprès du serveur ;
  - les actions attendent le temps de cette vérification, rien n'est fait deux fois ;
  - une erreur du serveur déclenche la même vérification ;
  - un départ en cours fait attendre un retour rapide.
- **Scène et rue** : une pièce ratée faute de mémoire est réessayée seule ; une boutique en panne ne laisse rien dans la rue.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§4 Déroulé et commandes, §6 Échanges, §8.6 Finition). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan4c-boutiques.md`, `…plan4d1-robustesse.md`.

## Décisions de ce plan

- **Découpage de la finition** : le plan 4d-2 couvre les commandes et affichages du §4 et les gênes du joueur. Les sons, les réglages mobiles, l'équilibrage des prix et des jauges et la table et la machine plus réalistes forment le plan 4d-3 : ils demandent surtout Studio et un téléphone.
- **Carnet, « métrage et coût en direct »** :
  - une ligne en bas à gauche, à côté de « Valider » : « Tissu à acheter : N dm, M po (tu as X po). » ;
  - N est la somme, par tissu, du conseil de `Metrage` moins le stock, et M le prix de ces décimètres ;
  - en rouge avec « il te manque Y po » si l'argent ne suffit pas ;
  - tant qu'aucun tissu n'est choisi : « Choisis les tissus : le métrage et le coût s'affichent ici. ».
- **Achat, « aperçu du rouleau »** :
  - l'échantillon de chaque ligne devient un bouton ;
  - il ouvre, par-dessus la liste, le rouleau conseillé, avec les pièces rangées comme `Metrage.disposition` les compte (droit-fil parfait) et le symétrique des pièces pliées ;
  - à 20 px par dm, la silhouette de chaque pièce, ou une boîte unie si la mémoire des images est pleine ;
  - « Fermer » est en haut, au-dessus de la liste.
  - La liste filtrable par style est celle du carnet (choix du tissu), déjà faite.
- **Découpe, « molette ou R pour tourner, A/D pour dérouler »** :
  - la molette tourne la pièce de 15° quand la souris est dessus, et le rouleau ne défile pas pendant ce temps ;
  - A et D font défiler le rouleau de 2 dm. Ils sont liés par `ContextActionService` (action `AtelierDerouler`, priorité haute, absorbée) tant que la fenêtre est ouverte, pour que l'avatar ne marche pas ;
  - R ne tourne plus rien fenêtre fermée.
  - Au téléphone, les boutons « « 15° », « 1° »… » et le défilement au doigt remplacent ↺ ↻ et « dérouler » : Gotham n'a pas ces symboles.
- **Tissu entamé** : « Entamé : U / L dm » à droite du droit-fil, et une ligne orange sur le rouleau à U dm (couper consomme le rouleau jusqu'au bas de la pièce la plus basse).
- **Accueil, « E ou clic »** : E sonne la clochette, fenêtre ouverte et hors du chat. Le bouton affiche « (E) » seulement avec un clavier.
- **Photo** : une prise sans réponse au bout de 2 s affiche « La photo n'a pas pu être prise. ». Dans l'aperçu, « Fermer » passe en haut (au-dessus des seuls textes), l'image et « Enregistrer » en dessous.
- **Réponse perdue** :
  - message `Session.INJOIGNABLE` (« Le serveur n'a pas répondu : on vérifie où en est ton atelier… ») ;
  - jusqu'au retour de l'état (2 s), les actions répondent `Session.VERIFICATION`, en refus passager ;
  - « Action impossible. » (erreur du serveur) porte `passager` et `resynchroniser`, et le client redemande l'état ;
  - l'indicateur d'attente est appelé sous `pcall` ;
  - l'écran d'achat suit les changements d'état.
- **Départ** : `Commande.departs[UserId]` est vrai pendant tout le départ, et `arrivee` l'attend comme une écriture en cours.
- **Scène** : une pièce ratée faute de mémoire des maillages est réessayée 3 s plus tard (`Scene.ESSAI_PIECE`), une synchronisation en attente à la fois.
- **Boutique en panne** : ce qui a été posé dans la rue avant la panne (boutique, vitrine) est retiré.
- **Laissé pour plus tard** : `derniere` après une livraison perdue (phrase d'adieu, paie non annoncée), et « Un instant… » qui reste 3 s après l'attente. Restent aussi des mineurs plus anciens :
  - pièce fantôme après « Recommencer » ;
  - aperçu des décorations reconstruit à chaque action ;
  - `toucher` qui ignore l'écart ;
  - liste des joueurs coupée ;
  - orientation des accessoires non reproduite.
  Les réglages mobiles (dont `UiKit.echelle`) vont au 4d-3.
- **Vérifié pendant la préparation** : chaque nouvelle vérification échoue quand on retire la correction qu'elle garde (huit variantes lancées sur le brouillon).
- **Non vérifié pendant la préparation** : Studio. La tâche 7 le fait par le connecteur MCP.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `commandes`, créée depuis `main` (où le plan 4d-1 est fusionné). Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Commandes** (spec §4) : tout se joue d'un seul doigt ou à la souris seule ; les touches du clavier (E, R, A, D, molette) ne sont que des raccourcis.
- **Symboles** (spec §4) : seulement ceux vérifiés à l'écran ; Gotham n'a ni « ✕ » ni « ⟳ ».

## Review Focus

- **Joueur au téléphone à la découpe** (ni molette ni clavier) et **joueur au clavier qui marche** (A et D sont aussi des touches de déplacement). Attendu : au téléphone, rien ne change ; au clavier, la table déroule sans faire marcher l'avatar, et fenêtre fermée l'avatar remarche. Tests : scénario, « D ne fait pas marcher l'avatar », « fenêtre fermée : A et D rendus à l'avatar ».
- **Joueur sans assez d'argent au carnet.** Attendu : la ligne dit ce qui manque, en rouge, avant de valider. Test : scénario, « pas assez d'argent : ce qui manque, en rouge ».
- **Serveur qui reste injoignable** pendant la vérification. Attendu : les actions ne restent jamais bloquées. Test : `39_session_resynchro`, « vérification ratée elle aussi : l'action suivante est tentée ».
- **Double appui sur « Fermer »** (aperçu de la photo, aperçu du rouleau). Attendu : le second appui ne tombe sur aucun bouton. Tests : scénario, « « Fermer » de l'aperçu n'est au-dessus d'aucun bouton », « « Fermer » au-dessus de la liste ».
- **Mémoire des images pleine à l'achat.** Attendu : l'aperçu du rouleau reste lisible (pièces unies). Test : scénario, « sans silhouette, les pièces restent visibles (papier uni) ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Metrage.luau` | `aAcheter(pieces, tissus, stock)` |
| `src/client/Atelier/EcranCarnet.luau` | Métrage et coût en direct |
| `src/client/Atelier/EcranAchat.luau` | Aperçu du rouleau ; suit les changements d'état |
| `src/client/Atelier/EcranDecoupe.luau` | Molette, A et D, tissu entamé, touches fenêtre ouverte seulement |
| `src/client/Atelier/EcranAccueil.luau` | Touche E |
| `src/client/Atelier/EcranPresentation.luau` | Message d'une prise sans réponse ; « Fermer » en haut de l'aperçu |
| `src/client/Atelier/Session.luau` | `INJOIGNABLE`, `VERIFICATION`, actions en attente pendant la vérification, `resynchroniser`, indicateur protégé |
| `src/server/Commande.luau` | « Action impossible. » passager avec `resynchroniser` ; départs notés |
| `src/client/Atelier/Scene.luau` | Pièce ratée réessayée (`ESSAI_PIECE`) |
| `src/server/Boutiques.luau` | Boutique en panne : rien de laissé dans la rue |
| `tests/unitaires/15_metrage.luau`, `20_scene.luau`, `29_…`, `34_boutiques.luau`, `38_…`, `39_…`, `40_…`, `tests/scenario.luau` | Tests |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Le carnet : métrage et coût en direct

**Files:**
- Modify: `src/shared/Metrage.luau`
- Modify: `src/client/Atelier/EcranCarnet.luau`
- Modify: `tests/unitaires/15_metrage.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Metrage.conseil(ids)` (plan 2), `EtatAtelier.prix(idTissu, dm)`.
- Produces: `Metrage.aAcheter(pieces, tissus, stock)` → `liste, total`, avec `liste = { { tissu, conseil, manque } }` par tissu (dans l'ordre des pièces) et `total` en dm. Libellé `Contenu.Metrage` du carnet.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/15_metrage.luau`, remplacer :

```lua
-- Droit-fil parfait : 0° pour une pièce normale, 45° pour une pièce en biais
```

par :

```lua
-- Tissu à acheter : le conseil de chaque tissu, moins le stock ; les pièces sans tissu ne comptent pas
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local liste, total = Metrage.aAcheter(PIECES, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "soie_rouge" }, { coton_blanc = 3 })
local conseilCoton = Metrage.conseil({ "corsage_droit_devant", "corsage_droit_dos" })
local conseilSoie = Metrage.conseil({ "jupe_droite_devant" })
U.verifier(#liste == 2 and liste[1].tissu == "coton_blanc" and liste[1].conseil == conseilCoton and liste[1].manque == math.max(0, conseilCoton - 3), "à acheter : le conseil du coton, moins son stock")
U.verifier(liste[2].tissu == "soie_rouge" and liste[2].conseil == conseilSoie and liste[2].manque == conseilSoie, "à acheter : la soie, sans stock")
U.verifier(total == liste[1].manque + liste[2].manque, "à acheter : le total")
local _, rien = Metrage.aAcheter(PIECES, { corsage_droit_devant = "coton_blanc" }, { coton_blanc = 99 })
U.verifier(rien == 0, "assez de stock : rien à acheter")
U.verifier(#Metrage.aAcheter(PIECES, {}, {}) == 0, "aucun tissu choisi : rien")

-- Droit-fil parfait : 0° pour une pièce normale, 45° pour une pièce en biais
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
```

par :

```lua
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
verifier(string.find(fenetre.Contenu.Metrage.Text, "Choisis les tissus", 1, true) == 1, "sans tissu : le métrage attend les tissus")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(jaugeApres.X.Scale > jaugeAvant.X.Scale, "la jauge Romantique monte avec la soie")
```

par :

```lua
verifier(jaugeApres.X.Scale > jaugeAvant.X.Scale, "la jauge Romantique monte avec la soie")
-- Métrage et coût en direct : le conseil pour toute la robe (en soie), au prix de la soie
local Metrage = requireModule(dossier.Metrage)
local piecesRobe = requireModule(dossier.Patron).piecesDuCroquis({ corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_trapeze" })
local dmRobe = Metrage.conseil(piecesRobe)
local prixRobe = EtatAtelier.prix("soie_rose_fleurs", dmRobe)
verifier(fenetre.Contenu.Metrage.Text == ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dmRobe, prixRobe, argent()), "métrage et coût en direct : " .. fenetre.Contenu.Metrage.Text)
-- Pas assez d'argent (copie du client appauvrie le temps du test) : la ligne dit ce qui manque, en rouge
local etatCarnet = requireModule(scriptClient.Session).courante.etat
local argentVrai = etatCarnet.argent
etatCarnet.argent = prixRobe - 10
cliquer("Variante_jupe_trapeze") -- même croquis : le carnet se redessine
verifier(fenetre.Contenu.Metrage.Text == ("Tissu à acheter : %d dm, %d po — il te manque 10 po."):format(dmRobe, prixRobe) and fenetre.Contenu.Metrage.TextColor3 == requireModule(scriptClient.UiKit).COULEURS.erreur, "pas assez d'argent : ce qui manque, en rouge")
etatCarnet.argent = argentVrai
cliquer("Variante_jupe_trapeze")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value` (`Metrage.aAcheter` n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Metrage.luau`, remplacer :

```lua
-- Longueur conseillée (dm) pour couper ces pièces dans un même tissu
function Metrage.conseil(ids)
	local _, longueur = Metrage.disposition(ids)
	return longueur
end
```

par :

```lua
-- Longueur conseillée (dm) pour couper ces pièces dans un même tissu
function Metrage.conseil(ids)
	local _, longueur = Metrage.disposition(ids)
	return longueur
end

-- Tissu à acheter pour un croquis : pieces = ses pièces (dans l'ordre), tissus = { [idPiece] = idTissu }
-- (les pièces sans tissu ne comptent pas), stock = { [idTissu] = dm }. Renvoie { { tissu, conseil, manque } }
-- par tissu, dans l'ordre des pièces, et le total manquant (dm).
function Metrage.aAcheter(pieces, tissus, stock)
	local ordre, parTissu = {}, {}
	for _, id in ipairs(pieces) do
		local t = tissus[id]
		if t then
			if not parTissu[t] then
				parTissu[t] = {}
				table.insert(ordre, t)
			end
			table.insert(parTissu[t], id)
		end
	end
	local liste, total = {}, 0
	for _, t in ipairs(ordre) do
		local conseil = Metrage.conseil(parTissu[t])
		local manque = math.max(0, conseil - (stock[t] or 0))
		table.insert(liste, { tissu = t, conseil = conseil, manque = manque })
		total += manque
	end
	return liste, total
end
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
-- Écran du carnet de croquis : variantes des 4 familles, tissu de chaque pièce, jauges de style
-- et exigences de la cliente mises à jour en direct.
```

par :

```lua
-- Écran du carnet de croquis : variantes des 4 familles, tissu de chaque pièce, jauges de style,
-- exigences de la cliente, métrage et coût du tissu à acheter, mis à jour en direct.
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
```

par :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 1, -190), Parent = gauche })
```

par :

```lua
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 1, -190), Parent = gauche })
	-- En bas à gauche, à côté de « Valider » : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, -260, 0, 46), Parent = contenu })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		local SYMBOLES = { ok = "✓", non = "×", ["?"] = "…" }
```

par :

```lua
		-- Tissu à acheter (le stock compte) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat.stock)
		local prix = 0
		for _, t in ipairs(aAcheter) do
			prix += EtatAtelier.prix(t.tissu, t.manque)
		end
		if #aAcheter == 0 then
			metrage.Text, metrage.TextColor3 = "Choisis les tissus : le métrage et le coût s'affichent ici.", C.texteDoux
		elseif prix > etat.argent then
			metrage.Text = ("Tissu à acheter : %d dm, %d po — il te manque %d po."):format(dm, prix, prix - etat.argent)
			metrage.TextColor3 = C.erreur
		else
			metrage.Text, metrage.TextColor3 = ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dm, prix, etat.argent), C.texte
		end
		local SYMBOLES = { ok = "✓", non = "×", ["?"] = "…" }
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105050 vérifications
TOUT EST VERT : 351 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Metrage.luau src/client/Atelier/EcranCarnet.luau tests/unitaires/15_metrage.luau tests/scenario.luau
git commit -m "Carnet : métrage et coût du tissu à acheter en direct

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'achat : aperçu du rouleau

**Files:**
- Modify: `src/client/Atelier/EcranAchat.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Metrage.disposition(ids)` (plan 2), `Vignettes.silhouette`, `Vignettes.motif`.
- Produces: bouton `Apercu_<idTissu>` (l'échantillon) ; aperçu `Contenu.ApercuRouleau` (TextButton) avec `Titre`, `FermerRouleau`, `Vue.Rouleau` et ses `Piece_<id>`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(quantite and quantite > 0, "quantité conseillée pré-remplie")
```

par :

```lua
verifier(quantite and quantite > 0, "quantité conseillée pré-remplie")
-- Aperçu du rouleau (toucher l'échantillon) : les pièces de ce tissu rangées comme le conseil les compte.
-- La mémoire des images est pleine jusqu'à la découpe (silhouettes impossibles) : les pièces sont en papier uni.
M.budget.images = 0
cliquer("Apercu_soie_rose_fleurs")
local apercuRouleau = fenetre.Contenu:FindFirstChild("ApercuRouleau")
verifier(apercuRouleau ~= nil and apercuRouleau:IsA("TextButton") and apercuRouleau.Text == "" and not apercuRouleau.AutoButtonColor, "l'aperçu du rouleau s'ouvre et arrête les appuis")
local copiesRobe, copiesVues = 0, 0
for _, id in ipairs(piecesRobe) do
	copiesRobe += if Catalogue.piece(id).pliee then 2 else 1
end
for _, d in ipairs(apercuRouleau.Vue.Rouleau:GetChildren()) do
	if string.sub(d.Name, 1, 6) == "Piece_" then
		copiesVues += 1
	end
end
local tailleRouleau = apercuRouleau.Vue.Rouleau.Size
verifier(tailleRouleau.X.Offset == 14 * 20 and tailleRouleau.Y.Offset == dmRobe * 20 and copiesVues == copiesRobe, "le rouleau conseillé (" .. dmRobe .. " dm), avec ses " .. copiesRobe .. " pièces rangées")
verifier(apercuRouleau.Titre.Text == ("Soie rose fleurie : %d dm conseillés"):format(dmRobe), "le titre donne le métrage conseillé")
verifier(apercuRouleau.Vue.Rouleau["Piece_" .. piecesRobe[1]].BackgroundTransparency < 1, "sans silhouette, les pièces restent visibles (papier uni)")
verifier(apercuRouleau.FermerRouleau.Position.Y.Offset + apercuRouleau.FermerRouleau.Size.Y.Offset <= fenetre.Contenu.Lignes.Position.Y.Offset, "« Fermer » au-dessus de la liste : un double appui ne touche aucun bouton")
verifierTailles("aperçu du rouleau")
cliquer("FermerRouleau")
verifier(fenetre.Contenu:FindFirstChild("ApercuRouleau") == nil, "l'aperçu du rouleau se referme")
```

L'épuisement de la mémoire des images est avancé avant l'aperçu, pour que les silhouettes restent impossibles jusqu'à la découpe. Dans `tests/scenario.luau`, supprimer la ligne :

```lua
M.budget.images = 0 -- mémoire des images pleine en arrivant à la découpe (silhouettes impossibles)
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : un seul bouton « Apercu_soie_rose_fleurs » visible (trouvé 0)`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock, quantité à acheter et coût.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Metrage = require(Couture:WaitForChild("Metrage"))
```

par :

```lua
-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock, quantité à acheter et coût.
-- Toucher l'échantillon d'un tissu montre le rouleau conseillé, avec les pièces rangées dessus.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Metrage = require(Couture:WaitForChild("Metrage"))
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

return function(ctx)
```

par :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX_APERCU = 20 -- pixels par dm dans l'aperçu du rouleau (14 dm de large : 280 px)

return function(ctx)
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces. Le tissu en trop reste dans ton stock.",
```

par :

```lua
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces (touche un échantillon pour voir le rouleau). Le tissu en trop reste dans ton stock.",
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	local function conseil(idTissu)
		local ids = {}
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if etat.tissus[id] == idTissu then
				table.insert(ids, id)
			end
		end
		return Metrage.conseil(ids)
	end
```

par :

```lua
	local function piecesDe(idTissu)
		local ids = {}
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if etat.tissus[id] == idTissu then
				table.insert(ids, id)
			end
		end
		return ids
	end
	local function conseil(idTissu)
		return Metrage.conseil(piecesDe(idTissu))
	end

	-- Aperçu du rouleau (par-dessus la liste) : le métrage conseillé, les pièces rangées comme le conseil
	-- les compte (droit-fil parfait), et leur symétrique pour une pièce coupée pliée. Un bouton sans texte,
	-- pas un simple cadre : dans Roblox, un cadre laisse passer l'appui aux boutons cachés dessous.
	-- « Fermer » est en haut, au-dessus de la liste : un double appui ne touche aucun bouton.
	local apercu
	local function fermerApercu()
		if apercu then
			apercu:Destroy()
			apercu = nil
		end
	end
	local function ouvrirApercu(idTissu)
		fermerApercu()
		local t = Catalogue.tissu(idTissu)
		local ids = piecesDe(idTissu)
		local placements, longueur = Metrage.disposition(ids)
		apercu = UiKit.creer("TextButton", { Name = "ApercuRouleau", Text = "", AutoButtonColor = false, BackgroundColor3 = C.fond, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = contenu })
		UiKit.texte({ Name = "Titre", Text = ("%s : %d dm conseillés"):format(t.nom, longueur), Font = Enum.Font.GothamBold, Size = UDim2.new(1, -150, 0, 30), ZIndex = 21, Parent = apercu })
		UiKit.boutonDoux({ Name = "FermerRouleau", Text = "Fermer", TextSize = 14, Position = UDim2.new(1, -140, 0, 0), Size = UDim2.fromOffset(140, 30), ZIndex = 21, Parent = apercu }, fermerApercu)
		local vue = UiKit.creer("ScrollingFrame", {
			Name = "Vue",
			BackgroundColor3 = C.secondaire,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 40),
			Size = UDim2.new(0, 14 * PX_APERCU + 12, 1, -40),
			CanvasSize = UDim2.fromOffset(0, longueur * PX_APERCU),
			ScrollBarThickness = 10,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ZIndex = 21,
			Parent = apercu,
		})
		local rouleau = UiKit.creer("ImageLabel", {
			Name = "Rouleau",
			BorderSizePixel = 0,
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(8 * PX_APERCU, 8 * PX_APERCU),
			Size = UDim2.fromOffset(14 * PX_APERCU, longueur * PX_APERCU),
			ZIndex = 21,
			Parent = vue,
		})
		local motif = Vignettes.motif(idTissu)
		if motif then
			rouleau.ImageContent = motif
		end
		local plie = false
		for _, id in ipairs(ids) do
			local p, b = placements[id], Polygone.boite(Catalogue.piece(id).contour)
			local copies = { { x = p.x, angle = p.angle } }
			if Catalogue.piece(id).pliee then
				plie = true
				table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
			end
			for _, c in ipairs(copies) do
				local img = UiKit.creer("ImageLabel", {
					Name = "Piece_" .. id,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(c.x * PX_APERCU, p.y * PX_APERCU),
					Size = UDim2.fromOffset((b.maxX - b.minX) * PX_APERCU, (b.maxY - b.minY) * PX_APERCU),
					Rotation = c.angle,
					ImageTransparency = 0.15,
					ZIndex = 23,
					Parent = rouleau,
				})
				local silhouette = Vignettes.silhouette(id)
				if silhouette then
					img.ImageContent = silhouette
				else
					img.BackgroundColor3, img.BackgroundTransparency = Color3.new(1, 1, 1), 0.4
				end
			end
		end
		if plie then
			UiKit.creer("Frame", { Name = "Pli", BackgroundColor3 = C.texte, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.fromOffset(Catalogue.PLI * PX_APERCU - 1, 0), Size = UDim2.new(0, 2, 1, 0), ZIndex = 22, Parent = rouleau })
		end
		UiKit.texte({
			Text = "Les pièces sont rangées en rangées, droit-fil parfait. À la table de découpe, tu les places toi-même : bien rangées, elles prennent moins de tissu.",
			TextSize = 14,
			TextColor3 = C.texteDoux,
			Position = UDim2.fromOffset(14 * PX_APERCU + 30, 40),
			Size = UDim2.new(1, -(14 * PX_APERCU + 30), 0, 80),
			ZIndex = 21,
			Parent = apercu,
		})
	end
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(80, 56),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			Parent = ligne,
		}), 6)
```

par :

```lua
		local echantillon = UiKit.arrondir(UiKit.creer("ImageButton", {
			Name = "Apercu_" .. idTissu,
			AutoButtonColor = false,
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(80, 56),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			Parent = ligne,
		}), 6)
		echantillon.Activated:Connect(function()
			ouvrirApercu(idTissu)
		end)
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "AllerDecoupe", Text = "Aller à la découpe", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:commencerDecoupe()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	return function() end
```

par :

```lua
	UiKit.bouton({ Name = "AllerDecoupe", Text = "Aller à la découpe", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:commencerDecoupe()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	return fermerApercu
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105050 vérifications
TOUT EST VERT : 360 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAchat.luau tests/scenario.luau
git commit -m "Achat : aperçu du rouleau conseillé, pièces rangées dessus

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La découpe : molette, A et D, tissu entamé

**Files:**
- Modify: `src/client/Atelier/EcranDecoupe.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `TableDecoupe:coupon()`, `Coupon:longueurUtilisee()` (plan 3b).
- Produces: action `AtelierDerouler` (A, D) liée tant que la fenêtre est ouverte ; libellé `Panneau.InfoRouleau` ; cadre `Rouleau.Tissu.Entame`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
UIS.InputEnded:Fire(doigt)
verifier(rouleau.ScrollingEnabled == true, "pièce lâchée : le rouleau défile de nouveau")
```

par :

```lua
UIS.InputEnded:Fire(doigt)
verifier(rouleau.ScrollingEnabled == true, "pièce lâchée : le rouleau défile de nouveau")
-- Molette sur la pièce : elle tourne de 15° ; le rouleau ne défile pas tant que la souris est dessus
local angleAvant = pieceC.Rotation
pieceC.MouseEnter:Fire()
verifier(rouleau.ScrollingEnabled == false, "souris sur la pièce : la molette ne fait pas défiler le rouleau")
pieceC.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, 1) })
verifier(pieceC.Rotation == angleAvant + 15, "molette vers le haut : la pièce tourne de 15°")
pieceC.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, -1) })
verifier(pieceC.Rotation == angleAvant, "molette vers le bas : elle revient")
pieceC.MouseLeave:Fire()
verifier(rouleau.ScrollingEnabled == true, "souris hors de la pièce : le rouleau défile de nouveau")
-- A et D : le rouleau se déroule de 2 dm ou revient ; les touches ne font pas marcher l'avatar
local deroule = M.actions.AtelierDerouler
verifier(deroule ~= nil and table.find(deroule.touches, Enum.KeyCode.A) ~= nil and table.find(deroule.touches, Enum.KeyCode.D) ~= nil, "A et D servent à dérouler tant que la table est affichée")
local defileAvant = rouleau.CanvasPosition.Y
verifier(deroule.f("AtelierDerouler", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.D }) == Enum.ContextActionResult.Sink, "D ne fait pas marcher l'avatar")
verifier(rouleau.CanvasPosition.Y == defileAvant + 2 * 36, "D : le rouleau se déroule de 2 dm")
deroule.f("AtelierDerouler", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.A })
verifier(rouleau.CanvasPosition.Y == defileAvant, "A : il revient")
-- Fenêtre fermée : A, D et R sont rendus au jeu
cliquer("Fermer")
verifier(M.actions.AtelierDerouler == nil, "fenêtre fermée : A et D rendus à l'avatar")
local rotationFermee = pieceC.Rotation
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard }, false)
verifier(pieceC.Rotation == rotationFermee, "fenêtre fermée : R ne tourne plus la pièce")
cliquer("OuvrirAtelier")
verifier(M.actions.AtelierDerouler ~= nil, "fenêtre rouverte : A et D déroulent de nouveau")
-- Tissu entamé : rien de coupé, le rouleau est intact
verifier(string.find(panneau.InfoRouleau.Text, "Entamé : 0 / ", 1, true) == 1 and not rouleau.Tissu.Entame.Visible, "rien de coupé : rouleau intact")
```

Dans `tests/scenario.luau`, remplacer :

```lua
		if titre() ~= "3. Table de découpe" or #panneau.ListePieces:GetChildren() < restantes then
			coupes += 1
		end
```

par :

```lua
		if titre() ~= "3. Table de découpe" or #panneau.ListePieces:GetChildren() < restantes then
			coupes += 1
			if coupes == 1 and titre() == "3. Table de découpe" then
				-- Couper consomme le rouleau jusqu'au bas de la pièce la plus basse : le tissu entamé s'affiche
				local c = requireModule(scriptClient.Session).courante.etat.coupons.soie_rose_fleurs
				verifier(c:longueurUtilisee() > 0 and panneau.InfoRouleau.Text == ("Entamé : %d / %d dm"):format(c:longueurUtilisee(), c.longueur), "une pièce coupée : le tissu entamé s'affiche")
				verifier(rouleau.Tissu.Entame.Visible and rouleau.Tissu.Entame.Position.Y.Offset == c:longueurUtilisee() * 36, "une ligne marque le tissu entamé sur le rouleau")
			end
		end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : souris sur la pièce : la molette ne fait pas défiler le rouleau`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées),
-- la pièce sélectionnée à glisser à la souris ou au doigt, la rotation, le droit-fil et la coupe.
-- La logique (position, aimantation, validité) est dans TableDecoupe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
```

par :

```lua
-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées,
-- tissu entamé), la pièce sélectionnée à glisser à la souris ou au doigt, la rotation (boutons, R, molette
-- sur la pièce), le déroulé (défilement, A et D), le droit-fil et la coupe.
-- La logique (position, aimantation, validité) est dans TableDecoupe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
local PAPIER = Color3.fromRGB(255, 248, 222) -- à défaut de silhouette (mémoire des images pleine)
```

par :

```lua
local PAPIER = Color3.fromRGB(255, 248, 222) -- à défaut de silhouette (mémoire des images pleine)
local DEROULER = 2 -- dm par appui sur A ou D
local ACTION_DEROULER = "AtelierDerouler" -- A et D déroulent le rouleau (au lieu de faire marcher l'avatar)
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	local calque = UiKit.creer("Frame", { Name = "Coupees", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = tissuImage })
```

par :

```lua
	local calque = UiKit.creer("Frame", { Name = "Coupees", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = tissuImage })
	-- Tissu entamé : couper consomme le rouleau jusqu'au bas de la pièce la plus basse
	local ligneEntame = UiKit.creer("Frame", { Name = "Entame", BackgroundColor3 = C.alerte, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 3), ZIndex = 4, Visible = false, Parent = tissuImage })
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(1, 0, 0, 22), Parent = panneau })
```

par :

```lua
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
	local infoRouleau = UiKit.texte({ Name = "InfoRouleau", TextSize = 14, TextColor3 = C.texteDoux, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.5, 0, 0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
		vue.CanvasSize = UDim2.fromOffset(0, coupon.longueur * PX)
```

par :

```lua
		vue.CanvasSize = UDim2.fromOffset(0, coupon.longueur * PX)
		local entame = coupon:longueurUtilisee()
		infoRouleau.Text = ("Entamé : %d / %d dm"):format(entame, coupon.longueur)
		ligneEntame.Visible = entame > 0
		ligneEntame.Position = UDim2.fromOffset(0, entame * PX)
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	local saisie, ecartX, ecartY = nil, 0, 0
```

par :

```lua
	local saisie, ecartX, ecartY = nil, 0, 0
	local survol = false -- souris sur la pièce : la molette la tourne, le rouleau ne défile pas
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	local function lacher()
		saisie = nil
		vue.ScrollingEnabled = true
	end
```

par :

```lua
	local function lacher()
		saisie = nil
		vue.ScrollingEnabled = not survol
	end
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	-- R : tourner de 15° (Maj + R : dans l'autre sens)
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.R then
			local inverse = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			tourner(inverse and -15 or 15)
		end
	end))
```

par :

```lua
	-- Molette sur la pièce : tourner de 15° (vers le haut : sens des aiguilles d'une montre)
	table.insert(connexions, piece.MouseEnter:Connect(function()
		survol = true
		vue.ScrollingEnabled = false
	end))
	table.insert(connexions, piece.MouseLeave:Connect(function()
		survol = false
		vue.ScrollingEnabled = saisie == nil
	end))
	table.insert(connexions, piece.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel and ctx.fenetre.Visible and table_.placement then
			tourner(input.Position.Z > 0 and 15 or -15)
		end
	end))
	-- R (fenêtre ouverte) : tourner de 15° (Maj + R : dans l'autre sens)
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and ctx.fenetre.Visible and input.KeyCode == Enum.KeyCode.R then
			local inverse = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			tourner(inverse and -15 or 15)
		end
	end))
	-- A et D : dérouler le rouleau (2 dm plus loin) ou revenir. Liées seulement quand la fenêtre est
	-- visible, et absorbées : l'avatar ne marche pas pendant ce temps.
	local function lierDerouler(actif)
		if not actif then
			ContextActionService:UnbindAction(ACTION_DEROULER)
			return
		end
		ContextActionService:BindActionAtPriority(ACTION_DEROULER, function(_, etatEntree, input)
			if etatEntree == Enum.UserInputState.Begin then
				local sens = input.KeyCode == Enum.KeyCode.D and 1 or -1
				local y = math.clamp(vue.CanvasPosition.Y + sens * DEROULER * PX, 0, vue.CanvasSize.Y.Offset)
				vue.CanvasPosition = Vector2.new(0, y)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D)
	end
	local function surVisibilite()
		lierDerouler(ctx.fenetre.Visible)
	end
	table.insert(connexions, ctx.fenetre:GetPropertyChangedSignal("Visible"):Connect(surVisibilite))
	surVisibilite()
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	return function()
		desabonner()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

par :

```lua
	return function()
		desabonner()
		lierDerouler(false)
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105050 vérifications
TOUT EST VERT : 376 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranDecoupe.luau tests/scenario.luau
git commit -m "Découpe : molette sur la pièce, A et D pour dérouler, tissu entamé marqué

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: La clochette au clavier, la photo sans réponse

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`
- Modify: `src/client/Atelier/EcranPresentation.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `ctx.fenetre`, `ctx.message` (plans 3a et 4d-1).
- Produces: touche E à l'accueil ; message « La photo n'a pas pu être prise. » quand la prise expire ; `FermerApercu` en haut de l'aperçu.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(laCliente.Parent == nil, "puis elle s'en va")
cliquer("Clochette")
verifier(scene:FindFirstChild("Cliente") ~= nil and scene.Cliente ~= laCliente, "la cliente suivante entre")
```

par :

```lua
verifier(laCliente.Parent == nil, "puis elle s'en va")
-- La touche E sonne la clochette, fenêtre ouverte seulement (comme au comptoir)
local toucheE = { KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }
cliquer("Fermer")
UIS.InputBegan:Fire(toucheE, false)
verifier(titre() == "Atelier de couture", "fenêtre fermée : E ne sonne pas")
cliquer("OuvrirAtelier")
UIS.InputBegan:Fire(toucheE, true)
verifier(titre() == "Atelier de couture", "E tapé dans le chat : rien")
M.avancer(0.5)
UIS.InputBegan:Fire(toucheE, false)
verifier(scene:FindFirstChild("Cliente") ~= nil and scene.Cliente ~= laCliente, "E : la cliente suivante entre")
```

Dans `tests/scenario.luau`, remplacer :

```lua
M.avancer(ScenePoste.ATTENTE_CAPTURE + 0.1)
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
```

par :

```lua
M.avancer(ScenePoste.ATTENTE_CAPTURE + 0.1)
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
M.avancer(1) -- le message de la capture refusée, plus haut, s'est effacé
verifier(fenetre.Message.Visible and fenetre.Message.Text == "La photo n'a pas pu être prise.", "capture sans réponse : le joueur est prévenu")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(apercu:IsA("TextButton") and apercu.Text == "" and not apercu.AutoButtonColor, "l'aperçu arrête les appuis : rien ne passe aux boutons cachés dessous")
```

par :

```lua
verifier(apercu:IsA("TextButton") and apercu.Text == "" and not apercu.AutoButtonColor, "l'aperçu arrête les appuis : rien ne passe aux boutons cachés dessous")
-- « Fermer » referme l'aperçu : un second appui trop long tomberait sur ce qui est dessous ; rien n'y est
local fermerA = apercu.FermerApercu
local hautF, basF = fermerA.Position.Y.Offset, fermerA.Position.Y.Offset + fermerA.Size.Y.Offset
local dessous = {}
for _, b in ipairs(fenetre.Contenu:GetChildren()) do
	local pos, ancre = b.Position or UDim2.new(), b.AnchorPoint or Vector2.new()
	if b:IsA("GuiButton") and b ~= apercu and pos.Y.Scale == 0 and ancre.Y == 0 then
		if pos.Y.Offset < basF and pos.Y.Offset + b.Size.Y.Offset > hautF then
			table.insert(dessous, b.Name)
		end
	end
end
verifier(#dessous == 0, "« Fermer » de l'aperçu n'est au-dessus d'aucun bouton ; dessous : " .. table.concat(dessous, ", "))
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : capture sans réponse : le joueur est prévenu`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	-- Aperçu de la photo prise. Un bouton sans texte, pas un simple cadre : dans Roblox, un cadre (même
	-- Active) laisse passer l'appui aux boutons cachés dessous (« Livrer la robe »…)
	local apercu = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Apercu", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
	local image = UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 300), ZIndex = 21, Parent = apercu })
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
```

par :

```lua
	-- Aperçu de la photo prise. Un bouton sans texte, pas un simple cadre : dans Roblox, un cadre (même
	-- Active) laisse passer l'appui aux boutons cachés dessous (« Livrer la robe »…). « Fermer » est en
	-- haut, au-dessus des textes : un double appui ne tombe sur aucun bouton une fois l'aperçu refermé.
	local apercu = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Apercu", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
	local image = UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 300), ZIndex = 21, Parent = apercu })
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 350), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	UiKit.boutonDoux({ Name = "FermerApercu", Text = "Fermer", TextSize = 14, Position = UDim2.fromOffset(0, 364), Size = UDim2.new(1, -6, 0, 34), ZIndex = 21, Parent = apercu }, function()
```

par :

```lua
	UiKit.boutonDoux({ Name = "FermerApercu", Text = "Fermer", TextSize = 14, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -6, 0, 34), ZIndex = 21, Parent = apercu }, function()
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		task.delay(scene.ATTENTE_CAPTURE, retablir, numero)
```

par :

```lua
		task.delay(scene.ATTENTE_CAPTURE, function()
			if enCours == numero then
				retablir(numero) -- pas de réponse à temps : l'interface revient, le joueur est prévenu
				ctx.message("La photo n'a pas pu être prise.", C.erreur)
			end
		end)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
-- Écran d'accueil : la clochette du comptoir fait entrer une cliente et crée la commande.
-- Après une livraison, il annonce ce qu'a pensé la cliente précédente.
return function(ctx)
```

par :

```lua
-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande. Après une livraison, il annonce ce qu'a pensé la cliente précédente.
local UserInputService = game:GetService("UserInputService")

return function(ctx)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	UiKit.bouton({
		Name = "Clochette",
		Text = "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110 + decalage),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, function()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	return function() end
```

par :

```lua
	local function sonner()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		end
	end
	UiKit.bouton({
		Name = "Clochette",
		Text = if UserInputService.KeyboardEnabled then "Sonner la clochette (E)" else "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110 + decalage),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, sonner)
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat) : sonner la clochette
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible then
			sonner()
		end
	end)
	return function()
		connexion:Disconnect()
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105050 vérifications
TOUT EST VERT : 381 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranPresentation.luau tests/scenario.luau
git commit -m "Clochette à la touche E ; photo sans réponse signalée ; « Fermer » de l'aperçu hors des boutons

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Réponse perdue : vérifier avant de refaire

**Files:**
- Modify: `src/client/Atelier/Session.luau`
- Modify: `src/server/Commande.luau` (`nouvelle`, `arrivee`, `depart`, `traiter`)
- Modify: `src/client/Atelier/EcranAchat.luau`
- Modify: `tests/unitaires/29_session_distante.luau`, `38_reponses_serveur.luau`, `39_session_resynchro.luau`, `40_sauvegarde_serie.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: la resynchronisation du plan 4d-1 (`Session.RESYNCHRO`, drapeau `resynchro`), `Commande.ecritures`.
- Produces:
  - `Session.INJOIGNABLE` et `Session.VERIFICATION` (textes) ;
  - pendant une vérification, toute action (hors « etat ») répond `{ ok = false, erreur = Session.VERIFICATION, passager = true }` ;
  - « Action impossible. » du serveur = `{ ok = false, erreur, passager = true, resynchroniser = true }` ;
  - `Commande.departs` = `[UserId] = true` pendant `depart`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(not r.ok and r.erreur == "Le serveur ne répond pas. Réessaie." and r.passager == true, "serveur injoignable : message (refus passager)")
brancher()
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "la session repart quand le serveur répond")
```

par :

```lua
U.verifier(not r.ok and r.erreur == Session.INJOIGNABLE and r.passager == true, "serveur injoignable : message (refus passager)")
brancher()
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session:acheter("coton_blanc", 1).ok, "la session repart quand le serveur répond")
```

Dans `tests/unitaires/39_session_resynchro.luau`, remplacer :

```lua
U.verifier(not r.ok and r.passager == true and r.erreur == "Le serveur ne répond pas. Réessaie.", "réponse perdue : refus passager")
U.verifier(session.etat.etape == "carnet" and cote().etape == "achat" and notifications == avant, "le serveur a agi, le client ne le sait pas encore")
```

par :

```lua
U.verifier(not r.ok and r.passager == true and r.erreur == Session.INJOIGNABLE, "réponse perdue : refus passager")
U.verifier(string.find(r.erreur, "Réessaie", 1, true) == nil, "le message n'invite pas à refaire une action que le serveur a peut-être faite")
U.verifier(session.etat.etape == "carnet" and cote().etape == "achat" and notifications == avant, "le serveur a agi, le client ne le sait pas encore")
-- Tant que l'état n'est pas revenu, les actions attendent : rien n'est fait deux fois
M.avancer(0.5)
r = session:validerCroquis(CROQUIS, TISSUS)
U.verifier(not r.ok and r.passager == true and r.erreur == Session.VERIFICATION and cote().etape == "achat", "pendant la vérification, les actions attendent")
```

Dans `tests/unitaires/39_session_resynchro.luau`, remplacer :

```lua
U.verifier(sansErreur and not r2.ok and r2.passager == true and not session.enCours, "réponse illisible : refus passager, sans erreur, session libre")
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "l'action suivante passe")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc, "copie réparée après la réponse illisible")
```

par :

```lua
U.verifier(sansErreur and not r2.ok and r2.passager == true and not session.enCours, "réponse illisible : refus passager, sans erreur, session libre")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc, "copie réparée après la réponse illisible")
U.verifier(session:acheter("coton_blanc", 1).ok, "l'action suivante passe")
```

Dans `tests/unitaires/39_session_resynchro.luau`, remplacer :

```lua
Session.courante, Commande.courante = courante, courant
```

par :

```lua

-- « Action impossible. » (erreur du serveur) : l'action a pu être faite ; l'état est redemandé
local vraie = Commande.instantane
local unefois = true
Commande.instantane = function(etat)
	if unefois then
		unefois = false
		error("panne simulée")
	end
	return vraie(etat)
end
remote.OnServerInvoke = function(j, action, ...)
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
local stockAvant = session.etat.stock.coton_blanc
r = session:acheter("coton_blanc", 1)
Commande.instantane = vraie
U.verifier(not r.ok and r.erreur == "Action impossible." and r.passager == true and session.etat.stock.coton_blanc == stockAvant, "erreur du serveur après l'achat : refus passager, copie pas encore à jour")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc and cote().stock.coton_blanc == stockAvant + 1, "l'état est redemandé : l'achat fait par le serveur apparaît")

-- Un indicateur d'attente qui lève une erreur ne bloque pas la session
session:surAttente(function()
	error("indicateur en panne")
end)
M.avancer(1)
local sansErreurAttente, r3 = pcall(session.acheter, session, "coton_blanc", 1)
U.verifier(sansErreurAttente and r3.ok and not session.enCours, "indicateur en panne : l'action passe, la session reste libre")
session:surAttente(function() end)

-- Serveur toujours injoignable : la vérification échoue aussi, et les actions ne restent pas bloquées
remote.OnServerInvoke = function()
	error("coupure simulée")
end
M.avancer(1)
session:acheter("coton_blanc", 1)
M.avancer(Session.RESYNCHRO + 0.1) -- la vérification échoue
local r4 = session:acheter("coton_blanc", 1)
U.verifier(not r4.ok and r4.erreur == Session.INJOIGNABLE, "vérification ratée elle aussi : l'action suivante est tentée, rien ne reste bloqué")
remote.OnServerInvoke = function(j, action, ...)
	return serveur:traiter(j, action, ...)
end
Session.courante, Commande.courante = courante, courant
```

Dans `tests/unitaires/38_reponses_serveur.luau`, remplacer :

```lua
U.verifier(sansErreur and not r2.ok and r2.erreur == "Action impossible.", "erreur en préparant l'état renvoyé : refus, pas d'erreur")
```

par :

```lua
U.verifier(sansErreur and not r2.ok and r2.erreur == "Action impossible.", "erreur en préparant l'état renvoyé : refus, pas d'erreur")
U.verifier(r2.passager == true and r2.resynchroniser == true, "l'action a pu être faite : refus passager, le client redemandera l'état")
```

Dans `tests/unitaires/40_sauvegarde_serie.luau`, remplacer :

```lua
U.verifier(magasin.ecritures == ecrituresArret, "serveur arrêté : plus de sauvegarde régulière")
Commande.courante = courant
```

par :

```lua
U.verifier(magasin.ecritures == ecrituresArret, "serveur arrêté : plus de sauvegarde régulière")

---------------------------------------------------------------------------
-- Retour rapide pendant un départ (qui attend encore une écriture régulière) : la lecture attend le départ
---------------------------------------------------------------------------
local serveur3 = Commande.nouvelle({ sauvegarde = sauvegarde, horloge = horloge, attendre = attendre })
local presse = joueurNumero("Presse", 707)
serveur3:arrivee(presse)
serveur3.departs[presse.UserId] = true -- son départ est en cours
local retourPresse = joueurNumero("Presse", 707)
local lectures3 = magasin.ecritures
local luPendantDepart = false
attentes = 0
pendant = function()
	luPendantDepart = luPendantDepart or magasin.ecritures ~= lectures3
	if attentes == 2 then
		serveur3.departs[presse.UserId] = nil -- le départ se termine
	end
end
serveur3:arrivee(retourPresse)
pendant = nil
U.verifier(not luPendantDepart and attentes == 2 and serveur3:atelier(retourPresse) ~= nil, "retour pendant le départ : la partie n'est lue qu'une fois le départ fini")
-- Le départ est noté du début à la fin de son écriture
local notePendant
local vraieDepuis = Sauvegarde.depuisEtat
Sauvegarde.depuisEtat = function(...)
	notePendant = serveur3.departs[retourPresse.UserId]
	return vraieDepuis(...)
end
serveur3:depart(retourPresse)
Sauvegarde.depuisEtat = vraieDepuis
U.verifier(notePendant == true and serveur3.departs[retourPresse.UserId] == nil, "départ noté pendant son écriture, puis effacé")
Commande.courante = courant
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Le serveur ne répond pas. Réessaie." and fenetre.Message.TextColor3 == GRIS, "refus passager : message en gris")
cliquer("PieceSuivante")
verifier(cousues() == 1, "première pièce cousue")
```

par :

```lua
local SessionClient = requireModule(scriptClient.Session)
verifier(fenetre.Message.Visible and fenetre.Message.Text == SessionClient.INJOIGNABLE and fenetre.Message.TextColor3 == GRIS, "refus passager : message en gris")
cliquer("PieceSuivante")
verifier(cousues() == 0 and fenetre.Message.Text == SessionClient.VERIFICATION, "tant que l'atelier vérifie où en est le serveur, la pièce attend")
M.avancer(SessionClient.RESYNCHRO)
cliquer("PieceSuivante")
verifier(cousues() == 1, "première pièce cousue")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("En stock : " .. quantite .. " dm") ~= nil, "le stock est mis à jour")
```

par :

```lua
verifier(texte("En stock : " .. quantite .. " dm") ~= nil, "le stock est mis à jour")
-- L'état change sans achat (réparé par le serveur, par exemple) : les lignes suivent
local stockServeur = serveur:atelier(joueur).etat.stock
stockServeur.soie_rose_fleurs = quantite + 7
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(texte("En stock : " .. (quantite + 7) .. " dm") ~= nil, "l'état change sans achat : la ligne suit")
stockServeur.soie_rose_fleurs = quantite
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : serveur injoignable : message (refus passager)`

- [ ] **Step 3: La session**

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."
Session.OCCUPE = "Un instant…" -- une action à la fois : un appui pendant l'attente du serveur est refusé
```

par :

```lua
-- Réponse perdue : le serveur a peut-être fait l'action ; on ne dit pas de la refaire, on vérifie d'abord
Session.INJOIGNABLE = "Le serveur n'a pas répondu : on vérifie où en est ton atelier…"
Session.VERIFICATION = "Un instant : on vérifie où en est ton atelier…" -- actions en attente de l'état
Session.OCCUPE = "Un instant…" -- une action à la fois : un appui pendant l'attente du serveur est refusé
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
-- Appel au serveur, sans jamais lever d'erreur. L'état joint à la réponse (acceptée ou refusée) est
-- rechargé. Renvoie la réponse, si l'état a changé, et si la réponse est perdue ou illisible (refus
-- passager : le serveur a pu agir sans que son état arrive).
local function appeler(self, nom, ...)
	if self.attente then
		self.attente(true)
	end
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if self.attente then
		self.attente(false)
	end
```

par :

```lua
-- Appel au serveur, sans jamais lever d'erreur. L'état joint à la réponse (acceptée ou refusée) est
-- rechargé. Renvoie la réponse, si l'état a changé, et si la réponse est perdue ou illisible (refus
-- passager : le serveur a pu agir sans que son état arrive). L'indicateur d'attente ne peut rien bloquer.
local function appeler(self, nom, ...)
	if self.attente then
		pcall(self.attente, true)
	end
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if self.attente then
		pcall(self.attente, false)
	end
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
		return { ok = false, erreur = INJOIGNABLE, passager = true }, false, true
	end
	return reponse, change, false
```

par :

```lua
		return { ok = false, erreur = Session.INJOIGNABLE, passager = true }, false, true
	end
	return reponse, change, reponse.resynchroniser == true
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
-- Une action (ou « etat ») : une à la fois. Les écrans sont prévenus après une action réussie, ou quand
-- l'état joint à une réponse a changé la copie du client. Réponse perdue : l'état est redemandé au
-- serveur un peu plus tard.
-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse, change, perdue
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = Session.OCCUPE, passager = true }
		end
```

par :

```lua
-- Une action (ou « etat ») : une à la fois. Les écrans sont prévenus après une action réussie, ou quand
-- l'état joint à une réponse a changé la copie du client. Réponse perdue (ou erreur du serveur, qui a pu
-- agir) : l'état est redemandé au serveur un peu plus tard, et les actions attendent jusque-là (rien
-- n'est fait deux fois).
-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse, change, perdue
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = Session.OCCUPE, passager = true }
		end
		if self.resynchro and nom ~= "etat" then
			return { ok = false, erreur = Session.VERIFICATION, passager = true }
		end
```

- [ ] **Step 4: Le serveur**

Dans `src/server/Commande.luau`, remplacer :

```lua
		ecritures = {}, -- [UserId] = vrai pendant l'écriture de sa partie (une à la fois par joueur)
```

par :

```lua
		ecritures = {}, -- [UserId] = vrai pendant l'écriture de sa partie (une à la fois par joueur)
		departs = {}, -- [UserId] = vrai pendant son départ (écriture comprise, même quand elle attend)
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	while self.ecritures[joueur.UserId] do
		self.attendre(0.5)
	end
```

par :

```lua
	while self.ecritures[joueur.UserId] or self.departs[joueur.UserId] do
		self.attendre(0.5)
	end
```

Dans `src/server/Commande.luau`, remplacer :

```lua
function Commande:depart(joueur)
	self:enregistrer(joueur, true, Commande.ESSAIS_ECRITURE)
	self:retirer(joueur)
end
```

par :

```lua
function Commande:depart(joueur)
	local id = joueur.UserId
	self.departs[id] = true -- un retour rapide sur ce serveur attend la fin du départ
	pcall(self.enregistrer, self, joueur, true, Commande.ESSAIS_ECRITURE)
	self:retirer(joueur)
	self.departs[id] = nil
end
```

Dans `src/server/Commande.luau`, remplacer :

```lua
		return refus("Action impossible.")
	end
	if reponse.ok then
```

par :

```lua
		-- L'action a pu être faite avant l'erreur : refus passager, et le client redemandera l'état
		return { ok = false, erreur = "Action impossible.", passager = true, resynchroniser = true }
	end
	if reponse.ok then
```

- [ ] **Step 5: L'écran d'achat suit l'état**

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	return fermerApercu
```

par :

```lua
	-- L'état peut changer sans achat (réparé par le serveur) : les lignes suivent
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			majLigne(idTissu)
		end
	end)
	return function()
		desabonner()
		fermerApercu()
	end
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105059 vérifications
TOUT EST VERT : 384 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/client/Atelier/Session.luau src/server/Commande.luau src/client/Atelier/EcranAchat.luau tests/unitaires/29_session_distante.luau tests/unitaires/38_reponses_serveur.luau tests/unitaires/39_session_resynchro.luau tests/unitaires/40_sauvegarde_serie.luau tests/scenario.luau
git commit -m "Réponse perdue : vérifier l'état avant de refaire, erreur du serveur rattrapée, départ attendu au retour

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Pièce ratée réessayée, boutique en panne nettoyée

**Files:**
- Modify: `src/client/Atelier/Scene.luau`
- Modify: `src/server/Boutiques.luau`
- Modify: `tests/unitaires/20_scene.luau`, `tests/unitaires/34_boutiques.luau`

**Interfaces:**
- Consumes: `Scene:synchroniser(etat, derniere)`, `Boutiques:attribuer(joueur)` (plans 4c et 4d-1).
- Produces: `Scene.ESSAI_PIECE = 3`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/20_scene.luau`, remplacer :

```lua
scene2:synchroniser(etat2)
U.verifier(scene2.robe:FindFirstChild("Piece_" .. PIECES[1] .. "_unique") ~= nil, "mémoire libérée : la pièce ratée est construite à la synchronisation suivante")
```

par :

```lua
M.avancer(Scene.ESSAI_PIECE + 0.1) -- aucune action du joueur entre-temps (décorations, photo)
U.verifier(scene2.robe:FindFirstChild("Piece_" .. PIECES[1] .. "_unique") ~= nil, "mémoire libérée : la pièce ratée est reconstruite peu après, sans attendre une action")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
U.verifier(rue:attribuer(joueurNumero("Suivante", 751)) == 4, "l'emplacement resté libre sert au joueur suivant")
monde:Destroy()
```

par :

```lua
local suivante = joueurNumero("Suivante", 751)
U.verifier(rue:attribuer(suivante) == 4, "l'emplacement resté libre sert au joueur suivant")
-- Panne en posant la vitrine, la boutique déjà dans la rue : elle est retirée, l'emplacement reste libre
rue:liberer(suivante)
local vitrineVraie = Boutique.VITRINE
Boutique.VITRINE = nil
local malchanceuse = joueurNumero("Malchanceuse", 752)
local sansErreur2, indice2 = pcall(rue.attribuer, rue, malchanceuse)
Boutique.VITRINE = vitrineVraie
U.verifier(sansErreur2 and indice2 == nil and malchanceuse:GetAttribute("Boutique") == 0, "panne en posant la vitrine : pas de boutique, sans erreur")
U.verifier(monde.Rue:FindFirstChild("Boutique_4") == nil and monde.Vitrines:FindFirstChild("Vitrine_4") == nil, "panne après la pose de la boutique : rien de laissé dans la rue")
U.verifier(rue:attribuer(joueurNumero("Suivante2", 753)) == 4, "l'emplacement sert au joueur suivant")
monde:Destroy()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `attempt to perform arithmetic (add) on nil and number` (`Scene.ESSAI_PIECE` n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
Scene.PERIODE_AVATARS = 0.2 -- secondes entre deux regards sur les visiteurs, pendant la caméra du poste
```

par :

```lua
Scene.PERIODE_AVATARS = 0.2 -- secondes entre deux regards sur les visiteurs, pendant la caméra du poste
Scene.ESSAI_PIECE = 3 -- secondes : une pièce ratée faute de mémoire est réessayée, sans attendre une action
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:synchroniser(etat, derniere)
	self:suivreCliente(etat, derniere)
```

par :

```lua
function Scene:synchroniser(etat, derniere)
	self.etatSuivi, self.derniereSuivie = etat, derniere -- pour réessayer une pièce ratée
	self:suivreCliente(etat, derniere)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
			-- Pièce ratée : oubliée, pour être reconstruite à la prochaine synchronisation
			if ratee and self.pieces[p.id] == entree then
				for _, part in ipairs(entree.parts) do
					part:Destroy()
				end
				self.pieces[p.id] = nil
			end
```

par :

```lua
			-- Pièce ratée : oubliée, et réessayée quelques secondes plus tard (une synchronisation en attente à
			-- la fois ; entre-temps, une action du joueur la réessaie aussi)
			if ratee and self.pieces[p.id] == entree then
				for _, part in ipairs(entree.parts) do
					part:Destroy()
				end
				self.pieces[p.id] = nil
				if not self.reessai then
					self.reessai = true
					task.delay(Scene.ESSAI_PIECE, function()
						self.reessai = false
						if self.dossier.Parent then
							self:synchroniser(self.etatSuivi, self.derniereSuivie)
						end
					end)
				end
			end
```

Dans `src/server/Boutiques.luau`, remplacer :

```lua
			if not ok then
				warn(("[Atelier] %s : boutique %d impossible à construire : %s"):format(joueur.Name, indice, tostring(b)))
				joueur:SetAttribute("Boutique", 0)
				return nil
			end
```

par :

```lua
			if not ok then
				warn(("[Atelier] %s : boutique %d impossible à construire : %s"):format(joueur.Name, indice, tostring(b)))
				-- Ce qui a pu être posé avant la panne est retiré : l'emplacement reste propre et libre
				for _, reste in ipairs({ { self.rue, "Boutique_" }, { self.vitrines, "Vitrine_" } }) do
					local objet = reste[1]:FindFirstChild(reste[2] .. indice)
					if objet then
						objet:Destroy()
					end
				end
				joueur:SetAttribute("Boutique", 0)
				return nil
			end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105062 vérifications
TOUT EST VERT : 384 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Scene.luau src/server/Boutiques.luau tests/unitaires/20_scene.luau tests/unitaires/34_boutiques.luau
git commit -m "Pièce ratée réessayée sans attendre une action ; boutique en panne : rien de laissé dans la rue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 4d-2 terminé ; la suite est le plan 4d-3.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan4d2Depot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Appuyer sur E (`user_keyboard_input`). Lire le titre de la fenêtre et `Contenu.Metrage.Text` (côté client, `execute_luau`).
2. Cliquer `Contenu.Gauche.Pieces.ToutEnUnTissu`, puis `Contenu.ChoixTissu.Grille.Tissu_coton_blanc`. Relire `Contenu.Metrage.Text`.
3. Relever les alertes (`get_console_output`).

Expected :
- titre « 1. Carnet de croquis » ;
- d'abord « Choisis les tissus : le métrage et le coût s'affichent ici. » ;
- puis « Tissu à acheter : N dm, M po (tu as 150 po). » avec N > 0 ;
- aucune alerte hors « Lieu non publié : les parties ne sont pas sauvegardées. ».

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

Ces vérifications demandent l'interface de Studio :
- la découpe à la souris : molette sur la pièce, A et D, ligne du tissu entamé ;
- l'aperçu du rouleau à l'achat ;
- l'émulation téléphone : découpe au doigt et boutons de rotation.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (plan 4d-1)
```

par :

```markdown
## État actuel (plan 4d-2)
```

Dans `README.md`, remplacer :

```markdown
1. **Commande** : la clochette fait entrer la cliente en personne (un avatar construit en code, taille S, M ou L)
```

par :

```markdown
1. **Commande** : la clochette (ou E) fait entrer la cliente en personne (un avatar construit en code, taille S, M ou L)
```

Dans `README.md`, remplacer :

```markdown
   Les jauges de style et l'état des exigences se mettent à jour en direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent sur le rouleau.
   Droit-fil aimanté, pièces pliées coupées en double au pli, chevauchements refusés, place proposée.
```

par :

```markdown
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre ; toucher l'échantillon d'un tissu
   montre le rouleau conseillé, avec les pièces rangées dessus.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent (boutons, R, molette
   sur la pièce) sur le rouleau, qu'on déroule en le faisant défiler (ou avec A et D). Droit-fil aimanté,
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée ; une ligne marque le tissu
   entamé (couper consomme le rouleau jusqu'au bas de la pièce la plus basse).
```

Dans `README.md`, remplacer :

```markdown
9. La suite : écarts à la spec §4, sons, réglages mobiles, équilibrage, mobilier (plan 4d-2).
```

par :

```markdown
9. La suite : sons, réglages mobiles, équilibrage, mobilier (plan 4d-3).
```

Dans `README.md`, remplacer :

```markdown
rien : une pièce cousue reste finie, on la rend de nouveau. Une réponse perdue est rattrapée : le client
redemande l'état au serveur, et chaque refus des règles emporte l'état du serveur, qui répare la copie du
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.
```

par :

```markdown
rien : une pièce cousue reste finie, on la rend de nouveau. Une réponse perdue (ou une erreur du serveur) est
rattrapée : le client redemande l'état au serveur, et les actions attendent le temps de cette vérification
(rien n'est fait deux fois). Chaque refus des règles emporte l'état du serveur, qui répare la copie du
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105062 vérifications
TOUT EST VERT : 384 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4d-2 terminé : commandes et affichages du §4, gênes restantes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
