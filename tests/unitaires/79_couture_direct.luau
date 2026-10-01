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
U.verifier(plateau:GetAttribute("Angle") > 25 and plateau.Signal.Visible and plateau.Signal.Text == "Arrête-toi et pivote : remets le pointillé droit", ("tissu de travers (%.0f°) : « Pivote »"):format(plateau:GetAttribute("Angle") or 0))
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
	if plateau2.Signal.Visible and plateau2.Signal.Text == "Un angle arrive : couds jusqu'au rond, puis pivote" then
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

-- (relecture) Une couturière qui obéit au signal : elle coud en corrigeant un peu (A / D) ; quand le signal lui dit de
-- s'arrêter, elle lâche Espace et pivote jusqu'à ce que le pointillé remonte droit, puis repart. Elle coud bien la pièce :
-- le signal ne la fait pas pivoter avant l'angle (la machine ne tourne le pointillé qu'à l'angle)
local ctx3 = contexte(sessionACoudre(33, "coton_blanc"))
local fermer3 = EcranCouture(ctx3)
local plateau3, panneau3 = ctx3.contenu.Plateau, ctx3.contenu.Panneau
local tenue3, espace3 = nil, false
local function presser(cle)
	if cle ~= tenue3 then
		if tenue3 then
			touche(tenue3, false)
		end
		if cle then
			touche(cle, true)
		end
		tenue3 = cle
	end
end
local function coudre(oui)
	if oui ~= espace3 then
		touche(Enum.KeyCode.Space, oui)
		espace3 = oui
	end
end
local arretee, images3, arrets = false, 0, 0
while not panneau3.Note.Text:find("^Pièce finie") and images3 < 3000 do
	local angle, ecart = math.rad(plateau3:GetAttribute("Angle")), plateau3:GetAttribute("Ecart")
	local signal = if plateau3.Signal.Visible then plateau3.Signal.Text:lower() else ""
	if not arretee and signal:find("arrête%-toi") then
		arretee, arrets = true, arrets + 1
	end
	if arretee then
		coudre(false)
		presser(if angle > math.rad(1) then Enum.KeyCode.D elseif angle < -math.rad(1) then Enum.KeyCode.A else nil)
		arretee = math.abs(angle) > math.rad(1)
	else
		local voulu = math.clamp(-2 * ecart, -0.4, 0.4) - angle
		presser(if voulu > 0.01 then Enum.KeyCode.A elseif voulu < -0.01 then Enum.KeyCode.D else nil)
		coudre(true)
	end
	M.avancer(1 / 60)
	images3 += 1
end
coudre(false)
presser(nil)
local noteObeissante = tonumber(panneau3.Note.Text:match("(%d+) %%"))
U.verifier(panneau3.Note.Text:find("^Pièce finie") ~= nil and noteObeissante ~= nil and noteObeissante >= 90 and arrets >= 2, ("qui obéit au signal finit la pièce, et la coud bien : %s (%d arrêts, %d images)"):format(panneau3.Note.Text, arrets, images3))
fermer3()
