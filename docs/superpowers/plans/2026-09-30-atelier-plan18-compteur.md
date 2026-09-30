# Aiguille & Dentelle — Plan 18 : le compteur du rouleau et « Jeter la bande »

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finir le tissu entamé comme dans *Dressmaker* : un compteur en mètres à la table (« 1,30 m entamés / 6,00 m », « Cette robe : +0,80 m (13 po) ») et un bouton pour jeter la bande entamée d'un rouleau.

**Architecture:** l'écran de la table (`EcranDecoupe`) remplace « Entamé : 11 / 30 dm » par un compteur sur deux lignes sous « Couper » (ce qui est entamé, et ce que la robe y ajoute, avec son prix) ; « Jeter la bande » (`UiKit.boutonConfirme`, en bas à droite) appelle `Session:jeterEntame`, visible tant que le rouleau est entamé et qu'aucune pièce de ce tissu n'est coupée pour la robe (`EtatAtelier:coupeDans`, que la règle de `jeterEntame` prend aussi). `Coupon:longueurUtilisee` ne rend plus « -0 ». La ligne d'achat d'un tissu a la place de deux lignes d'information.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` (section 4 ; plan 18 de la section 6, réduit par le plan 17 : les trous grisés, « Proposer » et le tissu neuf à l'achat y sont déjà).

## Décisions de ce plan

- **Unités** : la table compte en mètres, comme la spec (« 1,30 m entamés / 6,00 m ») ; l'achat reste en dm, comme tout l'écran d'achat (« Neuf : 9 dm (11 entamés) »).
- **Compteur** : deux lignes de 14 px sous « Couper » (la place libre entre « Couper » et « Recommencer la robe ») ; la seconde, « Cette robe : +X m (N po) », dit ce que les pièces de cette robe ajoutent à la bande et le prix de ce tissu au mètre (0 si elles tiennent dans les vides). « Droit-fil » prend toute la ligne qu'il partageait.
- **Jeter** : à la table seulement. La ligne d'achat n'a pas la place d'un bouton (nom, conseil, − / +, coût, « Acheter ») ; la bande et ses trous se voient à la table, où l'on décide de la garder ou non. La règle (serveur) permet aussi de jeter à l'achat. Après le second appui : « Bande entamée jetée : 0,60 m de Coton blanc. », et la place de la pièce est proposée de nouveau (le haut du rouleau s'est libéré).
- **« -0 »** : un rouleau vide rendait une longueur de « -0 » (arrondi de `math.ceil`), affichée « -0,00 m » ; `longueurUtilisee` la borne à 0.
- **Téléphone** : mesuré dans Studio pendant la préparation, avec 24 trous pliés (48 silhouettes) : écran construit en 95 ms, « Proposer » au pire en 3,5 ms (sur PC ; un téléphone, 5 à 10 fois plus lent, reste sous le dixième de seconde pour « Proposer »).
- **Mineurs de la relecture du plan 17** : `jeterEntame` regardait les pièces du rouleau et non les pièces coupées de ce tissu (écart après une relecture abîmée) : corrigé par `coupeDans` (tâche 2) ; la ligne d'achat « Conseillé : 27 dm · Neuf : 43 dm (50 entamés) » pouvait passer sur deux lignes dans 24 px : elle a désormais 36 px et va jusqu'au bouton − (tâche 3). L'annonce d'une bande jetée reste testée en deux morceaux (la règle rend `jetees`, l'écran l'annonce) : la jouer de bout en bout demanderait de couper une robe entière à 25 trous au milieu du scénario.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix variantes du brouillon échouent chacune sur la vérification qui les garde ; la table a été rendue dans Studio (compteur sous « Couper », « Jeter la bande » en bas à droite).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `compteur-rouleau`, créée depuis `main` (où le plan 17 et sa relecture sont fusionnés). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Jeter puis couper.** Attendu : le rouleau neuf, la pièce proposée en haut, « Couper » possible. Test : scénario (« la pièce remonte en haut du rouleau neuf », « une place libre proposée »).
- **Un rouleau sans bande.** Attendu : pas de « Jeter la bande ». Test : scénario (« rouleau neuf : pas de »).
- **Un double appui trop rapide sur « Jeter la bande ».** Attendu : il faut un second appui voulu (0,4 s au moins, dans les 3 s). Test : scénario (« premier appui : on demande de confirmer ») ; le délai est celui de `UiKit.boutonConfirme`, déjà testé.
- **Une robe coupée dans les vides de la bande.** Attendu : « Cette robe : +0,00 m (0 po) ». Test : scénario (compteur du coton entamé avant la coupe) et `63_coupon_trous` (`ajout`).
- **Un long compteur (10,00 m).** Attendu : deux lignes qui tiennent dans le panneau. Vérifié à l'œil dans Studio (une ligne fait au plus 25 caractères).

---

### Task 1: Le compteur du rouleau

**Files:**
- Modify: `src/client/Atelier/EcranDecoupe.luau`, `src/shared/Coupon.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `coupon:longueurUtilisee()`, `coupon:ajout()`, `coupon.longueur` (plan 17) ; `Mercerie.metres(cm)` (plan 16) ; `EtatAtelier.prix(idTissu, dm)`.
- Produces: `InfoRouleau` (sous « Couper », deux lignes) : « X m entamés / Y m » puis « Cette robe : +Z m (N po) ».

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(string.find(panneau.InfoRouleau.Text, "Entamé : 0 / ", 1, true) == 1 and not rouleau.Tissu.Entame.Visible, "rien de coupé : rouleau intact")
```

par :

```lua
verifier(string.find(panneau.InfoRouleau.Text, "0,00 m entamés / ", 1, true) == 1 and string.find(panneau.InfoRouleau.Text, "\nCette robe : +0,00 m (0 po)", 1, true) ~= nil and not rouleau.Tissu.Entame.Visible, "rien de coupé : rouleau intact (" .. panneau.InfoRouleau.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
				verifier(c:longueurUtilisee() > 0 and panneau.InfoRouleau.Text == ("Entamé : %d / %d dm"):format(c:longueurUtilisee(), c.longueur), "une pièce coupée : le tissu entamé s'affiche")
```

par :

```lua
				local metres = requireModule(scriptClient.Mercerie).metres
				verifier(c:longueurUtilisee() > 0 and c:ajout() == c:longueurUtilisee() and panneau.InfoRouleau.Text == ("%s m entamés / %s m\nCette robe : +%s m (%d po)"):format(metres(c:longueurUtilisee() * 10), metres(c.longueur * 10), metres(c:ajout() * 10), EtatAtelier.prix("soie_rose_fleurs", c:ajout())), "une pièce coupée : le compteur du rouleau, et ce que cette robe y ajoute (" .. panneau.InfoRouleau.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
fenetre.Contenu.Panneau.InfoRouleau.Text == ("Entamé : 6 / %d dm"):format(c.longueur),
```

par :

```lua
fenetre.Contenu.Panneau.InfoRouleau.Text == ("0,60 m entamés / %s m\nCette robe : +0,00 m (0 po)"):format(requireModule(scriptClient.Mercerie).metres(c.longueur * 10)),
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : rien de coupé : rouleau intact (Entamé : 0 / 14 dm)`

- [ ] **Step 3: Le compteur**

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
local TableDecoupe = require(script.Parent:WaitForChild("TableDecoupe"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
```

par :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local TableDecoupe = require(script.Parent:WaitForChild("TableDecoupe"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
	local infoRouleau = UiKit.texte({ Name = "InfoRouleau", TextSize = 14, TextColor3 = C.texteDoux, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.5, 0, 0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
```

par :

```lua
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(1, 0, 0, 22), Parent = panneau })
	-- (sous-projet 6) le compteur du rouleau, sous « Couper » : ce qui est entamé, et ce que cette robe y ajoute
	local infoRouleau = UiKit.texte({ Name = "InfoRouleau", TextSize = 14, TextColor3 = C.texteDoux, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(0, 396), Size = UDim2.new(1, 0, 0, 34), Parent = panneau })
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
		local entame = coupon:longueurUtilisee()
		infoRouleau.Text = ("Entamé : %d / %d dm"):format(entame, coupon.longueur)
```

par :

```lua
		local entame = coupon:longueurUtilisee()
		infoRouleau.Text = ("%s m entamés / %s m\nCette robe : +%s m (%d po)"):format(Mercerie.metres(entame * 10), Mercerie.metres(coupon.longueur * 10), Mercerie.metres(coupon:ajout() * 10), EtatAtelier.prix(table_.tissu, coupon:ajout()))
```

Dans `src/shared/Coupon.luau`, remplacer :

```lua
-- Longueur de tissu entamée, trous des robes d'avant compris (dm entiers, arrondie au-dessus)
function Coupon:longueurUtilisee()
	return math.ceil(self.basMax - EPSILON)
end
```

par :

```lua
-- Longueur de tissu entamée, trous des robes d'avant compris (dm entiers, arrondie au-dessus ; jamais « -0 »)
function Coupon:longueurUtilisee()
	return math.max(0, math.ceil(self.basMax - EPSILON))
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167985 vérifications
TOUT EST VERT : 949 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranDecoupe.luau src/shared/Coupon.luau tests/scenario.luau
git commit -m "Table de découpe : le compteur du rouleau en mètres, et ce que cette robe ajoute à la bande entamée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: « Jeter la bande »

**Files:**
- Modify: `src/client/Atelier/Session.luau`, `src/client/Atelier/EcranDecoupe.luau`, `src/shared/EtatAtelier.luau`
- Modify: `tests/scenario.luau`, `tests/unitaires/64_bande_entamee.luau`

**Interfaces:**
- Consumes: l'action `jeterEntame(idTissu) -> { ok, dm }` (plan 17) ; `UiKit.boutonConfirme` ; `Deblocages.de`.
- Produces: `session:jeterEntame(idTissu)` ; `etat:coupeDans(idTissu) -> bool` ; à la table, `JeterEntame` (en bas à droite du panneau).

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Proposer")
-- « Plus de tissu » cliqué deux fois très vite : un seul achat
```

par :

```lua
verifier(not fenetre.Contenu.Panneau.JeterEntame.Visible, "rouleau neuf : pas de « Jeter la bande »")
cliquer("Proposer")
-- « Plus de tissu » cliqué deux fois très vite : un seul achat
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Trop de trous : la bande entamée est jetée (Coton blanc, 1,30 m).", "une bande jetée d'elle-même est annoncée")
end
```

par :

```lua
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Trop de trous : la bande entamée est jetée (Coton blanc, 1,30 m).", "une bande jetée d'elle-même est annoncée")
end
do -- (sous-projet 6) « Jeter la bande » : au deuxième appui, la bande de coton quitte le stock, le rouleau repart neuf
	local s = serveur:atelier(joueur).etat
	local avant = s.stock.coton_blanc
	verifier(boutonNomme("JeterEntame").Visible and boutonNomme("JeterEntame").Position.X.Scale == 1, "coton blanc entamé, rien de coupé : « Jeter la bande », en bas à droite")
	cliquer("JeterEntame")
	verifier(s.entames.coton_blanc ~= nil and boutonNomme("JeterEntame").Text == "Vraiment ? Touche encore", "premier appui : on demande de confirmer")
	cliquer("JeterEntame")
	local trous = 0
	for _, d in ipairs(fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren()) do
		trous += if d.Name:match("^Trou_") then 1 else 0
	end
	verifier(s.entames.coton_blanc == nil and s.stock.coton_blanc == avant - 6 and not fenetre.Contenu.Panneau.JeterEntame.Visible and fenetre.Message.Text == "Bande entamée jetée : 0,60 m de Coton blanc.", "second appui : la bande (0,60 m) quitte le stock, le bouton s'en va (" .. fenetre.Message.Text .. ")")
	verifier(trous == 0 and string.find(fenetre.Contenu.Panneau.InfoRouleau.Text, "0,00 m entamés", 1, true) == 1 and fenetre.Contenu.Panneau.Statut.Text == "Place libre : tu peux couper.", "le rouleau repart neuf : plus de trous, une place libre proposée")
	verifier(fenetre.Contenu.Rouleau.Tissu.PieceCourante.Position.Y.Offset < 6 * 36, "la pièce remonte en haut du rouleau neuf (" .. fenetre.Contenu.Rouleau.Tissu.PieceCourante.Position.Y.Offset .. " px)")
end
```

Dans `tests/unitaires/64_bande_entamee.luau`, remplacer :

```lua
U.verifier(copieDeux.coupons.soie_rouge == soieAvant and copieDeux.coupons.coton_blanc.poses.jupe_droite_devant ~= nil, "une pièce coupée dans le coton : le rouleau de soie, inchangé, n'est pas reconstruit")
```

par :

```lua
U.verifier(copieDeux.coupons.soie_rouge == soieAvant and copieDeux.coupons.coton_blanc.poses.jupe_droite_devant ~= nil, "une pièce coupée dans le coton : le rouleau de soie, inchangé, n'est pas reconstruit")

-- (plan 18) Une pièce de ce tissu coupée, même absente du rouleau (après une relecture abîmée) : on ne jette plus
local rel = EtatAtelier.nouveau(1000)
aLaTable(rel, 20)
rel.entames.coton_blanc = { bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } }
rel.coupees.jupe_droite_dos = { x = 7.5, y = 9, angle = 0 }
U.verifier(rel:jeterEntame("coton_blanc").erreur == "Des pièces de ce tissu sont déjà coupées pour cette robe." and rel:coupeDans("coton_blanc") and not rel:coupeDans("soie_rouge"), "une pièce de ce tissu coupée, même absente du rouleau : on ne jette plus")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : une pièce de ce tissu coupée, même absente du rouleau : on ne jette plus`

- [ ] **Step 3: Le bouton**

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:acheterMercerie(idAccessoire, quantite)
	return agir(self, "acheterMercerie", idAccessoire, quantite)
end
```

par :

```lua
function Session:acheterMercerie(idAccessoire, quantite)
	return agir(self, "acheterMercerie", idAccessoire, quantite)
end
function Session:jeterEntame(idTissu)
	return agir(self, "jeterEntame", idTissu)
end
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

par :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)
```

par :

```lua
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	-- (sous-projet 6) Jeter la bande entamée de ce rouleau (deuxième appui pour confirmer), tant qu'aucune pièce de ce
	-- tissu n'est coupée pour cette robe : elle quitte le stock, le rouleau repart neuf
	local jeter = UiKit.boutonConfirme({ Name = "JeterEntame", Text = "Jeter la bande", TextSize = 14, TextWrapped = true, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(124, 34), Visible = false, Parent = panneau }, function()
		local idTissu = table_.tissu
		local r = session:jeterEntame(idTissu)
		if not r.ok then
			ctx.refus(r)
			return
		end
		ctx.message(("Bande entamée jetée : %s m %s."):format(Mercerie.metres(r.dm * 10), Deblocages.de(Catalogue.tissu(idTissu).nom)), C.ok)
		table_:proposer()
		rafraichir()
		montrerPiece()
	end)
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
		ligneEntame.Visible = entame > 0
		ligneEntame.Position = UDim2.fromOffset(0, entame * PX)
```

par :

```lua
		ligneEntame.Visible = entame > 0
		ligneEntame.Position = UDim2.fromOffset(0, entame * PX)
		jeter.Visible = etat.entames[table_.tissu] ~= nil and not etat:coupeDans(table_.tissu)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Jette la bande entamée d'un rouleau (elle quitte le stock) : à l'achat, ou à la table tant qu'aucune pièce de ce
-- tissu n'est coupée pour la robe en cours (le rouleau repart neuf)
```

par :

```lua
-- Une pièce de ce tissu est-elle déjà coupée pour la robe en cours ?
function EtatAtelier:coupeDans(idTissu)
	for idPiece in pairs(self.coupees) do
		if self.tissus[idPiece] == idTissu then
			return true
		end
	end
	return false
end

-- Jette la bande entamée d'un rouleau (elle quitte le stock) : à l'achat, ou à la table tant qu'aucune pièce de ce
-- tissu n'est coupée pour la robe en cours (le rouleau repart neuf)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local coupon = self.coupons[idTissu]
	if coupon and next(coupon.poses) then
		return refus("Des pièces de ce tissu sont déjà coupées pour cette robe.")
	end
```

par :

```lua
	if self:coupeDans(idTissu) then
		return refus("Des pièces de ce tissu sont déjà coupées pour cette robe.")
	end
	local coupon = self.coupons[idTissu]
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167986 vérifications
TOUT EST VERT : 960 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Session.luau src/client/Atelier/EcranDecoupe.luau src/shared/EtatAtelier.luau tests/scenario.luau tests/unitaires/64_bande_entamee.luau
git commit -m "Table de découpe : « Jeter la bande » (deuxième appui), tant qu'aucune pièce de ce tissu n'est coupée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La ligne d'achat sur deux lignes

**Files:**
- Modify: `src/client/Atelier/EcranAchat.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: le texte `Infos` d'une ligne d'achat (plan 17).
- Produces: `Infos` de 336 × 36 px, en haut à gauche de son cadre, jusqu'au bouton −.

- [ ] **Step 1: Écrire le test**

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(conseilCoton ~= nil and l.Infos.Text == ("Conseillé : %d dm · Neuf : 0 dm (6 entamés)"):format(conseilCoton) and l.Quantite.Text == conseilCoton .. " dm", "coton blanc tout entamé : la quantité proposée est le conseil entier (" .. l.Infos.Text .. ")")
```

par :

```lua
	verifier(conseilCoton ~= nil and l.Infos.Text == ("Conseillé : %d dm · Neuf : 0 dm (6 entamés)"):format(conseilCoton) and l.Quantite.Text == conseilCoton .. " dm", "coton blanc tout entamé : la quantité proposée est le conseil entier (" .. l.Infos.Text .. ")")
	verifier(l.Infos.Size.X.Offset >= 336 and l.Infos.Size.Y.Offset >= 34 and l.Infos.Position.Y.Offset + l.Infos.Size.Y.Offset <= l.Size.Y.Offset and l.Infos.Position.X.Offset + l.Infos.Size.X.Offset <= l.Moins.Position.X.Offset, "l'information du tissu a la place de deux lignes, dans la ligne d'achat, avant « − »")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : l'information du tissu a la place de deux lignes, dans la ligne d'achat, avant « − »`

- [ ] **Step 3: La ligne**

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		local l = { infos = UiKit.texte({ Name = "Infos", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(102, 40), Size = UDim2.fromOffset(320, 24), Parent = ligne }) }
```

par :

```lua
		-- (deux lignes au besoin : « Conseillé : 27 dm · Neuf : 43 dm (50 entamés) », jusqu'au bouton −)
		local l = { infos = UiKit.texte({ Name = "Infos", TextSize = 14, TextColor3 = C.texteDoux, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(102, 36), Size = UDim2.fromOffset(336, 36), Parent = ligne }) }
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167986 vérifications
TOUT EST VERT : 961 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAchat.luau tests/scenario.luau
git commit -m "Achat : l'information d'un tissu entamé a la place de deux lignes

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan18Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit), rendre l'écran de la table dans un `ScreenGui` de `StarterGui` avec un faux contexte (une session dont l'état, créé par `EtatAtelier`, est à la découpe d'une robe droite à manches longues et col montant en coton blanc : 60 dm en stock, et une bande de 24 cols montants pliés, soit 48 silhouettes) ; mesurer (`os.clock`) la construction de l'écran et le pire « Proposer » des pièces restantes ; faire défiler le rouleau en haut et capturer. Puis en Play : attendre 4 s, relever la console.

Expected : 48 silhouettes, « 1,70 m entamés / 6,00 m » puis « Cette robe : +0,00 m (0 po) » sous « Couper », « Jeter la bande » en bas à droite, « Proposer » bien sous le dixième de seconde ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play, retirer le `ScreenGui` d'essai et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 6 en cours, plans 15 à 17 : les mesures à molettes, la mercerie, le tissu entamé)
```

par :

```markdown
## État actuel (sous-projet 6 terminé côté code, plans 15 à 18 : les mesures à molettes, la mercerie, le tissu entamé)
```

Dans `README.md`, remplacer :

```markdown
   ou dessous (« Proposer une place » les évite). Au-delà de 24 trous ou de 5 m, la bande est jetée d'elle-même
   (elle quitte alors le stock), et on l'annonce. Une robe libre compte en matières ce qu'elle ajoute à la bande.
```

par :

```markdown
   ou dessous (« Proposer une place » les évite). Sous « Couper », le compteur du rouleau : « 1,10 m entamés /
   3,00 m » et « Cette robe : +0,60 m (3 po) ». « Jeter la bande » (deuxième appui pour confirmer) la retire du stock
   tant qu'aucune pièce de ce tissu n'est coupée pour la robe : le rouleau repart neuf. Au-delà de 24 trous ou de
   5 m, la bande est jetée d'elle-même, et on l'annonce. Une robe libre compte en matières ce qu'elle ajoute à la
   bande.
```

Dans `README.md`, remplacer :

```markdown
10. La suite : porter la robe sur son avatar et les défilés entre joueurs, ou d'autres écarts avec *Dressmaker*
   (compteur de mètres, robes plus riches) : à décider.
```

par :

```markdown
10. La suite : porter la robe sur son avatar et les défilés entre joueurs, ou d'autres écarts avec *Dressmaker*
   (robes plus riches, étiquettes de style, portraits des clientes) : à décider.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167986 vérifications
TOUT EST VERT : 961 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 18 terminé : le compteur du rouleau et « Jeter la bande » (sous-projet 6 terminé côté code)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
