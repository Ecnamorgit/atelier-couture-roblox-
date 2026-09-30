# Aiguille & Dentelle — Plan 14 : finitions du sous-projet 5

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Traiter les points mineurs laissés par les relectures des plans 11 à 13, et ce que l'essai dans Studio a montré une fois la vue 3D revenue : un chat qui ressemble à un chat qui dort, une une de gazette moins vide, des échantillons blancs visibles sur l'affiche.

**Architecture:** aucune notion nouvelle. `Croquis.details` dit à quelle partie appartient chaque trait (`Pixels.croquis` ne le trace que sur elle) ; `UiKit.pourcent` arrondit vers le bas la qualité affichée ; l'accueil ferme ses panneaux empilés par une seule fonction qui ignore le second appui d'un double clic ; le chat du serveur gagne yeux, nez, arrière-train et des oreilles vues de face ; la une de la gazette gagne un encart « À l'atelier ».

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` ; ce plan ne change aucune règle. Les points viennent des registres des plans 11, 12 et 13 (« minor (deferred) ») et de l'essai dans Studio.

## Décisions de ce plan

- **Retenus** : le croisé du cache-cœur tracé sur le col Claudine (plan 11) ; le test « mémoire pleine » qui remplaçait la fonction au lieu d'épuiser la mémoire des images, et la remise en tête d'un croquis revu jamais vérifiée (plan 11) ; « 80 % » affiché avec trois étoiles entre 79,5 et 79,99 % (plan 12) ; le commentaire de la « Suite » qui parlait encore de la bulle (plan 12) ; « Nouveau rang » vérifié à la vente seulement (plan 12) ; le double clic sur « Fermer » de la gazette qui fermait aussi la suite de l'histoire (plan 13) ; le chat vérifié d'un seul côté de la rue (plan 13) ; la note de licence du ronron sans son auteur, des lignes trop longues (plan 13) ; les cœurs du chat en police par défaut (plan 13).
- **Vu dans Studio** (la vue 3D revenue) : les oreilles du chat se voyaient de profil (des plaques) et sa queue dépassait comme un bâton ; la une de la gazette restait vide sous l'épilogue ; l'échantillon de l'organza blanc disparaissait sur la carte blanche de l'affiche. Retouchés à vue dans Studio avant d'en fixer les valeurs.
- **Laissés** : le même merci dans l'encadré (3 s) et le panneau « Suite » (qui reste lisible après son départ) ; l'astuce « argent ± 1 » du scénario (elle vérifie ce qu'il faut) ; la justification des confettis dans le plan 12 (le choix tient).
- **Qualité affichée** : arrondie vers le bas à l'arrondi près (`math.floor(q × 100 + 1e-7)`), à l'annonce, à la vente et à la présentation : le chiffre, les étoiles et le jugement de la cliente sont toujours d'accord.
- **Relu avant exécution** : un relecteur a lu le brouillon ; corrigés avant d'écrire ce plan : la queue du chat pivotait depuis l'intérieur de sa tête (elle part maintenant de l'arrière-train, le long du flanc) ; l'arrondi de la qualité n'était vérifié qu'isolément (un test rend l'accueil à 79,96 %) ; la marge d'arrondi (1e-9 sur la qualité, comme les étoiles) ; le test des oreilles, les messages des tests, le texte de l'encart.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; onze variantes du brouillon (traits sur toute la robe, qualité arrondie au plus proche, marge d'arrondi trop large, annonce arrondie au plus proche, file simple des croquis, double clic qui traverse, cœurs visibles d'emblée, oreilles de profil, queue dans la tête, une sans nouvelles, cartes sans liseré) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `finitions-sp5`, créée depuis `main` (où le plan 13 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi, contenu original.

## Review Focus

- **Robe à 79,9 % de qualité.** Attendu : « 79 % », trois étoiles, et la cliente qui l'a jugée sous 80 %. Test : `57_reputation` (« toujours d'accord »).
- **Double clic sur « Fermer » d'un panneau empilé.** Attendu : seul le panneau du dessus se ferme. Test : scénario (« la suite de l'histoire de Colette, lisible »).
- **Cache-cœur avec col Claudine.** Attendu : le croisé s'arrête sous le col. Test : `56_croquis`.
- **Un croquis revu parmi beaucoup d'autres.** Attendu : il reste gardé tant qu'il est parmi les six derniers vus. Test : `17_vignettes`.
- **Le chat des deux côtés de la rue.** Attendu : même allure et même place dans chaque boutique. Test : `34_boutiques` (boutiques 3 et 6).

---

### Task 1: Le carnet et la qualité affichée

**Files:**
- Modify: `src/shared/Croquis.luau`, `src/shared/Pixels.luau`, `src/client/Atelier/UiKit.luau`, `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/EcranPresentation.luau`
- Create: `tests/unitaires/59_accueil_qualite.luau`
- Modify: `tests/unitaires/56_croquis.luau`, `tests/unitaires/17_vignettes.luau`, `tests/unitaires/57_reputation.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Croquis.details`, `Pixels.croquis`, `Progression.etoiles`, l'écran `EcranAccueil` (existants) ; `M.budget.images` (simulation).
- Produces: `Croquis.details(croquis) -> { { a, b, famille } }` ; `UiKit.pourcent(qualite) -> entier`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/59_accueil_qualite.luau` :

```lua
-- Plan 14 : l'annonce de l'accueil montre la qualité arrondie vers le bas, d'accord avec les étoiles de la cliente
-- (une robe à 79,96 % s'annonce « 79 % », avec trois étoiles), à la livraison comme à la vente
local UiKit = U.module("UiKit")
local EtatAtelier = U.module("EtatAtelier")
local EcranAccueil = U.module("EcranAccueil")

local fenetre = Instance.new("Frame")
local contenu = Instance.new("Frame")
contenu.Parent = fenetre
local function annonce(action, qualite)
	contenu:ClearAllChildren()
	local reponse = { ok = true, reussie = true, verse = 50, paie = 50, prix = 50, bilan = { qualite = qualite } }
	local fermer = EcranAccueil({
		UiKit = UiKit,
		contenu = contenu,
		fenetre = fenetre,
		message = function() end,
		refus = function() end,
		session = { etat = EtatAtelier.nouveau(100), derniere = { action = action, reponse = reponse } },
	})
	if fermer then
		fermer()
	end
	local a = contenu:FindFirstChild("Annonce")
	return a and a.Text or ""
end

local livree = annonce("livrer", 0.7996)
U.verifier(string.find(livree, "★★★☆☆", 1, true) ~= nil and string.find(livree, "(qualité 79 %)", 1, true) ~= nil, "livrée à 79,96 % : trois étoiles et « 79 % » (" .. livree .. ")")
livree = annonce("livrer", 0.9)
U.verifier(string.find(livree, "★★★★★", 1, true) ~= nil and string.find(livree, "(qualité 90 %)", 1, true) ~= nil, "livrée à 90 % : cinq étoiles et « 90 % »")
local vendue = annonce("vendre", 0.7996)
U.verifier(string.find(vendue, "(qualité 79 %)", 1, true) ~= nil, "vendue à 79,96 % : « 79 % » (" .. vendue .. ")")
```

Dans `tests/unitaires/56_croquis.luau`, remplacer :

```lua
U.verifier(trait, "un trait de crayon foncé au bord de la jupe")
```

par :

```lua
U.verifier(trait, "un trait de crayon foncé au bord de la jupe")

-- Les traits de détail ne passent que sur leur propre partie : le croisé du cache-cœur s'arrête sous le col
do
	local croquisCroise = { corsage = "corsage_cache_coeur", manches = "manches_sans", col = "col_claudine", jupe = "jupe_droite" }
	local image = Pixels.croquis(croquisCroise, {}, L, H)
	local fin, surLeCol = 0, 0
	for j = 0, H - 1 do
		for i = 0, L - 1 do
			local v = buffer.readu32(image, (j * L + i) * 4)
			if v % 256 == 120 and math.floor(v / 256) % 256 == 100 and math.floor(v / 65536) % 256 == 106 and math.floor(v / 16777216) == 255 then
				fin += 1
				if Croquis.partieA(croquisCroise, (i + 0.5) * Croquis.LARGEUR / L, (j + 0.5) * Croquis.HAUTEUR / H) == "col" then
					surLeCol += 1
				end
			end
		end
	end
	U.verifier(fin > 0 and surLeCol == 0, "le croisé du cache-cœur ne passe pas sur le col Claudine (" .. surLeCol .. " points sur " .. fin .. ")")
	for _, s in ipairs(Croquis.details(croquisCroise)) do
		U.verifier(s.famille == "corsage", "chaque trait de détail sait à quelle partie il appartient")
	end
end
```

Dans `tests/unitaires/17_vignettes.luau`, remplacer :

```lua
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 9, "après sept autres croquis, le premier est repeint : on ne garde que les derniers (" .. peints .. " peints)")
	Pixels.croquis = peindre
```

par :

```lua
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 9, "après sept autres croquis, le premier est repeint : on ne garde que les derniers (" .. peints .. " peints)")
	-- Un croquis revu repasse en tête : il reste gardé tant qu'il est parmi les derniers vus
	for _, id in ipairs({ "coton_blanc", "coton_rose_pois", "lin_naturel", "lin_bleu", "coton_bleu_carreaux" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130) -- revu : en tête
	peints = 0
	for _, id in ipairs({ "lin_noir", "coton_jaune_fleurs", "coton_blanc" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 3, "un croquis revu repasse en tête et reste gardé : seuls les trois nouveaux sont peints (" .. peints .. " peints)")
	Pixels.croquis = peindre
```

Dans `tests/unitaires/57_reputation.luau`, remplacer :

```lua
-- Réputation : un titre par niveau de prestige (1 à 8), tous différents
```

par :

```lua
-- La qualité affichée ne contredit jamais les étoiles ni le jugement : arrondie vers le bas (79,9 % : « 79 % »)
do
	local UiKit = U.module("UiKit")
	U.verifier(UiKit.pourcent(0.7999) == 79 and UiKit.pourcent(0.8 - 1e-12) == 80 and UiKit.pourcent(1) == 100 and UiKit.pourcent(0) == 0, "le pourcentage affiché, arrondi vers le bas (à l'arrondi près)")
	-- (la même marge que les étoiles : juste sous 80 % de plus que 1e-9, trois étoiles et « 79 % » ; de moins, quatre et « 80 % »)
	U.verifier(UiKit.pourcent(0.8 - 5e-9) == 79 and Progression.etoiles(true, 0.8 - 5e-9) == 3 and UiKit.pourcent(0.8 - 5e-10) == 80 and Progression.etoiles(true, 0.8 - 5e-10) == 4, "la même marge d'arrondi que les étoiles")
	local accords = 0
	for q = 0, 10000 do
		local qualite = q / 10000
		local n, affiche = Progression.etoiles(true, qualite), UiKit.pourcent(qualite)
		if (n >= 3) == (affiche >= 60) and (n >= 4) == (affiche >= 80) and (n >= 5) == (affiche >= 90) then
			accords += 1
		end
	end
	U.verifier(accords == 10001, "les étoiles et le pourcentage affiché sont toujours d'accord (" .. accords .. ")")
end

-- Réputation : un titre par niveau de prestige (1 à 8), tous différents
```

Dans `tests/scenario.luau`, remplacer :

```lua
	-- Mémoire des images pleine : un mot à la place du dessin (pas l'ancien), le carnet marche quand même
	VignettesCarnet.croquis = function()
		return nil
	end
	cliquer("Suivant_col")
	verifier(dessin.SansDessin.Visible and dessin.ImageTransparency == 1 and page.Modele_col.Text ~= colAvant, "mémoire des images pleine : un mot à la place du dessin, les modèles se choisissent quand même")
	VignettesCarnet.croquis = peindre
	cliquer("Precedent_col")
```

par :

```lua
	-- Mémoire des images pleine (Roblox refuse une image de plus) : un mot à la place du dessin (pas l'ancien), le
	-- carnet marche quand même
	local budgetImages = M.budget.images
	M.budget.images = 0
	cliquer("Suivant_col")
	verifier(dessin.SansDessin.Visible and dessin.ImageTransparency == 1 and page.Modele_col.Text ~= colAvant, "mémoire des images pleine : un mot à la place du dessin, les modèles se choisissent quand même")
	M.budget.images = budgetImages
	cliquer("Precedent_col")
```

Dans `tests/scenario.luau`, remplacer :

```lua
dorees == n and n >= 2, ("Colette remercie dans l'encadré, avec son avis : %d étoiles (qualité %d %%)"):format(dorees, math.floor(qualite * 100 + 0.5)))
```

par :

```lua
dorees == n and n >= 2, ("Colette remercie dans l'encadré, avec son avis : %d étoiles (qualité %d %%)"):format(dorees, requireModule(scriptClient.UiKit).pourcent(qualite)))
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `sur le col Claudine (13 points sur 45)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Croquis.luau`, remplacer :

```lua
function Croquis.details(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		for _, s in ipairs(forme.details or {}) do
			table.insert(out, s)
			if forme.symetrique then
				table.insert(out, miroirSegment(s))
			end
		end
	end
	return out
end
```

par :

```lua
function Croquis.details(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		for _, s in ipairs(forme.details or {}) do
			-- chaque trait sait à quelle partie il appartient : il ne se trace que sur elle
			table.insert(out, { s[1], s[2], famille = famille })
			if forme.symetrique then
				local m = miroirSegment(s)
				table.insert(out, { m[1], m[2], famille = famille })
			end
		end
	end
	return out
end
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
-- Traits de détail (plis, croisé) du croquis : { { a, b } }
```

par :

```lua
-- Traits de détail (plis, croisé) du croquis : { { a, b, famille } }
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
	local function tracer(segment, couleur, surLaRobe)
		local a, b = segment[1], segment[2]
		local pas = math.max(1, math.ceil(math.sqrt(((b.x - a.x) * ex) ^ 2 + ((b.y - a.y) * ey) ^ 2) * 2))
		for t = 0, pas do
			local i = math.floor((a.x + (b.x - a.x) * t / pas) * ex)
			local j = math.floor((a.y + (b.y - a.y) * t / pas) * ey)
			if i >= 0 and j >= 0 and i < largeur and j < hauteur and (etiquette(i, j) > 0) == surLaRobe then
				buffer.writeu32(buf, (j * largeur + i) * 4, couleur)
			end
		end
	end
	local fin = empaqueter(CRAYON_FIN[1], CRAYON_FIN[2], CRAYON_FIN[3])
	for _, s in ipairs(Croquis.details(croquis)) do
		tracer(s, fin, true)
	end
	local esquisse = empaqueterAlpha(ESQUISSE[1], ESQUISSE[2], ESQUISSE[3], ESQUISSE[4])
	for _, s in ipairs(Croquis.MANNEQUIN) do
		tracer(s, esquisse, false)
	end
```

par :

```lua
	-- famille : le trait ne passe que sur cette partie de la robe (nil : que hors de la robe, le mannequin)
	local function tracer(segment, couleur, famille)
		local a, b = segment[1], segment[2]
		local pas = math.max(1, math.ceil(math.sqrt(((b.x - a.x) * ex) ^ 2 + ((b.y - a.y) * ey) ^ 2) * 2))
		for t = 0, pas do
			local i = math.floor((a.x + (b.x - a.x) * t / pas) * ex)
			local j = math.floor((a.y + (b.y - a.y) * t / pas) * ey)
			if i >= 0 and j >= 0 and i < largeur and j < hauteur then
				local k = etiquette(i, j)
				if (famille == nil and k == 0) or (famille ~= nil and k > 0 and parties[k].famille == famille) then
					buffer.writeu32(buf, (j * largeur + i) * 4, couleur)
				end
			end
		end
	end
	local fin = empaqueter(CRAYON_FIN[1], CRAYON_FIN[2], CRAYON_FIN[3])
	for _, s in ipairs(Croquis.details(croquis)) do
		tracer(s, fin, s.famille)
	end
	local esquisse = empaqueterAlpha(ESQUISSE[1], ESQUISSE[2], ESQUISSE[3], ESQUISSE[4])
	for _, s in ipairs(Croquis.MANNEQUIN) do
		tracer(s, esquisse, nil)
	end
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
-- L'avis d'une cliente en étoiles (1 à 5) : « ★★★★☆ »
```

par :

```lua
-- Une qualité (0 à 1) en pourcentage affiché, arrondi vers le bas (à l'arrondi près, comme les étoiles) : 79,9 % s'affiche « 79 % »,
-- comme la cliente le juge (et comme ses étoiles)
function UiKit.pourcent(qualite)
	return math.floor(qualite * 100 + 1e-7) -- (1e-9 sur la qualité, comme les étoiles et le jugement)
end

-- L'avis d'une cliente en étoiles (1 à 5) : « ★★★★☆ »
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
```

par :

```lua
			r.verse or r.paie,
			UiKit.pourcent(r.bilan.qualite)
		)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, math.floor(r.bilan.qualite * 100 + 0.5))
```

par :

```lua
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, UiKit.pourcent(r.bilan.qualite))
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
			then ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5))
			else ("Qualité de la robe : %d %% (ajustement %d %%)"):format(math.floor(bilan.qualite * 100 + 0.5), math.floor(bilan.ajustement * 100 + 0.5)),
```

par :

```lua
			then ("Qualité de la robe : %d %%"):format(UiKit.pourcent(bilan.qualite))
			else ("Qualité de la robe : %d %% (ajustement %d %%)"):format(UiKit.pourcent(bilan.qualite), math.floor(bilan.ajustement * 100 + 0.5)),
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167833 vérifications
TOUT EST VERT : 833 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Croquis.luau src/shared/Pixels.luau src/client/Atelier/UiKit.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranPresentation.luau tests/unitaires/56_croquis.luau tests/unitaires/17_vignettes.luau tests/unitaires/57_reputation.luau tests/unitaires/59_accueil_qualite.luau tests/scenario.luau
git commit -m "Carnet : chaque pli sur sa partie ; qualité affichée arrondie vers le bas, d'accord avec les étoiles ; tests de la mémoire des images

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'accueil et le chat, petits défauts

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/Chat.luau`, `src/client/Atelier/Sons.luau`, `README.md`
- Modify: `tests/scenario.luau`, `tests/unitaires/34_boutiques.luau`

**Interfaces:**
- Consumes: `UiKit.DELAI_NOUVEAU`, `Progression.texteRang` (existants).
- Produces: rien de nouveau (une fonction locale `fermerPanneau` dans l'accueil).

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("FermerEpilogue")
local suite = fenetre.Contenu.Suite
```

par :

```lua
cliquer("FermerEpilogue")
boutonNomme("FermerSuite").Activated:Fire() -- second appui d'un double clic : il tombe sur le « Fermer » de dessous
local suite = fenetre.Contenu.Suite
```

Dans `tests/scenario.luau`, remplacer :

```lua
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 5
cliquer("Livrer")
```

par :

```lua
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 5
serveur:atelier(joueur).etat.ventes = 24 -- (vingt-neuf robes en tout : celle-ci, la trentième, fait monter le rang)
cliquer("Livrer")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
```

par :

```lua
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
verifier(texte("Nouveau rang : Première main !") ~= nil, "la trentième robe livrée : « Nouveau rang : Première main ! »")
serveur:atelier(joueur).etat.ventes = 0
```

Dans `tests/scenario.luau`, remplacer :

```lua
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_ronron" and chat.Tete:FindFirstChild("Coeurs") ~= nil, "caresser le chat : il ronronne, des cœurs montent")
```

par :

```lua
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_ronron" and chat.Tete:FindFirstChild("Coeurs") ~= nil, "caresser le chat : il ronronne, des cœurs montent")
	local coeur = chat.Tete.Coeurs:FindFirstChild("Coeur1")
	verifier(coeur ~= nil and coeur.Font == Enum.Font.GothamBold and coeur.TextTransparency == 1, "les cœurs, dans la police du jeu, invisibles avant de monter")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
do -- Sous-projet 5 : le chat de l'atelier, sur son coussin près de la fenêtre ; « Caresser » (touche F)
	local chat = b3:FindFirstChild("Chat")
```

par :

```lua
for _, n in ipairs({ 3, 6 }) do -- Sous-projet 5 : le chat de l'atelier (des deux côtés de la rue), sur son coussin près de la fenêtre
	local boutique = monde.Rue:FindFirstChild("Boutique_" .. n)
	local chat = boutique:FindFirstChild("Chat")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
and chat:FindFirstChild("Queue") ~= nil, "un chat sur son coussin : un corps, une tête, une queue")
```

par :

```lua
and chat:FindFirstChild("Queue") ~= nil, "boutique " .. n .. " : un chat sur son coussin, un corps, une tête, une queue")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
and invite.MaxActivationDistance <= 7, "« Caresser », touche F (E sonne la clochette), sans appui long, de près (pas à travers le mur du voisin)")
```

par :

```lua
and invite.MaxActivationDistance <= 7, "boutique " .. n .. " : « Caresser », touche F (E sonne la clochette), sans appui long, de près (pas à travers le mur du voisin)")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
	U.verifier(bloquent == 0, "le chat ne gêne pas le passage")
```

par :

```lua
	U.verifier(bloquent == 0, "boutique " .. n .. " : le chat ne gêne pas le passage")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
	local p = Boutique.emplacement(3):PointToObjectSpace(chat.Coussin.CFrame.Position)
```

par :

```lua
	local p = Boutique.emplacement(n):PointToObjectSpace(chat.Coussin.CFrame.Position)
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
	U.verifier(dans and presFenetre and horsVitrine, "dans la boutique, près de la fenêtre, à côté du socle de la vitrine")
```

par :

```lua
	U.verifier(dans and presFenetre and horsVitrine, "boutique " .. n .. " : le chat dans la boutique, près de la fenêtre, à côté du socle de la vitrine")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : sous l'épilogue : la suite de l'histoire de Colette, lisible`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- Des nouveautés viennent de s'ouvrir : l'affiche « Nouveautés à l'atelier ! »
```

par :

```lua
	-- La gazette, la suite de l'histoire et l'affiche s'empilent, leurs « Fermer » au même coin : le second appui
	-- d'un double clic sur celui du dessus ne ferme pas aussi le panneau de dessous
	local panneauFerme = -math.huge
	local function fermerPanneau(panneau)
		return function()
			if os.clock() - panneauFerme < UiKit.DELAI_NOUVEAU then
				return
			end
			panneauFerme = os.clock()
			panneau.Visible = false
		end
	end
	-- Des nouveautés viennent de s'ouvrir : l'affiche « Nouveautés à l'atelier ! »
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Size = UDim2.fromOffset(100, 32), ZIndex = 22, Parent = affiche }, function()
			affiche.Visible = false
		end)
```

par :

```lua
Size = UDim2.fromOffset(100, 32), ZIndex = 22, Parent = affiche }, fermerPanneau(affiche))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente (sa réplique « merci »), dans un panneau (la
	-- bulle ne la montre que le temps de son départ) ; sous l'épilogue quand l'événement a lieu
```

par :

```lua
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente (sa réplique « merci »), dans un panneau
	-- (l'encadré de dialogue ne la montre que le temps de son départ) ; sous l'épilogue quand l'événement a lieu
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Size = UDim2.fromOffset(110, 34), ZIndex = 22, Parent = suite }, function()
			suite.Visible = false
		end)
```

par :

```lua
Size = UDim2.fromOffset(110, 34), ZIndex = 22, Parent = suite }, fermerPanneau(suite))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Size = UDim2.fromOffset(100, 32), ZIndex = 24, Parent = epilogue }, function()
			epilogue.Visible = false
		end)
```

par :

```lua
Size = UDim2.fromOffset(100, 32), ZIndex = 24, Parent = epilogue }, fermerPanneau(epilogue))
```

Dans `src/client/Atelier/Chat.luau`, remplacer :

```lua
		c.Text = "♥"
		c.TextColor3 = ROSE
```

par :

```lua
		c.Text = "♥"
		c.Font = Enum.Font.GothamBold
		c.TextTransparency = 1 -- (invisible jusqu'à ce qu'il monte)
		c.TextColor3 = ROSE
```

Dans `src/client/Atelier/Sons.luau`, remplacer :

```lua
-- Sons : les bruits de l'atelier et la musique. Tout vient de la bibliothèque libre de Roblox : sons de
-- l'interface de Roblox, effets de Pro Sound Effects, musique d'APM Music (sous licence pour les jeux
-- Roblox ; le ronron du chat : « cat purring », de la boutique des créateurs) ; rien n'est repris de Dressmaker. Chaque son est un objet Sound de SoundService (entendu par ce
-- joueur seulement), créé une fois. « actif » coupe tout (bouton « Son » à gauche de l'écran).
```

par :

```lua
-- Sons : les bruits de l'atelier et la musique. Tout vient de la bibliothèque libre de Roblox : sons de
-- l'interface de Roblox, effets de Pro Sound Effects, musique d'APM Music (sous licence pour les jeux
-- Roblox) ; le ronron du chat, lui, est un envoi d'un créateur de la boutique de Roblox (« cat purring », de
-- Bloonkii) : il pourrait être retiré, le chat se tairait alors. Rien n'est repris de Dressmaker. Chaque son est
-- un objet Sound de SoundService (entendu par ce joueur seulement), créé une fois. « actif » coupe tout (bouton
-- « Son » à gauche de l'écran).
```

Dans `src/client/Atelier/Sons.luau`, remplacer :

```lua
	ronron = 17867246413, -- boutique des créateurs de Roblox : « cat purring », le chat qu'on caresse
```

par :

```lua
	ronron = 17867246413, -- boutique des créateurs (Bloonkii) : « cat purring », 3 s, le chat qu'on caresse
```

Dans `README.md`, remplacer :

```markdown
l'interface de Roblox, Pro Sound Effects, APM Music, et pour le chat « cat purring », de la boutique des créateurs) ;
le bouton « Son »
```

par :

```markdown
l'interface de Roblox, Pro Sound Effects, APM Music ; pour le chat, « cat purring », envoyé par Bloonkii sur
la boutique des créateurs de Roblox) ; le bouton « Son »
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167837 vérifications
TOUT EST VERT : 836 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/Chat.luau src/client/Atelier/Sons.luau README.md tests/scenario.luau tests/unitaires/34_boutiques.luau
git commit -m "Accueil : un double clic sur « Fermer » ne ferme que le panneau du dessus ; le rang à la livraison vérifié ; cœurs du chat dans la police du jeu

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Ce que Studio a montré

**Files:**
- Modify: `src/server/Boutiques.luau`, `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/Chat.luau`
- Modify: `tests/unitaires/34_boutiques.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `bloc`, `rgb` de `Boutiques` ; `Progression.titreReputation`, `Progression.texteRang`.
- Produces: dans le modèle `Chat` : `Arriere`, `Oeil1`, `Oeil2`, `Nez`, la queue replacée (sa base, le bout −X, contre l'arrière-train ; `Chat.luau` la fait remuer de ±0,35 rad) ; dans la une : `Nouvelles`, `FiletBas` ; un `UIStroke` sur l'image de chaque carte de l'affiche.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
	U.verifier(chat ~= nil and chat:FindFirstChild("Coussin") ~= nil and chat:FindFirstChild("Tete") ~= nil and chat:FindFirstChild("Queue") ~= nil, "boutique " .. n .. " : un chat sur son coussin, un corps, une tête, une queue")
```

par :

```lua
	U.verifier(chat ~= nil and chat:FindFirstChild("Coussin") ~= nil and chat:FindFirstChild("Tete") ~= nil and chat:FindFirstChild("Queue") ~= nil, "boutique " .. n .. " : un chat sur son coussin, un corps, une tête, une queue")
	-- (vu dans Studio) un chat qui dort : les yeux fermés, un nez, un arrière-train ; les oreilles, deux triangles vus
	-- de face (un coin tourné d'un quart de tour)
	local regard = (Boutique.emplacement(n) * Boutique.CHAT).LookVector
	local deFace = true
	for k = 1, 2 do
		local oreille = chat:FindFirstChild("Oreille" .. k)
		deFace = deFace and oreille ~= nil and math.abs(oreille.CFrame.RightVector:Dot(regard)) > 0.99 -- (le triangle a pour normale son X)
	end
	U.verifier(chat:FindFirstChild("Oeil1") ~= nil and chat:FindFirstChild("Oeil2") ~= nil and chat:FindFirstChild("Nez") ~= nil and chat:FindFirstChild("Arriere") ~= nil and deFace, "boutique " .. n .. " : les yeux fermés, le nez, l'arrière-train, les oreilles de face")
	-- la queue part de l'arrière-train, et son bout, au repos comme en remuant, n'entre ni dans le corps ni dans la tête
	local queue, arriere = chat.Queue, chat.Arriere
	local base = (queue.CFrame * CFrame.new(-queue.Size.X / 2, 0, 0)).Position
	local horsDuCorps = true
	for _, angle in ipairs({ 0, 0.35, -0.35 }) do
		local bout = (queue.CFrame * CFrame.new(-queue.Size.X / 2, 0, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(queue.Size.X, 0, 0)).Position
		for _, nom in ipairs({ "Corps", "Tete" }) do
			horsDuCorps = horsDuCorps and (bout - chat[nom].CFrame.Position).Magnitude > chat[nom].Size.X / 2
		end
	end
	U.verifier((base - arriere.CFrame.Position).Magnitude <= arriere.Size.X / 2 + queue.Size.Y and horsDuCorps, "boutique " .. n .. " : la queue part de l'arrière-train, son bout ne rentre ni dans le corps ni dans la tête")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(une.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and fenetre.Contenu.Affiche.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border, "le filet de la gazette et le cadre de l'affiche entourent le panneau (pas son texte vide)")
```

par :

```lua
	verifier(une.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and fenetre.Contenu.Affiche.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border, "le filet de la gazette et le cadre de l'affiche entourent le panneau (pas son texte vide)")
	do -- En bas de la une, les nouvelles de l'atelier : sa réputation et le rang de la couturière
		local P, etatNouvelles = requireModule(dossier.Progression), requireModule(scriptClient.Session).courante.etat
		local nouvelles = une:FindFirstChild("Nouvelles")
		verifier(nouvelles ~= nil and une:FindFirstChild("FiletBas") ~= nil and string.find(nouvelles.Text:lower(), P.titreReputation(P.niveauPrestige(etatNouvelles.prestige)):lower(), 1, true) ~= nil and string.find(nouvelles.Text, P.texteRang(etatNouvelles.livraisons + etatNouvelles.ventes), 1, true) ~= nil, "la une : un filet, puis les nouvelles de l'atelier (" .. tostring(nouvelles and nouvelles.Text) .. ")")
	end
```

Dans `tests/scenario.luau`, remplacer :

```lua
and cartes == 5 and echantillons == 4 and affiche.Nouveau_dentelle_noire.Nom.Text == "Dentelle noire", 
```

par :

```lua
and cartes == 5 and echantillons == 4 and affiche.Nouveau_dentelle_noire.Nom.Text == "Dentelle noire" and affiche.Nouveau_dentelle_noire.Image:FindFirstChild("UIStroke") ~= nil, 
```

Dans `tests/scenario.luau`, remplacer :

```lua
"l'affiche des nouveautés : cinq cartes, l'échantillon des quatre satins (" .. cartes .. ", " .. echantillons .. ")")
```

par :

```lua
"l'affiche des nouveautés : cinq cartes, l'échantillon des quatre satins, un liseré autour (" .. cartes .. ", " .. echantillons .. ")")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : boutique 3 : les yeux fermés, le nez, l'arrière-train, les oreilles de face`

- [ ] **Step 3: Écrire le code**

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	bloc(chat, repere, "Tete", Vector3.new(-0.1, 0.9, -0.75), Vector3.new(0.95, 0.95, 0.95), ROUX, { forme = Enum.PartType.Ball, decor = true })
	for k, x in ipairs({ -0.35, 0.15 }) do
		bloc(chat, repere, "Oreille" .. k, Vector3.new(x, 1.42, -0.75), Vector3.new(0.12, 0.32, 0.28), ROUX_FONCE, { forme = Enum.PartType.Wedge, decor = true })
	end
	local queue = bloc(chat, repere, "Queue", Vector3.new(0.5, 0.55, -0.6), Vector3.new(1.3, 0.25, 0.25), ROUX_FONCE, { forme = Enum.PartType.Cylinder, decor = true })
	queue.CFrame = queue.CFrame * CFrame.Angles(0, math.rad(35), 0) -- enroulée devant elle
```

par :

```lua
	bloc(chat, repere, "Arriere", Vector3.new(0.25, 0.75, 0.55), Vector3.new(1.2, 1.2, 1.2), ROUX, { forme = Enum.PartType.Ball, decor = true })
	bloc(chat, repere, "Tete", Vector3.new(-0.1, 0.9, -0.75), Vector3.new(0.95, 0.95, 0.95), ROUX, { forme = Enum.PartType.Ball, decor = true })
	for k, x in ipairs({ -0.35, 0.15 }) do
		-- un coin tourné d'un quart de tour : son triangle se voit de face
		local oreille = bloc(chat, repere, "Oreille" .. k, Vector3.new(x, 1.42, -0.8), Vector3.new(0.1, 0.34, 0.3), ROUX_FONCE, { forme = Enum.PartType.Wedge, decor = true })
		oreille.CFrame = oreille.CFrame * CFrame.Angles(0, math.rad(if k == 1 then 90 else -90), 0)
	end
	for k, dx in ipairs({ -0.17, 0.17 }) do -- les yeux fermés : il dort
		bloc(chat, repere, "Oeil" .. k, Vector3.new(-0.1 + dx, 0.97, -1.2), Vector3.new(0.16, 0.035, 0.03), rgb(70, 40, 30), { decor = true })
	end
	bloc(chat, repere, "Nez", Vector3.new(-0.1, 0.86, -1.22), Vector3.new(0.09, 0.09, 0.09), rgb(230, 130, 150), { forme = Enum.PartType.Ball, decor = true })
	-- la queue le long de son flanc, sur le coussin : sa base (le bout −X, autour duquel elle remue) contre
	-- l'arrière-train, le bout vers l'avant
	local queue = bloc(chat, repere, "Queue", Vector3.new(0.75, 0.42, -0.12), Vector3.new(1.35, 0.24, 0.24), ROUX_FONCE, { forme = Enum.PartType.Cylinder, decor = true })
	queue.CFrame = queue.CFrame * CFrame.Angles(0, math.rad(95), 0)
```

Dans `src/client/Atelier/Chat.luau`, remplacer :

```lua
			queue.CFrame = base * CFrame.Angles(0, math.sin(ecoule * 9) * 0.45, 0) * CFrame.new(queue.Size.X / 2, 0, 0)
```

par :

```lua
			queue.CFrame = base * CFrame.Angles(0, math.sin(ecoule * 9) * 0.35, 0) * CFrame.new(queue.Size.X / 2, 0, 0)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			local motif = tissu and Vignettes.motif(n.id)
			if motif then
				image.ImageContent = motif
			end
```

par :

```lua
			UiKit.creer("UIStroke", { Color = Color3.fromRGB(226, 208, 196), Thickness = 1, Parent = image }) -- (un tissu blanc sur la carte blanche)
			local motif = tissu and Vignettes.motif(n.id)
			if motif then
				image.ImageContent = motif
			end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", 
```

par :

```lua
		-- En bas de la une, les nouvelles de l'atelier : sa réputation et le rang de la couturière
		UiKit.texte({ Name = "Nouvelles", Text = ("À l'atelier : réputation %s ; rang : %s."):format(Progression.titreReputation(Progression.niveauPrestige(etat.prestige)):lower(), Progression.texteRang(etat.livraisons + etat.ventes)), Font = Enum.Font.Merriweather, TextSize = 16, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 16, 1, -92), Size = UDim2.new(1, -32, 0, 36), ZIndex = 23, Parent = epilogue })
		UiKit.creer("Frame", { Name = "FiletBas", BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0, 16, 1, -100), Size = UDim2.new(1, -32, 0, 1), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", 
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167841 vérifications
TOUT EST VERT : 837 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Boutiques.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/Chat.luau tests/unitaires/34_boutiques.luau tests/scenario.luau
git commit -m "Le chat qui dort (yeux fermés, nez, oreilles de face) ; les nouvelles de l'atelier en bas de la une ; un liseré aux échantillons de l'affiche

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan14Depot.rbxl`) et l'ouvrir dans Studio. En mode édition, par `execute_luau` : construire une boutique (module `Boutiques` du serveur, joueur factice) et capturer son chat de face (`screen_capture` avec une position de caméra) ; rendre l'accueil dans un ScreenGui d'essai (tri par frère, comme le jeu) avec la livraison des régates au prestige 6, capturer la une puis l'affiche ; tout détruire.

Expected : un chat roux qui dort sur son coussin (yeux fermés, nez rose, oreilles en triangle, arrière-train, la queue le long de son flanc) ; la une avec le filet d'encre, les deux colonnes et « À l'atelier : réputation … ; rang : … » au-dessus du souvenir ; l'affiche et son cadre rose, l'organza blanc visible sur sa carte. Fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 5 terminé côté code, plans 11 à 13 : la fidélité à la présentation de *Dressmaker*)
```

par :

```markdown
## État actuel (sous-projet 5 terminé côté code, plans 11 à 14 : la fidélité à la présentation de *Dressmaker*)
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167841 vérifications
TOUT EST VERT : 837 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 14 terminé : finitions du sous-projet 5

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
