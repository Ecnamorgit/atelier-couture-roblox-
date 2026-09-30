# Aiguille & Dentelle — Plan 12 : paroles, avis, réputation, confettis

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rapprocher de *Dressmaker* la façon dont les clientes parlent et jugent : leurs paroles dans un encadré à leur prénom tant que la fenêtre de l'atelier est ouverte, un avis de 1 à 5 étoiles à la livraison, un titre de réputation sur la jauge de prestige, un rang de couturière, et des confettis quand la robe est terminée.

**Architecture:** `Progression` gagne trois fonctions pures (`etoiles`, `titreReputation`, `rang` et `texteRang`) ; un module client `Dialogue` tient l'encadré (prénom, texte, étoiles) ; `Scene:parler` envoie chaque nouvelle parole à la bulle et à l'encadré (`scene.surParole`), la bulle ne se voyant plus que fenêtre fermée ; l'accueil, le carnet d'adresses et la vente montrent étoiles, réputation et rang ; un module client `Confettis` fait pleuvoir des rectangles de couleur dans l'interface quand la dernière pièce est cousue. Aucune règle ne change.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` (sections 3, 4 — confettis — et 5 ; plan 12 de la section 6).

## Décisions de ce plan

- **Encadré de dialogue** : en haut à gauche de l'écran, juste sous les boutons de Roblox (comme le dit la spec), 360 px à l'échelle de la fenêtre ; un appui le referme jusqu'à la prochaine parole (la scène se resynchronise à chaque réponse du serveur : la même parole ne le rouvre pas) ; il se vide quand la cliente s'en va (la même durée que sa bulle, `Scene.DUREE_ADIEU`). La bulle ne se voit plus que fenêtre fermée, et jamais sur la photo.
- **Étoiles** : des glyphes ★ et ☆ (vérifiés dans Studio, lisibles à 26 px) ; dans l'encadré (merci, déception) et dans l'annonce de l'accueil (« Colette est ravie ! ★★★★☆ +45 pièces d'or… »). Le palier de 80 % est celui du point d'amitié de plus (`Progression.QUALITE_BONUS`) : quatre étoiles, c'est exactement une robe qui vaut un point d'amitié de plus.
- **Réputation** : « Réputation : Appréciée (prestige 3) — 62 / 100 » ; le libellé s'élargit à 600 px (le plus long, au niveau 8, en fait environ 520).
- **Rang** : selon les robes livrées ou vendues (`livraisons + ventes`) ; une robe offerte ne compte pas (elle n'est ni livrée ni vendue). En tête du carnet d'adresses, à la vente (« Ton rang : … »), et annoncé quand il monte.
- **Confettis** : dans l'interface, pas en particules dans la scène : à la dernière pièce, la fenêtre de couture est encore centrée devant le mannequin. 60 rectangles, 2,5 s, par-dessus la fenêtre et l'encadré. Son : « It's All A Big Joke - Tag2 » d'APM Music (bibliothèque libre de Roblox, 3 s).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; douze variantes du brouillon (palier de 75 %, titres décalés, rang atteint un cran trop tard, bulle toujours visible, encadré rouvert par la même parole, encadré jamais vidé, appui qui ne referme pas, refus sans étoile, annonce sans étoiles, rang jamais annoncé, confettis à chaque pièce, confettis qui restent) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `paroles-avis`, créée depuis `main` (où le plan 11 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker* ; titres, rangs et textes sont les nôtres.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Fenêtre ouverte, puis fermée, pendant qu'elle parle.** Attendu : l'encadré fenêtre ouverte, la bulle fenêtre fermée, jamais les deux. Test : scénario (« fenêtre fermée : sa bulle, pas d'encadré »).
- **Encadré refermé, puis une réponse du serveur sans nouvelle parole.** Attendu : il reste refermé. Test : scénario (« l'encadré reste refermé »).
- **Robe refusée, retouchée, puis acceptée.** Attendu : une étoile au refus, puis l'avis de la qualité. Tests : scénario (« une étoile », « avec son avis »).
- **Couture en plusieurs pièces.** Attendu : des confettis à la dernière pièce seulement, puis plus rien. Test : scénario (« pas encore de confettis », « puis ils disparaissent »).
- **Qualité juste sous 80 % à l'arrondi.** Attendu : quatre étoiles, comme le point d'amitié. Test : `57_reputation` (« à l'arrondi près »).

---

### Task 1: Étoiles, réputation, rang (`Progression`)

**Files:**
- Modify: `src/shared/Progression.luau`
- Create: `tests/unitaires/57_reputation.luau`

**Interfaces:**
- Consumes: `Progression.QUALITE_BONUS`, `Progression.SEUILS_PRESTIGE`, `Progression.niveauPrestige`, `Progression.gainAmitie` (existants).
- Produces: `Progression.PALIERS_ETOILES` ; `Progression.etoiles(reussie, qualite) -> 1..5` ; `Progression.TITRES_REPUTATION` ; `Progression.titreReputation(niveauPrestige) -> string` ; `Progression.RANGS` (`{ robes, nom }`) ; `Progression.rang(robes) -> rang, suivant?` ; `Progression.texteRang(robes) -> string`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/57_reputation.luau` :

```lua
-- Sous-projet 5 : l'avis de la cliente en étoiles, les titres de la réputation, le rang de la couturière. Ce n'est
-- qu'une autre façon de montrer ce que les règles disaient déjà (aucun gain n'en dépend).
local Progression = U.module("Progression")

-- Étoiles : refusée, une ; acceptée, deux, et une de plus à 60, 80 et 90 % de qualité
U.verifier(Progression.etoiles(false, 1) == 1, "robe refusée : une étoile, même parfaite")
U.verifier(Progression.etoiles(true, 0) == 2 and Progression.etoiles(true, 0.59) == 2, "robe acceptée : deux étoiles au moins")
U.verifier(Progression.etoiles(true, 0.6) == 3 and Progression.etoiles(true, 0.79) == 3, "60 % : trois étoiles")
U.verifier(Progression.etoiles(true, 0.8) == 4 and Progression.etoiles(true, 0.89) == 4, "80 % : quatre étoiles")
U.verifier(Progression.etoiles(true, 0.9) == 5 and Progression.etoiles(true, 1) == 5, "90 % : cinq étoiles")
U.verifier(Progression.etoiles(true, 0.8 - 1e-12) == 4, "à l'arrondi près, comme le point d'amitié de 80 %")
do -- Les étoiles suivent l'amitié : quatre étoiles ou plus, c'est le point d'amitié de plus
	local accordes = 0
	for q = 0, 100 do
		local qualite = q / 100
		if (Progression.etoiles(true, qualite) >= 4) == (Progression.gainAmitie(true, qualite) == 3) then
			accordes += 1
		end
	end
	U.verifier(accordes == 101, "quatre étoiles et plus : exactement quand la robe vaut un point d'amitié de plus")
end

-- Réputation : un titre par niveau de prestige (1 à 8), tous différents
U.verifier(#Progression.TITRES_REPUTATION == #Progression.SEUILS_PRESTIGE, "un titre par niveau de prestige")
U.verifier(Progression.titreReputation(1) == "Inconnue" and Progression.titreReputation(3) == "Appréciée" and Progression.titreReputation(8) == "Légendaire", "Inconnue au début, Légendaire au plus haut")
do
	local vus, doubles = {}, 0
	for _, t in ipairs(Progression.TITRES_REPUTATION) do
		doubles += if vus[t] then 1 else 0
		vus[t] = true
	end
	U.verifier(doubles == 0, "des titres tous différents")
end
U.verifier(Progression.titreReputation(Progression.niveauPrestige(Progression.SEUILS_PRESTIGE[5])) == Progression.TITRES_REPUTATION[5], "le titre suit le niveau de prestige")

-- Rang : selon les robes livrées ou vendues, le rang et le suivant
local rang, suivant = Progression.rang(0)
U.verifier(rang.nom == "Débutante" and suivant.nom == "Apprentie" and suivant.robes == 5, "aucune robe : débutante ; apprentie à 5 robes")
rang = Progression.rang(4)
U.verifier(rang.nom == "Débutante", "4 robes : encore débutante")
rang, suivant = Progression.rang(5)
U.verifier(rang.nom == "Apprentie" and suivant.nom == "Couturière" and suivant.robes == 15, "5 robes : apprentie ; couturière à 15")
rang = Progression.rang(30)
U.verifier(rang.nom == "Première main", "30 robes : première main")
rang, suivant = Progression.rang(500)
U.verifier(rang.nom == "Maîtresse couturière" and suivant == nil, "60 robes et plus : maîtresse couturière, au plus haut")
U.verifier(Progression.texteRang(7) == "Apprentie — 7 robes (Couturière à 15)", "le rang en clair : son nom, les robes, le suivant")
U.verifier(Progression.texteRang(1) == "Débutante — 1 robe (Apprentie à 5)", "une robe : au singulier")
U.verifier(Progression.texteRang(64) == "Maîtresse couturière — 64 robes", "au plus haut : pas de rang suivant")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Progression.luau`, remplacer :

```lua
	return if score >= 80 then 4 elseif score >= 60 then 3 elseif score >= 30 then 2 else 1
end

return Progression
```

par :

```lua
	return if score >= 80 then 4 elseif score >= 60 then 3 elseif score >= 30 then 2 else 1
end

-- Sous-projet 5 : l'avis de la cliente en étoiles, les titres de la réputation, le rang de la couturière. Aucune
-- règle n'en dépend : c'est ce que la livraison disait déjà, montré comme dans les jeux de couture.
-- Étoiles (1 à 5) : robe refusée, une ; acceptée, deux, et une de plus à chaque palier de qualité (80 % est aussi
-- le palier du point d'amitié de plus)
Progression.PALIERS_ETOILES = { 0.6, Progression.QUALITE_BONUS, 0.9 }
function Progression.etoiles(reussie, qualite)
	if not reussie then
		return 1
	end
	local n = 2
	for _, palier in ipairs(Progression.PALIERS_ETOILES) do
		if qualite >= palier - 1e-9 then -- (à l'arrondi près)
			n += 1
		end
	end
	return n
end

-- Titres de la réputation, un par niveau de prestige (1 à 8)
Progression.TITRES_REPUTATION = { "Inconnue", "Remarquée", "Appréciée", "Renommée", "Réputée", "Célèbre", "Illustre", "Légendaire" }
function Progression.titreReputation(niveauPrestige)
	return Progression.TITRES_REPUTATION[math.clamp(niveauPrestige, 1, #Progression.TITRES_REPUTATION)]
end

-- Rang de la couturière selon ses robes livrées ou vendues : le rang atteint, et le suivant (nil au plus haut)
Progression.RANGS = {
	{ robes = 0, nom = "Débutante" },
	{ robes = 5, nom = "Apprentie" },
	{ robes = 15, nom = "Couturière" },
	{ robes = 30, nom = "Première main" },
	{ robes = 60, nom = "Maîtresse couturière" },
}
function Progression.rang(robes)
	local atteint, suivant = Progression.RANGS[1], Progression.RANGS[2]
	for i, r in ipairs(Progression.RANGS) do
		if robes >= r.robes then
			atteint, suivant = r, Progression.RANGS[i + 1]
		end
	end
	return atteint, suivant
end

-- « Apprentie — 7 robes (Couturière à 15) » ; au plus haut, sans le rang suivant
function Progression.texteRang(robes)
	local rang, suivant = Progression.rang(robes)
	local texte = ("%s — %d robe%s"):format(rang.nom, robes, if robes > 1 then "s" else "")
	return if suivant then ("%s (%s à %d)"):format(texte, suivant.nom, suivant.robes) else texte
end

return Progression
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167751 vérifications
TOUT EST VERT : 792 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Progression.luau tests/unitaires/57_reputation.luau
git commit -m "Progression : l'avis en étoiles, les titres de la réputation, le rang de la couturière

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'encadré de dialogue (`Dialogue`, `Scene:parler`)

**Files:**
- Create: `src/client/Atelier/Dialogue.luau`, `tests/unitaires/58_dialogue.luau`
- Modify: `src/client/Atelier/Scene.luau`, `src/client/Atelier/init.client.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Progression.etoiles` (tâche 1) ; `Cliente.dire`, `UiKit.lignes` (existants).
- Produces: `Dialogue.nouveau(parent, UiKit)`, `dialogue:dire(nom, texte, etoiles?)`, `dialogue:montrer(actif)`, `dialogue:echelle(e)`, `Dialogue.OR` ; dans le ScreenGui `Atelier` : `Dialogue` (TextButton) et ses `Nom`, `Texte`, `Etoiles` (`Etoile1` à `Etoile5`) ; `Scene:parler(modele, texte, etoiles?)`, `Scene:taire()`, `Scene:majBulle(modele)`, le rappel `scene.surParole(nom, texte, etoiles)`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/58_dialogue.luau` :

```lua
-- Sous-projet 5 : l'encadré de dialogue. Tant que la fenêtre de l'atelier est ouverte, ce que dit la cliente se lit
-- dans un encadré à son nom (en haut à gauche, sous les boutons de Roblox), avec son avis en étoiles quand elle en
-- donne un ; un appui le referme jusqu'à sa prochaine parole.
local UiKit = U.module("UiKit")
local Dialogue = U.module("Dialogue")

local gui = Instance.new("ScreenGui")
local d = Dialogue.nouveau(gui, UiKit)
local cadre = gui:FindFirstChild("Dialogue")
U.verifier(cadre ~= nil and cadre:IsA("TextButton") and not cadre.Visible, "un encadré (un bouton : l'appui ne passe pas dessous), caché tant qu'elle n'a rien dit")
U.verifier(cadre.Position.X.Scale == 0 and cadre.Position.Y.Scale == 0 and cadre.Position.Y.Offset < 40, "en haut à gauche, juste sous les boutons de Roblox")

d:dire("Colette", "Bonjour ! J'aurais besoin d'une robe.")
U.verifier(cadre.Visible and cadre.Nom.Text == "Colette" and cadre.Texte.Text == "Bonjour ! J'aurais besoin d'une robe." and not cadre.Etoiles.Visible, "son nom, ses mots ; pas d'étoiles sans avis")
U.verifier(cadre.Nom.TextSize >= 14 and cadre.Texte.TextSize >= 14, "textes d'au moins 14 px")
local hauteurCourte = cadre.Size.Y.Offset
d:dire("Colette", string.rep("Une robe pour le bal des lanternes, avec des manches ballon et un col Claudine. ", 3))
U.verifier(cadre.Size.Y.Offset > hauteurCourte + 30 and cadre.Texte.Size.Y.Offset >= 3 * 16, "un long texte : l'encadré grandit (" .. cadre.Size.Y.Offset .. " px)")

-- L'avis : autant d'étoiles dorées que d'étoiles données, les autres éteintes
local function doree(k)
	return cadre.Etoiles["Etoile" .. k].TextColor3 == Dialogue.OR
end
d:dire("Colette", "Merci, elle est parfaite !", 4)
U.verifier(cadre.Etoiles.Visible and doree(1) and doree(4) and not doree(5), "quatre étoiles sur cinq")
U.verifier(cadre.Etoiles.Position.Y.Offset >= cadre.Texte.Position.Y.Offset + cadre.Texte.Size.Y.Offset and cadre.Etoiles.Position.Y.Offset + cadre.Etoiles.Size.Y.Offset <= cadre.Size.Y.Offset, "les étoiles sous le texte, dans l'encadré")
d:dire("Colette", "Ce n'est pas tout à fait ce que je voulais.", 1)
U.verifier(doree(1) and not doree(2), "une étoile au refus")

-- Fenêtre fermée : l'encadré se cache (la bulle prend le relais) ; rouverte : il revient
d:montrer(false)
U.verifier(not cadre.Visible, "fenêtre fermée : pas d'encadré")
d:dire("Colette", "Me revoilà !")
U.verifier(not cadre.Visible, "fenêtre fermée : même quand elle parle")
d:montrer(true)
U.verifier(cadre.Visible and cadre.Texte.Text == "Me revoilà !", "fenêtre rouverte : l'encadré revient, avec sa dernière parole")

-- Un appui le referme, jusqu'à sa prochaine parole
cadre.Activated:Fire()
U.verifier(not cadre.Visible, "un appui referme l'encadré")
d:montrer(false)
d:montrer(true)
U.verifier(not cadre.Visible, "refermé : il ne revient pas en rouvrant la fenêtre")
d:dire("Colette", "Voyons voir…")
U.verifier(cadre.Visible and cadre.Texte.Text == "Voyons voir…", "une nouvelle parole le rouvre")
d:dire(nil)
U.verifier(not cadre.Visible, "plus rien à dire : l'encadré se cache")

-- La même échelle que la fenêtre (petits écrans)
d:echelle(0.6)
U.verifier(cadre:FindFirstChild("UIScale").Scale == 0.6, "l'encadré se réduit comme la fenêtre")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(clienteMesuree.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.presentation, "elle se présente")
cliquer("ValiderMesures")
verifier(titre() == "Les mesures" and fenetre.Message.Visible and fenetre.Message.Text == "Mesure invalide : règle chaque ruban au bord de la silhouette.", "rubans pas réglés : mesures refusées, message")
```

par :

```lua
verifier(clienteMesuree.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.presentation, "elle se présente")
do -- Sous-projet 5 : fenêtre ouverte, elle parle dans l'encadré de dialogue, à son nom ; sa bulle est pour la rue
	local dialogue = gui.Atelier:FindFirstChild("Dialogue")
	verifier(dialogue ~= nil and dialogue.Visible and dialogue.Nom.Text == "Colette" and dialogue.Texte.Text == Clientes.get("colette").repliques.presentation and not clienteMesuree.Head.Bulle.Enabled, "fenêtre ouverte : elle se présente dans l'encadré, à son nom, pas dans sa bulle")
	cliquer("Fermer")
	verifier(not dialogue.Visible and clienteMesuree.Head.Bulle.Enabled, "fenêtre fermée : sa bulle, pas d'encadré")
	cliquer("OuvrirAtelier")
	verifier(dialogue.Visible and not clienteMesuree.Head.Bulle.Enabled, "fenêtre rouverte : de nouveau l'encadré")
	dialogue.Activated:Fire()
	verifier(not dialogue.Visible, "un appui referme l'encadré")
end
serveur:atelier(joueur).etat.argent += 1 -- (la réponse au refus emporte un état changé : la scène se resynchronise)
cliquer("ValiderMesures")
serveur:atelier(joueur).etat.argent -= 1
verifier(titre() == "Les mesures" and fenetre.Message.Visible and fenetre.Message.Text == "Mesure invalide : règle chaque ruban au bord de la silhouette.", "rubans pas réglés : mesures refusées, message")
verifier(not gui.Atelier.Dialogue.Visible, "la même parole, après une réponse du serveur : l'encadré reste refermé")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(clienteMesuree.Head.Bulle.Texte.Text == requireModule(scriptClient.Scene).PAROLES.carnet, "première visite, au carnet : elle explique ce qu'elle veut (pas « Me revoilà ! »)")
```

par :

```lua
verifier(clienteMesuree.Head.Bulle.Texte.Text == requireModule(scriptClient.Scene).PAROLES.carnet, "première visite, au carnet : elle explique ce qu'elle veut (pas « Me revoilà ! »)")
verifier(gui.Atelier.Dialogue.Visible and gui.Atelier.Dialogue.Texte.Text == requireModule(scriptClient.Scene).PAROLES.carnet, "une nouvelle parole rouvre l'encadré")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
```

par :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
do -- Son avis : une étoile
	local etoiles = gui.Atelier.Dialogue.Etoiles
	local OR = requireModule(scriptClient.Dialogue).OR
	verifier(gui.Atelier.Dialogue.Visible and gui.Atelier.Dialogue.Texte.Text == Clientes.get("colette").repliques.deception and etoiles.Visible and etoiles.Etoile1.TextColor3 == OR and etoiles.Etoile2.TextColor3 ~= OR, "robe refusée : sa déception dans l'encadré, une étoile")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and laCliente.Head.Bulle.Enabled and camera.FieldOfView == 70, "après la photo : interface, vue, champ et bulle rétablis")
```

par :

```lua
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and not laCliente.Head.Bulle.Enabled and camera.FieldOfView == 70, "après la photo : interface, vue et champ rétablis ; la bulle reste cachée (fenêtre ouverte : l'encadré parle)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.merci, "Colette remercie")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil, "puis elle s'en va")
```

par :

```lua
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.merci, "Colette remercie")
do -- Son avis en étoiles, dans l'encadré : celles de la qualité de la robe
	local dialogue = gui.Atelier.Dialogue
	local qualite = requireModule(scriptClient.Session).courante.derniere.reponse.bilan.qualite
	local n = requireModule(dossier.Progression).etoiles(true, qualite)
	local OR, dorees = requireModule(scriptClient.Dialogue).OR, 0
	for k = 1, 5 do
		dorees += if dialogue.Etoiles["Etoile" .. k].TextColor3 == OR then 1 else 0
	end
	verifier(dialogue.Visible and dialogue.Texte.Text == Clientes.get("colette").repliques.merci and dialogue.Etoiles.Visible and dorees == n and n >= 2, ("Colette remercie dans l'encadré, avec son avis : %d étoiles (qualité %d %%)"):format(dorees, math.floor(qualite * 100 + 0.5)))
end
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil and not gui.Atelier.Dialogue.Visible, "puis elle s'en va, et l'encadré se vide")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Dialogue n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

Créer `src/client/Atelier/Dialogue.luau` :

```lua
-- Dialogue (sous-projet 5) : l'encadré où se lit ce que dit la cliente tant que la fenêtre de l'atelier est ouverte
-- (sa bulle, au-dessus de sa tête, reste pour la rue). En haut à gauche de l'écran, juste sous les boutons de
-- Roblox : son prénom, ses mots, et son avis en étoiles quand elle en donne un. Un appui le referme jusqu'à sa
-- prochaine parole.
local Dialogue = {}
Dialogue.__index = Dialogue

Dialogue.LARGEUR = 360
Dialogue.TAILLE_TEXTE = 16
Dialogue.OR = Color3.fromRGB(232, 176, 46)
Dialogue.ETEINTE = Color3.fromRGB(222, 208, 212)
local MARGE = 14
local HAUT_TEXTE = 30 -- sous le prénom
local HAUTEUR_ETOILES = 28

function Dialogue.nouveau(parent, UiKit)
	local C = UiKit.COULEURS
	local self = setmetatable({ UiKit = UiKit, montre = true, parole = nil, referme = false }, Dialogue)
	-- Un bouton sans texte, pas un cadre : dans Roblox, un cadre laisse passer l'appui aux boutons dessous
	self.cadre = UiKit.arrondir(UiKit.creer("TextButton", {
		Name = "Dialogue",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 252, 247),
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(Dialogue.LARGEUR, 80),
		Visible = false,
		ZIndex = 40,
		Parent = parent,
	}), 12)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, Parent = self.cadre })
	self.mise = UiKit.creer("UIScale", { Parent = self.cadre })
	self.nom = UiKit.texte({ Name = "Nom", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.accent, Position = UDim2.fromOffset(MARGE, 8), Size = UDim2.new(1, -2 * MARGE, 0, 20), ZIndex = 41, Parent = self.cadre })
	self.texte = UiKit.texte({ Name = "Texte", TextSize = Dialogue.TAILLE_TEXTE, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(MARGE, HAUT_TEXTE), Size = UDim2.new(1, -2 * MARGE, 0, 20), ZIndex = 41, Parent = self.cadre })
	self.etoiles = UiKit.creer("Frame", { Name = "Etoiles", BackgroundTransparency = 1, Size = UDim2.fromOffset(5 * 28, HAUTEUR_ETOILES), Visible = false, ZIndex = 41, Parent = self.cadre })
	for k = 1, 5 do
		UiKit.texte({ Name = "Etoile" .. k, Text = "★", TextSize = 26, TextColor3 = Dialogue.ETEINTE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset((k - 1) * 28, 0), Size = UDim2.fromOffset(26, HAUTEUR_ETOILES), ZIndex = 41, Parent = self.etoiles })
	end
	self.cadre.Activated:Connect(function()
		self.referme = true
		self:maj()
	end)
	return self
end

-- La cliente dit ce texte (nil : plus rien à dire) ; etoiles : son avis (1 à 5), ou nil
function Dialogue:dire(nom, texte, etoiles)
	self.parole, self.referme = texte, false
	if texte then
		local hauteurTexte = self.UiKit.lignes(texte, Dialogue.LARGEUR - 2 * MARGE, Dialogue.TAILLE_TEXTE) * (Dialogue.TAILLE_TEXTE + 4)
		self.nom.Text = nom or ""
		self.texte.Text = texte
		self.texte.Size = UDim2.new(1, -2 * MARGE, 0, hauteurTexte)
		self.etoiles.Visible = etoiles ~= nil
		self.etoiles.Position = UDim2.fromOffset(MARGE - 2, HAUT_TEXTE + hauteurTexte + 2)
		for k = 1, 5 do
			self.etoiles["Etoile" .. k].TextColor3 = if etoiles and k <= etoiles then Dialogue.OR else Dialogue.ETEINTE
		end
		self.cadre.Size = UDim2.fromOffset(Dialogue.LARGEUR, HAUT_TEXTE + hauteurTexte + (if etoiles then HAUTEUR_ETOILES + 4 else 0) + 10)
	end
	self:maj()
end

-- Fenêtre de l'atelier ouverte (actif) : l'encadré se voit, s'il a quelque chose à dire et n'a pas été refermé
function Dialogue:montrer(actif)
	self.montre = actif
	self:maj()
end

-- Même échelle que la fenêtre (petits écrans)
function Dialogue:echelle(e)
	self.mise.Scale = e
end

function Dialogue:maj()
	self.cadre.Visible = self.montre and self.parole ~= nil and not self.referme
end

return Dialogue
```

- [ ] **Step 4: La scène et le script du client**

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
local Histoire = require(Couture:WaitForChild("Histoire"))
local Lighting
```

par :

```lua
local Histoire = require(Couture:WaitForChild("Histoire"))
local Progression = require(Couture:WaitForChild("Progression"))
local Lighting
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
	if commande then
		Cliente.dire(self.cliente, replique(etat))
	elseif self.cliente then
```

par :

```lua
	if commande then
		self:parler(self.cliente, replique(etat), if etat.etape == "refus" then Progression.etoiles(false, 0) else nil)
	elseif self.cliente then
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
		Cliente.dire(self.cliente, reussie and merci or Scene.PAROLES.abandon)
		local partante = self.cliente
		self.partante, self.cliente, self.clienteCommande = partante, nil, nil
		task.delay(Scene.DUREE_ADIEU, function()
			partante:Destroy()
			if self.partante == partante then
				self.partante = nil
			end
		end)
```

par :

```lua
		local avis = if reussie then Progression.etoiles(true, derniere.reponse.bilan.qualite) else nil
		self:parler(self.cliente, reussie and merci or Scene.PAROLES.abandon, avis)
		local partante = self.cliente
		self.partante, self.cliente, self.clienteCommande = partante, nil, nil
		task.delay(Scene.DUREE_ADIEU, function()
			partante:Destroy()
			if self.partante == partante then
				self.partante = nil
				if not self.cliente then
					self:taire() -- elle est partie : l'encadré se vide (sauf si la suivante parle déjà)
				end
			end
		end)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
-- Photo : décor derrière le mannequin, lumière, couleur du mannequin (réglages = { decor, lumiere, mannequin })
```

par :

```lua
-- Ce que dit la cliente (modele) : sa bulle, pour la rue (cachée tant que la fenêtre de l'atelier est ouverte), et
-- l'encadré de dialogue de l'interface, surParole(prénom, texte, étoiles ou nil), prévenu quand elle dit autre chose
-- (la scène se synchronise à chaque réponse du serveur : un encadré refermé ne se rouvre pas pour la même parole)
function Scene:parler(modele, texte, etoiles)
	Cliente.dire(modele, texte)
	self:majBulle(modele)
	if texte ~= self.paroleDite or modele ~= self.parleuse then
		self.paroleDite, self.parleuse = texte, modele
		local fiche = self.clienteId and Clientes.get(self.clienteId)
		if self.surParole then
			self.surParole(if fiche then fiche.nom:match("^(%S+)") else "La cliente", texte, etoiles)
		end
	end
end

-- Plus personne ne parle : l'encadré se vide
function Scene:taire()
	self.paroleDite, self.parleuse = nil, nil
	if self.surParole then
		self.surParole(nil, nil)
	end
end

-- La bulle ne se voit que fenêtre fermée (l'encadré parle sinon), et jamais sur la photo
function Scene:majBulle(modele)
	local bulle = modele and modele:FindFirstChild("Head") and modele.Head:FindFirstChild("Bulle")
	if bulle then
		bulle.Enabled = not self.ouverte and not self.enPhoto
	end
end

-- Photo : décor derrière le mannequin, lumière, couleur du mannequin (réglages = { decor, lumiere, mannequin })
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:cadrerPhoto(actif)
	local bulle = self.cliente and self.cliente:FindFirstChild("Head") and self.cliente.Head:FindFirstChild("Bulle")
	if bulle then
		bulle.Enabled = not actif
	end
```

par :

```lua
function Scene:cadrerPhoto(actif)
	self.enPhoto = actif
	self:majBulle(self.cliente)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
```

par :

```lua
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:majBulle(self.cliente)
	self:majBulle(self.partante)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Sons = require(script:WaitForChild("Sons"))
```

par :

```lua
local Sons = require(script:WaitForChild("Sons"))
local Dialogue = require(script:WaitForChild("Dialogue"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
}), 14)

-- Mise à l'échelle sur les petits écrans (suit la caméra et la taille de la fenêtre du jeu)
local echelle = UiKit.creer("UIScale", { Parent = fenetre })
local connexionCamera
local function ajuster()
	local camera = workspace.CurrentCamera
	echelle.Scale = UiKit.echelle(camera and camera.ViewportSize or Vector2.new(1280, 720))
end
```

par :

```lua
}), 14)
-- Ce que dit la cliente, fenêtre ouverte : l'encadré de dialogue, en haut à gauche (sa bulle est pour la rue)
local dialogue = Dialogue.nouveau(gui, UiKit)
scene.surParole = function(nom, texte, etoiles)
	dialogue:dire(nom, texte, etoiles)
end

-- Mise à l'échelle sur les petits écrans (suit la caméra et la taille de la fenêtre du jeu)
local echelle = UiKit.creer("UIScale", { Parent = fenetre })
local connexionCamera
local function ajuster()
	local camera = workspace.CurrentCamera
	echelle.Scale = UiKit.echelle(camera and camera.ViewportSize or Vector2.new(1280, 720))
	dialogue:echelle(echelle.Scale)
end
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
	boutonAtelier.Visible = not fenetre.Visible
	scene:ouvrir(fenetre.Visible, session.etat)
```

par :

```lua
	boutonAtelier.Visible = not fenetre.Visible
	dialogue:montrer(fenetre.Visible)
	scene:ouvrir(fenetre.Visible, session.etat)
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167767 vérifications
TOUT EST VERT : 802 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/Dialogue.luau tests/unitaires/58_dialogue.luau src/client/Atelier/Scene.luau src/client/Atelier/init.client.luau tests/scenario.luau
git commit -m "Encadré de dialogue : la cliente parle à son prénom fenêtre ouverte, avec son avis en étoiles ; sa bulle est pour la rue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Étoiles dans l'annonce, réputation, rang

**Files:**
- Modify: `src/client/Atelier/UiKit.luau`, `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/EcranPresentation.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Progression.etoiles`, `Progression.titreReputation`, `Progression.rang`, `Progression.texteRang` (tâche 1).
- Produces: `UiKit.etoiles(n) -> "★★★★☆"` ; `fenetre.Contenu.Prestige` (réputation), `CarnetAdresses.TitreAdresses`, `fenetre.Contenu.Rang` (vente).

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
```

par :

```lua
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
do -- Sous-projet 5 : son avis en étoiles, dans l'annonce
	local qualite = requireModule(scriptClient.Session).courante.derniere.reponse.bilan.qualite
	local n = requireModule(dossier.Progression).etoiles(true, qualite)
	verifier(texte("Colette est ravie ! " .. string.rep("★", n) .. string.rep("☆", 5 - n) .. " +") ~= nil, "l'annonce donne son avis : " .. n .. " étoiles sur 5")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Contenu.Prestige.Text == ("Prestige 3 — %d / 100"):format(prestigeJoueur), "jauge de prestige : « Prestige 3 — " .. prestigeJoueur .. " / 100 »")
```

par :

```lua
verifier(fenetre.Contenu.Prestige.Text == ("Réputation : Appréciée (prestige 3) — %d / 100"):format(prestigeJoueur), "jauge de prestige : « Réputation : Appréciée (prestige 3) — " .. prestigeJoueur .. " / 100 »")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
```

par :

```lua
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
do -- Le rang de la couturière, en tête du carnet d'adresses
	local e = requireModule(scriptClient.Session).courante.etat
	verifier(fenetre.Contenu.CarnetAdresses.TitreAdresses.Text == "Carnet d'adresses — " .. requireModule(dossier.Progression).texteRang(e.livraisons + e.ventes), "carnet d'adresses : le rang de la couturière (" .. fenetre.Contenu.CarnetAdresses.TitreAdresses.Text .. ")")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Contenu:FindFirstChild("Livrer") == nil, "une robe libre ne se livre pas")
```

par :

```lua
verifier(fenetre.Contenu:FindFirstChild("Livrer") == nil, "une robe libre ne se livre pas")
do -- À la vente : le rang de la couturière
	local e = serveur:atelier(joueur).etat
	verifier(fenetre.Contenu.Rang.Text == "Ton rang : " .. requireModule(dossier.Progression).texteRang(e.livraisons + e.ventes), "à la vente : le rang (" .. fenetre.Contenu.Rang.Text .. ")")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avantVente = argent()
cliquer("Vendre")
cliquer("Vendre")
verifier(titre() == "Aiguille & Dentelle" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
```

par :

```lua
local avantVente = argent()
-- (quatorze robes déjà livrées : celle-ci est la quinzième, la couturière change de rang)
local livraisonsVraies = serveur:atelier(joueur).etat.livraisons
serveur:atelier(joueur).etat.livraisons = 14
cliquer("Vendre")
cliquer("Vendre")
verifier(titre() == "Aiguille & Dentelle" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
verifier(texte("Nouveau rang : Couturière !") ~= nil, "la quinzième robe : « Nouveau rang : Couturière ! »")
serveur:atelier(joueur).etat.livraisons = livraisonsVraies
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `étoiles sur 5`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.texte(props)
```

par :

```lua
-- L'avis d'une cliente en étoiles (1 à 5) : « ★★★★☆ »
function UiKit.etoiles(n)
	return string.rep("★", n) .. string.rep("☆", 5 - n)
end

function UiKit.texte(props)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	return ("Amitié %s : %s%d%s"):format(Deblocages.de(prenom), amitie.gain >= 0 and "+" or "", amitie.gain, niveau)
end
```

par :

```lua
	return ("Amitié %s : %s%d%s"):format(Deblocages.de(prenom), amitie.gain >= 0 and "+" or "", amitie.gain, niveau)
end

-- Le rang de la couturière vient de monter (robes livrées ou vendues) : « Nouveau rang : Couturière ! » ; sinon nil
local function nouveauRang(etat)
	local robes = etat.livraisons + etat.ventes
	local rang = Progression.rang(robes)
	return if rang ~= Progression.rang(robes - 1) then ("Nouveau rang : %s !"):format(rang.nom) else nil
end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		annonce = ("%s est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
```

par :

```lua
		annonce = ("%s est ravie ! %s +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			UiKit.etoiles(Progression.etoiles(true, r.bilan.qualite)),
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		table.insert(suite, ligneAmitie(r.amitie))
	elseif action == "vendre" then
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, math.floor(r.bilan.qualite * 100 + 0.5))
```

par :

```lua
		table.insert(suite, ligneAmitie(r.amitie))
		table.insert(suite, nouveauRang(ctx.session.etat))
	elseif action == "vendre" then
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, math.floor(r.bilan.qualite * 100 + 0.5))
		table.insert(suite, nouveauRang(ctx.session.etat))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- La jauge de prestige : « Prestige 3 — 62 / 100 »
	local niveau = Progression.niveauPrestige(etat.prestige)
	local seuil, suivant = Progression.SEUILS_PRESTIGE[niveau], Progression.SEUILS_PRESTIGE[niveau + 1]
	local y = ligne + 66
	UiKit.texte({
		Name = "Prestige",
		Text = if suivant then ("Prestige %d — %d / %d"):format(niveau, etat.prestige, suivant) else ("Prestige %d — %d (au plus haut)"):format(niveau, etat.prestige),
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(360, 22),
```

par :

```lua
	-- La jauge de prestige, et le titre de la réputation : « Réputation : Appréciée (prestige 3) — 62 / 100 »
	local niveau = Progression.niveauPrestige(etat.prestige)
	local seuil, suivant = Progression.SEUILS_PRESTIGE[niveau], Progression.SEUILS_PRESTIGE[niveau + 1]
	local y = ligne + 66
	local reputation = ("Réputation : %s (prestige %d)"):format(Progression.titreReputation(niveau), niveau)
	UiKit.texte({
		Name = "Prestige",
		Text = if suivant then ("%s — %d / %d"):format(reputation, etat.prestige, suivant) else ("%s — %d, au plus haut"):format(reputation, etat.prestige),
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(600, 22),
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		UiKit.texte({ Text = "Carnet d'adresses", Font = Enum.Font.GothamBold, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = carnet })
```

par :

```lua
		-- En tête : le rang de la couturière (robes livrées ou vendues)
		UiKit.texte({ Name = "TitreAdresses", Text = "Carnet d'adresses — " .. Progression.texteRang(etat.livraisons + etat.ventes), Font = Enum.Font.GothamBold, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = carnet })
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		UiKit.texte({ Name = "PrixVente", Text = ("Prix de vente : %d po"):format(etat:prixVente()), Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 22), Parent = contenu })
```

par :

```lua
		UiKit.texte({ Name = "PrixVente", Text = ("Prix de vente : %d po"):format(etat:prixVente()), Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 22), Parent = contenu })
		UiKit.texte({ Name = "Rang", Text = "Ton rang : " .. Progression.texteRang(etat.livraisons + etat.ventes), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167767 vérifications
TOUT EST VERT : 806 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/UiKit.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranPresentation.luau tests/scenario.luau
git commit -m "Accueil : l'avis en étoiles, le titre de la réputation ; le rang de la couturière au carnet d'adresses et à la vente

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Confettis à la robe terminée

**Files:**
- Create: `src/client/Atelier/Confettis.luau`
- Modify: `src/client/Atelier/Sons.luau`, `src/client/Atelier/init.client.luau`
- Modify: `tests/scenario.luau`, `tests/unitaires/41_sons.luau`

**Interfaces:**
- Consumes: `session:surAction`, `Sons.jouer` (existants) ; l'encadré `Dialogue` (tâche 2, pour l'ordre d'affichage).
- Produces: `Confettis.lancer(parent, graine?) -> Frame` (« Confettis », détruit après `Confettis.DUREE`) ; `Sons.IDS.fete`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(boutonNomme("PieceSuivante").Text == (k == 6 and "Finir la couture" or "Pièce suivante"), "bouton de fin de pièce " .. k)
	cliquer("PieceSuivante")
end
```

par :

```lua
	verifier(boutonNomme("PieceSuivante").Text == (k == 6 and "Finir la couture" or "Pièce suivante"), "bouton de fin de pièce " .. k)
	cliquer("PieceSuivante")
	verifier(k == 6 or gui.Atelier:FindFirstChild("Confettis") == nil, "pièce " .. k .. " cousue, la robe pas finie : pas encore de confettis")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "panneau à droite, la robe cousue sur le mannequin")
```

par :

```lua
verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "panneau à droite, la robe cousue sur le mannequin")
do -- Sous-projet 5 : la robe terminée, une pluie de confettis par-dessus la fenêtre et un petit son de fête
	local confettis = gui.Atelier:FindFirstChild("Confettis")
	verifier(confettis ~= nil and #confettis:GetChildren() >= 40 and confettis.ZIndex > gui.Atelier.Dialogue.ZIndex and table.find(M.sonsJoues, "Atelier_fete") ~= nil, "robe terminée : des confettis, un son de fête")
	local premier = confettis:GetChildren()[1]
	local hauteurAvant = premier.Position.Y.Scale
	M.avancer(0.5)
	verifier(premier.Position.Y.Scale > hauteurAvant + 0.1, "les confettis tombent")
	M.avancer(3)
	verifier(gui.Atelier:FindFirstChild("Confettis") == nil, "puis ils disparaissent")
end
```

Dans `tests/unitaires/41_sons.luau`, remplacer :

```lua
local Sons = U.module("Sons")
```

par :

```lua
local Sons = U.module("Sons")
U.verifier(Sons.IDS.fete ~= nil, "un son de fête (la robe terminée)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : un son de fête (la robe terminée)`

- [ ] **Step 3: Écrire le module**

Créer `src/client/Atelier/Confettis.luau` :

```lua
-- Confettis (sous-projet 5) : la robe terminée (dernière pièce cousue), une pluie de confettis tombe sur l'écran,
-- puis disparaît. Des petits rectangles de couleur qui tournent en tombant, dans l'interface (pas des particules
-- dans la scène : ils se voient par-dessus la fenêtre de l'atelier, sur tous les appareils).
local RunService = game:GetService("RunService")

local Confettis = {}
Confettis.NOMBRE = 60
Confettis.DUREE = 2.5 -- secondes
Confettis.COULEURS = {
	Color3.fromRGB(236, 92, 146), -- rose
	Color3.fromRGB(246, 196, 72), -- or
	Color3.fromRGB(120, 204, 170), -- menthe
	Color3.fromRGB(118, 172, 236), -- ciel
	Color3.fromRGB(186, 146, 226), -- lilas
}

-- Lance une pluie de confettis dans parent (un ScreenGui) ; renvoie le cadre, détruit à la fin
function Confettis.lancer(parent, graine)
	local rng = Random.new(graine or math.floor(os.clock() * 1000))
	local cadre = Instance.new("Frame")
	cadre.Name = "Confettis"
	cadre.BackgroundTransparency = 1
	cadre.Size = UDim2.fromScale(1, 1)
	cadre.ZIndex = 50
	cadre.Parent = parent
	local morceaux = {}
	for k = 1, Confettis.NOMBRE do
		local m = Instance.new("Frame")
		m.Name = "Confetti" .. k
		m.BorderSizePixel = 0
		m.BackgroundColor3 = Confettis.COULEURS[rng:NextInteger(1, #Confettis.COULEURS)]
		m.AnchorPoint = Vector2.new(0.5, 0.5)
		m.Size = UDim2.fromOffset(rng:NextInteger(6, 10), rng:NextInteger(10, 16))
		m.Rotation = rng:NextNumber(0, 360)
		m.ZIndex = 51
		local c = { objet = m, x = rng:NextNumber(0.02, 0.98), y = -rng:NextNumber(0.02, 0.4), chute = rng:NextNumber(0.45, 0.75), derive = rng:NextNumber(-0.06, 0.06), tour = rng:NextNumber(-300, 300) }
		m.Position = UDim2.fromScale(c.x, c.y)
		m.Parent = cadre
		morceaux[k] = c
	end
	local ecoule, connexion = 0, nil
	connexion = RunService.RenderStepped:Connect(function(dt)
		ecoule += dt
		if ecoule >= Confettis.DUREE or not cadre.Parent then
			connexion:Disconnect()
			cadre:Destroy()
			return
		end
		for _, c in ipairs(morceaux) do
			c.y += c.chute * dt
			c.x += c.derive * dt
			c.objet.Position = UDim2.fromScale(c.x, c.y)
			c.objet.Rotation += c.tour * dt
		end
	end)
	return cadre
end

return Confettis
```

- [ ] **Step 4: Le son et le déclenchement**

Dans `src/client/Atelier/Sons.luau`, remplacer :

```lua
	reussite = 1839881844, -- APM Music : « Spinning Around (b) », 2 s enjouées
```

par :

```lua
	reussite = 1839881844, -- APM Music : « Spinning Around (b) », 2 s enjouées
	fete = 9045129322, -- APM Music : « It's All A Big Joke - Tag2 », 3 s de bois et de guitare sautillants (robe terminée)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Dialogue = require(script:WaitForChild("Dialogue"))
```

par :

```lua
local Dialogue = require(script:WaitForChild("Dialogue"))
local Confettis = require(script:WaitForChild("Confettis"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
session:surAction(function(nom, reponse)
	if nom == "livrer" then
		Sons.jouer(if reponse.reussie then "reussite" else "echec")
```

par :

```lua
session:surAction(function(nom, reponse)
	if nom == "rendreCouture" and session.etat.etape == "decorations" then
		-- La dernière pièce cousue : la robe est terminée, une pluie de confettis et un petit son de fête
		Confettis.lancer(gui)
		Sons.jouer("fete")
	elseif nom == "livrer" then
		Sons.jouer(if reponse.reussie then "reussite" else "echec")
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167769 vérifications
TOUT EST VERT : 813 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/Confettis.luau src/client/Atelier/Sons.luau src/client/Atelier/init.client.luau tests/scenario.luau tests/unitaires/41_sons.luau
git commit -m "Confettis et petit son de fête quand la dernière pièce est cousue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan12Depot.rbxl`) et l'ouvrir dans Studio. En mode édition, par `execute_luau` : dans un ScreenGui d'essai de `StarterGui`, créer un encadré (`Dialogue.nouveau`) qui dit une réplique avec quatre étoiles, et lancer des confettis (`Confettis.lancer`) en posant leurs rectangles au hasard dans l'écran ; capturer l'écran (`screen_capture`), puis détruire le ScreenGui. En Play : attendre 4 s, appuyer sur E ; capturer l'écran ; fermer la fenêtre de l'atelier (bouton « × ») et capturer de nouveau ; relever la console.

Expected : l'encadré lisible (prénom en rose, texte, quatre étoiles dorées et une éteinte), des confettis de cinq couleurs ; en Play, la cliente se présente dans l'encadré, en haut à gauche sous les boutons de Roblox, sans bulle au-dessus de sa tête ; fenêtre fermée, sa bulle et plus d'encadré ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 5 en cours, plan 11 : le carnet de croquis dessiné)
```

par :

```markdown
## État actuel (sous-projet 5 en cours, plans 11 et 12 : le carnet dessiné ; paroles, avis et réputation)
```

Dans `README.md`, remplacer :

```markdown
   parle par une bulle, avec ses propres mots (présentation, arrivée, merci, déception). En passant commande,
```

par :

```markdown
   parle avec ses propres mots (présentation, arrivée, merci, déception) : fenêtre de l'atelier ouverte, dans un
   encadré à son prénom, en haut à gauche de l'écran (un appui le referme jusqu'à sa prochaine parole) ;
   fenêtre fermée, dans une bulle au-dessus de sa tête. En passant commande,
```

Dans `README.md`, remplacer :

```markdown
   Une pièce finie n'est rendue qu'avec « Pièce suivante » : la dernière couture se défait encore.
```

par :

```markdown
   Une pièce finie n'est rendue qu'avec « Pièce suivante » : la dernière couture se défait encore. La dernière
   pièce cousue, la robe est terminée : une pluie de confettis et un petit son de fête.
```

Dans `README.md`, remplacer :

```markdown
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
```

par :

```markdown
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
   **Avis en étoiles** : refusée, une étoile ; acceptée, deux, plus une à 60, 80 et 90 % de qualité (dans
   l'encadré de la cliente et l'annonce de l'accueil) ; rien n'en dépend.
```

Dans `README.md`, remplacer :

```markdown
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné, et montre la jauge de prestige
   (« Prestige 3 — 62 / 100 »). Un abandon ne fait jamais perdre un niveau d'amitié.
```

par :

```markdown
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné, et montre la jauge de prestige avec le
   titre de la réputation (« Réputation : Appréciée (prestige 3) — 62 / 100 » ; Inconnue, Remarquée, Appréciée,
   Renommée, Réputée, Célèbre, Illustre, Légendaire). Un abandon ne fait jamais perdre un niveau d'amitié.
   **Rang** de la couturière, selon les robes livrées ou vendues : Débutante, Apprentie (5), Couturière (15),
   Première main (30), Maîtresse couturière (60) ; en tête du carnet d'adresses et à la vente, annoncé quand il
   monte (« Nouveau rang : Couturière ! »).
```

Dans `README.md`, remplacer :

```markdown
10. La suite : la fin du sous-projet 5 (paroles des clientes dans un encadré, avis en étoiles, réputation,
   confettis, gazette du quartier, affiche des nouveautés, chat de l'atelier) ; porter la robe sur son avatar et
   les défilés entre joueurs restent à décider.
```

par :

```markdown
10. La suite : la fin du sous-projet 5 (gazette du quartier, affiche des nouveautés, chat de l'atelier) ;
   porter la robe sur son avatar et les défilés entre joueurs restent à décider.
```

Dans `README.md`, remplacer :

```markdown
déclic de la photo et la réaction de la cliente. Tout vient de la bibliothèque libre de Roblox (sons de
```

par :

```markdown
déclic de la photo, la fête de la robe terminée et la réaction de la cliente. Tout vient de la bibliothèque
libre de Roblox (sons de
```

Dans `README.md`, remplacer :

```markdown
  l'avatar de la cliente et sa bulle ; `Scene` tient, dans la boutique du joueur, la cliente, le mannequin,
```

par :

```markdown
  l'avatar de la cliente et sa bulle ; `Dialogue`, l'encadré où elle parle fenêtre ouverte ; `Confettis`, la
  pluie de la robe terminée ; `Scene` tient, dans la boutique du joueur, la cliente, le mannequin,
```

Dans `README.md`, remplacer :

```markdown
et qui vient à la clochette ; amitié, prestige et leurs niveaux |
```

par :

```markdown
et qui vient à la clochette ; amitié, prestige et leurs niveaux ; avis en étoiles, titres de la réputation, rang de la couturière |
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167769 vérifications
TOUT EST VERT : 813 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 12 terminé : paroles dans un encadré, avis en étoiles, réputation, rang, confettis

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
