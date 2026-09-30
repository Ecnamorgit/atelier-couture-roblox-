# Aiguille & Dentelle — Plan 7 : finitions (robes libres, mesures, courrier, histoire)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Traiter les points mineurs reportés par les relectures des plans 5a à 5d qui touchent le joueur : des textes justes pour une robe libre, une annulation au choix de la taille, une sauvegarde plus stricte des robes libres ; des rubans de mesure faciles à saisir au doigt et qui restent dans leur cadre, un ajustement toujours recalculé ; un courrier qui dit quand la boîte est pleine, des boutons « Inviter » plus hauts ; une conversation d'histoire qu'un double clic ou la touche E ne bouscule pas ; des tests renforcés, des commentaires et des textes remis à leur place.

**Architecture:** aucune nouvelle notion ; des retouches dans les écrans (`EcranDecorations`, `EcranPresentation`, `EcranAccueil`, `EcranAchat`, `EcranMesures`, `init.client`), la sauvegarde et `EtatAtelier:reprendreMesures`.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** les specs des sous-projets 2 et 3 (`docs/superpowers/specs/2026-09-29-clientes-progression-design.md`, `…2026-09-30-histoire-evenements-design.md`) ; ce plan ne change aucune règle. Les points viennent des registres des plans 5a à 5d et 6 (« minor (deferred) »).

## Décisions de ce plan

- **Retenus** (effet pour le joueur, test possible) : textes d'une robe libre (« Présenter la robe », titre « 7. Photo et vente », qualité sans ajustement, « Gratuit » à l'achat, remerciement selon le cadeau), « Vendre » en 14 px, « × » au choix de la taille, robe libre relue sans ajustement ni acompte ; poignée des rubans de 44 px, ruban borné au cadre, ajustement recalculé à la reprise des mesures ; « Courrier (boîte pleine) », « Inviter » de 40 px ; tests des lettres abîmées une à une, test de l'acompte abîmé qui garde le reste de la partie ; commentaires déplacés ; « Accepter la commande » à côté de « Suivant », E sans effet quand un panneau couvre l'accueil, README (18 objets) et titre de la spec du sous-projet 3.
- **Laissés** : « +0 » d'amitié et message d'abandon (le scénario n'abandonne pas de commande : pas de test sans un long parcours) ; coût de `Commandes.generer` ; fourchette du carnet avec les tissus fermés ; conditions de déblocage en double (garde-fou sans test possible) ; hauteur de l'annonce ; lettres et commandes relues contre les déblocages (rien ne se referme aujourd'hui) ; code en double entre `livrer` et `vendre` ; lettre portant une robe d'histoire (DataStore seulement) ; demande d'histoire dans la bulle d'une première visite ; petites incohérences du récit.
- **Poignée** : un bouton transparent de 44 px (on l'attrape au doigt) autour d'une pastille de 24 px (ce qu'on voit).
- **Ruban** : borné entre 2 dm et le bord droit du cadre (la vraie mesure est toujours en deçà ; le serveur refuse de toute façon au-delà de 1,5 dm d'écart).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix variantes du brouillon (« × », robe libre relue, poignée, ruban borné, ajustement recalculé, boîte pleine, hauteur d'« Inviter », titre de la vente, touche E, place d'« Accepter ») échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `finitions`, créée depuis `main` (où le plan 6 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Commandes** : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Ruban tiré très loin au doigt.** Attendu : il s'arrête au bord du cadre, la poignée reste attrapable. Test : scénario, « tiré trop loin : le ruban s'arrête au bord du cadre ».
- **Robe libre relue d'une sauvegarde avec un ajustement ou un acompte.** Attendu : abandonnée. Test : `50_robes_libres`, « robe libre abîmée (ajustement / acompte) : abandonnée ».
- **Ajustement gardé qui ne correspond plus aux mesures.** Attendu : recalculé. Test : `44_mesures`, « « Reprendre ses mesures » : celles de sa première visite ».
- **Trois lettres et une annonce longue.** Attendu : la boîte pleine est dite, tout tient dans la fenêtre. Test : scénario, « boîte pleine : c'est dit, et les trois lettres tiennent dans la fenêtre ».
- **Renoncer à une robe libre au choix de la taille.** Attendu : rien n'est commencé. Test : scénario, « « × » : on renonce à la robe libre, rien n'est commencé ».

---

### Task 1: Les robes libres : textes, annulation, sauvegarde

**Files:**
- Modify: `src/client/Atelier/EcranDecorations.luau`, `init.client.luau`, `EcranPresentation.luau`, `EcranAccueil.luau`, `EcranAchat.luau`
- Modify: `src/server/Sauvegarde.luau`
- Modify: `tests/unitaires/50_robes_libres.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `commande.libre` (plan 5c).
- Produces: bouton `AnnulerTaille` ; textes « Présenter la robe », « 7. Photo et vente », « Toile de jute — Gratuit », « X te remercie pour la robe. » (cadeau de moins de 3 points d'amitié).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/50_robes_libres.luau`, remplacer :

```lua
for _, cas in ipairs({ { "exigences", { { type = "qualite", valeur = 0.5 } } }, { "cliente", "colette" }, { "libre", "oui" }, { "matieres", -5 } }) do
```

par :

```lua
for _, cas in ipairs({ { "exigences", { { type = "qualite", valeur = 0.5 } } }, { "cliente", "colette" }, { "libre", "oui" }, { "matieres", -5 }, { "ajustement", 1 }, { "acompte", 5 } }) do
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(boutonL.AbsolutePosition.X + boutonL.AbsoluteSize.X <= boutonCarnet.AbsolutePosition.X, "le choix de la taille ne recouvre pas « Carnet d'adresses »")
cliquer("RobeLibre_M")
```

par :

```lua
verifier(boutonL.AbsolutePosition.X + boutonL.AbsoluteSize.X <= boutonCarnet.AbsolutePosition.X, "le choix de la taille ne recouvre pas « Carnet d'adresses »")
cliquer("AnnulerTaille")
verifier(fenetre.Contenu:FindFirstChild("ChoixTaille") == nil and boutonNomme("RobeLibre") ~= nil and serveur:atelier(joueur).etat.etape == "accueil", "« × » : on renonce à la robe libre, rien n'est commencé")
cliquer("RobeLibre")
cliquer("RobeLibre_M")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Décontracté") ~= nil, "la toile de jute est gratuite")
cliquer("FermerChoix")
```

par :

```lua
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Décontracté") ~= nil, "la toile de jute est gratuite")
cliquer("Tissu_toile_jute")
cliquer("ToutEnUnTissu")
cliquer("Valider")
verifier(titre() == "2. Achat du tissu" and texte("Toile de jute — Gratuit") ~= nil, "à l'achat aussi, la toile de jute est « Gratuit »")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	e.commande.matieres = if tissu == "toile_jute" then 0 else 10
	e.etape = "photo"
	requireModule(scriptClient.Session).courante:actualiser()
end
```

par :

```lua
	e.commande.matieres = if tissu == "toile_jute" then 0 else 10
	e.etape = "decorations"
	requireModule(scriptClient.Session).courante:actualiser()
	verifier(boutonNomme("Presenter").Text == "Présenter la robe", "robe libre : « Présenter la robe » (pas de cliente)")
	cliquer("Presenter")
	verifier(titre() == "7. Photo et vente" and string.find(fenetre.Contenu.Qualite.Text, "ajustement", 1, true) == nil and boutonNomme("Vendre").TextSize <= 14, "photo d'une robe libre : « 7. Photo et vente », la qualité sans ajustement, « Vendre » en 14 px")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "Aiguille & Dentelle" and texte("Colette adore la robe que tu lui offres !") ~= nil and texte("Amitié de Colette : +") ~= nil, "offerte à Colette : l'accueil l'annonce")
```

par :

```lua
local gainCadeau = serveur:atelier(joueur).etat.clientes.colette.amitie - amitieColette
verifier(titre() == "Aiguille & Dentelle" and texte(if gainCadeau >= 3 then "Colette adore la robe que tu lui offres !" else "Colette te remercie pour la robe.") ~= nil and texte("Amitié de Colette : +") ~= nil, "offerte à Colette : l'accueil l'annonce, selon ce qu'elle en pense (+" .. gainCadeau .. ")")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : robe libre abîmée (ajustement) : abandonnée`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "Presenter", Text = "Présenter à la cliente",
```

par :

```lua
	UiKit.bouton({ Name = "Presenter", Text = if ctx.session.etat.commande.libre then "Présenter la robe" else "Présenter à la cliente",
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		titre.Text = TITRES[etat.etape] or etat.etape
```

par :

```lua
		-- (la photo d'une robe libre mène à la vente, pas à une livraison)
		titre.Text = if etat.etape == "photo" and etat.commande and etat.commande.libre then "7. Photo et vente" else TITRES[etat.etape] or etat.etape
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		Text = ("Qualité de la robe : %d %% (ajustement %d %%)"):format(math.floor(bilan.qualite * 100 + 0.5), math.floor(bilan.ajustement * 100 + 0.5)),
```

par :

```lua
		Text = if libre
			then ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5))
			else ("Qualité de la robe : %d %% (ajustement %d %%)"):format(math.floor(bilan.qualite * 100 + 0.5), math.floor(bilan.ajustement * 100 + 0.5)),
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		UiKit.boutonConfirme({ Name = "Vendre", Text = ("Vendre (%d po)"):format(etat:prixVente()), Position
```

par :

```lua
		UiKit.boutonConfirme({ Name = "Vendre", Text = ("Vendre (%d po)"):format(etat:prixVente()), TextSize = 14, Position
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		annonce = ("%s adore la robe que tu lui offres ! Elle part en vitrine."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente")
```

par :

```lua
		local prenom = fiche and fiche.nom:match("^(%S+)") or "La cliente"
		annonce = if r.amitie and r.amitie.gain >= 3
			then ("%s adore la robe que tu lui offres ! Elle part en vitrine."):format(prenom)
			else ("%s te remercie pour la robe. Elle part en vitrine."):format(prenom)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
					local rl = ctx.session:nouvelleRobeLibre(taille)
					if not rl.ok then
						ctx.refus(rl)
					end
				end)
			end
```

par :

```lua
					local rl = ctx.session:nouvelleRobeLibre(taille)
					if not rl.ok then
						ctx.refus(rl)
					end
				end)
			end
			-- « × » : on renonce, rien n'est commencé
			UiKit.boutonDoux({ Name = "AnnulerTaille", Text = "×", TextSize = 18, Position = UDim2.fromOffset(276, 8), Size = UDim2.fromOffset(34, 34), Parent = choix }, function()
				choix:Destroy()
				libre.Visible = true
			end)
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		UiKit.texte({ Text = ("%s — %d po/m"):format(t.nom, t.prix),
```

par :

```lua
		UiKit.texte({ Text = ("%s — %s"):format(t.nom, if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)),
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		return c.libre == true and c.cliente == nil and etape ~= "mesures" and type(c.exigences) == "table" and next(c.exigences) == nil
```

par :

```lua
		return c.libre == true and c.cliente == nil and c.ajustement == nil and c.acompte == nil and etape ~= "mesures" and type(c.exigences) == "table" and next(c.exigences) == nil
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107920 vérifications
TOUT EST VERT : 677 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranDecorations.luau src/client/Atelier/init.client.luau src/client/Atelier/EcranPresentation.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranAchat.luau src/server/Sauvegarde.luau tests/unitaires/50_robes_libres.luau tests/scenario.luau
git commit -m "Robes libres : textes justes, « × » au choix de la taille, sauvegarde plus stricte

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les mesures : poignée, ruban borné, ajustement recalculé

**Files:**
- Modify: `src/client/Atelier/EcranMesures.luau`, `src/shared/EtatAtelier.luau` (`reprendreMesures`)
- Modify: `tests/unitaires/44_mesures.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Notation.ajustement(vraies, prises)` (plan 5a).
- Produces: poignée `Poignee_<cle>` de 44 px avec une `Pastille` de 24 px ; `reprendreMesures` recalcule `commande.ajustement`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/44_mesures.luau`, remplacer :

```lua
U.verifier(r.cliente == "colette" and not r.premiereVisite and e.etape == "mesures", "Colette revient")
r = e:reprendreMesures()
```

par :

```lua
U.verifier(r.cliente == "colette" and not r.premiereVisite and e.etape == "mesures", "Colette revient")
e.clientes.colette.ajustement = 1 -- (un ajustement gardé qui ne correspond plus à ses mesures : recalculé)
r = e:reprendreMesures()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Valeur_poitrine").Text == justePoitrine, "doigt levé : le ruban ne bouge plus")
```

par :

```lua
verifier(texte("Valeur_poitrine").Text == justePoitrine, "doigt levé : le ruban ne bouge plus")
-- La poignée est assez grosse pour le doigt ; tirée trop loin, le ruban s'arrête au bord du cadre
verifier(silhouetteM.Poignee_poitrine.AbsoluteSize.X >= 40 and silhouetteM.Poignee_poitrine.AbsoluteSize.Y >= 40, "poignée d'au moins 40 px (le doigt)")
silhouetteM.Poignee_poitrine.InputBegan:Fire(doigtRuban)
doigtRuban.Position = Vector3.new(2000, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
M.services.UserInputService.InputEnded:Fire(doigtRuban)
local rubanP = silhouetteM.Ruban_poitrine
verifier(rubanP.Position.X.Offset + rubanP.Size.X.Offset <= silhouetteM.Size.X.Offset, "tiré trop loin : le ruban s'arrête au bord du cadre")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : « Reprendre ses mesures » : celles de sa première visite`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranMesures.luau`, remplacer :

```lua
	local function regler(cle, valeur)
		prises[cle] = math.clamp(arrondi(valeur), 2, 15)
		maj(cle)
	end
```

par :

```lua
	-- Un ruban va de 2 dm jusqu'au bord droit du cadre, pas au-delà (la vraie mesure est toujours en deçà)
	local maxi = {}
	local function regler(cle, valeur)
		prises[cle] = math.clamp(arrondi(valeur), 2, maxi[cle])
		maj(cle)
	end
```

Dans `src/client/Atelier/EcranMesures.luau`, remplacer :

```lua
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - vraieLargeur / 2, m.y - 4), ZIndex = 3, Parent = silhouette })
		local poignee = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Poignee_" .. cle, Text = "", AutoButtonColor = false, BackgroundColor3 = C.accent, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = 4, Parent = silhouette }), 12)
```

par :

```lua
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - vraieLargeur / 2, m.y - 4), ZIndex = 3, Parent = silhouette })
		maxi[cle] = math.floor((LARGEUR - (centre - vraieLargeur / 2)) / (FACE * PX) * 10) / 10
		-- La poignée : une pastille de 24 px, dans une zone de 44 px qu'on attrape au doigt
		local poignee = UiKit.creer("TextButton", { Name = "Poignee_" .. cle, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(44, 44), ZIndex = 4, Parent = silhouette })
		UiKit.arrondir(UiKit.creer("Frame", { Name = "Pastille", BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = 4, Parent = poignee }), 12)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.commande.mesures, self.commande.ajustement = copie(fiche.mesures), fiche.ajustement or 1
```

par :

```lua
	-- (l'ajustement est recalculé : il ne dépend que des mesures gardées et des vraies)
	self.commande.mesures = copie(fiche.mesures)
	self.commande.ajustement = Notation.ajustement(Clientes.get(self.commande.cliente).mesures, fiche.mesures)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107920 vérifications
TOUT EST VERT : 705 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranMesures.luau src/shared/EtatAtelier.luau tests/unitaires/44_mesures.luau tests/scenario.luau
git commit -m "Mesures : poignée de 44 px, ruban borné au cadre, ajustement recalculé à la reprise

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le courrier, des tests renforcés, des commentaires à leur place

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`, `src/shared/Notation.luau`, `src/client/Atelier/UiKit.luau`, `src/client/Atelier/Scene.luau`
- Modify: `tests/unitaires/47_acompte.luau`, `51_courrier.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `EtatAtelier.LETTRES_MAX` (plan 5d).
- Produces: « Courrier (boîte pleine) : » ; boutons `Inviter_<i>` de 40 px, tous les 44 px.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/51_courrier.luau`, remplacer :

```lua
p.lettres = {
	{ cliente = "inconnue", commande = { cliente = "inconnue", taille = "M", exigences = { { type = "qualite", valeur = 0.5 } } } },
	{ cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = {} } },
	{ cliente = "colette", commande = { cliente = "margot", taille = "S", exigences = { { type = "qualite", valeur = 0.5 } } } },
	"abîmée",
	p.lettres[1], p.lettres[1], p.lettres[1], p.lettres[1],
}
relue = Sauvegarde.versEtat(p)
U.verifier(#relue.lettres == 3 and relue.lettres[1].cliente == "colette", "lettres illisibles laissées, trois au plus")
```

par :

```lua
local bonne = p.lettres[1]
for k, abimee in ipairs({
	{ cliente = "inconnue", commande = { cliente = "inconnue", taille = "M", exigences = { { type = "qualite", valeur = 0.5 } } } },
	{ cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = {} } },
	{ cliente = "colette", commande = { cliente = "margot", taille = "S", exigences = { { type = "qualite", valeur = 0.5 } } } },
	"abîmée",
}) do
	p.lettres = { abimee }
	U.verifier(#Sauvegarde.versEtat(p).lettres == 0, "lettre illisible laissée (" .. k .. ")")
end
p.lettres = { bonne, bonne, bonne, bonne }
relue = Sauvegarde.versEtat(p)
U.verifier(#relue.lettres == 3 and relue.lettres[1].cliente == "colette", "trois lettres au plus")
```

Dans `tests/unitaires/47_acompte.luau`, remplacer :

```lua
	U.verifier(r2.etape == "accueil" and r2.commande == nil, cas[1] .. " illisible (" .. tostring(cas[2]) .. ") : commande abandonnée")
```

par :

```lua
	U.verifier(r2.etape == "accueil" and r2.commande == nil, cas[1] .. " illisible (" .. tostring(cas[2]) .. ") : commande abandonnée")
	U.verifier(r2.argent == enCours.argent and r2.prestige == enCours.prestige and r2.clientes.colette ~= nil and r2.clientes.colette.mesures ~= nil, cas[1] .. " illisible : le reste de la partie est gardé")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Une lettre de Colette est arrivée.") ~= nil and fenetre.Contenu:FindFirstChild("Lettre1") ~= nil and boutonNomme("Inviter_1") ~= nil, "une lettre de Colette arrive, avec « Inviter »")
```

par :

```lua
verifier(texte("Une lettre de Colette est arrivée.") ~= nil and fenetre.Contenu:FindFirstChild("Lettre1") ~= nil and boutonNomme("Inviter_1") ~= nil, "une lettre de Colette arrive, avec « Inviter »")
verifier(boutonNomme("Inviter_1").AbsoluteSize.Y >= 40, "« Inviter » assez haut pour le doigt")
```

Dans `tests/scenario.luau`, remplacer :

```lua
e.histoire.faites.lanternes_margot = true -- (la robe de Margot, déjà livrée : celle de Colette sera la dernière)
```

par :

```lua
e.histoire.faites.lanternes_margot = true -- (la robe de Margot, déjà livrée : celle de Colette sera la dernière)
-- (et trois lettres en attente : la boîte est pleine)
local lettre = { cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } } }
e.lettres = { lettre, table.clone(lettre), table.clone(lettre) }
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifierTailles("épilogue")
```

par :

```lua
verifierTailles("épilogue")
local inviter3 = boutonNomme("Inviter_3")
verifier(fenetre.Contenu.Courrier.Text == "Courrier (boîte pleine) :" and inviter3.Position.Y.Offset + inviter3.Size.Y.Offset <= 466, "boîte pleine : c'est dit, et les trois lettres tiennent dans la fenêtre")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : « Inviter » assez haut pour le doigt`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Text = if #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.",
```

par :

```lua
Text = if #etat.lettres >= EtatAtelier.LETTRES_MAX then "Courrier (boîte pleine) :" elseif #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.",
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			local yl = y + 114 + (i - 1) * 40
```

par :

```lua
			local yl = y + 114 + (i - 1) * 44
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			UiKit.boutonDoux({ Name = "Inviter_" .. i, Text = "Inviter", TextSize = 16, Position = UDim2.fromOffset(610, yl), Size = UDim2.fromOffset(120, 34), Parent = ctx.contenu }, function()
```

par :

```lua
			UiKit.boutonDoux({ Name = "Inviter_" .. i, Text = "Inviter", TextSize = 16, Position = UDim2.fromOffset(610, yl), Size = UDim2.fromOffset(120, 40), Parent = ctx.contenu }, function()
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
-- Ajustement de la robe à la cliente (sous-projet 2)
```

par :

```lua
-- Ajustement de la robe à la cliente (sous-projet 2)
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
	return math.clamp(1 - total / Notation.PENTE_MESURE, 0.5, 1)
end

function Notation.bilan(recette)
```

par :

```lua
	return math.clamp(1 - total / Notation.PENTE_MESURE, 0.5, 1)
end

-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
function Notation.bilan(recette)
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
-- Bouton secondaire (fond clair)
-- Un élément du catalogue pas encore ouvert (déblocages) : grisé, marqué par l'attribut « Ferme »
```

par :

```lua
-- Un élément du catalogue pas encore ouvert (déblocages) : grisé, marqué par l'attribut « Ferme »
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.boutonDoux(props, auClic, calme)
```

par :

```lua
-- Bouton secondaire (fond clair)
function UiKit.boutonDoux(props, auClic, calme)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
-- Met la scène d'accord avec l'état de l'atelier (derniere = dernière action réussie de la session).
-- Peut attendre (création des maillages) : l'appeler dans une tâche à part pour ne pas bloquer l'interface.
-- Une lettre dépasse de la boîte aux lettres du comptoir tant que le courrier en contient
```

par :

```lua
-- Une lettre dépasse de la boîte aux lettres du comptoir tant que le courrier en contient
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:synchroniser(etat, derniere)
```

par :

```lua
-- Met la scène d'accord avec l'état de l'atelier (derniere = dernière action réussie de la session).
-- Peut attendre (création des maillages) : l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat, derniere)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107928 vérifications
TOUT EST VERT : 709 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/shared/Notation.luau src/client/Atelier/UiKit.luau src/client/Atelier/Scene.luau tests/unitaires/47_acompte.luau tests/unitaires/51_courrier.luau tests/scenario.luau
git commit -m "Courrier : boîte pleine annoncée, « Inviter » plus haut ; tests renforcés, commentaires à leur place

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: L'histoire : double clic, touche E ; README et spec

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`
- Modify: `README.md`, `docs/superpowers/specs/2026-09-30-histoire-evenements-design.md`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: panneaux `Conversation`, `Epilogue`, `Suite`, `CarnetAdresses` (plans 5d, 6).
- Produces: « Accepter la commande » en x = 220 ; E ignoré quand un de ces panneaux est visible.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
local def = Histoire.commande("lanternes_colette")
cliquer("CommandeHistoire")
local conversation = fenetre.Contenu.Conversation
```

par :

```lua
local def = Histoire.commande("lanternes_colette")
cliquer("CommandeHistoire")
local conversation = fenetre.Contenu.Conversation
-- Pendant la conversation, E ne sonne pas la clochette ; « Accepter » n'est pas sous « Suivant » (un double clic
-- n'accepte pas la commande)
M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
verifier(e.etape == "accueil" and conversation.Visible, "pendant la conversation, E ne sonne pas la clochette")
local suivantC, accepterC = conversation.SuivantConversation, conversation.AccepterCommande
verifier(accepterC.Position.X.Offset >= suivantC.Position.X.Offset + suivantC.Size.X.Offset, "« Accepter la commande » n'est pas sous « Suivant »")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : pendant la conversation, E ne sonne pas la clochette`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		accepter = UiKit.bouton({ Name = "AccepterCommande", Text = "Accepter la commande", Visible = false, Position = UDim2.fromOffset(0, 150), Size = UDim2.fromOffset(260, 44), ZIndex = 21, Parent = conversation }, function()
```

par :

```lua
		-- (à droite de « Suivant » : un double clic sur « Suivant » n'accepte pas la commande)
		accepter = UiKit.bouton({ Name = "AccepterCommande", Text = "Accepter la commande", Visible = false, Position = UDim2.fromOffset(220, 150), Size = UDim2.fromOffset(260, 44), ZIndex = 21, Parent = conversation }, function()
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat) : sonner la clochette
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible then
			sonner()
		end
	end)
```

par :

```lua
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat, ni quand un panneau est ouvert par-dessus l'accueil :
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses) : sonner la clochette
	local function panneauOuvert()
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses" }) do
			local p = ctx.contenu:FindFirstChild(nom)
			if p and p.Visible then
				return true
			end
		end
		return false
	end
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible and not panneauOuvert() then
			sonner()
		end
	end)
```

Dans `README.md`, remplacer :

```markdown
7. **Décorations** : 10 objets (boutons, nœuds, fleurs, broche, perle, étoile, croix) et 5 garnitures (dentelles,
```

par :

```markdown
7. **Décorations** : 18 objets (boutons, nœuds, fleurs, broche, perle, étoile, croix, et les huit souvenirs du
   quartier une fois leur événement passé) et 5 garnitures (dentelles,
```

Dans `docs/superpowers/specs/2026-09-30-histoire-evenements-design.md`, remplacer :

```markdown
# Atelier de couture — Sous-projet 3 : l'histoire et les événements du quartier
```

par :

```markdown
# Aiguille & Dentelle — Sous-projet 3 : l'histoire et les événements du quartier
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107928 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau README.md docs/superpowers/specs/2026-09-30-histoire-evenements-design.md tests/scenario.luau
git commit -m "Conversation d'histoire : ni double clic ni touche E ne la bousculent ; README et spec à jour

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vérification dans Studio

**Files:**
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 7 terminé.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan7Depot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s ; appuyer sur E, attendre 1,5 s. Côté client (`execute_luau`), lire la taille absolue de `Silhouette.Poignee_poitrine` et de sa `Pastille`. Glisser la poignée de la poitrine (`user_mouse_input`) de son centre jusqu'à 400 px plus à droite ; relire la position et la taille du ruban `Ruban_poitrine` et la largeur de la silhouette. Relever les alertes.

Expected :
- poignée d'environ 31 px à l'échelle de la fenêtre (44 × l'échelle), pastille d'environ 17 px ;
- le bord droit du ruban ne dépasse pas la largeur de la silhouette ;
- aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part).

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107928 vérifications
TOUT EST VERT : 711 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add AtelierCouture.rbxl
git commit -m "Plan 7 terminé : finitions des robes libres, des mesures et du courrier

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
