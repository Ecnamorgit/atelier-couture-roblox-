# Aiguille & Dentelle — Plan 26 : le guidage de la couture

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que le joueur apprenne à coudre droit sans l'assistance : la couture se voit en direct (couleurs de l'écart, jauge de précision, angle annoncé, « Parfait ! »), et des conseils pas à pas l'accompagnent à sa première robe ; « ? » les rappelle.

**Architecture:** `MachineCoudre` gagne `coutureParfaite(k)`. `EcranCouture` colore l'aiguille et les points selon l'écart, ajoute la jauge « Precision », la ligne du tissu, le signal en haut du plateau (« Un angle : arrête-toi et pivote », « Pivote ») et la marque de l'angle sur le pointillé, et salue une couture parfaite. Un nouveau module `GuideCouture` (logique pure) suit les gestes du joueur et donne le conseil en cours ; l'écran l'affiche dans une bulle en bas du plateau, à la première robe (aucune robe livrée ni vendue) ou sur « ? ». Rien n'est sauvegardé ; le serveur ne change pas.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-10-01-couture-guidee-design.md` (section 3, « Le guidage » ; plan 26 de la section 5).

## Décisions de ce plan

- **Les couleurs** : vert à 0,05 dm du pointillé au plus (la note entière), orange jusqu'à 0,15 dm, rouge au-delà ; l'aiguille suit l'écart en cours, chaque point garde celui de sa mesure. La jauge suit la note provisoire : verte dès 90 %, orange dès 60 %, rouge en dessous.
- **Le signal** : « Un angle : arrête-toi et pivote » à moins de 0,5 dm d'un angle (la marque, un rond, est posée au bout du pointillé dès que la couture en cours finit sur un angle ; depuis la relecture du plan 25, ce bout est le croisement des deux pointillés, là où la machine tourne) ; sinon « Pivote : le pointillé doit remonter droit » quand le tissu penche de plus de 25°.
- **« Parfait ! »** : une couture finie dont toutes les mesures sont à 0,05 dm au plus ; affiché 1,5 s.
- **Le tissu** : « <nom> : un tissu stable » (jute, coton, lin, laine), « un tissu qui tire un peu » (crêpe, velours, brocart), « un tissu qui glisse, tiens-le bien » (soie, satin, organza, tulle). La spec donnait « Soie : elle glisse, tiens-la bien » : la tournure en « un tissu » s'accorde avec tous les noms (« Tweed brun », « Soie ivoire »).
- **Les conseils** (`GuideCouture`) : 1. tenir « Coudre » — s'efface à 0,5 dm cousu ; 2. pivoter avec ◀ ▶ (A / D) — après 0,3 s de pivot en cousant ; 3. dans un angle, s'arrêter et pivoter — quand un angle est passé et que le tissu, redressé à moins de 10°, coud de nouveau (sans angle à venir sur la pièce, le conseil passe) ; 4. ralentir dans les courbes — après 5 s de couture, ou la pièce finie ; puis « Bravo » 4 s. Une autre pièce sous l'aiguille : l'angle se compte sur elle. Les conseils finis ne reviennent pas d'eux-mêmes pendant la partie (`session.conseilsCoutureVus`) ; « ? » les reprend au premier.
- **À l'écran** : la liste des pièces raccourcie à 120 px ; la note (y 124) laisse la place à « ? » ; la jauge (y 150), la ligne du tissu (y 160), la consigne (y 180). La bulle des conseils (64 px, en bas du plateau), le signal et « Parfait ! » (en haut) ne cachent pas l'aiguille. Le plateau porte les attributs `Angle` (degrés) et `Ecart` (dm) : c'est ce que lisent les tests pour coudre au clavier.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` après la fusion du plan 25 ; quatorze variantes du brouillon échouent sur la vérification qui les garde. Dans Studio : la bulle (le contour sur le bord, pas sur le texte), le signal, « Parfait ! » en pastille verte, la jauge et « ? » vus ; les quatre conseils tiennent dans la bulle.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `couture-guidee`, créée depuis `main` après la fusion du plan 25. Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Le joueur s'arrête au milieu d'une couture.** Attendu : « Parfait ! » s'efface quand même au bout de 1,5 s (mis à jour à chaque image). Test : `79_couture_direct`.
- **Une pièce sans angle passe sous l'aiguille au conseil de l'angle.** Attendu : le conseil passe au suivant, rien ne reste bloqué. Test : `80_guide_couture`.
- **La robe recommencée, ou l'écran rouvert, à la première robe.** Attendu : les conseils déjà vus ne reviennent pas d'eux-mêmes ; « ? » les montre. Test : `80_guide_couture`.
- **Le tissu de travers depuis le début (A tenue avant de coudre).** Attendu : « Pivote » s'affiche, l'aiguille rougit hors de la ligne. Test : `79_couture_direct`.
- **Une couture à l'écart nul tout du long, la dernière de la pièce.** Attendu : parfaite aussi (pas de couture suivante pour la borner). Test : `79_couture_direct`.

---

### Task 1: La couture en direct

**Files:**
- Modify: `src/client/Atelier/MachineCoudre.luau`, `src/client/Atelier/EcranCouture.luau`
- Create: `tests/unitaires/79_couture_direct.luau`

**Interfaces:**
- Consumes: `MachineCoudre` du plan 25 (`ecarts`, `debuts`, `k`, `etat().virage`, `glisse`) ; `UiKit.COULEURS` (`ok`, `alerte`, `erreur`, `accent`).
- Produces: `MachineCoudre.PARFAIT`, `MachineCoudre:coutureParfaite(k)` ; à l'écran, dans le plateau : `Signal`, `Parfait`, `Tissu.Angle`, `Aiguille.Contour`, attributs `Angle` et `Ecart` ; dans le panneau : `Precision.Remplissage`, `Tissu`.

- [ ] **Step 1: Écrire le test**

Créer `tests/unitaires/79_couture_direct.luau` :

```lua
-- Sous-projet 8 (plan 26) : la couture se voit en direct. L'aiguille et les points prennent la couleur de l'écart, la
-- jauge « Précision » suit la note, l'angle qui vient est marqué et annoncé, « Pivote » quand le tissu penche trop,
-- « Parfait ! » salue une couture sans faute ; le tissu dit s'il glisse.
local MachineCoudre = U.module("MachineCoudre")
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")
local Metrage = U.module("Metrage")
local EcranCouture = U.module("EcranCouture")
local C = UiKit.COULEURS

---------------------------------------------------------------------------
-- Une couture parfaite : toutes ses mesures à 0,05 dm du pointillé au plus
---------------------------------------------------------------------------
local ID = "corsage_droit_devant" -- coutures : le côté droit, le bas, le côté gauche (deux angles droits)
local function jusquAuBout(m) -- coud droit jusqu'au bout de la couture en cours (la dernière image s'arrête à l'angle)
	local k = m.k
	while m.k == k do
		m:avancer(math.clamp((m.longueurs[k] - m.s) / MachineCoudre.VITESSES[m.vitesse], 1e-6, 1 / 60), true, 0)
	end
end
local function redresser(m) -- l'aiguille plantée, le tissu pivote jusqu'à être droit
	while math.abs(m.angle) > 1e-9 do
		m:avancer(math.min(math.abs(m.angle) / MachineCoudre.ROTATION_MAX, 1 / 60), false, if m.angle > 0 then -1 else 1)
	end
end
local droite = MachineCoudre.nouvelle(ID, 1)
droite.glisse = 0 -- (un tissu qui ne tire pas : la couture reste sur le pointillé)
jusquAuBout(droite)
U.verifier(droite:coutureParfaite(1) and not droite:coutureParfaite(2), "couture droite d'un bout à l'autre : parfaite ; celle en cours ne l'est pas encore")
redresser(droite)
jusquAuBout(droite)
redresser(droite)
jusquAuBout(droite)
U.verifier(droite:fini() and droite:coutureParfaite(2) and droite:coutureParfaite(3), "redressé dans chaque angle : toutes parfaites, la dernière aussi")
U.verifier(not droite:coutureParfaite(0) and not droite:coutureParfaite(4), "pas de couture 0 ni 4")
droite:decoudre()
U.verifier(not droite:coutureParfaite(3), "décousue : elle n'est plus parfaite")
local travers = MachineCoudre.nouvelle(ID, 1)
travers.glisse = 0
jusquAuBout(travers)
jusquAuBout(travers) -- sans pivoter dans l'angle : l'aiguille s'écarte
U.verifier(travers:coutureParfaite(1) and not travers:coutureParfaite(2), "sans pivoter dans l'angle, la couture suivante n'est pas parfaite")

---------------------------------------------------------------------------
-- L'écran : une robe en soie, à la couture
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ids = Patron.piecesDuCroquis(CROQUIS)
local function sessionACoudre(graine, tissu)
	local session = Session.nouvelle(graine)
	U.commander(session)
	local tissus = {}
	for _, id in ipairs(ids) do
		tissus[id] = tissu
	end
	assert(session:validerCroquis(CROQUIS, tissus).ok)
	session.etat.argent = 1000
	local placements, longueur = Metrage.disposition(ids)
	assert(session:acheter(tissu, longueur).ok and session:commencerDecoupe().ok)
	for _, id in ipairs(ids) do
		assert(session:couper(id, placements[id]).ok, id)
	end
	for _, id in ipairs(ids) do
		assert(session:epingler(id).ok, id)
	end
	assert(session.etat.etape == "couture" and session.etat:piecesACoudre()[1] == ID)
	return session
end
local function contexte(session)
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
end
local ESPACE = { KeyCode = Enum.KeyCode.Space, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) }
local function touche(cle, appui)
	local action = if cle == Enum.KeyCode.Space then "AtelierCoudre" else "AtelierPivoter"
	M.actions[action].f(action, if appui then Enum.UserInputState.Begin else Enum.UserInputState.End, { KeyCode = cle, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) })
end

local ctx = contexte(sessionACoudre(31, "soie_ivoire"))
local fermer = EcranCouture(ctx)
local plateau, panneau = ctx.contenu.Plateau, ctx.contenu.Panneau
local tissuC = plateau.Tissu
local function contour()
	return plateau.Aiguille.Contour.Color
end
U.verifier(panneau.Tissu.Text == "Soie ivoire : un tissu qui glisse, tiens-le bien", "le tissu, et s'il glisse : " .. panneau.Tissu.Text)
U.verifier(contour() == C.ok and not plateau.Signal.Visible and not plateau.Parfait.Visible and panneau.Precision.Remplissage.Size.X.Scale == 0, "au départ : l'aiguille verte, pas de signal, la jauge vide")
U.verifier(panneau.Pieces.Position.Y.Offset + panneau.Pieces.Size.Y.Offset <= panneau.Note.Position.Y.Offset and panneau.Note.Position.Y.Offset + panneau.Note.Size.Y.Offset <= panneau.Precision.Position.Y.Offset and panneau.Precision.Position.Y.Offset + panneau.Precision.Size.Y.Offset <= panneau.Tissu.Position.Y.Offset, "la liste, la note, la jauge et le tissu l'un sous l'autre")

-- Droit, sur la ligne : des points verts. Puis le tissu penche trop : « Pivote » ; l'aiguille s'écarte, elle rougit, les
-- points aussi
touche(Enum.KeyCode.Space, true)
M.avancer(0.3)
touche(Enum.KeyCode.Space, false)
touche(Enum.KeyCode.A, true)
M.avancer(0.5)
touche(Enum.KeyCode.A, false)
U.verifier(plateau:GetAttribute("Angle") > 25 and plateau.Signal.Visible and plateau.Signal.Text == "Pivote : le pointillé doit remonter droit", ("tissu de travers (%.0f°) : « Pivote »"):format(plateau:GetAttribute("Angle") or 0))
touche(Enum.KeyCode.Space, true)
M.avancer(0.6)
touche(Enum.KeyCode.Space, false)
local verts, rouges = 0, 0
for _, p in ipairs(tissuC.Points:GetChildren()) do
	verts += if p.BackgroundColor3 == C.ok then 1 else 0
	rouges += if p.BackgroundColor3 == C.erreur then 1 else 0
end
U.verifier(math.abs(plateau:GetAttribute("Ecart")) > 0.15 and contour() == C.erreur, ("hors de la ligne (%.2f dm) : l'aiguille rouge"):format(plateau:GetAttribute("Ecart") or 0))
U.verifier(verts >= 1 and rouges >= 1, ("les points : verts au départ, rouges hors de la ligne (%d, %d)"):format(verts, rouges))
local pourcent = tonumber(panneau.Note.Text:match("(%d+) %%"))
local jauge = panneau.Precision.Remplissage
U.verifier(pourcent ~= nil and math.abs(jauge.Size.X.Scale * 100 - pourcent) <= 0.5 and jauge.BackgroundColor3 == (if pourcent >= 90 then C.ok elseif pourcent >= 60 then C.alerte else C.erreur), ("la jauge suit la note (%s, %.2f)"):format(panneau.Note.Text, jauge.Size.X.Scale))
U.verifier(not plateau.Parfait.Visible, "rien de parfait")
fermer()

-- Une couturière soigneuse, au clavier, sur du coton : elle suit la ligne (A / D d'après l'angle et l'écart)
local ctx2 = contexte(sessionACoudre(32, "coton_blanc"))
local fermer2 = EcranCouture(ctx2)
local plateau2 = ctx2.contenu.Plateau
U.verifier(ctx2.contenu.Panneau.Tissu.Text == "Coton blanc : un tissu stable", "le coton : un tissu stable")
local segments = Patron.trajetCouture(ID)
local boite = Polygone.boite(Catalogue.piece(ID).contour)
local tenue = nil
local function piloter(cousant)
	local angle, ecart = math.rad(plateau2:GetAttribute("Angle")), plateau2:GetAttribute("Ecart")
	local ecartVoulu = math.clamp(-2 * ecart, -0.4, 0.4) - angle
	local voulue = if ecartVoulu > 0.01 then Enum.KeyCode.A elseif ecartVoulu < -0.01 then Enum.KeyCode.D else nil
	if voulue ~= tenue then
		if tenue then
			touche(tenue, false)
		end
		if voulue then
			touche(voulue, true)
		end
		tenue = voulue
	end
end
touche(Enum.KeyCode.Space, true)
local signale, marque, images = false, nil, 0
while not plateau2.Parfait.Visible and images < 1200 do
	piloter()
	M.avancer(1 / 60)
	images += 1
	if plateau2.Signal.Visible and plateau2.Signal.Text == "Un angle : arrête-toi et pivote" then
		signale = true
		marque = marque or (plateau2.Tissu.Angle.Visible and plateau2.Tissu.Angle.Position)
	end
	U.verifier(math.abs(plateau2:GetAttribute("Ecart")) > 0.05 or plateau2.Aiguille.Contour.Color == C.ok, "sur la ligne : l'aiguille verte")
end
touche(Enum.KeyCode.Space, false)
if tenue then
	touche(tenue, false)
end
U.verifier(plateau2.Parfait.Visible and plateau2.Parfait.Text == "Parfait !", ("la première couture sans faute : « Parfait ! » (%d images)"):format(images))
local ax, ay = (segments[1].b.x - boite.minX) * 80, (segments[1].b.y - boite.minY) * 80
U.verifier(signale and marque and math.abs(marque.X.Offset - ax) < 1 and math.abs(marque.Y.Offset - ay) < 1, "l'angle annoncé à son approche, et marqué au bout du pointillé")
M.avancer(1.6)
U.verifier(not plateau2.Parfait.Visible, "« Parfait ! » s'efface")
fermer2()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call missing method 'coutureParfaite' of table`

- [ ] **Step 3: La machine, l'écran**

Dans `src/client/Atelier/MachineCoudre.luau`, remplacer :

```lua
-- Note de couture de ce qui est déjà cousu (nil si rien)
```

par :

```lua
-- (plan 26) La couture k, finie, est-elle parfaite ? Tous ses points à 0,05 dm du pointillé au plus (la note entière)
MachineCoudre.PARFAIT = 0.05
function MachineCoudre:coutureParfaite(k)
	local debut, suite = self.debuts[k], self.debuts[k + 1]
	if not debut or not (suite or self:fini()) then
		return false
	end
	local fin = if suite then suite.mesures else #self.ecarts
	if fin <= debut.mesures then
		return false
	end
	for i = debut.mesures + 1, fin do
		if math.abs(self.ecarts[i]) > MachineCoudre.PARFAIT + 1e-9 then
			return false
		end
	end
	return true
end

-- Note de couture de ce qui est déjà cousu (nil si rien)
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local RYTHMES = { tortue = 0.8, normale = 1, lapin = 1.3 } -- vitesse du son de la machine
```

par :

```lua
local RYTHMES = { tortue = 0.8, normale = 1, lapin = 1.3 } -- vitesse du son de la machine
-- (plan 26) L'écart en couleur : vert sur la ligne (la note entière), orange un peu à côté, rouge au-delà
local PRES, LOIN = 0.05, 0.15 -- dm
local SIGNAL_ANGLE = 0.5 -- dm : l'angle qui arrive est annoncé
local PENCHE = math.rad(25) -- au-delà, le pointillé penche trop : « Pivote »
local DUREE_PARFAIT = 1.5 -- s
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local aiguille = UiKit.arrondir(UiKit.creer("Frame", { Name = "Aiguille", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Parent = plateau }), 6)
	UiKit.creer("UIStroke", { Color = C.erreur, Thickness = 2, Parent = aiguille })
```

par :

```lua
	local aiguille = UiKit.arrondir(UiKit.creer("Frame", { Name = "Aiguille", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Parent = plateau }), 6)
	local contourAiguille = UiKit.creer("UIStroke", { Name = "Contour", Color = C.ok, Thickness = 2, Parent = aiguille })
	-- (plan 26) L'angle qui vient, marqué sur le pointillé ; le signal et « Parfait ! » en haut du plateau
	local marqueAngle = UiKit.arrondir(UiKit.creer("Frame", { Name = "Angle", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), Visible = false, Parent = tissu }), 7)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, Parent = marqueAngle })
	local signal = UiKit.arrondir(UiKit.texte({ Name = "Signal", Text = "", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(1, -40, 0, 30), Visible = false, Parent = plateau }), 8)
	local parfait = UiKit.arrondir(UiKit.texte({ Name = "Parfait", Text = "Parfait !", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.ok, BackgroundTransparency = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48), Size = UDim2.fromOffset(160, 36), Visible = false, Parent = plateau }), 18)
	local finParfait = 0
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local listePieces = UiKit.creer("ScrollingFrame", { Name = "Pieces", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, #ids * 24), Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 144), Parent = panneau })
```

par :

```lua
	local listePieces = UiKit.creer("ScrollingFrame", { Name = "Pieces", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, #ids * 24), Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 120), Parent = panneau })
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 0, 24), Parent = panneau })
```

par :

```lua
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, -46, 0, 22), Parent = panneau })
	-- (plan 26) la jauge de précision, et le tissu (s'il glisse)
	local jauge = UiKit.arrondir(UiKit.creer("Frame", { Name = "Precision", BackgroundColor3 = C.secondaire, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, -6, 0, 6), Parent = panneau }), 3)
	local remplissage = UiKit.arrondir(UiKit.creer("Frame", { Name = "Remplissage", BackgroundColor3 = C.ok, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = jauge }), 3)
	local ligneTissu = UiKit.texte({ Name = "Tissu", Text = "", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 160), Size = UDim2.new(1, 0, 0, 18), Parent = panneau })
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 178),
		Size = UDim2.new(1, 0, 0, 52),
```

par :

```lua
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 180),
		Size = UDim2.new(1, 0, 0, 52),
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		local contenuImage = Vignettes.piece(id, etat.tissus[id], etat.coupees[id], 256)
```

par :

```lua
		-- (plan 26) le tissu, et ce qu'il fait sous l'aiguille
		local t = Catalogue.tissu(etat.tissus[id])
		ligneTissu.Text = t.nom .. " : " .. (if machine.glisse >= 1.4 then "un tissu qui glisse, tiens-le bien" elseif machine.glisse <= 0.8 then "un tissu stable" else "un tissu qui tire un peu")
		local contenuImage = Vignettes.piece(id, etat.tissus[id], etat.coupees[id], 256)
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local function ajouterPoints()
		local e = machine:etat()
		local x, y = versTissu(e.point)
		for i = #points + 1, #machine.ecarts do
			points[i] = UiKit.creer("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.accent, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(4, 4), Parent = calquePoints })
		end
	end
```

par :

```lua
	-- (plan 26) la couleur d'un écart : vert sur la ligne, orange un peu à côté, rouge hors de la ligne
	local function couleurEcart(e)
		local a = math.abs(e)
		return if a <= PRES + 1e-9 then C.ok elseif a <= LOIN then C.alerte else C.erreur
	end
	local function ajouterPoints()
		local e = machine:etat()
		local x, y = versTissu(e.point)
		for i = #points + 1, #machine.ecarts do
			points[i] = UiKit.creer("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = couleurEcart(machine.ecarts[i]), BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(4, 4), Parent = calquePoints })
		end
	end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		tissu.Rotation = math.deg(phi)
		tissu.Position = UDim2.new(0.5, -(vx * c - vy * s), 0.5, -(vx * s + vy * c))
	end
```

par :

```lua
		tissu.Rotation = math.deg(phi)
		tissu.Position = UDim2.new(0.5, -(vx * c - vy * s), 0.5, -(vx * s + vy * c))
		-- (plan 26) en direct : la couleur de l'aiguille, l'angle qui vient, le signal
		plateau:SetAttribute("Angle", math.deg(e.angle))
		plateau:SetAttribute("Ecart", e.ecart)
		contourAiguille.Color = couleurEcart(e.ecart)
		local seg = machine.segments[e.segment]
		marqueAngle.Visible = e.virage ~= nil
		if e.virage then
			local mx, my = versTissu(seg.b)
			marqueAngle.Position = UDim2.fromOffset(mx, my)
		end
		local texte = nil
		if e.virage and e.virage.distance < SIGNAL_ANGLE then
			texte = "Un angle : arrête-toi et pivote"
		elseif math.abs(e.angle) > PENCHE then
			texte = "Pivote : le pointillé doit remonter droit"
		end
		signal.Visible = texte ~= nil and not machine:fini()
		signal.Text = texte or ""
	end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		local provisoire = machine and machine:noteProvisoire()
		local finie = machine ~= nil and machine:fini()
```

par :

```lua
		local provisoire = machine and machine:noteProvisoire()
		local finie = machine ~= nil and machine:fini()
		remplissage.Size = UDim2.fromScale(provisoire or 0, 1)
		remplissage.BackgroundColor3 = if (provisoire or 1) >= 0.9 then C.ok elseif provisoire >= 0.6 then C.alerte else C.erreur
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		machine:avancer(dt, cousant, r) -- (sans coudre : le tissu pivote, l'aiguille plantée)
		ajouterPoints()
```

par :

```lua
		local avant = machine.k
		machine:avancer(dt, cousant, r) -- (sans coudre : le tissu pivote, l'aiguille plantée)
		if machine.k > avant and machine:coutureParfaite(avant) then
			finParfait = os.clock() + DUREE_PARFAIT -- une couture sans faute
		end
		ajouterPoints()
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		local actif = machine ~= nil and not machine:fini() and ctx.fenetre.Visible
```

par :

```lua
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		parfait.Visible = os.clock() < finParfait
		local actif = machine ~= nil and not machine:fini() and ctx.fenetre.Visible
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269753 vérifications
TOUT EST VERT : 1029 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/MachineCoudre.luau src/client/Atelier/EcranCouture.luau tests/unitaires/79_couture_direct.luau
git commit -m "Couture en direct : l'aiguille et les points en couleur, la jauge de précision, l'angle annoncé, « Pivote », « Parfait ! », le tissu qui glisse

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les conseils pas à pas

**Files:**
- Create: `src/client/Atelier/GuideCouture.luau`, `tests/unitaires/80_guide_couture.luau`
- Modify: `src/client/Atelier/EcranCouture.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `MachineCoudre` (`parcouru`, `k`, `angle`, `segments`, `virage(k)`, `fini()`) ; `session.etat.livraisons`, `session.etat.ventes` (existants) ; l'écran de la tâche 1.
- Produces: `GuideCouture.nouveau()`, `:suivre(dt, machine, cousant, rotation)`, `:texte()`, `GuideCouture.CONSEILS`, `BRAVO`, `DROIT` ; à l'écran : `Plateau.Conseil`, `Panneau.Aide` ; `session.conseilsCoutureVus`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/80_guide_couture.luau` :

```lua
-- Sous-projet 8 (plan 26) : les conseils pas à pas de la couture. À la première robe, chaque conseil s'efface quand le
-- joueur l'a fait : avancer, pivoter en cousant, passer un angle en redressant le tissu, coudre quelques secondes ; puis
-- « Bravo ». Ensuite, « ? » les rappelle.
local GuideCouture = U.module("GuideCouture")
local MachineCoudre = U.module("MachineCoudre")
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local EcranCouture = U.module("EcranCouture")

local DT = 1 / 60
local function images(guide, machine, n, cousant, rotation)
	for _ = 1, n do
		machine:avancer(DT, cousant, rotation)
		guide:suivre(DT, machine, cousant, rotation)
	end
end

---------------------------------------------------------------------------
-- Les étapes, sur une vraie machine
---------------------------------------------------------------------------
local ID = "corsage_droit_devant" -- coutures : le côté droit, le bas, le côté gauche (deux angles droits)
local m = MachineCoudre.nouvelle(ID, 1)
m.glisse = 0 -- (un tissu qui ne tire pas : la couture reste droite tant qu'on ne pivote pas)
local g = GuideCouture.nouveau()
U.verifier(g:texte() == GuideCouture.CONSEILS[1], "premier conseil : tenir « Coudre »")
images(g, m, 20, true, 0)
U.verifier(g.etape == 1, "pas encore 0,5 dm cousu : le premier conseil reste")
images(g, m, 15, true, 0)
U.verifier(g:texte() == GuideCouture.CONSEILS[2], ("0,5 dm cousu : le deuxième conseil, pivoter (%.2f dm)"):format(m.parcouru))
images(g, m, 30, false, 1)
U.verifier(g.etape == 2, "pivoter sans coudre ne compte pas pour ce conseil")
images(g, m, 10, true, -1)
images(g, m, 10, true, 1)
U.verifier(g:texte() == GuideCouture.CONSEILS[3], "pivoté en cousant : le troisième conseil, l'angle")
-- jusqu'à l'angle, sans le redresser : le conseil reste ; redressé et cousant de nouveau : le suivant
while m.k == 1 do
	m:avancer(DT, true, 0)
	g:suivre(DT, m, true, 0)
end
images(g, m, 5, true, 0)
U.verifier(g.etape == 3 and math.abs(m.angle) > GuideCouture.DROIT, "l'angle passé, le tissu de travers : le conseil reste")
while math.abs(m.angle) > math.rad(2) do
	m:avancer(DT, false, if m.angle > 0 then -1 else 1)
	g:suivre(DT, m, false, if m.angle > 0 then -1 else 1)
end
U.verifier(g.etape == 3, "redressé sans coudre : le conseil reste jusqu'à ce qu'on reparte")
images(g, m, 1, true, 0)
U.verifier(g:texte() == GuideCouture.CONSEILS[4], "redressé, on repart : le dernier conseil, la vitesse")
images(g, m, 60 * 4, true, 0)
U.verifier(g.etape == 4, "quatre secondes de couture : le conseil reste")
images(g, m, 60 * 1 + 2, false, 0)
U.verifier(g.etape == 4, "à l'arrêt, le temps ne compte pas")
images(g, m, 60 * 1 + 2, true, 0)
U.verifier(g:texte() == GuideCouture.BRAVO, "cinq secondes de couture : « Bravo »")
images(g, m, 60 * 4 + 2, false, 0)
U.verifier(g:texte() == nil and g.etape == 6, "« Bravo » s'efface au bout de quatre secondes : plus de conseil")

-- Une pièce sans angle à venir (le col Claudine : une couture courte et droite) : le conseil de l'angle passe
local col = MachineCoudre.nouvelle("col_claudine", 2)
local g2 = GuideCouture.nouveau()
g2.etape = 3
g2:suivre(DT, col, false, 0)
U.verifier(g2.etape == 4, "pas d'angle sur cette pièce : on passe au conseil suivant")
-- Une pièce finie avant les cinq secondes : « Bravo » quand même
local courte = MachineCoudre.nouvelle("col_claudine", 3)
local g3 = GuideCouture.nouveau()
g3.etape = 4
while not courte:fini() do
	courte:avancer(DT, true, 0)
end
g3:suivre(DT, courte, false, 0)
U.verifier(g3:texte() == GuideCouture.BRAVO, "pièce finie : « Bravo »")
-- Une autre pièce passe sous l'aiguille : l'angle se compte sur elle
local g4 = GuideCouture.nouveau()
g4.etape = 3
local avant = MachineCoudre.nouvelle(ID, 4)
g4:suivre(DT, avant, false, 0) -- (l'angle à passer est au bout de la première couture)
local nouvelle = MachineCoudre.nouvelle(ID, 5)
nouvelle.k = 2
nouvelle.angle = 0
g4:suivre(DT, nouvelle, true, 0)
U.verifier(g4.etape == 3, "nouvelle pièce : un angle de l'ancienne ne compte pas")

---------------------------------------------------------------------------
-- À l'écran : la bulle des conseils, à la première robe ; « ? » les rappelle
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ids = Patron.piecesDuCroquis(CROQUIS)
local function sessionACoudre(graine)
	local session = Session.nouvelle(graine)
	U.commander(session)
	local tissus = {}
	for _, id in ipairs(ids) do
		tissus[id] = "coton_blanc"
	end
	assert(session:validerCroquis(CROQUIS, tissus).ok)
	session.etat.argent = 1000
	local placements, longueur = Metrage.disposition(ids)
	assert(session:acheter("coton_blanc", longueur).ok and session:commencerDecoupe().ok)
	for _, id in ipairs(ids) do
		assert(session:couper(id, placements[id]).ok, id)
	end
	for _, id in ipairs(ids) do
		assert(session:epingler(id).ok, id)
	end
	return session
end
local function ouvrir(session)
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	local ctx = { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
	return ctx, EcranCouture(ctx)
end
local function espace(appui)
	M.actions.AtelierCoudre.f("AtelierCoudre", if appui then Enum.UserInputState.Begin else Enum.UserInputState.End, { KeyCode = Enum.KeyCode.Space, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) })
end

local premiere = sessionACoudre(41)
local ctx, fermer = ouvrir(premiere)
local bulle = ctx.contenu.Plateau.Conseil
U.verifier(bulle.Visible and bulle.Text == GuideCouture.CONSEILS[1], "première robe : le premier conseil s'affiche")
espace(true)
M.avancer(0.7)
espace(false)
U.verifier(bulle.Visible and bulle.Text == GuideCouture.CONSEILS[2], "Espace tenu : le conseil suivant")
local aide = ctx.contenu.Panneau.Aide
U.verifier(aide.Text == "?" and aide.TextSize >= 14, "le bouton « ? »")
aide.Activated:Fire()
U.verifier(bulle.Visible and bulle.Text == GuideCouture.CONSEILS[1], "« ? » : les conseils reprennent au premier")
fermer()

-- Les conseils finis, ils ne reviennent pas d'eux-mêmes pendant la partie
premiere.conseilsCoutureVus = true
local ctx2, fermer2 = ouvrir(premiere)
U.verifier(not ctx2.contenu.Plateau.Conseil.Visible, "conseils déjà vus : pas de bulle")
fermer2()
-- Une robe déjà livrée : pas de conseils ; « ? » les montre
local habituee = sessionACoudre(42)
habituee.etat.livraisons = 1
local ctx3, fermer3 = ouvrir(habituee)
local bulle3 = ctx3.contenu.Plateau.Conseil
U.verifier(not bulle3.Visible, "une robe déjà livrée : pas de conseils")
M.avancer(0.5) -- (un bouton qui vient d'apparaître ignore les clics)
ctx3.contenu.Panneau.Aide.Activated:Fire()
U.verifier(bulle3.Visible and bulle3.Text == GuideCouture.CONSEILS[1], "« ? » montre les conseils")
fermer3()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(#panneauC.Pieces:GetChildren() == 6, "6 pièces à coudre")
coudre(2)
```

par :

```lua
verifier(#panneauC.Pieces:GetChildren() == 6, "6 pièces à coudre")
do -- (sous-projet 8) La première robe : les conseils pas à pas, en bas du plateau ; le premier s'efface en cousant
	local conseil = fenetre.Contenu.Plateau.Conseil
	local premier = conseil.Text
	verifier(conseil.Visible and premier:find("« Coudre »") ~= nil, "première robe : un conseil pour commencer (" .. premier .. ")")
	coudre(2)
	verifier(conseil.Visible and conseil.Text ~= premier, "cousu : le conseil suivant (" .. conseil.Text .. ")")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `GuideCouture n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Le guide, la bulle, « ? »**

Créer `src/client/Atelier/GuideCouture.luau` :

```lua
-- GuideCouture (sous-projet 8) : les conseils pas à pas de la couture, à la première robe (et sur demande, « ? »).
-- Chaque conseil s'efface quand le joueur l'a fait : avancer, pivoter en cousant, passer un angle en s'arrêtant pour
-- redresser le tissu, puis coudre quelques secondes ; enfin « Bravo ». Logique pure, sans affichage.
local GuideCouture = {}
GuideCouture.__index = GuideCouture

GuideCouture.CONSEILS = {
	"Tiens « Coudre » (ou Espace) : le tissu avance sous l'aiguille.",
	"Le tissu tourne un peu en avançant : fais-le pivoter avec ◀ ▶ (ou A / D) pour garder l'aiguille sur le pointillé.",
	"Un angle arrive : lâche « Coudre », fais pivoter le tissu jusqu'à ce que le pointillé remonte droit, puis repars.",
	"Ralentis dans les courbes (W / S, ou Tortue), accélère dans les lignes droites : ta précision s'affiche en direct.",
}
GuideCouture.BRAVO = "Bravo, tu sais coudre ! « ? » rappelle ces conseils."
GuideCouture.AVANCE = 0.5 -- dm cousus pour le premier conseil
GuideCouture.PIVOT = 0.3 -- s à pivoter en cousant pour le deuxième
GuideCouture.DROIT = math.rad(10) -- passé un angle, le tissu est redressé à moins de 10°
GuideCouture.PRATIQUE = 5 -- s de couture pour le dernier
GuideCouture.DUREE_BRAVO = 4 -- s

function GuideCouture.nouveau()
	return setmetatable({ etape = 1, pivot = 0, pratique = 0, bravo = 0 }, GuideCouture)
end

-- Reste-t-il un angle à passer sur cette pièce, à partir de la couture k ?
local function angleAVenir(machine, k)
	for j = k, #machine.segments - 1 do
		if machine:virage(j) then
			return true
		end
	end
	return false
end

-- Une image de dt secondes : machine (MachineCoudre), cousant, rotation (le pivot voulu par le joueur)
function GuideCouture:suivre(dt, machine, cousant, rotation)
	if machine ~= self.machine then -- une autre pièce : l'angle à passer se compte sur elle
		self.machine, self.couture = machine, machine.k
	end
	if self.etape == 1 then
		if machine.parcouru >= GuideCouture.AVANCE then
			self.etape = 2
		end
	elseif self.etape == 2 then
		if cousant and rotation ~= 0 then
			self.pivot += dt
		end
		if self.pivot >= GuideCouture.PIVOT then
			self.etape, self.couture = 3, machine.k
		end
	elseif self.etape == 3 then
		-- un angle passé (le pointillé a tourné), puis le tissu redressé en cousant de nouveau ; sans angle à venir sur
		-- cette pièce, le conseil attendra une autre pièce : on passe au suivant
		local passe = machine.k > self.couture and machine:virage(machine.k - 1) ~= nil
		if (passe and cousant and math.abs(machine.angle) < GuideCouture.DROIT) or (not passe and not angleAVenir(machine, machine.k)) then
			self.etape = 4
		end
	elseif self.etape == 4 then
		if cousant then
			self.pratique += dt
		end
		if self.pratique >= GuideCouture.PRATIQUE or machine:fini() then
			self.etape = 5
		end
	elseif self.etape == 5 then
		self.bravo += dt
		if self.bravo >= GuideCouture.DUREE_BRAVO then
			self.etape = 6
		end
	end
end

-- Le texte à montrer, ou nil (les conseils sont finis)
function GuideCouture:texte()
	if self.etape <= #GuideCouture.CONSEILS then
		return GuideCouture.CONSEILS[self.etape]
	elseif self.etape == 5 then
		return GuideCouture.BRAVO
	end
	return nil
end

return GuideCouture
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local MachineCoudre = require(script.Parent:WaitForChild("MachineCoudre"))
```

par :

```lua
local MachineCoudre = require(script.Parent:WaitForChild("MachineCoudre"))
local GuideCouture = require(script.Parent:WaitForChild("GuideCouture"))
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local parfait = UiKit.arrondir(UiKit.texte({ Name = "Parfait",
```

par :

```lua
	-- (plan 26) Les conseils pas à pas, en bas du plateau : à la première robe, puis sur demande (« ? »)
	local bulle = UiKit.arrondir(UiKit.texte({ Name = "Conseil", Text = "", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -40, 0, 64), Visible = false, Parent = plateau }), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bulle })
	UiKit.creer("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = bulle })
	local guide = nil
	local parfait = UiKit.arrondir(UiKit.texte({ Name = "Parfait",
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local jauge = UiKit.arrondir(
```

par :

```lua
	local montrerConseil
	UiKit.boutonDoux({ Name = "Aide", Text = "?", TextSize = 18, Position = UDim2.new(1, -40, 0, 120), Size = UDim2.fromOffset(34, 28), Parent = panneau }, function()
		guide = GuideCouture.nouveau() -- les conseils reprennent au premier
		montrerConseil()
	end)
	local jauge = UiKit.arrondir(
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	-- Le son de la machine suit l'aiguille
```

par :

```lua
	-- (plan 26) Le conseil en cours ; les conseils finis, la bulle disparaît (et ne revient qu'avec « ? » pendant cette
	-- partie : rien n'est sauvegardé)
	montrerConseil = function()
		local texte = guide and guide:texte()
		bulle.Visible = texte ~= nil
		bulle.Text = texte or ""
		if guide and not texte then
			guide = nil
			session.conseilsCoutureVus = true
		end
	end
	if session.etat.livraisons + session.etat.ventes == 0 and not session.conseilsCoutureVus then
		guide = GuideCouture.nouveau() -- la première robe : les conseils pas à pas
	end
	montrerConseil()
	-- Le son de la machine suit l'aiguille
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		local r = if actif then rotation() else 0
		if not cousant and r == 0 then
```

par :

```lua
		local r = if actif then rotation() else 0
		if guide and machine then
			guide:suivre(dt, machine, cousant, r)
			montrerConseil()
		end
		if not cousant and r == 0 then
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269775 vérifications
TOUT EST VERT : 1031 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/GuideCouture.luau src/client/Atelier/EcranCouture.luau tests/unitaires/80_guide_couture.luau tests/scenario.luau
git commit -m "Couture guidée : des conseils pas à pas à la première robe, chacun s'efface quand on l'a fait ; « ? » les rappelle

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan26Depot.rbxl`) et l'ouvrir dans Studio (ne toucher à aucune autre fenêtre de Studio). En édition (`execute_luau`, Edit) : mener un `EtatAtelier` neuf jusqu'à la couture (une robe en soie, aucune robe livrée) et rendre l'écran de couture dans un `ScreenGui` d'essai de `StarterGui` (une session simulée) ; le regarder (`screen_capture`), puis supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : la bulle du premier conseil en bas du plateau (texte lisible, contour sur le bord), « ? » à droite de la note, la jauge et la ligne du tissu (« … : un tissu qui glisse, tiens-le bien ») sous la note ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 8 en cours, plan 25 : la machine qui pivote)
```

par :

```markdown
## État actuel (sous-projet 8, plans 25 et 26 : la couture guidée)
```

Dans `README.md`, remplacer :

```markdown
   lapin (W / S), découd-vite ; l'assistance tient la ligne mais ne s'arrête pas dans les angles (note plafonnée à
   85 %).
```

par :

```markdown
   lapin (W / S), découd-vite ; l'assistance tient la ligne mais ne s'arrête pas dans les angles (note plafonnée à
   85 %). La couture se voit en direct : l'aiguille et les points verts sur la ligne, orange puis rouges quand on
   s'en écarte ; une jauge de précision ; l'angle qui vient est marqué sur le pointillé et annoncé ; « Pivote »
   quand le tissu penche trop ; « Parfait ! » salue une couture sans faute ; le tissu dit s'il glisse. À la
   première robe, des conseils pas à pas (chacun s'efface quand on l'a fait) ; le bouton « ? » les rappelle.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269775 vérifications
TOUT EST VERT : 1031 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 26 terminé : le guidage de la couture

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
