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
-- (les étapes d'abord, sans le temps de lecture : chaque conseil se lit ensuite au moins AFFICHAGE_MIN)
local AFFICHAGE_MIN = GuideCouture.AFFICHAGE_MIN
GuideCouture.AFFICHAGE_MIN = 0
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

-- (relecture) Le temps de lire : un conseil reste au moins AFFICHAGE_MIN, même si son geste est déjà fait
GuideCouture.AFFICHAGE_MIN = AFFICHAGE_MIN
local deja = MachineCoudre.nouvelle(ID, 6)
deja.parcouru = 1
local g5 = GuideCouture.nouveau()
images(g5, deja, 60, false, 0)
U.verifier(g5.etape == 1, "geste déjà fait : le conseil reste une seconde (le temps de le lire)")
images(g5, deja, 62, false, 0)
U.verifier(g5.etape == 2, "puis il s'efface")

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
M.avancer(1.5)
U.verifier(bulle.Visible and bulle.Text == GuideCouture.CONSEILS[2], "Espace tenu : le conseil suivant")
local aide = ctx.contenu.Panneau.Aide
U.verifier(aide.Text == "?" and aide.TextSize >= 14, "le bouton « ? »")
aide.Activated:Fire()
U.verifier(bulle.Visible and bulle.Text == GuideCouture.CONSEILS[1], "« ? » : les conseils reprennent au premier")
M.avancer(0.5)
U.verifier(bulle.Text == GuideCouture.CONSEILS[1], "« ? » en cours de pièce (déjà 0,5 dm cousu) : le premier conseil reste lisible")
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
