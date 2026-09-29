# Cœur de l'atelier — Plan 4d-3 : sons, téléphone, mobilier, dernières gênes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finir le sous-projet 1 (spec §8.6, « Finition ») : des sons pour chaque geste de l'atelier et une musique d'ambiance, l'avatar immobile tant que la fenêtre est ouverte (téléphone), une table de découpe et une machine à coudre qui ressemblent à de vrais meubles, et les gênes relevées par la relecture du plan 4d-2.

**Architecture:**
- **Sons** (nouveau module client) : un objet Sound par bruit, dans SoundService, joué par son nom (`Sons.jouer`), ou en boucle (`Sons.boucle` : machine à coudre, musique) ; `Sons.activer` coupe tout. La `Session` annonce chaque action réussie (`surAction`) : le script du client y associe un son. `UiKit` fait un petit clic à chaque bouton.
- **Téléphone** : la `Scene` coupe les commandes de l'avatar tant que la fenêtre est ouverte (à tous les postes, plus seulement caméra fixe) ; `UiKit.echelle` est bornée.
- **Mobilier** : `Boutiques` construit la table (plateau sur pieds, tapis quadrillé, rouleau, ciseaux) et la machine (meuble, socle, colonne, bras, tête, aiguille, volant, bobine) en pièces simples.
- **Gênes du 4d-2** : la ligne du métrage passe sous les jauges ; le carnet et l'achat suivent l'état ; le nouvel essai d'une pièce ratée ne pose que les pièces ; le départ signale une erreur d'écriture ; les textes de l'achat sont raccourcis.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§1 « Jamais copié : … la musique, les sons », §1 contraintes tactile et souris, §4, §8.6 Finition). Plans précédents : `…plan4d1-robustesse.md`, `…plan4d2-commandes.md`.

## Décisions de ce plan

- **Sons** : rien n'est repris de Dressmaker (spec §1). Tout vient de la bibliothèque libre de Roblox, vérifié dans Studio (les 13 sons se chargent) :
  - **interface de Roblox** (créateur « Roblox ») : clic (`Roblox GUI - Select`), achat (`Purchase`), refus (`Negative`), épinglage (`Equip`), décoration (`Bubble`), photo (`Camera Shutter`), robe refusée (`Call Decline`) ;
  - **Pro Sound Effects** (sous licence Roblox) : clochette (diapason frappé), ciseaux, cliquetis de machine à coudre (en boucle, au rythme de la vitesse : tortue 0,8, normale 1, lapin 1,3), tissu qui se déchire (découdre) ;
  - **APM Music** (sous licence Roblox) : robe acceptée (« Spinning Around (b) », 2 s enjouées) et musique d'ambiance (« Fishing For Compliments », jazz tranquille, en boucle, volume 0,12).
- **Où les sons se jouent** :
  - actions réussies annoncées par la `Session` (`surAction`) : clochette, achat, ciseaux, épinglage, robe acceptée ou refusée, abandon ;
  - refus non passager : `ctx.refus` ;
  - clic : `UiKit.surClic` ;
  - machine : l'écran de couture, tant qu'on tient « Coudre » ;
  - découdre, décoration posée, photo : dans leurs écrans.
- **Bouton « Son »** : sous « Atelier », à gauche de l'écran (hors de la fenêtre : rien à décaler) ; il coupe tout, et la musique reprend quand on le rallume.
- **Téléphone** :
  - tant que la fenêtre est ouverte, les commandes de l'avatar sont coupées à toutes les étapes, pour que le stick et le saut ne passent pas sous la fenêtre ; on la ferme pour se promener ;
  - `UiKit.echelle` est bornée à [0,35 ; 1] (un écran annoncé à 1 × 1 au démarrage donnait une échelle négative).
  - Un téléphone couché (844 × 390) garde une échelle d'environ 0,59 : les textes de 14 px y font environ 8 px. Une mise en page propre au téléphone demande un essai sur appareil : c'est au commanditaire de le juger (liste des tâches).
- **Mobilier** : environ 45 pièces de plus, toutes simples (blocs et cylindres) ; les petits objets ne gênent pas les déplacements, et une boutique reste sous 100 pièces.
- **Équilibrage** (§8.6) : reporté au sous-projet 2. Tant que l'argent ne sert qu'au tissu et aux décorations (pas encore de déblocages), régler les prix n'a pas d'enjeu.
- **Gênes du 4d-2 réglées** :
  - ligne du métrage sous les jauges (elle chevauchait « Même tissu pour toute la robe » avec 6 pièces) ;
  - carnet et achat qui suivent l'état ; la quantité proposée à l'achat devient ce qui manque encore (après un achat partiel aussi) ;
  - nouvel essai d'une pièce ratée qui ne pose que les pièces (sans bouger la caméra ni la bulle pendant une photo) ;
  - avertissement si l'écriture du départ échoue ;
  - aide de l'achat sur une ligne, « posées rang par rang ».
- **Laissés pour plus tard** :
  - le symétrique non retourné d'une pièce pliée dans l'aperçu du rouleau (même approximation qu'à la table) ;
  - la mise en page propre au téléphone ;
  - les mineurs antérieurs : pièce fantôme, aperçu des décorations reconstruit, `toucher`, liste des joueurs, orientation des accessoires.
- **Vérifié pendant la préparation** :
  - dans Studio : les 13 sons se chargent ;
  - sur le brouillon : chaque nouvelle vérification des tâches 2 et 5 échoue quand on retire la ligne qu'elle garde (douze variantes).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `finition`, créée depuis `main` (où le plan 4d-2 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : aucun son ni aucune musique de Dressmaker ; seulement des sons de la bibliothèque libre de Roblox.
- **Commandes** (spec §4) : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Sons qui restent allumés** (quitter la couture en tenant « Coudre », fermer la fenêtre, couper le son pendant que la machine tourne). Attendu : la machine s'arrête dès qu'on ne coud plus, et le bouton « Son » éteint tout. Tests : scénario, « on lâche : la machine s'arrête », « « Son » : la musique s'arrête » ; `41_sons`, « son coupé : ni bruit ni machine ».
- **Joueur au téléphone, fenêtre ouverte à une étape sans caméra fixe** (carnet, achat, découpe). Attendu : l'avatar ne bouge pas, puis remarche fenêtre fermée. Test : `23_scene_decorations`, « au carnet, fenêtre ouverte : commandes de l'avatar coupées ».
- **Écran minuscule ou annoncé à 1 × 1 au démarrage.** Attendu : jamais d'échelle nulle ou négative. Test : `24_textes`, « écran annoncé à 1 × 1 au démarrage : échelle bornée à 0,35 ».
- **Mémoire pleine pendant une prise de vue.** Attendu : la vue de la photo ne bouge pas. Test : `20_scene`, « le nouvel essai ne touche pas à la vue de la photo en cours ».
- **Stock qui change pendant l'achat** (achat partiel, état réparé). Attendu : la quantité proposée est ce qui manque encore. Test : scénario, « le stock baisse sans achat : la quantité proposée remonte d'autant ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/client/Atelier/Sons.luau` | **Nouveau** : sons et musique, bouton « Son » |
| `src/client/Atelier/Session.luau` | `surAction(f)` |
| `src/client/Atelier/init.client.luau` | Sons des actions, clic, bouton « Son », musique |
| `src/client/Atelier/UiKit.luau` | `surClic` ; `echelle` bornée |
| `src/client/Atelier/EcranCouture.luau`, `EcranPresentation.luau`, `EcranDecorations.luau` | Machine, découdre, photo, décoration |
| `src/client/Atelier/Scene.luau` | Commandes coupées fenêtre ouverte ; `poserPieces` (nouvel essai sobre) |
| `src/server/Boutiques.luau` | Table et machine détaillées |
| `src/client/Atelier/EcranCarnet.luau`, `EcranAchat.luau` | Métrage sous les jauges ; suivre l'état ; textes |
| `src/server/Commande.luau` | Avertissement si l'écriture du départ échoue |
| `tests/mock.luau`, `tests/gen_api.py` | SoundService, `Play`, `Stop`, `M.sonsJoues` |
| `tests/unitaires/41_sons.luau` | **Nouveau** |
| `tests/unitaires/20_scene.luau`, `23_…`, `24_textes.luau`, `34_boutiques.luau`, `40_…`, `tests/scenario.luau` | Tests complétés |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Le module des sons

**Files:**
- Create: `src/client/Atelier/Sons.luau`
- Modify: `src/client/Atelier/Session.luau` (`surAction`)
- Modify: `tests/mock.luau`, `tests/gen_api.py`
- Create: `tests/unitaires/41_sons.luau`

**Interfaces:**
- Consumes: `Session` (plans 4a à 4d-2).
- Produces:
  - `Sons.IDS` (nom → identifiant), `Sons.VOLUMES`, `Sons.actif` ;
  - `Sons.jouer(nom, vitesse?)`, `Sons.boucle(nom, actif, vitesse?)`, `Sons.activer(actif)` ;
  - chaque son est un `Sound` nommé `Atelier_<nom>` dans SoundService ;
  - `Session:surAction(f)` : `f(nom, reponse)` après chaque action réussie (hors « etat ») ;
  - faux Roblox : `M.sonsJoues` (noms des sons lancés, dans l'ordre).

- [ ] **Step 1: Écrire les tests**

Dans `tests/gen_api.py`, remplacer :

```python
"StarterGui","Lighting","CaptureService","HttpService"}
```

par :

```python
"StarterGui","Lighting","CaptureService","HttpService","SoundService","Sound"}
```

Dans `tests/mock.luau`, remplacer :

```lua
		"CaptureService",
		"HttpService",
	}) do
```

par :

```lua
		"CaptureService",
		"HttpService",
		"SoundService",
	}) do
```

Dans `tests/mock.luau`, remplacer :

```lua
-- M.echecGalerie simule une galerie indisponible
```

par :

```lua
-- Sons : Play et Stop ; M.sonsJoues garde le nom des sons lancés, dans l'ordre
function methodes.Play(self)
	rawget(self, "__props").IsPlaying = true
	M.sonsJoues = M.sonsJoues or {}
	table.insert(M.sonsJoues, self.Name)
end
function methodes.Stop(self)
	rawget(self, "__props").IsPlaying = false
end
-- M.echecGalerie simule une galerie indisponible
```

Créer `tests/unitaires/41_sons.luau` :

```lua
local Sons = U.module("Sons")
local Session = U.module("Session")

local SoundService = M.services.SoundService
local function son(nom)
	return SoundService:FindFirstChild("Atelier_" .. nom)
end
M.sonsJoues = {}

---------------------------------------------------------------------------
-- Un son ponctuel : un objet Sound de SoundService, créé une fois, rejoué à chaque fois
---------------------------------------------------------------------------
Sons.jouer("clochette")
local clochette = son("clochette")
U.verifier(clochette ~= nil and clochette.SoundId == "rbxassetid://" .. Sons.IDS.clochette, "la clochette est un son de SoundService, à son identifiant")
U.verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_clochette", "la clochette sonne")
Sons.jouer("clochette")
U.verifier(son("clochette") == clochette and #M.sonsJoues == 2, "rejouée, avec le même objet")
for nom, id in pairs(Sons.IDS) do
	U.verifier(type(id) == "number" and id > 0, "identifiant du son « " .. nom .. " »")
end

---------------------------------------------------------------------------
-- Une boucle (machine à coudre) : lancée, vitesse réglée, arrêtée
---------------------------------------------------------------------------
Sons.boucle("couture", true, 1.3)
local couture = son("couture")
U.verifier(couture.Looped and couture.IsPlaying and couture.PlaybackSpeed == 1.3, "la machine tourne, au rythme demandé")
local joues = #M.sonsJoues
Sons.boucle("couture", true, 1.3)
U.verifier(#M.sonsJoues == joues, "déjà lancée : pas relancée à chaque image")
Sons.boucle("couture", false)
U.verifier(not couture.IsPlaying, "la machine s'arrête")

---------------------------------------------------------------------------
-- Couper le son : rien ne joue, les boucles s'arrêtent ; la musique reprend au retour
---------------------------------------------------------------------------
Sons.boucle("musique", true)
U.verifier(son("musique").IsPlaying and son("musique").Volume < son("clochette").Volume, "la musique joue, plus bas que les bruits")
Sons.activer(false)
U.verifier(not Sons.actif and not son("musique").IsPlaying, "son coupé : la musique s'arrête")
joues = #M.sonsJoues
Sons.jouer("achat")
Sons.boucle("couture", true)
U.verifier(#M.sonsJoues == joues and not couture.IsPlaying, "son coupé : ni bruit ni machine")
Sons.activer(true)
U.verifier(son("musique").IsPlaying, "son rétabli : la musique reprend")
Sons.boucle("musique", false)

---------------------------------------------------------------------------
-- La session annonce chaque action réussie (pour les sons de l'interface)
---------------------------------------------------------------------------
local courante = Session.courante
local session = Session.nouvelle(3)
local annonces = {}
session:surAction(function(nom, reponse)
	table.insert(annonces, { nom = nom, ok = reponse.ok })
end)
session:nouvelleCommande()
session:acheter("coton_blanc", 0) -- refusé
U.verifier(#annonces == 1 and annonces[1].nom == "nouvelleCommande" and annonces[1].ok, "une action réussie est annoncée, pas un refus")
Session.courante = courante
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Sons n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 3: Écrire le module**

Créer `src/client/Atelier/Sons.luau` :

```lua
-- Sons : les bruits de l'atelier et la musique. Tout vient de la bibliothèque libre de Roblox : sons de
-- l'interface de Roblox, effets de Pro Sound Effects, musique d'APM Music (sous licence pour les jeux
-- Roblox) ; rien n'est repris de Dressmaker. Chaque son est un objet Sound de SoundService (entendu par ce
-- joueur seulement), créé une fois. « actif » coupe tout (bouton « Son » à gauche de l'écran).
local SoundService = game:GetService("SoundService")

local Sons = {}

Sons.IDS = {
	clic = 17208396156, -- Roblox GUI - Select
	clochette = 9120288444, -- Pro Sound Effects : diapason frappé, son clair
	achat = 17208380755, -- Roblox GUI - Purchase
	refus = 17208353912, -- Roblox GUI - Negative
	couper = 9118830451, -- Pro Sound Effects : ciseaux
	epingler = 17208323435, -- Roblox GUI - Equip
	couture = 9126029570, -- Pro Sound Effects : cliquetis de machine à coudre (en boucle)
	decoudre = 9113827551, -- Pro Sound Effects : tissu de lin qui se déchire
	decoration = 17208204604, -- Roblox GUI - Bubble
	photo = 17208312548, -- Roblox GUI - Camera Shutter
	reussite = 1839881844, -- APM Music : « Spinning Around (b) », 2 s enjouées
	echec = 17208214688, -- Roblox GUI - Call Decline
	musique = 1837589367, -- APM Music : « Fishing For Compliments », jazz tranquille (en boucle)
}
Sons.VOLUMES = { clic = 0.25, musique = 0.12, couture = 0.45 } -- 0,6 pour les autres

Sons.actif = true
local objets, voulues = {}, {}

local function objet(nom)
	local s = objets[nom]
	if not s then
		s = Instance.new("Sound")
		s.Name = "Atelier_" .. nom
		s.SoundId = "rbxassetid://" .. Sons.IDS[nom]
		s.Volume = Sons.VOLUMES[nom] or 0.6
		s.Parent = SoundService
		objets[nom] = s
	end
	return s
end

-- Un son ponctuel (vitesse : 1 par défaut)
function Sons.jouer(nom, vitesse)
	if not Sons.actif then
		return
	end
	local s = objet(nom)
	s.PlaybackSpeed = vitesse or 1
	s.TimePosition = 0
	s:Play()
end

-- Un son en boucle (machine à coudre, musique), lancé ou arrêté ; vitesse : son rythme
function Sons.boucle(nom, actif, vitesse)
	voulues[nom] = actif or nil
	local s = objet(nom)
	s.Looped = true
	s.PlaybackSpeed = vitesse or 1
	if actif and Sons.actif then
		if not s.IsPlaying then
			s:Play()
		end
	elseif s.IsPlaying then
		s:Stop()
	end
end

-- Coupe ou rétablit tout le son ; au retour, les boucles voulues reprennent (la musique)
function Sons.activer(actif)
	Sons.actif = actif
	for nom, s in pairs(objets) do
		if not actif and s.IsPlaying then
			s:Stop()
		elseif actif and voulues[nom] and not s.IsPlaying then
			s:Play()
		end
	end
end

return Sons
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
	local action = reponse.ok and nom ~= "etat"
	if action then
		self.derniere = { action = nom, reponse = reponse }
	end
```

par :

```lua
	local action = reponse.ok and nom ~= "etat"
	if action then
		self.derniere = { action = nom, reponse = reponse }
		if self.annonce then
			pcall(self.annonce, nom, reponse) -- (sons de l'interface) : ne peut rien bloquer
		end
	end
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
-- attente(actif) est appelée au début (vrai) et à la fin (faux) de chaque appel au serveur (indicateur)
function Session:surAttente(f)
	self.attente = f
end
```

par :

```lua
-- attente(actif) est appelée au début (vrai) et à la fin (faux) de chaque appel au serveur (indicateur)
function Session:surAttente(f)
	self.attente = f
end

-- f(nom, reponse) est appelée après chaque action réussie du joueur (sons de l'interface)
function Session:surAction(f)
	self.annonce = f
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105086 vérifications
TOUT EST VERT : 385 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Sons.luau src/client/Atelier/Session.luau tests/mock.luau tests/gen_api.py tests/unitaires/41_sons.luau
git commit -m "Sons : module des bruits et de la musique ; la session annonce les actions réussies

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les sons dans l'atelier

**Files:**
- Modify: `src/client/Atelier/UiKit.luau` (`surClic`)
- Modify: `src/client/Atelier/init.client.luau`
- Modify: `src/client/Atelier/EcranCouture.luau`, `EcranPresentation.luau`, `EcranDecorations.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Sons` et `Session:surAction` (tâche 1), `ctx.refus` (plan 4d-1).
- Produces: bouton `Son` (dans l'écran, sous `OuvrirAtelier`) ; `UiKit.surClic`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("OuvrirAtelier")
verifier(fenetre.Visible, "le bouton Atelier rouvre la fenêtre")
```

par :

```lua
cliquer("OuvrirAtelier")
verifier(fenetre.Visible, "le bouton Atelier rouvre la fenêtre")
-- Sons : la musique d'ambiance joue ; le bouton « Son » coupe tout, puis rétablit
local SoundService = M.services.SoundService
local function sonsDepuis(n)
	local out = {}
	for k = n + 1, #(M.sonsJoues or {}) do
		table.insert(out, M.sonsJoues[k])
	end
	return table.concat(out, ",")
end
local function nombreSons()
	return #(M.sonsJoues or {})
end
verifier(SoundService:FindFirstChild("Atelier_musique") ~= nil and SoundService.Atelier_musique.IsPlaying, "la musique d'ambiance joue")
cliquer("Son")
verifier(boutonNomme("Son").Text == "Son : non" and not SoundService.Atelier_musique.IsPlaying, "« Son » : la musique s'arrête")
local nCoupe = nombreSons()
cliquer("Fermer")
cliquer("OuvrirAtelier")
verifier(nombreSons() == nCoupe, "son coupé : les boutons ne font plus de bruit")
cliquer("Son")
verifier(boutonNomme("Son").Text == "Son : oui" and SoundService.Atelier_musique.IsPlaying, "« Son » de nouveau : la musique reprend")
local nSons = nombreSons()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(pendantAttente ~= nil and pendantAttente.visible and string.find(pendantAttente.texte, "sauvegardée", 1, true) ~= nil, "serveur lent : l'avertissement affiché n'est pas remplacé")
```

par :

```lua
verifier(pendantAttente ~= nil and pendantAttente.visible and string.find(pendantAttente.texte, "sauvegardée", 1, true) ~= nil, "serveur lent : l'avertissement affiché n'est pas remplacé")
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible and fenetre.Message.Text ~= "Un instant…" and fenetre.Message.TextColor3 ~= GRIS, "valider sans tissu : message d'erreur (en rouge), à la place de l'indicateur")
```

par :

```lua
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible and fenetre.Message.Text ~= "Un instant…" and fenetre.Message.TextColor3 ~= GRIS, "valider sans tissu : message d'erreur (en rouge), à la place de l'indicateur")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_refus", "un refus fait son petit bruit")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avant = argent()
cliquer("Acheter")
verifier(argent() < avant, "l'achat débite l'argent")
```

par :

```lua
local avant = argent()
cliquer("Acheter")
verifier(argent() < avant, "l'achat débite l'argent")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat", "l'achat fait sonner la caisse")
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Decoudre")
verifier(panneauC.Note.Text == "Couture : —" and #points:GetChildren() == 0, "découdre défait la couture")
```

par :

```lua
cliquer("Decoudre")
verifier(panneauC.Note.Text == "Couture : —" and #points:GetChildren() == 0, "découdre défait la couture")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_decoudre", "découdre : le tissu se défait (son)")
-- La machine tourne (son en boucle) tant qu'on tient « Coudre », et s'arrête au lâcher
local appuiSon = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) }
boutonNomme("Coudre").InputBegan:Fire(appuiSon)
M.avancer(0.5)
verifier(SoundService.Atelier_couture.IsPlaying and SoundService.Atelier_couture.Looped, "on tient « Coudre » : la machine tourne")
UIS.InputEnded:Fire(appuiSon)
M.avancer(0.1)
verifier(not SoundService.Atelier_couture.IsPlaying, "on lâche : la machine s'arrête")
cliquer("Decoudre")
```

Dans `tests/scenario.luau`, remplacer :

```lua
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == "Coût : 3 po", "nœud posé sur le corsage : 3 po")
```

par :

```lua
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == "Coût : 3 po", "nœud posé sur le corsage : 3 po")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_decoration", "une décoration posée fait son petit bruit")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(pendant ~= nil and pendant.interface == false and pendant.vue == origineBoutique * ScenePoste.CAMERA_PHOTO and pendant.bulle == false, "photo prise sans l'interface ni la bulle, vue centrée sur la robe")
```

par :

```lua
verifier(pendant ~= nil and pendant.interface == false and pendant.vue == origineBoutique * ScenePoste.CAMERA_PHOTO and pendant.bulle == false, "photo prise sans l'interface ni la bulle, vue centrée sur la robe")
verifier(table.find(M.sonsJoues, "Atelier_photo") ~= nil and M.sonsJoues[#M.sonsJoues] == "Atelier_photo", "déclic de l'appareil photo")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
```

par :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_echec", "robe refusée : un son déçu")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
```

par :

```lua
verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_reussite", "robe acceptée : une petite fanfare")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : la musique d'ambiance joue`

- [ ] **Step 3: Le clic des boutons, les sons des actions, le bouton « Son »**

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
			dernier = maintenant
			auClic(...)
		end)
```

par :

```lua
			dernier = maintenant
			if UiKit.surClic then
				pcall(UiKit.surClic) -- (le petit clic des boutons, réglé par le script du client)
			end
			auClic(...)
		end)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Vignettes = require(script:WaitForChild("Vignettes"))
```

par :

```lua
local Vignettes = require(script:WaitForChild("Vignettes"))
local Sons = require(script:WaitForChild("Sons"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local function refus(r)
	afficherMessage(r.erreur, if r.passager then C.texteDoux else C.erreur)
end
```

par :

```lua
local function refus(r)
	afficherMessage(r.erreur, if r.passager then C.texteDoux else C.erreur)
	if not r.passager then
		Sons.jouer("refus")
	end
end
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
-- Fenêtre au centre, ou panneau à droite (titre et argent sur deux lignes)
```

par :

```lua
-- Sons : un petit clic à chaque bouton, un bruit par action réussie, la musique d'ambiance ; le bouton
-- « Son » (sous « Atelier ») coupe tout
UiKit.surClic = function()
	Sons.jouer("clic")
end
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", couper = "couper", epingler = "epingler", abandonner = "echec" }
session:surAction(function(nom, reponse)
	if nom == "livrer" then
		Sons.jouer(if reponse.reussie then "reussite" else "echec")
	elseif SONS_ACTIONS[nom] then
		Sons.jouer(SONS_ACTIONS[nom])
	end
end)
local boutonSon
boutonSon = UiKit.boutonDoux({
	Name = "Son",
	Text = "Son : oui",
	TextSize = 14,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 46),
	Size = UDim2.fromOffset(140, 36),
	Parent = gui,
}, function()
	Sons.activer(not Sons.actif)
	boutonSon.Text = if Sons.actif then "Son : oui" else "Son : non"
end)
Sons.boucle("musique", true)

-- Fenêtre au centre, ou panneau à droite (titre et argent sur deux lignes)
```

- [ ] **Step 4: La machine, découdre, la photo, les décorations**

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
```

par :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée
```

par :

```lua
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée
local RYTHMES = { tortue = 0.8, normale = 1, lapin = 1.3 } -- vitesse du son de la machine
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		if machine and machine:decoudre() then
			effacerPoints()
			rafraichir()
		end
```

par :

```lua
		if machine and machine:decoudre() then
			Sons.jouer("decoudre")
			effacerPoints()
			rafraichir()
		end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		if not machine or machine:fini() or not tenu or not ctx.fenetre.Visible then
			return
		end
```

par :

```lua
	-- Le son de la machine suit l'aiguille : il tourne tant qu'on coud, au rythme de la vitesse choisie
	local rythme = nil
	local function sonMachine(cousant)
		local r = cousant and RYTHMES[vitesse] or nil
		if r ~= rythme then
			rythme = r
			Sons.boucle("couture", r ~= nil, r)
		end
	end
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		local cousant = machine ~= nil and not machine:fini() and tenu ~= nil and ctx.fenetre.Visible
		sonMachine(cousant)
		if not cousant then
			return
		end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	return function()
		desabonner()
		lierEspace(false)
```

par :

```lua
	return function()
		desabonner()
		lierEspace(false)
		sonMachine(false)
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
```

par :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
```

par :

```lua
		Sons.jouer("photo")
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))
```

par :

```lua
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
			local r = deco:toucher(t.indicePiece, t.copie, t.u, t.v)
			if not r.ok then
				ctx.refus(r)
			end
```

par :

```lua
			local r = deco:toucher(t.indicePiece, t.copie, t.u, t.v)
			if r.ok then
				Sons.jouer("decoration")
			else
				ctx.refus(r)
			end
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105086 vérifications
TOUT EST VERT : 407 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier tests/scenario.luau
git commit -m "Sons dans l'atelier : clic, clochette, caisse, ciseaux, machine, photo, réaction de la cliente, musique ; bouton « Son »

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Téléphone : l'avatar immobile fenêtre ouverte, échelle bornée

**Files:**
- Modify: `src/client/Atelier/Scene.luau` (`ouvrir`, `regarder`, `detruire`, nouveau `majControles`)
- Modify: `src/client/Atelier/UiKit.luau` (`echelle`)
- Modify: `tests/unitaires/23_scene_decorations.luau`, `tests/unitaires/24_textes.luau`

**Interfaces:**
- Consumes: option `controles` de `Scene.nouvelle` (plan 3c).
- Produces: `Scene:majControles()` ; `UiKit.echelle` dans [0,35 ; 1].

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/23_scene_decorations.luau`, remplacer :

```lua
-- Relecture finale : pendant les postes, l'avatar ne bouge pas (commandes du joueur coupées), et les
-- commandes reviennent en quittant le poste ou en fermant la fenêtre
```

par :

```lua
-- Tant que la fenêtre de l'atelier est ouverte, l'avatar ne bouge pas (commandes du joueur coupées : au
-- téléphone, le stick et le saut passeraient sous la fenêtre) ; elles reviennent quand on la ferme
```

Dans `tests/unitaires/23_scene_decorations.luau`, remplacer :

```lua
U.verifier(#appels == 0 or appels[#appels] == true, "au carnet : l'avatar garde ses commandes")
```

par :

```lua
U.verifier(appels[#appels] == false, "au carnet, fenêtre ouverte : commandes de l'avatar coupées")
scene2:ouvrir(false, etat2)
U.verifier(appels[#appels] == true, "au carnet, fenêtre fermée : l'avatar bouge")
scene2:ouvrir(true, etat2)
```

Dans `tests/unitaires/23_scene_decorations.luau`, remplacer :

```lua
U.verifier(appels[#appels] == false, "fenêtre rouverte au poste : commandes coupées")
etat2.etape = "carnet"
scene2:synchroniser(etat2)
U.verifier(appels[#appels] == true, "retour au carnet : commandes rendues")
scene2:detruire()
```

par :

```lua
U.verifier(appels[#appels] == false, "fenêtre rouverte au poste : commandes coupées")
local nAppels = #appels
etat2.etape = "carnet"
scene2:synchroniser(etat2)
U.verifier(appels[#appels] == false and #appels == nAppels, "retour au carnet, fenêtre ouverte : commandes toujours coupées, sans appel de trop")
scene2:detruire()
U.verifier(appels[#appels] == true, "scène détruite : l'avatar retrouve ses commandes")
```

Dans `tests/unitaires/24_textes.luau`, remplacer :

```lua
U.verifier(UiKit.exigence(auMoins, Catalogue) == "Au moins 30 en Élégant", "sans scores : l'exigence seule (carnet)")
```

par :

```lua
U.verifier(UiKit.exigence(auMoins, Catalogue) == "Au moins 30 en Élégant", "sans scores : l'exigence seule (carnet)")

-- Échelle de la fenêtre (téléphones) : réduite pour tenir, jamais nulle ni négative
U.verifier(UiKit.echelle(Vector2.new(1920, 1080)) == 1, "grand écran : échelle 1")
local telephone = UiKit.echelle(Vector2.new(844, 390))
U.verifier(telephone > 0.5 and telephone < 1, "téléphone couché : la fenêtre se réduit pour tenir (" .. telephone .. ")")
U.verifier(UiKit.echelle(Vector2.new(1, 1)) == 0.35, "écran annoncé à 1 × 1 au démarrage : échelle bornée à 0,35")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : au carnet, fenêtre ouverte : commandes de l'avatar coupées`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
-- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:regarder(ouverte and Scene.POSTES[etat.etape] == true)
end
```

par :

```lua
-- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:regarder(ouverte and Scene.POSTES[etat.etape] == true)
end

-- Commandes de l'avatar : coupées tant que la fenêtre de l'atelier est ouverte (au téléphone, le stick et le
-- bouton de saut passeraient sous la fenêtre ; au clavier, l'avatar marcherait derrière elle), rendues quand
-- on la ferme. Un seul appel par changement.
function Scene:majControles()
	local coupees = self.ouverte == true
	if coupees ~= self.controlesCoupes then
		self.controlesCoupes = coupees
		self.controles(not coupees)
	end
end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
		self.cameraFixe = true
		self.controles(false)
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
		self.controles(true)
	end
```

par :

```lua
		self.cameraFixe = true
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
	end
	self:majControles()
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:detruire()
	self:finirPhoto()
	self:regarder(false)
```

par :

```lua
function Scene:detruire()
	self:finirPhoto()
	self.ouverte = false
	self:regarder(false)
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.echelle(tailleEcran)
	return math.min(1, (tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR)
end
```

par :

```lua
-- (jamais sous 0,35 : au démarrage, Roblox peut annoncer un écran de 1 × 1)
function UiKit.echelle(tailleEcran)
	return math.clamp(math.min((tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR), 0.35, 1)
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105091 vérifications
TOUT EST VERT : 407 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Scene.luau src/client/Atelier/UiKit.luau tests/unitaires/23_scene_decorations.luau tests/unitaires/24_textes.luau
git commit -m "Téléphone : l'avatar ne bouge pas tant que la fenêtre est ouverte ; échelle de la fenêtre bornée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Une vraie table de découpe, une vraie machine à coudre

**Files:**
- Modify: `src/server/Boutiques.luau` (`construire`)
- Modify: `tests/unitaires/34_boutiques.luau`

**Interfaces:**
- Consumes: `bloc(modele, origine, nom, position, taille, couleur, options)` (plan 4c).
- Produces: pièces nommées `TableDecoupe` (plateau), `PiedTable_1..4`, `TapisDecoupe`, `LigneTapis_1..13`, `RouleauTable`, `Ciseaux_Lame1..2`, `Ciseaux_Anneau1..2`, `Machine` (meuble), `PiedMachine_1..4`, `SocleMachine`, `ColonneMachine`, `BrasMachine`, `TeteMachine`, `Aiguille`, `Volant`, `Bobine`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
U.verifier(unRouleau.Shape == Enum.PartType.Cylinder and unRouleau.Size.X >= 1.5 and unRouleau.Material ~= Enum.Material.Fabric, "rouleaux assez longs (un cylindre s'allonge selon X), en matière lisse (la matière tissu assombrit trop)")
```

par :

```lua
U.verifier(unRouleau.Shape == Enum.PartType.Cylinder and unRouleau.Size.X >= 1.5 and unRouleau.Material ~= Enum.Material.Fabric, "rouleaux assez longs (un cylindre s'allonge selon X), en matière lisse (la matière tissu assombrit trop)")
-- La table de découpe et la machine à coudre ressemblent à de vrais meubles : plateau sur pieds, tapis de coupe
-- quadrillé, rouleau et ciseaux ; machine sur son meuble, avec socle, colonne, bras, tête, aiguille, volant, bobine
local manquants = {}
for _, nom in ipairs({ "PiedTable_1", "PiedTable_4", "TapisDecoupe", "RouleauTable", "Ciseaux_Lame1", "Ciseaux_Lame2", "Ciseaux_Anneau1", "PiedMachine_1", "PiedMachine_4", "SocleMachine", "ColonneMachine", "BrasMachine", "TeteMachine", "Aiguille", "Volant", "Bobine" }) do
	if not b3:FindFirstChild(nom) then
		table.insert(manquants, nom)
	end
end
U.verifier(#manquants == 0, "table et machine détaillées ; manquent : " .. table.concat(manquants, ", "))
local lignesTapis = 0
for _, p in ipairs(b3:GetChildren()) do
	if p.Name:sub(1, 11) == "LigneTapis_" then
		lignesTapis += 1
	end
end
U.verifier(lignesTapis >= 8, "le tapis de coupe est quadrillé (" .. lignesTapis .. " lignes)")
U.verifier(not b3.Aiguille.CanCollide and not b3.Ciseaux_Lame1.CanCollide and not b3.Bobine.CanCollide and not b3.TapisDecoupe.CanCollide, "les petits objets ne gênent pas les déplacements")
U.verifier(b3.Volant.Shape == Enum.PartType.Cylinder and b3.Bobine.Shape == Enum.PartType.Cylinder and b3.Aiguille.Shape == Enum.PartType.Cylinder, "volant, bobine et aiguille sont ronds")
local hautTable = Boutique.emplacement(3):PointToObjectSpace(b3.TableDecoupe.CFrame.Position).Y + b3.TableDecoupe.Size.Y / 2
U.verifier(hautTable > 2.5 and hautTable < 3.5 and b3.TableDecoupe.Size.Y <= 0.5, "un plateau de table (pas un bloc), à hauteur de travail : " .. hautTable)
local parties = 0
for _, p in ipairs(b3:GetDescendants()) do
	if p:IsA("BasePart") then
		parties += 1
	end
end
U.verifier(parties <= 100, "une boutique reste légère (8 dans la rue) : " .. parties .. " pièces")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `TeteMachine, Aiguille, Volant, Bobine` (message « table et machine détaillées ; manquent : … »)

- [ ] **Step 3: Écrire le code**

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	-- Table de découpe et machine à coudre, au fond
	bloc(modele, origine, "TableDecoupe", Vector3.new(-6, 1.5, 51), Vector3.new(6, 3, 4), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "Machine", Vector3.new(7, 1.5, 51), Vector3.new(4, 3, 2.5), BOIS, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "CorpsMachine", Vector3.new(7, 3.6, 51), Vector3.new(1.6, 1.2, 0.8), rgb(60, 60, 70), { matiere = Enum.Material.Metal, decor = true })
```

par :

```lua
	-- Table de découpe, au fond à gauche : plateau sur quatre pieds, tapis de coupe quadrillé, un rouleau de
	-- tissu et une paire de ciseaux
	local TX, TZ = -6, 51
	local LIGNE = rgb(230, 240, 230)
	bloc(modele, origine, "TableDecoupe", Vector3.new(TX, 2.85, TZ), Vector3.new(6, 0.3, 4), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	for k, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		bloc(modele, origine, "PiedTable_" .. k, Vector3.new(TX + c[1] * 2.7, 1.35, TZ + c[2] * 1.7), Vector3.new(0.3, 2.7, 0.3), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	end
	bloc(modele, origine, "TapisDecoupe", Vector3.new(TX, 3.025, TZ), Vector3.new(5.4, 0.05, 3.4), rgb(70, 130, 100), { decor = true })
	for k = 1, 5 do -- lignes du tapis, dans la longueur
		bloc(modele, origine, "LigneTapis_" .. k, Vector3.new(TX, 3.055, TZ - 1.7 + k * 3.4 / 6), Vector3.new(5.4, 0.01, 0.03), LIGNE, { decor = true })
	end
	for k = 1, 8 do -- puis en travers
		bloc(modele, origine, "LigneTapis_" .. (5 + k), Vector3.new(TX - 2.7 + k * 0.6, 3.055, TZ), Vector3.new(0.03, 0.01, 3.4), LIGNE, { decor = true })
	end
	bloc(modele, origine, "RouleauTable", Vector3.new(TX - 0.6, 3.35, TZ + 1.2), Vector3.new(3.6, 0.6, 0.6), rgb(232, 170, 190), { forme = Enum.PartType.Cylinder, decor = true })
	for k, angle in ipairs({ 15, -15 }) do -- ciseaux : deux lames croisées…
		local lame = bloc(modele, origine, "Ciseaux_Lame" .. k, Vector3.new(TX + 1.6, 3.07, TZ - 0.8), Vector3.new(1, 0.04, 0.1), rgb(200, 200, 210), { matiere = Enum.Material.Metal, decor = true })
		lame.CFrame = lame.CFrame * CFrame.Angles(0, math.rad(angle), 0)
	end
	for k, dz in ipairs({ -0.15, 0.15 }) do -- … et deux anneaux, à plat sur le tapis
		local anneau = bloc(modele, origine, "Ciseaux_Anneau" .. k, Vector3.new(TX + 2.25, 3.07, TZ - 0.8 + dz), Vector3.new(0.05, 0.28, 0.28), rgb(200, 60, 80), { forme = Enum.PartType.Cylinder, decor = true })
		anneau.CFrame = anneau.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end
	-- Machine à coudre, au fond à droite, sur son meuble : socle, colonne, bras, tête et aiguille (émail crème),
	-- volant sur le côté, bobine de fil sur le bras
	local MX, MZ = 7, 51
	local EMAIL = rgb(240, 236, 228)
	bloc(modele, origine, "Machine", Vector3.new(MX, 2.85, MZ), Vector3.new(4, 0.3, 2.5), BOIS, { matiere = Enum.Material.Wood })
	for k, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		bloc(modele, origine, "PiedMachine_" .. k, Vector3.new(MX + c[1] * 1.7, 1.35, MZ + c[2] * 1), Vector3.new(0.3, 2.7, 0.3), BOIS, { matiere = Enum.Material.Wood })
	end
	bloc(modele, origine, "SocleMachine", Vector3.new(MX, 3.175, MZ), Vector3.new(2.4, 0.35, 1.1), EMAIL, { decor = true })
	bloc(modele, origine, "ColonneMachine", Vector3.new(MX + 0.85, 3.95, MZ), Vector3.new(0.55, 1.2, 0.8), EMAIL, { decor = true })
	bloc(modele, origine, "BrasMachine", Vector3.new(MX + 0.05, 4.7, MZ), Vector3.new(2.2, 0.45, 0.8), EMAIL, { decor = true })
	bloc(modele, origine, "TeteMachine", Vector3.new(MX - 0.85, 4.2, MZ), Vector3.new(0.5, 0.75, 0.8), EMAIL, { decor = true })
	local aiguille = bloc(modele, origine, "Aiguille", Vector3.new(MX - 0.85, 3.6, MZ - 0.2), Vector3.new(0.5, 0.05, 0.05), rgb(200, 200, 210), { forme = Enum.PartType.Cylinder, matiere = Enum.Material.Metal, decor = true })
	aiguille.CFrame = aiguille.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout
	bloc(modele, origine, "Volant", Vector3.new(MX + 1.2, 4.35, MZ), Vector3.new(0.15, 0.9, 0.9), rgb(90, 90, 100), { forme = Enum.PartType.Cylinder, matiere = Enum.Material.Metal, decor = true })
	local bobine = bloc(modele, origine, "Bobine", Vector3.new(MX + 0.4, 5.1, MZ), Vector3.new(0.35, 0.25, 0.25), rgb(210, 50, 90), { forme = Enum.PartType.Cylinder, decor = true })
	bobine.CFrame = bobine.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout sur le bras
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105097 vérifications
TOUT EST VERT : 407 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Boutiques.luau tests/unitaires/34_boutiques.luau
git commit -m "Boutique : table de découpe sur pieds avec tapis quadrillé, rouleau et ciseaux ; machine à coudre sur son meuble

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Les gênes relevées au plan 4d-2

**Files:**
- Modify: `src/client/Atelier/Scene.luau` (`synchroniser`, nouveau `poserPieces`)
- Modify: `src/client/Atelier/EcranCarnet.luau`, `EcranAchat.luau`
- Modify: `src/server/Commande.luau` (`depart`)
- Modify: `tests/unitaires/20_scene.luau`, `40_sauvegarde_serie.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Scene.ESSAI_PIECE` (plan 4d-2), `Metrage.aAcheter` (plan 4d-2).
- Produces: `Scene:poserPieces()` ; libellé `Contenu.Droite.Metrage` (carnet).

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(string.find(fenetre.Contenu.Metrage.Text, "Choisis les tissus", 1, true) == 1, "sans tissu : le métrage attend les tissus")
```

par :

```lua
local ligneMetrage = fenetre.Contenu.Droite:FindFirstChild("Metrage")
verifier(ligneMetrage ~= nil and string.find(ligneMetrage.Text, "Choisis les tissus", 1, true) == 1, "sans tissu : le métrage attend les tissus, dans la colonne de droite")
local derniereJauge = fenetre.Contenu.Droite["Jauge_" .. Catalogue.STYLES[#Catalogue.STYLES]]
local hauteurDroite = fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset + fenetre.Contenu.Droite.Size.Y.Offset -- (tailles relatives)
verifier(ligneMetrage.AnchorPoint.Y == 1 and ligneMetrage.Position.Y.Scale == 1 and derniereJauge.Position.Y.Offset + derniereJauge.Size.Y.Offset < hauteurDroite + ligneMetrage.Position.Y.Offset - ligneMetrage.Size.Y.Offset, "la ligne du métrage est en bas de la colonne, sous les jauges, loin des boutons du carnet")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Contenu.Metrage.Text == ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dmRobe, prixRobe, argent()), "métrage et coût en direct : " .. fenetre.Contenu.Metrage.Text)
```

par :

```lua
verifier(ligneMetrage.Text == ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dmRobe, prixRobe, argent()), "métrage et coût en direct : " .. ligneMetrage.Text)
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Contenu.Metrage.Text == ("Tissu à acheter : %d dm, %d po — il te manque 10 po."):format(dmRobe, prixRobe) and fenetre.Contenu.Metrage.TextColor3 == requireModule(scriptClient.UiKit).COULEURS.erreur, "pas assez d'argent : ce qui manque, en rouge")
etatCarnet.argent = argentVrai
cliquer("Variante_jupe_trapeze")
```

par :

```lua
verifier(ligneMetrage.Text == ("Tissu à acheter : %d dm, %d po — il te manque 10 po."):format(dmRobe, prixRobe) and ligneMetrage.TextColor3 == requireModule(scriptClient.UiKit).COULEURS.erreur, "pas assez d'argent : ce qui manque, en rouge")
etatCarnet.argent = argentVrai
cliquer("Variante_jupe_trapeze")
-- L'état change sans action du carnet (réparé par le serveur) : la ligne suit
serveur:atelier(joueur).etat.argent = argentVrai + 1000
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(string.find(ligneMetrage.Text, ("(tu as %d po)"):format(argentVrai + 1000), 1, true) ~= nil, "l'argent change sans action du carnet : la ligne suit")
serveur:atelier(joueur).etat.argent = argentVrai
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("En stock : " .. (quantite + 7) .. " dm") ~= nil, "l'état change sans achat : la ligne suit")
```

par :

```lua
verifier(texte("En stock : " .. (quantite + 7) .. " dm") ~= nil, "l'état change sans achat : la ligne suit")
stockServeur.soie_rose_fleurs = 2
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(ligne.Quantite.Text == (quantite - 2) .. " dm", "le stock baisse sans achat : la quantité proposée remonte d'autant")
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- Aperçu du rouleau (toucher l'échantillon) : les pièces de ce tissu rangées comme le conseil les compte.
```

par :

```lua
local aideAchat = texte("métrage conseillé")
verifier(aideAchat ~= nil and #aideAchat.Text <= 110, "l'aide de l'achat tient sur une ligne (" .. (aideAchat and #aideAchat.Text or 0) .. " caractères)")
-- Aperçu du rouleau (toucher l'échantillon) : les pièces de ce tissu rangées comme le conseil les compte.
```

Dans `tests/unitaires/20_scene.luau`, remplacer :

```lua
M.avancer(Scene.ESSAI_PIECE + 0.1) -- aucune action du joueur entre-temps (décorations, photo)
```

par :

```lua
scene2:cadrerPhoto(true) -- une prise de vue commence
M.avancer(Scene.ESSAI_PIECE + 0.1) -- aucune action du joueur entre-temps (décorations, photo)
U.verifier(camera.CFrame == scene2.origine * Scene.CAMERA_PHOTO, "le nouvel essai ne touche pas à la vue de la photo en cours")
scene2:cadrerPhoto(false)
```

Dans `tests/unitaires/40_sauvegarde_serie.luau`, remplacer :

```lua
U.verifier(notePendant == true and serveur3.departs[retourPresse.UserId] == nil, "départ noté pendant son écriture, puis effacé")
```

par :

```lua
U.verifier(notePendant == true and serveur3.departs[retourPresse.UserId] == nil, "départ noté pendant son écriture, puis effacé")
local malchance = joueurNumero("Malchance", 708)
serveur3:arrivee(malchance)
local vraiEnregistrer = serveur3.enregistrer
serveur3.enregistrer = function()
	error("panne simulée")
end
local sansErreurDepart = pcall(serveur3.depart, serveur3, malchance)
serveur3.enregistrer = vraiEnregistrer
U.verifier(sansErreurDepart and serveur3:atelier(malchance) == nil and serveur3.departs[malchance.UserId] == nil, "erreur en écrivant au départ : atelier retiré, départ effacé, sans erreur")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le nouvel essai ne touche pas à la vue de la photo en cours`

- [ ] **Step 3: La scène ne réessaie que les pièces**

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:synchroniser(etat, derniere)
	self.etatSuivi, self.derniereSuivie = etat, derniere -- pour réessayer une pièce ratée
	self:suivreCliente(etat, derniere)
```

par :

```lua
function Scene:synchroniser(etat, derniere)
	self:suivreCliente(etat, derniere)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
	local recette = etat:recette()
	self.recette = recette
	local voulues = {}
```

par :

```lua
	local recette = etat:recette()
	self.recette = recette
	local voulues = {} -- [idPiece] = pièce de la recette, pour chaque pièce épinglée
	self.voulues = voulues
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
	if not recette then
		return
	end
	for _, p in ipairs(recette.pieces) do
		if voulues[p.id] and not self.pieces[p.id] then
```

par :

```lua
	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
	self:poserPieces()
end

-- Pose sur le mannequin les pièces épinglées qui n'y sont pas encore. Une pièce ratée faute de mémoire est
-- oubliée et réessayée quelques secondes plus tard, seule : ni la cliente, ni la caméra, ni les
-- décorations ne bougent (une prise de vue peut être en cours).
function Scene:poserPieces()
	local recette, voulues = self.recette, self.voulues
	if not recette or not self.dossier.Parent then
		return
	end
	for _, p in ipairs(recette.pieces) do
		if voulues[p.id] and not self.pieces[p.id] then
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

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

par :

```lua
			-- Pièce ratée : oubliée, et réessayée quelques secondes plus tard (un essai en attente à la fois ;
			-- entre-temps, une action du joueur la réessaie aussi)
			if ratee and self.pieces[p.id] == entree then
				for _, part in ipairs(entree.parts) do
					part:Destroy()
				end
				self.pieces[p.id] = nil
				if not self.reessai then
					self.reessai = true
					task.delay(Scene.ESSAI_PIECE, function()
						self.reessai = false
						self:poserPieces()
					end)
				end
			end
```

- [ ] **Step 4: Le carnet et l'achat**

Dans `src/client/Atelier/EcranCarnet.luau`, supprimer les lignes :

```lua
	-- En bas à gauche, à côté de « Valider » : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, -260, 0, 46), Parent = contenu })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		jauges[style] = { plage = plage, acquis = acquis }
	end
```

par :

```lua
		jauges[style] = { plage = plage, acquis = acquis }
	end
	-- Sous les jauges, en bas de la colonne : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 46), Parent = droite })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	rafraichir()
	return fermerChoix
end
```

par :

```lua
	rafraichir()
	-- L'état peut changer sans action du carnet (réparé par le serveur) : argent et stock suivent
	local desabonner = session:surChangement(function(e)
		if e.etape == "carnet" then
			rafraichir()
		end
	end)
	return function()
		desabonner()
		fermerChoix()
	end
end
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces (touche un échantillon pour voir le rouleau). Le tissu en trop reste dans ton stock.",
```

par :

```lua
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces. Touche un échantillon pour voir le rouleau.",
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
			Text = "Les pièces sont rangées en rangées, droit-fil parfait. À la table de découpe, tu les places toi-même : bien rangées, elles prennent moins de tissu.",
```

par :

```lua
			Text = "Les pièces sont posées rang par rang, au droit-fil. À la table de découpe, tu les places toi-même : bien serrées, elles prennent moins de tissu. Le tissu en trop reste dans ton stock.",
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	local lignes = {}
	local quantites = {}
```

par :

```lua
	local lignes = {}
	local quantites = {}
	local stocksVus = {} -- stock de chaque tissu au dernier calcul de la quantité proposée
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		quantites[idTissu] = math.max(0, conseil(idTissu) - (etat.stock[idTissu] or 0))
```

par :

```lua
		stocksVus[idTissu] = etat.stock[idTissu] or 0
		quantites[idTissu] = math.max(0, conseil(idTissu) - stocksVus[idTissu])
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
			local r = session:acheter(idTissu, q)
			if r.ok then
				quantites[idTissu] = 0
				majLigne(idTissu)
				ctx.message
```

par :

```lua
			local r = session:acheter(idTissu, q)
			if r.ok then
				ctx.message
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	-- L'état peut changer sans achat (réparé par le serveur) : les lignes suivent
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			majLigne(idTissu)
		end
	end)
```

par :

```lua
	-- Le stock change (achat, ou état réparé par le serveur) : la quantité proposée est ce qui manque encore
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			local stock = etat.stock[idTissu] or 0
			if stock ~= stocksVus[idTissu] then
				stocksVus[idTissu] = stock
				quantites[idTissu] = math.max(0, conseil(idTissu) - stock)
			end
			majLigne(idTissu)
		end
	end)
```

- [ ] **Step 5: Le départ signale une erreur d'écriture**

Dans `src/server/Commande.luau`, remplacer :

```lua
	pcall(self.enregistrer, self, joueur, true, Commande.ESSAIS_ECRITURE)
	self:retirer(joueur)
```

par :

```lua
	local ok, erreur = pcall(self.enregistrer, self, joueur, true, Commande.ESSAIS_ECRITURE)
	if not ok then
		warn(("[Atelier] %s : erreur en écrivant sa partie au départ : %s"):format(joueur.Name, tostring(erreur)))
	end
	self:retirer(joueur)
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105099 vérifications
TOUT EST VERT : 411 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/client/Atelier/Scene.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/EcranAchat.luau src/server/Commande.luau tests/unitaires/20_scene.luau tests/unitaires/40_sauvegarde_serie.luau tests/scenario.luau
git commit -m "Métrage sous les jauges, carnet et achat qui suivent l'état, nouvel essai de pièce sans toucher la photo, départ qui signale une erreur

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le sous-projet 1 terminé.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan4d3Depot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Côté client (`execute_luau`), lire `SoundService.Atelier_musique` : `IsLoaded`, `IsPlaying`, `TimeLength`.
2. Appuyer sur E, attendre 1 s, lire `SoundService.Atelier_clochette.IsLoaded` et `TimeLength`.
3. Côté serveur, lire la position des pièces `Volant`, `Aiguille`, `TapisDecoupe` de `workspace.Rue.Boutique_1` dans le repère `Boutique.emplacement(1)`.
4. Relever les alertes (`get_console_output`).

Expected :
- musique chargée et jouée (durée d'environ 133 s) ;
- clochette chargée (environ 2,8 s) ;
- volant vers (8,2 ; 4,35 ; 51), aiguille vers (6,15 ; 3,6 ; 50,8), tapis vers (−6 ; 3,03 ; 51) ;
- aucune alerte hors « Lieu non publié : les parties ne sont pas sauvegardées. ».

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

Ces vérifications demandent l'interface de Studio ou un téléphone :
- écouter les sons et régler leurs volumes à l'oreille ;
- regarder la table et la machine dans la boutique ;
- jouer une robe sur téléphone : lisibilité des textes à l'échelle réduite, avatar immobile fenêtre ouverte.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (plan 4d-2)
```

par :

```markdown
## État actuel (sous-projet 1 terminé, plan 4d-3)
```

Dans `README.md`, remplacer :

```markdown
9. La suite : sons, réglages mobiles, équilibrage, mobilier (plan 4d-3).
```

par :

```markdown
9. La suite : sous-projet 2, clientes et progression (prise de mesures, clientes qui reviennent, déblocages,
   équilibrage des prix).
```

Dans `README.md`, remplacer :

```markdown
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.
```

par :

```markdown
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.

**Sons** : une musique d'ambiance, un petit clic à chaque bouton, la clochette, la caisse, les ciseaux, la
machine à coudre (tant qu'on coud, au rythme de la vitesse), le tissu qu'on découd, les décorations, le
déclic de la photo et la réaction de la cliente. Tout vient de la bibliothèque libre de Roblox (sons de
l'interface de Roblox, Pro Sound Effects, APM Music) ; le bouton « Son », sous « Atelier », coupe tout.

**Téléphone et clavier** : tant que la fenêtre de l'atelier est ouverte, l'avatar ne bouge pas (le stick et
le bouton de saut ne passent pas sous la fenêtre) ; on la ferme pour se promener dans la rue. La fenêtre se
réduit pour tenir dans l'écran.
```

Dans `README.md`, remplacer :

```markdown
  comptoir et clochette, étagère de tissus, table, machine), et le socle de sa vitrine, qui porte la
```

par :

```markdown
  comptoir et clochette, étagère de tissus, table de découpe sur pieds avec son tapis quadrillé, son rouleau
  et ses ciseaux, machine à coudre sur son meuble, avec son volant et sa bobine), et le socle de sa vitrine, qui porte la
```

Dans `README.md`, remplacer :

```markdown
  la robe épinglée, l'aperçu des décorations, les réglages de la photo et la caméra du poste ;
  un module `Ecran…` par étape.
```

par :

```markdown
  la robe épinglée, l'aperçu des décorations, les réglages de la photo et la caméra du poste ; `Sons` joue
  les bruits et la musique ; un module `Ecran…` par étape.
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105099 vérifications
TOUT EST VERT : 411 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4d-3 terminé : sous-projet 1 (le cœur de l'atelier) complet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
