# Aiguille & Dentelle — Plan 13 : gazette, affiche des nouveautés, chat de l'atelier

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Terminer le sous-projet 5 : quand un événement a lieu, son épilogue fait la une d'un journal du quartier ; quand des tissus, modèles ou décorations s'ouvrent, une affiche « Nouveautés à l'atelier ! » les montre ; un chat roux dort dans chaque boutique, et on peut le caresser.

**Architecture:** `Histoire` gagne le nom du journal et `enColonnes` (le texte coupé en deux colonnes équilibrées) ; l'accueil (`EcranAccueil`) remplace le panneau de l'épilogue par la une de la gazette, et ajoute l'affiche des nouveautés (sous la gazette et la suite de l'histoire) ; le serveur (`Boutiques`) pose dans chaque boutique un chat en quelques pièces, avec une invite de proximité « Caresser » ; un module client `Chat` répond à l'invite (ronron, queue qui remue, cœurs), pour le seul joueur qui caresse. Aucune règle ne change.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` (sections 4 — gazette, affiche, chat — et 5 ; plan 13 de la section 6).

## Décisions de ce plan

- **Gazette** : « La Gazette du Dé » ; sous le titre, « N° k — Jour n de l'atelier — Édition du quartier » (k : le rang de l'événement, n : les robes livrées ou vendues, faute de calendrier dans le jeu) ; le titre de l'épilogue (« Le bal des lanternes a eu lieu ! ») ; l'épilogue en deux colonnes, coupé à la fin de la phrase la plus proche du milieu si elle n'en est pas à plus d'un cinquième du texte, sinon à l'espace le plus proche ; le souvenir et le prestige gagnés en bas. Polices Garamond (journal) et Merriweather (texte), encre sur papier journal. Les noms `Epilogue`, `TitreEpilogue`, `Souvenir`, `FermerEpilogue` restent.
- **Affiche** : après une livraison, une vente ou un cadeau qui ouvre quelque chose ; une carte par nouveauté, huit au plus (quatre par ligne), l'échantillon de chaque tissu, « Modèle » ou « Décoration » sinon ; au-delà, « Et encore N autres nouveautés. ». Elle est sous la gazette et la suite de l'histoire (ZIndex 20), et E ne sonne pas la clochette tant qu'elle est ouverte. La ligne « Nouveau : » de l'annonce reste.
- **Chat** : sur un coussin framboise près de la fenêtre, à côté du socle de la vitrine (`Boutique.CHAT`) ; en boules, coin et cylindre (corps, tête, oreilles, queue), rien ne bloque le passage. L'invite « Caresser » se déclenche à la touche F (E sonne la clochette), sans appui long, à 10 studs. Une caresse à la fois : 2,5 s de ronron, la queue qui remue autour de sa base, cinq cœurs qui montent en s'effaçant. Le son vient de la boutique des créateurs de Roblox (« cat purring », 17867246413) : aucune bibliothèque officielle n'a de ronron ; à écouter par le commanditaire.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; quatorze variantes du brouillon (coupe au milieu brut, coupe sans les phrases, une seule colonne, sans numéro, pas d'affiche, affiche sans échantillons, affiche sans limite, clochette malgré l'affiche, invite sur E, coussin qui bloque, chat sur la vitrine, chat muet, caresses superposées, queue qui ne revient pas) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `gazette-chat`, créée depuis `main` (où le plan 12 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker* ; le journal, l'affiche et le chat sont les nôtres.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Épilogue à une seule longue phrase, ou à une phrase finale très courte.** Attendu : deux colonnes équilibrées quand même. Test : `52_histoire` (« une fin de phrase trop loin du milieu »).
- **Un événement qui ouvre aussi un niveau de prestige.** Attendu : la gazette, puis la suite de l'histoire, puis l'affiche, chacune se referme. Test : scénario (« sous la gazette, l'affiche », « sous la suite de l'histoire, l'affiche des nouveautés »).
- **Plus de huit nouveautés d'un coup.** Attendu : huit cartes et « Et encore N autres nouveautés. ». Test : scénario (« huit cartes »).
- **Deux caresses coup sur coup.** Attendu : une seule caresse à la fois, puis la queue revient au repos. Test : scénario (« une caresse à la fois », « la queue au repos »).
- **Le chat dans chacune des huit boutiques, des deux côtés de la rue.** Attendu : dans la boutique, près de la fenêtre, sans gêner. Test : `34_boutiques` (la boutique 3, de l'autre côté de la rue).

---

### Task 1: La gazette du quartier

**Files:**
- Modify: `src/shared/Histoire.luau`, `src/client/Atelier/EcranAccueil.luau`
- Modify: `tests/unitaires/52_histoire.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Histoire.get`, `Histoire.titreEpilogue`, `ev.rang`, `Histoire.PRESTIGE_EVENEMENT` (existants).
- Produces: `Histoire.GAZETTE` ; `Histoire.enColonnes(texte) -> colonne1, colonne2` ; dans `fenetre.Contenu.Epilogue` : `Journal`, `Date`, `TitreEpilogue`, `Colonne1`, `Colonne2`, `Souvenir`, `FermerEpilogue`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
U.verifier(string.find(Histoire.get("bal_hiver").epilogue, "Dehors", 1, true) ~= nil, "bal d'hiver : la neige tombe dehors")
```

par :

```lua
U.verifier(string.find(Histoire.get("bal_hiver").epilogue, "Dehors", 1, true) ~= nil, "bal d'hiver : la neige tombe dehors")

-- Sous-projet 5 : la gazette du quartier donne l'épilogue en deux colonnes, coupé à la fin de la phrase la plus
-- proche du milieu (à défaut, à l'espace le plus proche)
local a, b = Histoire.enColonnes("Un. Deux trois quatre. Cinq six. Sept huit neuf dix.")
U.verifier(a == "Un. Deux trois quatre." and b == "Cinq six. Sept huit neuf dix.", "coupé à la fin de la phrase la plus proche du milieu")
a, b = Histoire.enColonnes("Une très longue première phrase qui prend presque toute la place du texte. Fin.")
U.verifier(math.abs(#a - #b) <= 8 and a .. " " .. b == "Une très longue première phrase qui prend presque toute la place du texte. Fin.", "une fin de phrase trop loin du milieu : coupé à l'espace le plus proche")
a, b = Histoire.enColonnes("une seule phrase sans point final assez longue")
U.verifier(a .. " " .. b == "une seule phrase sans point final assez longue" and math.abs(#a - #b) <= 8, "sans phrase : coupé à l'espace le plus proche du milieu")
a, b = Histoire.enColonnes("Court")
U.verifier(a == "Court" and b == "", "un mot : une seule colonne")
for _, ev in ipairs(Histoire.EVENEMENTS) do
	a, b = Histoire.enColonnes(ev.epilogue)
	U.verifier(a ~= "" and b ~= "" and a .. " " .. b == ev.epilogue and #a <= 0.75 * #ev.epilogue and #b <= 0.75 * #ev.epilogue, ev.id .. " : l'épilogue en deux colonnes équilibrées (" .. #a .. " et " .. #b .. ")")
end
U.verifier(Histoire.GAZETTE == "La Gazette du Dé", "le journal du quartier")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte(Histoire.get("lanternes").epilogue) ~= nil and laColette.Head.Bulle.Texte.Text == def.repliques.merci, "l'épilogue ; Colette raconte la suite")
```

par :

```lua
do -- Sous-projet 5 : l'épilogue est la une de la gazette du quartier
	local une = fenetre.Contenu.Epilogue
	local e1, e2 = Histoire.enColonnes(Histoire.get("lanternes").epilogue)
	verifier(une.Journal.Text == Histoire.GAZETTE and string.match(une.Date.Text, "^N° 1 — Jour %d+ de l'atelier") ~= nil and une.Colonne1.Text == e1 and une.Colonne2.Text == e2 and une.Colonne2.Position.X.Scale == 0.5, "la une de la gazette : le journal, le numéro et le jour, l'épilogue en deux colonnes")
	verifier(laColette.Head.Bulle.Texte.Text == def.repliques.merci, "Colette raconte la suite")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Histoire.luau`, remplacer :

```lua
-- « Le bal des lanternes a eu lieu ! », « Les régates du lac ont eu lieu ! »
function Histoire.titreEpilogue(ev)
	return ("%s %s eu lieu !"):format(ev.nom, if ev.pluriel then "ont" else "a")
end
```

par :

```lua
-- « Le bal des lanternes a eu lieu ! », « Les régates du lac ont eu lieu ! »
function Histoire.titreEpilogue(ev)
	return ("%s %s eu lieu !"):format(ev.nom, if ev.pluriel then "ont" else "a")
end

-- Sous-projet 5 : quand un événement a lieu, son épilogue fait la une du journal du quartier, en deux colonnes
Histoire.GAZETTE = "La Gazette du Dé"

-- Le texte en deux colonnes : coupé à la fin de la phrase la plus proche du milieu, si elle n'en est pas à plus
-- d'un cinquième du texte (sinon, à l'espace le plus proche du milieu) ; renvoie les deux morceaux (le second est
-- vide pour un seul mot)
function Histoire.enColonnes(texte)
	local milieu, coupe = #texte / 2, nil
	local function essayer(p)
		if not coupe or math.abs(p - milieu) < math.abs(coupe - milieu) then
			coupe = p
		end
	end
	for p in texte:gmatch("[%.!?]() ") do
		if math.abs(p - milieu) <= #texte / 5 then
			essayer(p)
		end
	end
	if not coupe then
		for p in texte:gmatch("() ") do
			essayer(p)
		end
	end
	if not coupe then
		return texte, ""
	end
	return texte:sub(1, coupe - 1), texte:sub(coupe + 1)
end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- Un événement vient d'avoir lieu : son épilogue et son souvenir, par-dessus l'accueil
	local eu = r and action == "livrer" and r.evenement
	if eu then
		local epilogue = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Epilogue", Text = "", AutoButtonColor = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "TitreEpilogue", Text = Histoire.titreEpilogue(Histoire.get(eu.id)), Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.accent, Size = UDim2.new(1, -130, 0, 34), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "TexteEpilogue", Text = eu.epilogue, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", Text = ("Souvenir : %s (une nouvelle décoration). Prestige : +%d."):format(souvenir and souvenir.nom or eu.souvenir, Histoire.PRESTIGE_EVENEMENT), TextSize = 16, Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 44), ZIndex = 23, Parent = epilogue })
		UiKit.boutonDoux({ Name = "FermerEpilogue", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 23, Parent = epilogue }, function()
			epilogue.Visible = false
		end)
	end
```

par :

```lua
	-- Un événement vient d'avoir lieu : la une de la gazette du quartier, par-dessus l'accueil (le journal, son numéro
	-- et le jour de l'atelier, le titre, l'épilogue en deux colonnes, le souvenir gagné)
	local eu = r and action == "livrer" and r.evenement
	if eu then
		local ev = Histoire.get(eu.id)
		local PAPIER, ENCRE = Color3.fromRGB(244, 238, 222), Color3.fromRGB(44, 36, 32)
		local epilogue = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Epilogue", Text = "", AutoButtonColor = false, BackgroundColor3 = PAPIER, Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = ctx.contenu }), 4)
		UiKit.creer("UIStroke", { Color = ENCRE, Thickness = 2, Parent = epilogue })
		UiKit.texte({ Name = "Journal", Text = Histoire.GAZETTE, Font = Enum.Font.Garamond, TextSize = 42, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 46), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "Date", Text = ("N° %d — Jour %d de l'atelier — Édition du quartier"):format(ev.rang, etat.livraisons + etat.ventes), Font = Enum.Font.Garamond, TextSize = 16, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 20), ZIndex = 23, Parent = epilogue })
		for k, y in ipairs({ 80, 84 }) do -- le double filet sous le titre du journal
			UiKit.creer("Frame", { Name = "Filet" .. k, BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0, 16, 0, y), Size = UDim2.new(1, -32, 0, k), ZIndex = 23, Parent = epilogue })
		end
		UiKit.texte({ Name = "TitreEpilogue", Text = Histoire.titreEpilogue(ev), Font = Enum.Font.Merriweather, TextSize = 26, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 36), ZIndex = 23, Parent = epilogue })
		local colonne1, colonne2 = Histoire.enColonnes(eu.epilogue)
		UiKit.texte({ Name = "Colonne1", Text = colonne1, Font = Enum.Font.Merriweather, TextSize = 16, TextColor3 = ENCRE, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(24, 146), Size = UDim2.new(0.5, -40, 0, 170), ZIndex = 23, Parent = epilogue })
		UiKit.creer("Frame", { Name = "Separation", BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0.5, -1, 0, 146), Size = UDim2.fromOffset(1, 160), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "Colonne2", Text = colonne2, Font = Enum.Font.Merriweather, TextSize = 16, TextColor3 = ENCRE, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.new(0.5, 16, 0, 146), Size = UDim2.new(0.5, -40, 0, 170), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", Text = ("Souvenir : %s (une nouvelle décoration). Prestige : +%d."):format(souvenir and souvenir.nom or eu.souvenir, Histoire.PRESTIGE_EVENEMENT), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 16, 1, -54), Size = UDim2.new(1, -32, 0, 24), ZIndex = 23, Parent = epilogue })
		UiKit.boutonDoux({ Name = "FermerEpilogue", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(100, 32), ZIndex = 24, Parent = epilogue }, function()
			epilogue.Visible = false
		end)
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167802 vérifications
TOUT EST VERT : 816 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/52_histoire.luau tests/scenario.luau
git commit -m "La Gazette du Dé : l'épilogue d'un événement fait la une du journal du quartier, en deux colonnes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'affiche des nouveautés

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `r.nouveaux` (`{ genre, id, nom }`, de `Deblocages.nouveaux`), `Vignettes.motif`, `Catalogue.tissu` (existants).
- Produces: `fenetre.Contenu.Affiche` : `TitreAffiche`, `SousTitre`, les cartes `Nouveau_<id>` (`Image`, `Nom`, `Genre`), `EtEncore`, `FermerAffiche`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Acompte de ") ~= nil and texte("(niveau 3 !)") ~= nil and texte("Nouveau : les satins (4), Dentelle noire.") ~= nil, "l'accueil rappelle l'acompte, le niveau de prestige atteint et ce qui vient de s'ouvrir")
```

par :

```lua
verifier(texte("Acompte de ") ~= nil and texte("(niveau 3 !)") ~= nil and texte("Nouveau : les satins (4), Dentelle noire.") ~= nil, "l'accueil rappelle l'acompte, le niveau de prestige atteint et ce qui vient de s'ouvrir")
do -- Sous-projet 5 : l'affiche des nouveautés, une carte par nouveauté (l'échantillon de chaque tissu)
	local affiche = fenetre.Contenu:FindFirstChild("Affiche")
	local cartes, echantillons = 0, 0
	for _, c in ipairs(affiche and affiche:GetChildren() or {}) do
		if c.Name:match("^Nouveau_") then
			cartes += 1
			echantillons += if c.Image.ImageContent ~= nil and c.Image.ImageContent.statique then 1 else 0
		end
	end
	verifier(affiche ~= nil and affiche.Visible and affiche.TitreAffiche.Text == "Nouveautés à l'atelier !" and cartes == 5 and echantillons == 4 and affiche.Nouveau_dentelle_noire.Nom.Text == "Dentelle noire", "l'affiche des nouveautés : cinq cartes, l'échantillon des quatre satins (" .. cartes .. ", " .. echantillons .. ")")
	M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
	verifier(titre() == "Aiguille & Dentelle", "E ne sonne pas la clochette tant que l'affiche est ouverte")
	cliquer("FermerAffiche")
	verifier(not affiche.Visible, "l'affiche se referme")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "Aiguille & Dentelle" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
```

par :

```lua
verifier(titre() == "Aiguille & Dentelle" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
verifier(fenetre.Contenu:FindFirstChild("Affiche") == nil, "rien de nouveau : pas d'affiche")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(laColette.Head.Bulle.Texte.Text == def.repliques.merci, "Colette raconte la suite")
end
```

par :

```lua
	verifier(laColette.Head.Bulle.Texte.Text == def.repliques.merci, "Colette raconte la suite")
	-- (le prestige 6 ouvre plus de huit nouveautés : huit cartes, et le reste en une ligne)
	local affiche, cartes = fenetre.Contenu.Affiche, 0
	for _, c in ipairs(affiche:GetChildren()) do
		cartes += if c.Name:match("^Nouveau_") then 1 else 0
	end
	local n = #requireModule(scriptClient.Session).courante.derniere.reponse.nouveaux
	verifier(affiche.Visible and n > 8 and cartes == 8 and affiche.EtEncore.Text == ("Et encore %d autres nouveautés."):format(n - 8), "sous la gazette, l'affiche : huit cartes, et « Et encore " .. (n - 8) .. " autres nouveautés. »")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("FermerSuite")
```

par :

```lua
cliquer("FermerSuite")
verifier(fenetre.Contenu.Affiche.Visible, "sous la suite de l'histoire, l'affiche des nouveautés")
cliquer("FermerAffiche")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `l'échantillon des quatre satins (0, 0)`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Histoire = require(Couture:WaitForChild("Histoire"))
```

par :

```lua
local Histoire = require(Couture:WaitForChild("Histoire"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente
```

par :

```lua
	-- Des nouveautés viennent de s'ouvrir : l'affiche « Nouveautés à l'atelier ! », une carte par nouveauté (huit au
	-- plus), avec l'échantillon de chaque tissu ; sous la gazette et la suite de l'histoire, s'il y en a
	local nouveaux = r and (action == "livrer" or action == "vendre" or action == "offrir") and r.nouveaux
	if nouveaux and #nouveaux > 0 then
		local CARTES, GENRES = 8, { tissus = "Tissu", variantes = "Modèle", accessoires = "Décoration" }
		local affiche = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Affiche", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 244, 218), Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.creer("UIStroke", { Color = C.accent, Thickness = 3, Parent = affiche })
		UiKit.texte({ Name = "TitreAffiche", Text = "Nouveautés à l'atelier !", Font = Enum.Font.GothamBlack, TextSize = 30, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 40), ZIndex = 21, Parent = affiche })
		UiKit.texte({ Name = "SousTitre", Text = "Ta réputation grandit : voici ce qui vient d'arriver.", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 22), ZIndex = 21, Parent = affiche })
		for k, n in ipairs(nouveaux) do
			if k > CARTES then
				break
			end
			local ligneCarte, colonne = (k - 1) // 4, (k - 1) % 4
			local carte = UiKit.arrondir(UiKit.creer("Frame", { Name = "Nouveau_" .. n.id, BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.new(colonne * 0.25, 8, 0, 92 + ligneCarte * 152), Size = UDim2.new(0.25, -16, 0, 142), ZIndex = 21, Parent = affiche }), 8)
			local tissu = n.genre == "tissus" and Catalogue.tissu(n.id)
			local image = UiKit.arrondir(UiKit.creer("ImageLabel", { Name = "Image", BackgroundColor3 = if tissu then UiKit.couleur(tissu.motif.couleurs[1]) else C.secondaire, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(76, 76), ZIndex = 22, Parent = carte }), 8)
			local motif = tissu and Vignettes.motif(n.id)
			if motif then
				image.ImageContent = motif
			end
			if not tissu then
				UiKit.texte({ Name = "Genre", Text = GENRES[n.genre] or "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 23, Parent = image })
			end
			UiKit.texte({ Name = "Nom", Text = n.nom, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 92), Size = UDim2.new(1, -12, 0, 40), ZIndex = 22, Parent = carte })
		end
		if #nouveaux > CARTES then
			UiKit.texte({ Name = "EtEncore", Text = ("Et encore %d autres nouveautés."):format(#nouveaux - CARTES), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(1, 0, 0, 24), ZIndex = 21, Parent = affiche })
		end
		UiKit.boutonDoux({ Name = "FermerAffiche", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(100, 32), ZIndex = 22, Parent = affiche }, function()
			affiche.Visible = false
		end)
	end
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses) : sonner la clochette
	local function panneauOuvert()
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses" }) do
```

par :

```lua
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses, affiche des nouveautés) : sonner la clochette
	local function panneauOuvert()
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses", "Affiche" }) do
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167802 vérifications
TOUT EST VERT : 824 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau tests/scenario.luau
git commit -m "Affiche « Nouveautés à l'atelier ! » : une carte par nouveauté, l'échantillon de chaque tissu

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le chat de l'atelier

**Files:**
- Create: `src/client/Atelier/Chat.luau`
- Modify: `src/shared/Boutique.luau`, `src/server/Boutiques.luau`, `src/client/Atelier/Sons.luau`, `src/client/Atelier/init.client.luau`
- Modify: `tests/unitaires/34_boutiques.luau`, `tests/unitaires/41_sons.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `bloc` et `rgb` de `Boutiques` (existants), `ProximityPromptService.PromptTriggered`, `Sons.jouer`.
- Produces: `Boutique.CHAT` ; dans chaque boutique, le modèle `Chat` (`Coussin`, `Corps` et son invite `Caresser`, `Tete`, `Oreille1`, `Oreille2`, `Queue`) ; `Chat.brancher(ProximityPromptService, Sons)`, `Chat.caresser(chat, Sons)`, `Chat.DUREE` ; `Sons.IDS.ronron`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
U.verifier(meubles, "sol, murs, vitre, comptoir et clochette, étagère, table de découpe, machine, enseigne")
```

par :

```lua
U.verifier(meubles, "sol, murs, vitre, comptoir et clochette, étagère, table de découpe, machine, enseigne")
do -- Sous-projet 5 : le chat de l'atelier, sur son coussin près de la fenêtre ; « Caresser » (touche F)
	local chat = b3:FindFirstChild("Chat")
	local corps = chat and chat:FindFirstChild("Corps")
	local invite = corps and corps:FindFirstChild("Caresser")
	U.verifier(chat ~= nil and chat:FindFirstChild("Coussin") ~= nil and chat:FindFirstChild("Tete") ~= nil and chat:FindFirstChild("Queue") ~= nil, "un chat sur son coussin : un corps, une tête, une queue")
	U.verifier(invite ~= nil and invite:IsA("ProximityPrompt") and invite.ActionText == "Caresser" and invite.KeyboardKeyCode == Enum.KeyCode.F and invite.HoldDuration == 0, "« Caresser », touche F (E sonne la clochette), sans appui long")
	local p = Boutique.emplacement(3):PointToObjectSpace(chat.Coussin.CFrame.Position)
	local demi = chat.Coussin.Size.X / 2
	local vitrine = Boutique.VITRINE.Position
	local dans = math.abs(p.X) + demi < Boutique.LARGEUR / 2 and p.Z - demi > Boutique.AVANT and p.Z + demi < Boutique.FOND
	local presFenetre = p.X > Boutique.FENETRE[1] and p.Z < Boutique.AVANT + 8
	local horsVitrine = math.abs(p.X - vitrine.X) >= 2 + demi or math.abs(p.Z - vitrine.Z) >= 2 + demi
	U.verifier(dans and presFenetre and horsVitrine, "dans la boutique, près de la fenêtre, à côté du socle de la vitrine")
	local bloquent = 0
	for _, d in ipairs(chat:GetDescendants()) do
		bloquent += if d:IsA("BasePart") and d.CanCollide ~= false then 1 else 0 -- (explicitement : Roblox fait tout bloquer par défaut)
	end
	U.verifier(bloquent == 0, "le chat ne gêne pas le passage")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- La touche E sonne la clochette, fenêtre ouverte seulement (comme au comptoir)
```

par :

```lua
do -- Sous-projet 5 : le chat de l'atelier ; une caresse le fait ronronner, remuer la queue, et des cœurs montent
	local chat = maBoutique.Chat
	local queue = chat.Queue
	local repos = queue.CFrame
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_ronron" and chat.Tete:FindFirstChild("Coeurs") ~= nil, "caresser le chat : il ronronne, des cœurs montent")
	M.avancer(0.2)
	verifier(queue.CFrame ~= repos, "il remue la queue")
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	local nCoeurs = 0
	for _, c in ipairs(chat.Tete:GetChildren()) do
		nCoeurs += if c.Name == "Coeurs" then 1 else 0
	end
	verifier(nCoeurs == 1, "une caresse à la fois")
	M.avancer(3)
	verifier(chat.Tete:FindFirstChild("Coeurs") == nil and queue.CFrame == repos, "puis il se rendort, la queue au repos")
end
-- La touche E sonne la clochette, fenêtre ouverte seulement (comme au comptoir)
```

Dans `tests/unitaires/41_sons.luau`, remplacer :

```lua
U.verifier(Sons.IDS.fete ~= nil, "un son de fête (la robe terminée)")
```

par :

```lua
U.verifier(Sons.IDS.fete ~= nil, "un son de fête (la robe terminée)")
U.verifier(Sons.IDS.ronron ~= nil, "le ronron du chat")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : un chat sur son coussin : un corps, une tête, une queue`

- [ ] **Step 3: Écrire le module du client**

Créer `src/client/Atelier/Chat.luau` :

```lua
-- Chat (sous-projet 5) : le chat roux de chaque boutique, qu'on caresse (invite « Caresser », touche F) : il
-- ronronne, remue la queue et de petits cœurs montent au-dessus de sa tête. Pour le plaisir seulement : rien ne
-- part au serveur, seul le joueur qui le caresse le voit et l'entend.
local RunService = game:GetService("RunService")

local Chat = {}
Chat.DUREE = 2.5 -- secondes de ronron
Chat.COEURS = 5
local ROSE = Color3.fromRGB(236, 92, 146)

-- Les invites « Caresser » de tous les chats de la rue ; sons : le module Sons
function Chat.brancher(ProximityPromptService, Sons)
	return ProximityPromptService.PromptTriggered:Connect(function(invite)
		if invite.Name == "Caresser" and invite.Parent and invite.Parent.Parent then
			Chat.caresser(invite.Parent.Parent, Sons)
		end
	end)
end

-- Une caresse (une à la fois par chat)
function Chat.caresser(chat, Sons)
	local tete, queue = chat:FindFirstChild("Tete"), chat:FindFirstChild("Queue")
	if not tete or chat:GetAttribute("Caresse") then
		return
	end
	chat:SetAttribute("Caresse", true)
	Sons.jouer("ronron")
	-- Les cœurs, au-dessus de la tête, montent en s'effaçant
	local coeurs = Instance.new("BillboardGui")
	coeurs.Name = "Coeurs"
	coeurs.Size = UDim2.fromOffset(90, 110)
	coeurs.StudsOffset = Vector3.new(0, 1.6, 0)
	coeurs.LightInfluence = 0
	coeurs.Parent = tete
	local rng = Random.new()
	local morceaux = {}
	for k = 1, Chat.COEURS do
		local c = Instance.new("TextLabel")
		c.Name = "Coeur" .. k
		c.BackgroundTransparency = 1
		c.Text = "♥"
		c.TextColor3 = ROSE
		c.TextSize = rng:NextInteger(18, 28)
		c.Size = UDim2.fromOffset(30, 30)
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Parent = coeurs
		morceaux[k] = { objet = c, x = rng:NextNumber(0.15, 0.85), depart = (k - 1) / Chat.COEURS }
	end
	-- La queue remue autour de sa base
	local repos = queue and queue.CFrame
	local base = queue and repos * CFrame.new(-queue.Size.X / 2, 0, 0)
	local ecoule, connexion = 0, nil
	connexion = RunService.RenderStepped:Connect(function(dt)
		ecoule += dt
		if ecoule >= Chat.DUREE or not chat.Parent then
			connexion:Disconnect()
			coeurs:Destroy()
			if queue then
				queue.CFrame = repos
			end
			chat:SetAttribute("Caresse", nil)
			return
		end
		if queue then
			queue.CFrame = base * CFrame.Angles(0, math.sin(ecoule * 9) * 0.45, 0) * CFrame.new(queue.Size.X / 2, 0, 0)
		end
		for _, m in ipairs(morceaux) do
			local t = math.clamp((ecoule / Chat.DUREE) * 1.6 - m.depart, 0, 1)
			m.objet.Position = UDim2.fromScale(m.x, 1 - t)
			m.objet.TextTransparency = if t <= 0 then 1 else t * 0.9
		end
	end)
end

return Chat
```

- [ ] **Step 4: Le chat dans chaque boutique, le son, l'invite**

Dans `src/shared/Boutique.luau`, remplacer :

```lua
-- La boîte aux lettres, sur le comptoir (le courrier, sous-projet 2)
```

par :

```lua
-- Le chat de l'atelier (sous-projet 5), sur son coussin près de la fenêtre, à côté du socle de la vitrine ; il
-- regarde vers l'atelier (−Z de son repère)
Boutique.CHAT = CFrame.lookAt(Vector3.new(10.2, 0, 36.5), Vector3.new(0, 0, 36.5))
-- La boîte aux lettres, sur le comptoir (le courrier, sous-projet 2)
```

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	bobine.CFrame = bobine.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout sur le bras
	modele.Parent = parent
```

par :

```lua
	bobine.CFrame = bobine.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout sur le bras
	-- Le chat de l'atelier (sous-projet 5) : un chat roux qui dort sur son coussin ; « Caresser » (touche F, E sonne
	-- la clochette) le fait ronronner, chez le joueur qui le caresse seulement (module Chat du client)
	local chat = Instance.new("Model")
	chat.Name = "Chat"
	local repere = origine * Boutique.CHAT
	local ROUX, ROUX_FONCE = rgb(222, 132, 62), rgb(186, 96, 40)
	bloc(chat, repere, "Coussin", Vector3.new(0, 0.2, 0), Vector3.new(2.4, 0.4, 2.4), rgb(176, 64, 96), { decor = true })
	local corps = bloc(chat, repere, "Corps", Vector3.new(0, 0.95, 0.15), Vector3.new(1.5, 1.5, 1.5), ROUX, { forme = Enum.PartType.Ball, decor = true })
	bloc(chat, repere, "Tete", Vector3.new(-0.1, 0.9, -0.75), Vector3.new(0.95, 0.95, 0.95), ROUX, { forme = Enum.PartType.Ball, decor = true })
	for k, x in ipairs({ -0.35, 0.15 }) do
		bloc(chat, repere, "Oreille" .. k, Vector3.new(x, 1.42, -0.75), Vector3.new(0.12, 0.32, 0.28), ROUX_FONCE, { forme = Enum.PartType.Wedge, decor = true })
	end
	local queue = bloc(chat, repere, "Queue", Vector3.new(0.5, 0.55, -0.6), Vector3.new(1.3, 0.25, 0.25), ROUX_FONCE, { forme = Enum.PartType.Cylinder, decor = true })
	queue.CFrame = queue.CFrame * CFrame.Angles(0, math.rad(35), 0) -- enroulée devant elle
	local invite = Instance.new("ProximityPrompt")
	invite.Name = "Caresser"
	invite.ActionText = "Caresser"
	invite.ObjectText = "Le chat"
	invite.KeyboardKeyCode = Enum.KeyCode.F
	invite.HoldDuration = 0
	invite.MaxActivationDistance = 10
	invite.RequiresLineOfSight = false
	invite.Parent = corps
	chat.Parent = modele
	modele.Parent = parent
```

Dans `src/client/Atelier/Sons.luau`, remplacer :

```lua
	fete = 9045129322,
```

par :

```lua
	ronron = 17867246413, -- boutique des créateurs de Roblox : « cat purring », le chat qu'on caresse
	fete = 9045129322,
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Confettis = require(script:WaitForChild("Confettis"))
```

par :

```lua
local Confettis = require(script:WaitForChild("Confettis"))
local Chat = require(script:WaitForChild("Chat"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
Sons.boucle("musique", true)
```

par :

```lua
Sons.boucle("musique", true)
-- Le chat de chaque boutique se caresse (invite « Caresser ») : il ronronne, pour ce joueur seulement
Chat.brancher(game:GetService("ProximityPromptService"), Sons)
```

Dans `src/client/Atelier/Sons.luau`, remplacer :

```lua
-- Roblox) ; rien n'est repris de Dressmaker.
```

par :

```lua
-- Roblox ; le ronron du chat : « cat purring », de la boutique des créateurs) ; rien n'est repris de Dressmaker.
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167808 vérifications
TOUT EST VERT : 828 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/Chat.luau src/shared/Boutique.luau src/server/Boutiques.luau src/client/Atelier/Sons.luau src/client/Atelier/init.client.luau tests/unitaires/34_boutiques.luau tests/unitaires/41_sons.luau tests/scenario.luau
git commit -m "Le chat de l'atelier : il dort sur son coussin près de la fenêtre ; une caresse le fait ronronner

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan13Depot.rbxl`) et l'ouvrir dans Studio. En mode édition, par `execute_luau` : rendre l'accueil dans un ScreenGui d'essai de `StarterGui` avec un faux contexte dont la dernière action est la livraison qui fait avoir lieu le bal des lanternes et ouvre les nouveautés du prestige 6 ; capturer la gazette, la refermer, capturer l'affiche ; détruire le ScreenGui. En Play : attendre 4 s, fermer la fenêtre de l'atelier, placer la caméra devant le chat de la boutique du joueur, déclencher l'invite « Caresser » (`fireproximityprompt` n'existe pas : appuyer sur F près du chat, ou appeler `Chat.caresser` par la barre de commande) et capturer ; relever la console.

Expected : la une du journal (titre du journal, numéro et jour, double filet, titre de l'événement, deux colonnes séparées par un trait, souvenir) ; l'affiche (titre, huit cartes, « Et encore … ») ; le chat roux sur son coussin, près de la fenêtre ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 5 en cours, plans 11 et 12 : le carnet dessiné ; paroles, avis et réputation)
```

par :

```markdown
## État actuel (sous-projet 5 terminé côté code, plans 11 à 13 : la fidélité à la présentation de *Dressmaker*)
```

Dans `README.md`, remplacer :

```markdown
   exigences de style montent avec le prestige. L'accueil annonce ce qui vient de s'ouvrir.
```

par :

```markdown
   exigences de style montent avec le prestige. L'accueil annonce ce qui vient de s'ouvrir, et une affiche
   « Nouveautés à l'atelier ! » le montre (une carte par nouveauté, huit au plus, l'échantillon de chaque tissu).
```

Dans `README.md`, remplacer :

```markdown
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue, un souvenir (une des douze
   décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes ordinaires
   continuent à côté.
```

par :

```markdown
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue fait la une de « La Gazette
   du Dé », le journal du quartier (numéro, jour de l'atelier, titre, texte en deux colonnes), avec un souvenir (une
   des douze décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes
   ordinaires continuent à côté.
   **Le chat** : un chat roux dort sur son coussin près de la fenêtre de chaque boutique ; « Caresser » (touche F)
   le fait ronronner, remuer la queue, et de petits cœurs montent. Pour le plaisir seulement.
```

Dans `README.md`, remplacer :

```markdown
10. La suite : la fin du sous-projet 5 (gazette du quartier, affiche des nouveautés, chat de l'atelier) ;
   porter la robe sur son avatar et les défilés entre joueurs restent à décider.
```

par :

```markdown
10. La suite : porter la robe sur son avatar et les défilés entre joueurs, ou d'autres écarts avec *Dressmaker*
   (mesures à molettes, compteur de mètres, mercerie en stock, robes plus riches) : à décider.
```

Dans `README.md`, remplacer :

```markdown
déclic de la photo, la fête de la robe terminée et la réaction de la cliente. Tout vient de la bibliothèque
libre de Roblox (sons de
```

par :

```markdown
déclic de la photo, la fête de la robe terminée, la réaction de la cliente et le ronron du chat. Tout vient de
la bibliothèque libre de Roblox (sons de
```

Dans `README.md`, remplacer :

```markdown
  pluie de la robe terminée ; `Scene` tient, dans la boutique du joueur, la cliente, le mannequin,
```

par :

```markdown
  pluie de la robe terminée ; `Chat`, les caresses au chat de l'atelier ; `Scene` tient, dans la boutique du
  joueur, la cliente, le mannequin,
```

Dans `README.md`, remplacer :

```markdown
l'interface de Roblox, Pro Sound Effects, APM Music) ; le bouton « Son »
```

par :

```markdown
l'interface de Roblox, Pro Sound Effects, APM Music, et pour le chat « cat purring », de la boutique des créateurs) ;
le bouton « Son »
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167808 vérifications
TOUT EST VERT : 828 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 13 terminé : la gazette du quartier, l'affiche des nouveautés, le chat de l'atelier (sous-projet 5 terminé)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
