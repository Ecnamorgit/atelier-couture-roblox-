# Aiguille & Dentelle — Plan 25 : la machine qui pivote

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire de la couture un vrai geste, comme à la machine de *Dressmaker* : on fait avancer le tissu et on le fait pivoter pour suivre le pointillé, on s'arrête et on pivote dans les angles, on règle la vitesse ; l'assistance tient la ligne sans tout faire.

**Architecture:** `MachineCoudre` est réécrite : l'état gagne l'angle du tissu par rapport au pointillé ; `avancer(dt, cousant, rotation)` fait pivoter (même sans coudre) et avancer le tissu, l'écart naissant de l'angle ; le tissu tire selon sa matière ; à l'angle de deux coutures qui se suivent, le pointillé tourne. `EcranCouture` lit A / D, ← / →, W / S, les boutons ◀ ▶ et le glisser, et fait tourner le tissu à l'écran avec son angle. Le relevé envoyé au serveur ne change pas.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-10-01-couture-guidee-design.md` (section 2, « La machine qui pivote » ; plan 25 de la section 5).

## Décisions de ce plan

- **Le geste** : en cousant, le tissu avance de v × dt dans le sens de l'aiguille ; l'avance le long du pointillé est v × dt × cos(angle), jamais moins d'un cinquième ; l'écart grandit de v × dt × sin(angle). Pivot : 90° par seconde au plus, qu'on couse ou non.
- **Le tissu tire** : 0,35 rad par dm au plus (deux sinusoïdes, graine par pièce), multiplié selon la matière : jute 0,7 ; coton, lin, laine 0,8 ; brocart 1 ; crêpe, velours 1,2 ; soie, satin 1,5 ; organza, tulle 1,6.
- **Les angles** : deux coutures se suivent quand leurs arêtes se suivent sur le contour (les coutures sont décalées de la valeur de couture : leurs bouts ne se touchent pas) ; au passage, l'angle du tissu se décale de celui du pointillé, l'écart reste. Une couture séparée reprend au début de son pointillé, le tissu droit. Le découd-vite reprend une couture comme on y était arrivé.
- **L'assistance** pivote vers le pointillé en cousant, au plus à 60° par seconde (les deux tiers du pivot), et ne s'arrête pas dans les angles ; note plafonnée à 85 % (inchangé).
- **Jouabilité**, réglée sur des couturières simulées (60 images par seconde, trois graines, quatre pièces en coton) : la soigneuse (corrige l'angle et l'écart, s'arrête et pivote au-delà de 20°) coud à 100 % ; la pressée (lapin, sans s'arrêter) 78 % ; les mains libres ratent les pièces à angles et à courbes (23 à 31 % ; le col Claudine, une couture courte et droite, se coud presque sans pivoter) ; l'assistée sans s'arrêter 75 % en moyenne. La spec demandait « assistée au-dessus de 60 % » : retenu en moyenne, 50 % au pire.
- **Les commandes** : A / ← pivotent comme ◀, D / → comme ▶ ; W / ↑ plus vite, S / ↓ moins vite (liées seulement pendant la couture, comme Espace) ; glisser en tenant « Coudre » vers la gauche fait comme ◀. Au doigt, ◀ ▶ se tiennent d'un autre doigt.
- **À l'écran** : le tissu tourne de l'angle ; la couture penche quand on dévie (l'aiguille avance toujours vers le haut).
- **Scénario** : glisser tout le temps du même côté fait maintenant tourner le tissu sans fin (l'aiguille tourne en rond) : la couture ratée est sous 50 % ; la deuxième pièce se coud avec l'assistance, à vitesse normale (49 %), un second doigt qui glisse n'y change rien.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; cinq variantes du brouillon échouent sur la vérification qui les garde (une sixième, l'assistance qui pivoterait sans limite, est bornée par le pivot de 90° par seconde : elle ne change rien). Dans Studio : l'écran de couture vu, « Coudre » et ◀ ▶ côte à côte.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `machine-pivot`, créée depuis `main`. Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Un relevé fait avec la nouvelle machine, aux trois vitesses.** Attendu : accepté par le serveur (nombre de mesures, durée). Test : `19_machine_coudre`.
- **Une image très lente (téléphone qui rame).** Attendu : rien ne saute (DT_MAX), le pivot et l'avance restent bornés. Test : `19_machine_coudre`.
- **La fenêtre fermée en tenant A ou ◀.** Attendu : le tissu cesse de pivoter ; A / D et W / S rendus au jeu. Test : scénario (A / D liées tant que la machine est affichée).
- **Une pièce sans angle (col Claudine) et une pièce à courbes (manche ballon).** Attendu : jouables, la soigneuse y coud à 90 % au moins. Test : `19_machine_coudre`.
- **Le tissu qui glisse.** Attendu : la soie tire davantage que le coton. Test : `19_machine_coudre`.

---

### Task 1: La machine qui pivote, et son écran

**Files:**
- Modify: `src/client/Atelier/MachineCoudre.luau` (réécrite), `src/client/Atelier/EcranCouture.luau`
- Modify: `tests/unitaires/19_machine_coudre.luau` (réécrit), `tests/scenario.luau`

**Interfaces:**
- Consumes: `Patron.trajetCouture`, `Catalogue.piece(id).coutures` et `contour`, `Catalogue.tissu(id).matiere`, `Notation.noteCouture` (existants).
- Produces: `MachineCoudre.nouvelle(idPiece, graine, matiere)` ; `:avancer(dt, cousant, rotation)` ; `:tirage(t)` ; `:virage(k)` → angle signé ou nil ; `:etat()` → aussi `angle` et `virage = { angle, distance }` ; `MachineCoudre.ROTATION_MAX`, `ROTATION_ASSISTANCE`, `TIRAGE`, `GLISSE`, `AVANCE_MIN` ; à l'écran, `PivoterGauche`, `PivoterDroite` et l'action `AtelierPivoter`.

- [ ] **Step 1: Écrire les tests**

Le test de la machine est réécrit en entier.

Créer `tests/unitaires/19_machine_coudre.luau` :

```lua
-- La machine à coudre (sous-projet 8) : on fait avancer le tissu sous l'aiguille et on le fait pivoter pour suivre le
-- pointillé ; dans un angle, on s'arrête et on pivote ; l'assistance tient la ligne sans s'arrêter.
local MachineCoudre = U.module("MachineCoudre")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")

local ID = "corsage_droit_devant" -- coutures : le côté droit, le bas, le côté gauche (deux angles droits)
local segments, longueur = Patron.trajetCouture(ID)
local PAS = Catalogue.PAS_MESURE_COUTURE

---------------------------------------------------------------------------
-- Départ, avance, vitesse
---------------------------------------------------------------------------
local m = MachineCoudre.nouvelle(ID, 1)
local e0 = m:etat()
U.verifier(e0.segment == 1 and e0.nbSegments == #segments and e0.avance == 0 and e0.ecart == 0 and e0.angle == 0, "départ : début de la première couture, le tissu droit")
U.verifier(U.proche(e0.point.x, segments[1].a.x) and U.proche(e0.point.y, segments[1].a.y), "l'aiguille part du début du pointillé")
U.verifier(m.vitesse == "normale" and m:noteProvisoire() == nil and not m:fini(), "vitesse normale, rien de cousu")
m:avancer(1, true, 0)
U.verifier(U.proche(m:etat().avance, MachineCoudre.DT_MAX * MachineCoudre.VITESSES.normale, 1e-3), "une image trop longue est ramenée à DT_MAX")
m:avancer(0.1, true, 0)
m:avancer(0.1, true, 0)
local function uneParPas(machine)
	return #machine.ecarts == math.floor(machine.parcouru / PAS + 1e-9)
end
U.verifier(uneParPas(m) and #m.ecarts >= 2 and U.proche(m.duree, 0.3), "une mesure par 0,1 dm d'avance ; la durée compte le temps passé à coudre")
local mesures, parcouru = #m.ecarts, m.parcouru
m:avancer(0, true, 0)
m:avancer(-1, true, 0)
m:avancer(0 / 0, true, 0)
U.verifier(#m.ecarts == mesures and m.parcouru == parcouru and U.proche(m.duree, 0.3), "durée nulle, négative ou invalide : rien ne bouge")
m:avancer(0.1, true, 0 / 0)
U.verifier(m.parcouru > parcouru and uneParPas(m), "pivot invalide : compté comme nul")
U.verifier(not m:choisirVitesse("fusee") and m.vitesse == "normale" and m:choisirVitesse("lapin") and m.vitesse == "lapin", "vitesse inconnue refusée ; lapin")

---------------------------------------------------------------------------
-- Pivoter : sans coudre, l'aiguille plantée ; en cousant de travers, l'aiguille s'écarte
---------------------------------------------------------------------------
local p = MachineCoudre.nouvelle(ID, 2)
p:avancer(0.5, false, 1)
local apres = p:etat()
U.verifier(U.proche(apres.angle, MachineCoudre.ROTATION_MAX * MachineCoudre.DT_MAX) and apres.avance == 0 and #p.ecarts == 0 and p.duree == 0, "pivoter sans coudre : le tissu tourne (90° par seconde au plus), rien n'est cousu")
local droit, travers = MachineCoudre.nouvelle(ID, 2), MachineCoudre.nouvelle(ID, 2)
travers.angle = math.rad(30)
for _ = 1, 30 do
	droit:avancer(1 / 60, true, 0)
	travers:avancer(1 / 60, true, 0)
end
U.verifier(math.abs(droit.e) < 0.05 and travers.e > 0.2 and travers.s < droit.s, ("de travers, l'aiguille s'écarte et avance moins le long du pointillé (%.3f dm, %.3f)"):format(travers.e, droit.e))

---------------------------------------------------------------------------
-- Les angles : le pointillé tourne ; deux coutures séparées : on reprend au début, le tissu droit
---------------------------------------------------------------------------
local virage = MachineCoudre.nouvelle(ID, 3):virage(1)
U.verifier(virage ~= nil and U.proche(math.abs(virage), math.pi / 2, 1e-6), "corsage : un angle droit entre le côté et le bas")
local a = MachineCoudre.nouvelle(ID, 3)
while a:etat().segment == 1 do
	a:avancer(1 / 60, true, math.clamp(-(a.angle + 2 * a.e) * 3, -1, 1))
end
U.verifier(math.abs(math.abs(a.angle) - math.pi / 2) < 0.2, ("passé l'angle, le tissu est de travers d'un angle droit (%.0f°)"):format(math.deg(a.angle)))
local avantPivot = a.e
for _ = 1, 30 do
	a:avancer(1 / 60, true, 0)
end
U.verifier(math.abs(a.e - avantPivot) > 0.2, "qui coud sans pivoter s'écarte vite")
local separee = MachineCoudre.nouvelle("jupe_trapeze_devant", 4) -- coutures : le haut, le côté droit, puis le côté gauche
U.verifier(separee:virage(1) ~= nil and separee:virage(2) == nil, "jupe trapèze : un angle entre le haut et le côté ; le côté gauche est une couture séparée")
separee.k, separee.s, separee.e, separee.angle = 2, separee.longueurs[2] - 0.01, 0.3, 0.4
separee:avancer(1 / 60, true, 0)
local e3 = separee:etat()
U.verifier(e3.segment == 3 and math.abs(e3.ecart) < 0.005 and math.abs(e3.angle) < 0.01, "couture séparée : l'aiguille reprend au début de son pointillé, le tissu droit")

---------------------------------------------------------------------------
-- Couturières simulées (60 images par seconde) : la soigneuse corrige l'angle et l'écart, s'arrête et pivote dans les
-- angles ; la pressée coud au lapin sans s'arrêter ; les mains libres ne pivotent jamais ; l'assistée laisse faire
-- l'assistance, sans s'arrêter
---------------------------------------------------------------------------
local function couturiere(machine, facon)
	local arret, images = false, 0
	while not machine:fini() and images < 200000 do
		local voulu = math.clamp(-2 * machine.e, -0.4, 0.4)
		local rotation = if facon == "mains libres" or facon == "assistee" then 0 else math.clamp((voulu - machine.angle) * 3, -1, 1)
		local cousant = true
		if facon == "soigneuse" then
			if math.abs(machine.angle) > math.rad(20) then
				arret = true
			elseif math.abs(machine.angle) < math.rad(3) then
				arret = false
			end
			cousant = not arret
		end
		machine:avancer(1 / 60, cousant, rotation)
		images += 1
	end
	return machine:noteProvisoire() or 0
end
-- (le col Claudine, une seule couture courte et droite, se coud presque sans pivoter : il ne compte pas pour les mains
-- libres, qui doivent rater les pièces à angles et à courbes)
local PIECES = { "corsage_droit_devant", "manche_ballon", "jupe_trapeze_devant", "col_claudine" }
local notes = {}
for _, facon in ipairs({ "soigneuse", "pressee", "mains libres", "assistee" }) do
	local pire, total, n = 1, 0, 0
	for k, id in ipairs(PIECES) do
		if not (facon == "mains libres" and id == "col_claudine") then
			for graine = 1, 3 do
				local machine = MachineCoudre.nouvelle(id, 10 * k + graine, "coton")
				machine:choisirVitesse(if facon == "pressee" then "lapin" else "normale")
				machine:activerAssistance(facon == "assistee")
				local note = couturiere(machine, facon)
				pire, total, n = math.min(pire, note), total + note, n + 1
			end
		end
	end
	notes[facon] = { pire = pire, moyenne = total / n }
end
local resume = ("soigneuse %.2f (pire %.2f), pressée %.2f, mains libres %.2f, assistée %.2f (pire %.2f)"):format(notes.soigneuse.moyenne, notes.soigneuse.pire, notes.pressee.moyenne, notes["mains libres"].moyenne, notes.assistee.moyenne, notes.assistee.pire)
U.verifier(notes.soigneuse.pire >= 0.9, "la soigneuse coud à 90 % au moins (" .. resume .. ")")
U.verifier(notes.pressee.moyenne <= notes.soigneuse.moyenne - 0.15, "la pressée coud nettement moins bien (" .. resume .. ")")
U.verifier(notes["mains libres"].moyenne <= 0.35, "les mains libres ratent les pièces à angles et à courbes (" .. resume .. ")")
U.verifier(notes.assistee.moyenne >= 0.6 and notes.assistee.pire >= 0.5 and notes.assistee.moyenne <= Catalogue.PLAFOND_ASSISTANCE + 1e-9 and notes.assistee.moyenne < notes.soigneuse.moyenne, "l'assistance aide sans tout faire : 60 à 85 % en moyenne sans s'arrêter (" .. resume .. ")")

-- L'assistance ne s'arrête pas dans les angles : qui coud sans s'arrêter y rate encore des points
local assistee = MachineCoudre.nouvelle(ID, 21, "coton")
assistee:activerAssistance(true)
couturiere(assistee, "assistee")
local horsLigne = 0
for _, e in ipairs(assistee.ecarts) do
	horsLigne += if math.abs(e) > 0.15 then 1 else 0
end
U.verifier(horsLigne >= 5, ("assistée sans s'arrêter : des points hors de la ligne dans les angles (%d)"):format(horsLigne))

-- Les tissus qui glissent tirent davantage : les mains libres s'écartent plus vite sur la soie que sur le coton
local function ecartLibre(matiere)
	local machine = MachineCoudre.nouvelle("jupe_droite_devant", 5, matiere)
	for _ = 1, 120 do
		machine:avancer(1 / 60, true, 0)
	end
	return math.abs(machine.angle)
end
U.verifier(MachineCoudre.GLISSE.soie > MachineCoudre.GLISSE.coton and ecartLibre("soie") > ecartLibre("coton") and MachineCoudre.nouvelle(ID, 1, "inconnue").glisse == 1, "la soie glisse plus que le coton ; une matière inconnue, comme d'habitude")

---------------------------------------------------------------------------
-- Découd-vite, assistance comptée
---------------------------------------------------------------------------
local c = MachineCoudre.nouvelle(ID, 6)
while c:etat().segment == 1 do
	c:avancer(1 / 60, true, 0)
end
local fin1 = #c.ecarts
for _ = 1, 20 do
	c:avancer(1 / 60, true, 0)
end
local angleDebut2 = c.debuts[2].angle
U.verifier(c:decoudre() and c:etat().segment == 2 and c:etat().avance == 0 and #c.ecarts == fin1 and c.angle == angleDebut2, "découdre : la couture en cours est défaite, on reprend à l'angle")
U.verifier(c:decoudre() and c:etat().segment == 1 and #c.ecarts == 0 and c.parcouru == 0 and c.angle == 0 and c.e == 0, "découdre au début d'une couture : la précédente est défaite")
U.verifier(not c:decoudre(), "rien à découdre au départ")
local aide = MachineCoudre.nouvelle(ID, 7)
aide:activerAssistance(true)
aide:avancer(0.1, true, 0)
aide:activerAssistance(false)
aide:avancer(0.1, true, 0)
U.verifier(select(3, aide:releve()) == true, "l'assistance reste comptée après l'avoir coupée")
while aide:decoudre() do
end
U.verifier(select(3, aide:releve()) == false, "tout décousu sans assistance : elle ne compte plus")

---------------------------------------------------------------------------
-- Reproductible, et accepté par EtatAtelier aux trois vitesses
---------------------------------------------------------------------------
local r1, r2, autre = MachineCoudre.nouvelle(ID, 8), MachineCoudre.nouvelle(ID, 8), MachineCoudre.nouvelle(ID, 9)
couturiere(r1, "mains libres")
couturiere(r2, "mains libres")
couturiere(autre, "mains libres")
U.verifier(r1.ecarts[20] == r2.ecarts[20] and r1.ecarts[20] ~= autre.ecarts[20] and #r1.ecarts == math.floor(longueur / PAS + 1e-9), "même graine, même tirage ; autre graine, autre tirage ; une mesure par 0,1 dm")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local etat = EtatAtelier.nouveau()
U.commander(etat, Random.new(3))
local tissus = {}
for idPiece in pairs(DISPOSITION) do
	tissus[idPiece] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:couper(idPiece, DISPOSITION[idPiece])
end
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:epingler(idPiece)
end
for k, vitesse in ipairs({ "tortue", "normale", "lapin" }) do
	local idPiece = etat:piecesDuCroquis()[k]
	local machine = MachineCoudre.nouvelle(idPiece, k, "coton")
	machine:choisirVitesse(vitesse)
	couturiere(machine, "soigneuse")
	local r = etat:rendreCouture(idPiece, machine:releve())
	U.verifier(r.ok and U.proche(r.note, machine:noteProvisoire()), "relevé accepté par EtatAtelier à la vitesse " .. vitesse .. " : " .. tostring(r.erreur))
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(panneauC.Note.Text:match("^Couture : %d+ %%$") ~= nil, "Espace coud : " .. panneauC.Note.Text)
cliquer("Decoudre")
```

par :

```lua
verifier(panneauC.Note.Text:match("^Couture : %d+ %%$") ~= nil, "Espace coud : " .. panneauC.Note.Text)
cliquer("Decoudre")
do -- (sous-projet 8) A tenue : le tissu pivote, l'aiguille plantée (rien n'est cousu) ; D le ramène ; W / S, la vitesse
	local tissuC = fenetre.Contenu.Plateau.Tissu
	local avant = tissuC.Rotation
	local touches = M.actions.AtelierPivoter and M.actions.AtelierPivoter.touches or {}
	local liees = true
	for _, cle in ipairs({ Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.W, Enum.KeyCode.S }) do
		liees = liees and table.find(touches, cle) ~= nil
	end
	verifier(liees, "A / D, ← / → et W / S servent à la machine tant qu'elle est affichée")
	local function tenir(cle, duree)
		local touche = { KeyCode = cle, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) }
		M.actions.AtelierPivoter.f("AtelierPivoter", Enum.UserInputState.Begin, touche)
		M.avancer(duree)
		M.actions.AtelierPivoter.f("AtelierPivoter", Enum.UserInputState.End, touche)
	end
	tenir(Enum.KeyCode.A, 0.5)
	verifier(tissuC.Rotation < avant - 20 and panneauC.Note.Text == "Couture : —", ("A tenue : le tissu pivote (%.0f° → %.0f°), rien n'est cousu"):format(avant, tissuC.Rotation))
	tenir(Enum.KeyCode.D, 0.5)
	verifier(math.abs(tissuC.Rotation - avant) < 2, "D le ramène")
	tenir(Enum.KeyCode.W, 0.1)
	verifier(boutonNomme("Vitesse_lapin").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "W : plus vite (lapin)")
	tenir(Enum.KeyCode.S, 0.1)
	verifier(boutonNomme("Vitesse_normale").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "S : moins vite (normale)")
	-- ◀ tenu (souris) : comme A
	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(900, 400, 0) }
	boutonNomme("PivoterGauche").InputBegan:Fire(appui)
	M.avancer(0.5)
	UIS.InputEnded:Fire(appui)
	verifier(tissuC.Rotation < avant - 20, "◀ tenu : le tissu pivote")
	boutonNomme("PivoterDroite").InputBegan:Fire(appui)
	M.avancer(0.5)
	UIS.InputEnded:Fire(appui)
	verifier(math.abs(tissuC.Rotation - avant) < 2, "▶ le ramène")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
local ratee = tonumber(panneauC.Pieces.Ligne1.Text:match("(%d+) %%$"))
cliquer("Vitesse_lapin")
verifier(boutonNomme("Vitesse_lapin").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "vitesse lapin choisie")
-- Deuxième pièce au doigt : un second doigt qui glisse ne dirige pas l'aiguille
```

par :

```lua
local ratee = tonumber(panneauC.Pieces.Ligne1.Text:match("(%d+) %%$"))
cliquer("Vitesse_lapin")
verifier(boutonNomme("Vitesse_lapin").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "vitesse lapin choisie")
-- (sous-projet 8) l'assistance tient la ligne : la deuxième pièce se coud sans pivoter soi-même, à vitesse normale
cliquer("Vitesse_normale")
cliquer("Assistance")
verifier(panneauC.Assistance.Text == "Assistance : tient la ligne (85 % au plus)", "assistance activée")
-- Deuxième pièce au doigt : un second doigt qui glisse ne fait pas pivoter le tissu
```

Dans `tests/scenario.luau`, remplacer :

```lua
local auDoigt = tonumber(panneauC.Pieces.Ligne2.Text:match("(%d+) %%$"))
verifier(auDoigt ~= nil and auDoigt > 30, "un second doigt ne dirige pas l'aiguille : " .. tostring(auDoigt))
cliquer("Assistance")
verifier(panneauC.Assistance.Text == "Assistance : oui (85 % au plus)", "assistance activée")
```

par :

```lua
local auDoigt = tonumber(panneauC.Pieces.Ligne2.Text:match("(%d+) %%$"))
verifier(auDoigt ~= nil and auDoigt > 30, "un second doigt ne fait pas pivoter le tissu (assistée, 49 %% ; tournée à fond, moins de 20) : " .. tostring(auDoigt))
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(ratee ~= nil and ratee < 20, "la couture ratée est mal notée : " .. tostring(ratee))
```

par :

```lua
-- (sous-projet 8 : glisser tout le temps du même côté fait tourner le tissu sans fin, l'aiguille tourne en rond)
verifier(ratee ~= nil and ratee < 50, "la couture ratée est mal notée : " .. tostring(ratee))
```

Dans `tests/scenario.luau`, remplacer :

```lua
coudre(60, 400) -- en tirant tout le temps du même côté : couture ratée
```

par :

```lua
coudre(60, 400) -- en glissant tout le temps du même côté : le tissu tourne sans fin, couture ratée
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : départ : début de la première couture, le tissu droit`

- [ ] **Step 3: La machine, l'écran**

La machine est réécrite en entier.

Créer `src/client/Atelier/MachineCoudre.luau` :

```lua
-- MachineCoudre : logique du mini-jeu de couture (sans affichage), testable seule.
-- Sous-projet 8 : comme à une vraie machine, on fait avancer le tissu sous l'aiguille (tenir « Coudre ») et on le fait
-- pivoter (−1 à 1) pour garder l'aiguille sur le pointillé. L'angle du tissu par rapport au pointillé fait dériver
-- l'aiguille ; le tissu tire un peu en avançant (davantage s'il glisse : la soie, le satin…) ; à l'angle de deux coutures
-- qui se suivent, le pointillé tourne : on s'arrête et on pivote. L'écart entre l'aiguille et le pointillé est relevé
-- tous les 0,1 dm d'avance : c'est ce relevé qui est noté (Notation.noteCouture).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Notation = require(Couture:WaitForChild("Notation"))

local MachineCoudre = {}
MachineCoudre.__index = MachineCoudre

MachineCoudre.VITESSES = { tortue = 0.5, normale = 1, lapin = Catalogue.VITESSE_COUTURE_MAX } -- dm/s
MachineCoudre.ROTATION_MAX = math.rad(90) -- rad/s : le pivot le plus rapide (A / D tenus)
MachineCoudre.ROTATION_ASSISTANCE = math.rad(60) -- rad/s : l'assistance pivote moins vite
MachineCoudre.TIRAGE = 0.35 -- rad par dm cousu : ce que le tissu tire, au plus, en avançant
-- Ce que le tissu tire selon sa matière : les tissus qui glissent tirent davantage
MachineCoudre.GLISSE = {
	coton = 0.8, lin = 0.8, jute = 0.7, laine = 0.8,
	crepe = 1.2, velours = 1.2, brocart = 1,
	soie = 1.5, satin = 1.5, organza = 1.6, tulle = 1.6,
}
MachineCoudre.AVANCE_MIN = 0.2 -- même de travers, le tissu avance au moins d'un cinquième le long du pointillé
MachineCoudre.DT_MAX = 0.1 -- s : une image très lente ne fait pas sauter l'aiguille
local PAS_CALCUL = 0.02 -- dm entre deux calculs de l'écart
local PAS = Catalogue.PAS_MESURE_COUTURE

-- graine : fixe le tirage (même graine, même tissu qui tire) ; matiere (facultative) : celle du tissu de la pièce
function MachineCoudre.nouvelle(idPiece, graine, matiere)
	local segments, longueur = Patron.trajetCouture(idPiece)
	local def = Catalogue.piece(idPiece)
	local longueurs, suites = {}, {}
	for k, seg in ipairs(segments) do
		longueurs[k] = Polygone.longueur(seg)
		-- deux coutures qui se suivent sur le contour forment un angle
		suites[k] = def.coutures[k + 1] ~= nil and def.coutures[k + 1] == def.coutures[k] % #def.contour + 1
	end
	local rng = Random.new(graine or 0)
	return setmetatable({
		idPiece = idPiece,
		segments = segments,
		longueurs = longueurs,
		suites = suites,
		longueur = longueur,
		glisse = MachineCoudre.GLISSE[matiere] or 1,
		phases = { rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0, 2 * math.pi) },
		vitesse = "normale",
		assistance = false,
		assistanceUtilisee = false,
		k = 1, -- couture en cours
		s = 0, -- dm cousus sur la couture en cours
		e = 0, -- écart de l'aiguille au pointillé (dm), mesuré le long de la normale de la couture
		angle = 0, -- angle du tissu par rapport au pointillé (rad) : l'aiguille s'en écarte d'autant
		parcouru = 0, -- dm d'avance en tout
		ecarts = {},
		duree = 0,
		debuts = { { parcouru = 0, mesures = 0 } }, -- où en était le relevé au début de chaque couture
	}, MachineCoudre)
end

-- Ce que le tissu tire (rad par dm cousu) après t dm de couture
function MachineCoudre:tirage(t)
	local p = self.phases
	return MachineCoudre.TIRAGE * self.glisse * (0.6 * math.sin(1.7 * t + p[1]) + 0.4 * math.sin(0.61 * t + p[2]))
end

function MachineCoudre:fini()
	return self.k > #self.segments
end

function MachineCoudre:choisirVitesse(nom)
	if MachineCoudre.VITESSES[nom] then
		self.vitesse = nom
		return true
	end
	return false
end

function MachineCoudre:activerAssistance(actif)
	self.assistance = actif == true
end

-- Direction (vecteur unitaire) de la couture k
local function direction(seg, l)
	return (seg.b.x - seg.a.x) / l, (seg.b.y - seg.a.y) / l
end

-- Angle dont tourne le pointillé à l'angle qui suit la couture k (rad, signé), ou nil (pas d'angle)
function MachineCoudre:virage(k)
	if not self.suites[k] or not self.segments[k + 1] then
		return nil
	end
	local ax, ay = direction(self.segments[k], self.longueurs[k])
	local bx, by = direction(self.segments[k + 1], self.longueurs[k + 1])
	return math.atan2(ax * by - ay * bx, ax * bx + ay * by)
end

-- Passe à la couture suivante : dans un angle, le pointillé tourne (l'angle du tissu se décale d'autant, l'écart reste) ;
-- une couture séparée reprend au début de son pointillé, le tissu droit
local function suivante(self)
	local virage = self:virage(self.k)
	self.k += 1
	self.s = 0
	if virage then
		self.angle -= virage
	else
		self.e, self.angle = 0, 0
	end
	self.debuts[self.k] = { parcouru = self.parcouru, mesures = #self.ecarts, e = self.e, angle = self.angle }
end

local function pivoter(self, vitesseAngle, dt)
	self.angle += vitesseAngle * dt
	-- (au-delà d'un demi-tour, l'angle revient de l'autre côté)
	self.angle = (self.angle + math.pi) % (2 * math.pi) - math.pi
end

-- Une image de dt secondes. cousant : le tissu avance ; rotation : le pivot voulu par le joueur (−1 à 1). On peut pivoter
-- sans coudre (l'aiguille plantée, dans un angle) ; l'assistance, elle, ne pivote qu'en cousant.
function MachineCoudre:avancer(dt, cousant, rotation)
	if self:fini() or type(dt) ~= "number" or not (dt > 0) then
		return
	end
	dt = math.min(dt, MachineCoudre.DT_MAX)
	if type(rotation) ~= "number" or rotation ~= rotation then
		rotation = 0
	end
	rotation = math.clamp(rotation, -1, 1)
	if not cousant then
		pivoter(self, rotation * MachineCoudre.ROTATION_MAX, dt)
		return
	end
	if self.assistance then
		self.assistanceUtilisee = true
	end
	self.duree += dt
	local v = MachineCoudre.VITESSES[self.vitesse]
	local reste = v * dt
	while reste > 1e-12 and not self:fini() do
		local d = math.min(PAS_CALCUL, reste)
		local temps = d / v
		local vitesseAngle = rotation * MachineCoudre.ROTATION_MAX
		if self.assistance then
			-- elle vise le pointillé : l'angle qui ramène l'aiguille dessus en 1 dm environ
			local voulu = math.clamp(-self.e, -0.5, 0.5)
			vitesseAngle += math.clamp((voulu - self.angle) * 4, -1, 1) * MachineCoudre.ROTATION_ASSISTANCE
		end
		pivoter(self, math.clamp(vitesseAngle, -MachineCoudre.ROTATION_MAX, MachineCoudre.ROTATION_MAX), temps)
		self.angle += self:tirage(self.parcouru) * d
		local lk = self.longueurs[self.k]
		local ds = math.min(d * math.max(math.cos(self.angle), MachineCoudre.AVANCE_MIN), lk - self.s)
		local part = ds / math.max(d * math.max(math.cos(self.angle), MachineCoudre.AVANCE_MIN), 1e-12)
		self.e = math.clamp(self.e + d * part * math.sin(self.angle), -Catalogue.ECART_MAX_COUTURE, Catalogue.ECART_MAX_COUTURE)
		self.s += ds
		self.parcouru += ds
		reste -= d * part
		while self.parcouru >= (#self.ecarts + 1) * PAS - 1e-9 do
			table.insert(self.ecarts, self.e)
		end
		if self.s >= lk - 1e-9 then
			suivante(self)
		end
	end
end

-- Découd-vite : défait la couture en cours, ou la précédente si on est au début de celle-ci ; on reprend au début de
-- son pointillé, comme on y était arrivé
function MachineCoudre:decoudre()
	local k = self.k
	if k > #self.segments or self.s <= 1e-9 then
		k -= 1
	end
	if k < 1 then
		return false
	end
	local debut = self.debuts[k]
	self.k, self.s = k, 0
	self.e, self.angle = debut.e or 0, debut.angle or 0
	self.parcouru = debut.parcouru
	for i = #self.ecarts, debut.mesures + 1, -1 do
		self.ecarts[i] = nil
	end
	for j = #self.debuts, k + 1, -1 do
		self.debuts[j] = nil
	end
	if self.parcouru == 0 and not self.assistance then
		self.assistanceUtilisee = false -- tout est décousu : l'essai avec l'assistance ne compte plus
	end
	return true
end

-- Position de l'aiguille pour l'affichage (repère du patron, dm), angle du tissu, et l'angle qui vient
function MachineCoudre:etat()
	local k = math.min(self.k, #self.segments)
	local seg, lk = self.segments[k], self.longueurs[k]
	local dx, dy = direction(seg, lk)
	local s = self:fini() and lk or self.s
	local ix, iy = seg.a.x + dx * s, seg.a.y + dy * s
	local virage = not self:fini() and self:virage(k)
	return {
		segment = k,
		nbSegments = #self.segments,
		avance = s,
		longueurSegment = lk,
		ecart = self.e,
		angle = self.angle,
		ideal = { x = ix, y = iy }, -- point du pointillé sous l'aiguille
		point = { x = ix - dy * self.e, y = iy + dx * self.e }, -- aiguille, décalée de l'écart
		direction = { x = dx, y = dy },
		progression = self.parcouru / self.longueur,
		virage = virage and { angle = virage, distance = lk - s } or nil, -- l'angle au bout de cette couture
	}
end

-- Relevé à envoyer : écarts, durée passée à coudre, et si l'assistance a servi
function MachineCoudre:releve()
	return table.clone(self.ecarts), self.duree, self.assistanceUtilisee
end

-- Note de couture de ce qui est déjà cousu (nil si rien)
function MachineCoudre:noteProvisoire()
	if #self.ecarts == 0 then
		return nil
	end
	return Notation.noteCouture(self.ecarts, self.assistanceUtilisee)
end

return MachineCoudre
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
-- Écran de couture : la pièce passe sous l'aiguille, une couture après l'autre. On maintient « Coudre »
-- (ou Espace) et on glisse à gauche ou à droite pour garder l'aiguille sur le pointillé.
-- Vitesse tortue ↔ lapin, découd-vite, assistance (note plafonnée). La logique est dans MachineCoudre.
```

par :

```lua
-- Écran de couture : la pièce passe sous l'aiguille, une couture après l'autre. On maintient « Coudre »
-- (ou Espace) pour faire avancer le tissu, et on le fait pivoter (A / D, ← / →, les boutons ◀ ▶, ou en glissant) pour
-- garder l'aiguille sur le pointillé ; dans un angle, on s'arrête et on pivote (sous-projet 8). Vitesse tortue ↔ lapin
-- (W / S), découd-vite, assistance qui tient la ligne (note plafonnée). La logique est dans MachineCoudre.
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local COURSE = 100 -- px de glisser pour corriger à fond (à l'échelle 1)
```

par :

```lua
local COURSE = 100 -- px de glisser pour pivoter à fond (à l'échelle 1)
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée
```

par :

```lua
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée
local ACTION_PIVOT = "AtelierPivoter" -- A / D, ← / → : pivoter le tissu ; W / S : la vitesse
local TOUCHES_PIVOT = { [Enum.KeyCode.A] = 1, [Enum.KeyCode.Left] = 1, [Enum.KeyCode.D] = -1, [Enum.KeyCode.Right] = -1 }
local TOUCHES_VITESSE = { [Enum.KeyCode.W] = 1, [Enum.KeyCode.Up] = 1, [Enum.KeyCode.S] = -1, [Enum.KeyCode.Down] = -1 }
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local tenu = nil -- appui en cours : { entree, objet, x0, x }
```

par :

```lua
	local tenu = nil -- appui en cours : { entree, objet, x0, x }
	local pivots = {} -- touches et boutons de pivot tenus : [clé] = sens (1 : ◀, −1 : ▶)
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local boutonCoudre = UiKit.bouton({ Name = "Coudre", Text = "Coudre (maintenir)", TextSize = 18, Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, -6, 0, 58), Parent = panneau })
```

par :

```lua
	local boutonCoudre = UiKit.bouton({ Name = "Coudre", Text = "Coudre (maintenir)", TextSize = 18, Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, -124, 0, 58), Parent = panneau })
	-- ◀ ▶ : pivoter le tissu, tenus (au doigt, avec un autre doigt que celui qui tient « Coudre »)
	local boutonsPivot = {
		UiKit.boutonDoux({ Name = "PivoterGauche", Text = "◀", TextSize = 28, Position = UDim2.new(1, -118, 0, 362), Size = UDim2.fromOffset(54, 58), Parent = panneau }),
		UiKit.boutonDoux({ Name = "PivoterDroite", Text = "▶", TextSize = 28, Position = UDim2.new(1, -60, 0, 362), Size = UDim2.fromOffset(54, 58), Parent = panneau }),
	}
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		Text = "Maintiens « Coudre » (ou Espace) et glisse à gauche ou à droite : l'aiguille doit rester sur le pointillé.",
```

par :

```lua
		Text = "Tiens « Coudre » (ou Espace) pour avancer ; ◀ ▶ (A / D) font pivoter le tissu : garde l'aiguille sur le pointillé. Dans un angle, arrête-toi et pivote.",
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local function commencerPiece(id)
		machine = MachineCoudre.nouvelle(id, session.rng:NextInteger(1, 1000000))
```

par :

```lua
	local function commencerPiece(id)
		machine = MachineCoudre.nouvelle(id, session.rng:NextInteger(1, 1000000), Catalogue.tissu(session.etat.tissus[id]).matiere)
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	-- Le tissu tourne pour que la couture en cours monte vers l'aiguille, et se place sous elle
	local function dessiner()
		local e = machine:etat()
		local phi = -math.pi / 2 - math.atan2(e.direction.y, e.direction.x)
```

par :

```lua
	-- Le tissu tourne pour que la couture en cours monte vers l'aiguille quand il est droit ; de travers, elle penche
	-- (l'aiguille avance toujours vers le haut de l'écran) ; il se place sous l'aiguille
	local function dessiner()
		local e = machine:etat()
		local phi = -math.pi / 2 - math.atan2(e.direction.y, e.direction.x) - e.angle
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		boutonAssistance.Text = assistance and "Assistance : oui (85 % au plus)" or "Assistance : non"
```

par :

```lua
		boutonAssistance.Text = assistance and "Assistance : tient la ligne (85 % au plus)" or "Assistance : non"
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	-- Maintenir « Coudre » (souris ou doigt), ou Espace ; glisser corrige la direction
	local function direction()
		local course = COURSE * plateau.AbsoluteSize.X / LARGEUR_PLATEAU
		-- Glisser vers la droite pousse le tissu à droite : l'écart diminue
		return -math.clamp((tenu.x - tenu.x0) / math.max(course, 1), -1, 1)
	end
```

par :

```lua
	-- Maintenir « Coudre » (souris ou doigt), ou Espace ; pivoter : A / D, ← / →, ◀ ▶ tenus, ou glisser en tenant « Coudre »
	-- (vers la gauche comme ◀, vers la droite comme ▶)
	local function rotation()
		local r = 0
		for _, sens in pairs(pivots) do
			r += sens
		end
		if tenu and tenu.entree ~= "espace" then
			local course = COURSE * plateau.AbsoluteSize.X / LARGEUR_PLATEAU
			r -= math.clamp((tenu.x - tenu.x0) / math.max(course, 1), -1, 1)
		end
		return math.clamp(r, -1, 1)
	end
	for k, b in ipairs(boutonsPivot) do
		local sens = if k == 1 then 1 else -1
		table.insert(connexions, b.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				pivots[input] = sens
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				pivots.souris = sens
			end
		end))
	end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		ContextActionService:BindActionAtPriority(ACTION_ESPACE, function(_, etatEntree)
			if etatEntree == Enum.UserInputState.Begin then
				if not tenu then
					local souris = UserInputService:GetMouseLocation()
					tenu = { entree = "espace", x0 = souris.X, x = souris.X }
				end
			elseif tenu and tenu.entree == "espace" then
				tenu = nil -- relâchée ou annulée
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
	end
```

par :

```lua
		ContextActionService:BindActionAtPriority(ACTION_ESPACE, function(_, etatEntree)
			if etatEntree == Enum.UserInputState.Begin then
				if not tenu then
					local souris = UserInputService:GetMouseLocation()
					tenu = { entree = "espace", x0 = souris.X, x = souris.X }
				end
			elseif tenu and tenu.entree == "espace" then
				tenu = nil -- relâchée ou annulée
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
		-- A / D, ← / → pivotent tant qu'on les tient ; W / S changent de vitesse (absorbées : l'avatar ne bouge pas)
		ContextActionService:BindActionAtPriority(ACTION_PIVOT, function(_, etatEntree, objet)
			local sens = TOUCHES_PIVOT[objet.KeyCode]
			if sens then
				pivots[objet.KeyCode] = if etatEntree == Enum.UserInputState.Begin then sens else nil
			elseif etatEntree == Enum.UserInputState.Begin and TOUCHES_VITESSE[objet.KeyCode] then
				local rang = 1
				for k, v in ipairs(VITESSES) do
					rang = if v[1] == vitesse then k else rang
				end
				vitesse = VITESSES[math.clamp(rang + TOUCHES_VITESSE[objet.KeyCode], 1, #VITESSES)][1]
				if machine then
					machine:choisirVitesse(vitesse)
				end
				rafraichir()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down)
	end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		if not actif then
			ContextActionService:UnbindAction(ACTION_ESPACE)
			return
		end
```

par :

```lua
		if not actif then
			ContextActionService:UnbindAction(ACTION_ESPACE)
			ContextActionService:UnbindAction(ACTION_PIVOT)
			table.clear(pivots)
			return
		end
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		if fin then
			tenu = nil
		end
	end))
```

par :

```lua
		if fin then
			tenu = nil
		end
	end))
	-- (un bouton ◀ ▶ relâché, où que ce soit)
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pivots.souris = nil
		else
			pivots[input] = nil
		end
	end))
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		local cousant = machine ~= nil and not machine:fini() and tenu ~= nil and ctx.fenetre.Visible
		sonMachine(cousant)
		if not cousant then
			return
		end
		machine:avancer(dt, direction())
		ajouterPoints()
		if machine:fini() then
			tenu = nil
		end
		rafraichir()
	end))
```

par :

```lua
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		local actif = machine ~= nil and not machine:fini() and ctx.fenetre.Visible
		local cousant = actif and tenu ~= nil
		sonMachine(cousant)
		local r = if actif then rotation() else 0
		if not cousant and r == 0 then
			return
		end
		machine:avancer(dt, cousant, r) -- (sans coudre : le tissu pivote, l'aiguille plantée)
		ajouterPoints()
		if machine:fini() then
			tenu = nil
		end
		rafraichir()
	end))
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
		table.clear(pivots)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269409 vérifications
TOUT EST VERT : 1029 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/MachineCoudre.luau src/client/Atelier/EcranCouture.luau tests/unitaires/19_machine_coudre.luau tests/scenario.luau
git commit -m "Couture : on fait pivoter le tissu (A / D, ◀ ▶), on s'arrête dans les angles ; le tissu tire selon sa matière ; l'assistance tient la ligne sans tout faire

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan25Depot.rbxl`) et l'ouvrir dans Studio (ne toucher à aucune autre fenêtre de Studio). En édition (`execute_luau`, Edit) : mener un `EtatAtelier` jusqu'à la couture (une robe en soie) et rendre l'écran de couture dans un `ScreenGui` d'essai de `StarterGui` (une session simulée) ; le regarder (`screen_capture`), puis supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : « Coudre » et ◀ ▶ côte à côte, la consigne lisible ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7, plans 19 à 24 : des robes plus riches, à couches ; seize étiquettes ; les portraits des clientes)
```

par :

```markdown
## État actuel (sous-projet 8 en cours, plan 25 : la machine qui pivote)
```

Dans `README.md`, remplacer :

```markdown
6. **Couture** : on maintient « Coudre » (ou Espace) et on glisse pour garder l'aiguille sur le pointillé
   pendant que le tissu tire ; vitesse tortue, normale ou lapin, découd-vite, assistance (note plafonnée à 85 %).
```

par :

```markdown
6. **Couture** : on maintient « Coudre » (ou Espace) pour faire avancer le tissu, et on le fait pivoter (A / D,
   ← / →, les boutons ◀ ▶, ou en glissant) pour garder l'aiguille sur le pointillé ; le tissu tire un peu (davantage
   s'il glisse : soie, satin, organza, tulle) ; dans un angle, on s'arrête et on pivote. Vitesse tortue, normale ou
   lapin (W / S), découd-vite ; l'assistance tient la ligne mais ne s'arrête pas dans les angles (note plafonnée à
   85 %).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269409 vérifications
TOUT EST VERT : 1029 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 25 terminé : la machine qui pivote

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
