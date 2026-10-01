-- Tutoriel (sous-projet 9) : les conseils pas à pas d'un poste, à la première robe. Un bandeau sur la barre de titre dit
-- le conseil en cours, un anneau qui pulse entoure l'élément à toucher (un cadre de la fenêtre, recalé sur l'élément à
-- chaque image : ni une liste qui défile ni un écran qui vide l'élément ne le perdent) ; chaque conseil s'efface quand le geste est fait
-- (une condition lue à chaque image) ou, s'il ne demande que de lire, au bout de sa durée. « ? » les reprend au premier.
-- Rien n'est sauvegardé : les conseils vus ne reviennent pas d'eux-mêmes pendant la partie.
local RunService = game:GetService("RunService")

local Tutoriel = {}
Tutoriel.__index = Tutoriel

Tutoriel.PULSATION = 1.4 -- s : un battement de l'anneau
Tutoriel.MARGE = 6 -- px : l'anneau déborde d'autant autour de l'élément
Tutoriel.AFFICHAGE_MIN = 2 -- s : un conseil reste au moins ce temps, même si son geste est déjà fait (le lire)

-- La première robe : aucune robe livrée ni vendue (la même règle que les conseils de la couture)
function Tutoriel.premiereRobe(etat)
	return etat.livraisons + etat.ventes == 0
end

-- Pose le bandeau et « ? » sur la fenêtre (une fois, par le script du client)
function Tutoriel.installer(fenetre, UiKit)
	local C = UiKit.COULEURS
	local self = setmetatable({ UiKit = UiKit, fenetre = fenetre, k = nil, temps = 0 }, Tutoriel)
	self.bandeau = UiKit.arrondir(UiKit.texte({
		Name = "Conseil",
		Text = "",
		TextSize = 15,
		TextColor3 = C.texte,
		BackgroundColor3 = C.panneau,
		BackgroundTransparency = 0,
		Position = UDim2.fromOffset(16, 6),
		Visible = false,
		ZIndex = 20,
		Parent = fenetre,
	}), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.bandeau })
	UiKit.creer("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = self.bandeau })
	self:creerAnneau(fenetre)
	self.aide = UiKit.boutonDoux({ Name = "Aide", Text = "?", TextSize = 18, Size = UDim2.fromOffset(36, 36), Visible = false, Parent = fenetre }, function()
		self:relancer()
	end)
	self.connexion = RunService.RenderStepped:Connect(function(dt)
		self:image(dt)
	end)
	self:disposer(false)
	return self
end

-- Fenêtre centrée (deux lignes à gauche de l'argent) ou panneau à droite (deux lignes plus courtes, sur le titre)
function Tutoriel:disposer(panneau)
	if panneau then
		self.bandeau.Size = UDim2.new(1, -116, 0, 36)
		self.bandeau.TextSize = 14
		self.aide.Position = UDim2.new(1, -92, 0, 6)
	else
		self.bandeau.Size = UDim2.new(1, -410, 0, 48)
		self.bandeau.TextSize = 15
		self.aide.Position = UDim2.new(1, -384, 0, 12)
	end
end

-- L'anneau : un cadre (pas un bouton : l'appui passe à l'élément dessous), rangé dans le contenu de l'écran sous ses
-- calques (le choix d'un tissu, l'aperçu du rouleau, la mercerie… ont un ZIndex de 10 et plus)
Tutoriel.ZINDEX_ANNEAU = 9
function Tutoriel:creerAnneau(parent)
	local UiKit = self.UiKit
	self.anneau = UiKit.creer("Frame", { Name = "Anneau", BackgroundTransparency = 1, Visible = false, ZIndex = Tutoriel.ZINDEX_ANNEAU, Parent = parent })
	self.coin = UiKit.creer("UICorner", { Name = "Coin", CornerRadius = UDim.new(0, 12), Parent = self.anneau })
	self.contour = UiKit.creer("UIStroke", { Name = "Contour", Color = UiKit.COULEURS.accent, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.anneau })
end

-- L'élément est-il affiché (lui et chacun de ses parents jusqu'à la fenêtre) ?
local function affiche(element, fenetre)
	local i = element
	while i and i ~= fenetre do
		if not i:IsA("GuiObject") or not i.Visible then
			return false
		end
		i = i.Parent
	end
	return i == fenetre
end

-- Recale l'anneau sur la partie visible de l'élément désigné (rognée par les listes qui défilent et les cadres qui
-- rognent au-dessus de lui), dans le repère de la fenêtre (mise à l'échelle sur les petits écrans) ; sans élément, ou
-- rien de visible : pas d'anneau
function Tutoriel:placerAnneau()
	local fenetre = self.fenetre
	-- (dans le contenu de l'écran s'il y en a un ; un écran qui vide son contenu le détruit : on en refait un)
	local parent = fenetre:FindFirstChild("Contenu") or fenetre
	if not self.anneau.Parent then
		self:creerAnneau(parent)
	elseif self.anneau.Parent ~= parent then
		self.anneau.Parent = parent
	end
	local a, cible = self.anneau, self.cible
	a:SetAttribute("Cible", cible and cible.Name or nil)
	if not cible or not affiche(cible, fenetre) then
		a.Visible = false
		return
	end
	local p, t = cible.AbsolutePosition, cible.AbsoluteSize
	local x0, y0, x1, y1 = p.X, p.Y, p.X + t.X, p.Y + t.Y
	local i = cible.Parent
	while i and i ~= fenetre do
		if i:IsA("ScrollingFrame") or i.ClipsDescendants then
			local q, u = i.AbsolutePosition, i.AbsoluteSize
			x0, y0, x1, y1 = math.max(x0, q.X), math.max(y0, q.Y), math.min(x1, q.X + u.X), math.min(y1, q.Y + u.Y)
		end
		i = i.Parent
	end
	if x1 - x0 < 1 or y1 - y0 < 1 then
		a.Visible = false
		return
	end
	local echelle = fenetre.AbsoluteSize.X / math.max(fenetre.Size.X.Offset, 1)
	echelle = if echelle > 0 then echelle else 1
	local f, m = parent.AbsolutePosition, Tutoriel.MARGE
	a.Position = UDim2.fromOffset((x0 - f.X) / echelle - m, (y0 - f.Y) / echelle - m)
	a.Size = UDim2.fromOffset((x1 - x0) / echelle + 2 * m, (y1 - y0) / echelle + 2 * m)
	-- (l'arrondi de l'élément, élargi de la marge : un rond autour d'une molette)
	local rayon = UDim.new(0, 8 + m)
	for _, enfant in ipairs(cible:GetChildren()) do
		if enfant:IsA("UICorner") then
			rayon = UDim.new(enfant.CornerRadius.Scale, enfant.CornerRadius.Offset + m)
		end
	end
	self.coin.CornerRadius = rayon
	a.Visible = true
end

function Tutoriel:retirerAnneau()
	self.cible = nil
	self:placerAnneau()
end

-- Affiche le conseil k (au-delà du dernier : les conseils sont finis, donc vus)
function Tutoriel:aller(k)
	self:retirerAnneau()
	if not self.etapes or k > #self.etapes then
		self.k = nil
		self.bandeau.Visible = false
		if self.session and self.poste then
			self.session.tutorielsVus[self.poste] = true
		end
		return
	end
	self.k, self.temps, self.fait = k, 0, false
	local etape = self.etapes[k]
	self.bandeau.Text = etape.texte
	self.bandeau.Visible = true
	self.cible = etape.cible and etape.cible()
	self:placerAnneau()
end

-- Un poste s'ouvre. etapes : { { texte, cible = function() return GuiObject end ?, fait = function(dt) return bool end ?,
-- duree = s ? } } ; relancer (facultatif) : ce que fait « ? » à la place (la couture a ses propres conseils)
function Tutoriel:demarrer(session, poste, etapes, relancer)
	self:arreter()
	session.tutorielsVus = session.tutorielsVus or {}
	self.session, self.poste, self.etapes, self.relance = session, poste, etapes, relancer
	self.aide.Visible = etapes ~= nil or relancer ~= nil
	if etapes and Tutoriel.premiereRobe(session.etat) and not session.tutorielsVus[poste] then
		self:aller(1)
	end
end

-- « ? » : les conseils du poste reprennent au premier
function Tutoriel:relancer()
	if self.relance then
		self.relance()
	elseif self.etapes then
		self:aller(1)
	end
end

-- Le poste se ferme : ses conseils sont vus (même ceux que le joueur n'a pas attendus)
function Tutoriel:arreter()
	if self.session and self.poste and self.etapes then
		self.session.tutorielsVus[self.poste] = true
	end
	self:retirerAnneau()
	self.session, self.poste, self.etapes, self.relance, self.k = nil, nil, nil, nil, nil
	self.bandeau.Visible = false
	self.aide.Visible = false
end

-- Une image : l'anneau suit l'élément désigné (relu : l'écran a pu le refaire) et pulse ; le conseil s'efface quand
-- son geste est fait, ou au bout de sa durée (jamais avant AFFICHAGE_MIN : le temps de le lire)
function Tutoriel:image(dt)
	if not self.k or not self.fenetre.Visible then
		return -- (fenêtre fermée : les conseils attendent)
	end
	self.temps += dt
	local etape = self.etapes[self.k]
	self.cible = etape.cible and etape.cible()
	self:placerAnneau()
	self.contour.Transparency = 0.35 - 0.35 * math.cos(2 * math.pi * self.temps / Tutoriel.PULSATION)
	-- (le geste est lu à chaque image et retenu : fait puis défait pendant la lecture, il compte)
	if etape.fait and not self.fait and etape.fait(dt) then
		self.fait = true
	end
	if self.temps >= Tutoriel.AFFICHAGE_MIN and (self.fait or (etape.duree and self.temps >= etape.duree)) then
		self:aller(self.k + 1)
	end
end

return Tutoriel
