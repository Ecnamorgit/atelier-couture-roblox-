-- Tutoriel (sous-projet 9) : les conseils pas à pas d'un poste, à la première robe. Un bandeau sur la barre de titre dit
-- le conseil en cours, un anneau qui pulse entoure l'élément à toucher ; chaque conseil s'efface quand le geste est fait
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
	local self = setmetatable({ UiKit = UiKit, k = nil, temps = 0 }, Tutoriel)
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

function Tutoriel:retirerAnneau()
	if self.anneau then
		self.anneau:Destroy()
	end
	self.anneau, self.contour, self.cible = nil, nil, nil
end

function Tutoriel:poserAnneau(cible)
	local UiKit = self.UiKit
	self.cible = cible
	self.anneau = UiKit.arrondir(UiKit.creer("Frame", {
		Name = "Anneau",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2 * Tutoriel.MARGE, 1, 2 * Tutoriel.MARGE),
		ZIndex = (cible.ZIndex or 1) + 1,
		Parent = cible,
	}), 12)
	self.contour = UiKit.creer("UIStroke", { Name = "Contour", Color = UiKit.COULEURS.accent, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.anneau })
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
	self.k, self.temps = k, 0
	local etape = self.etapes[k]
	self.bandeau.Text = etape.texte
	self.bandeau.Visible = true
	local cible = etape.cible and etape.cible()
	if cible then
		self:poserAnneau(cible)
	end
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

-- Une image : l'anneau suit l'élément désigné (posé de nouveau si l'écran l'a refait) et pulse ; le conseil s'efface quand
-- son geste est fait, ou au bout de sa durée (jamais avant AFFICHAGE_MIN : le temps de le lire)
function Tutoriel:image(dt)
	if not self.k then
		return
	end
	self.temps += dt
	local etape = self.etapes[self.k]
	local cible = etape.cible and etape.cible()
	if cible ~= self.cible then
		self:retirerAnneau()
		if cible then
			self:poserAnneau(cible)
		end
	end
	if self.contour then
		self.contour.Transparency = 0.35 - 0.35 * math.cos(2 * math.pi * self.temps / Tutoriel.PULSATION)
	end
	if self.temps >= Tutoriel.AFFICHAGE_MIN and ((etape.fait and etape.fait(dt)) or (etape.duree and self.temps >= etape.duree)) then
		self:aller(self.k + 1)
	end
end

return Tutoriel
