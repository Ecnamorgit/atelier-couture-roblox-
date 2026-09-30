-- Dialogue (sous-projet 5) : l'encadré où se lit ce que dit la cliente tant que la fenêtre de l'atelier est ouverte
-- (sa bulle, au-dessus de sa tête, reste pour la rue) : son prénom, ses mots, et son avis en étoiles quand elle en
-- donne un. À gauche de la fenêtre quand la place existe ; sinon en haut à gauche de l'écran, sous les boutons de
-- Roblox, par-dessus la fenêtre : il s'efface alors seul après quelques secondes. Un appui le referme jusqu'à sa
-- prochaine parole.
local Dialogue = {}
Dialogue.__index = Dialogue

Dialogue.LARGEUR = 360
Dialogue.TAILLE_TEXTE = 16
Dialogue.OR = Color3.fromRGB(232, 176, 46)
Dialogue.ETEINTE = Color3.fromRGB(222, 208, 212)
Dialogue.DUREE_PAR_DESSUS = 6 -- secondes de lecture quand il passe par-dessus la fenêtre
local MARGE = 14
local HAUT_TEXTE = 30 -- sous le prénom
local HAUTEUR_ETOILES = 28

function Dialogue.nouveau(parent, UiKit)
	local C = UiKit.COULEURS
	local self = setmetatable({ UiKit = UiKit, montre = true, parole = nil, referme = false, parDessus = true, paroles = 0 }, Dialogue)
	-- Un bouton sans texte, pas un cadre : dans Roblox, un cadre laisse passer l'appui aux boutons dessous
	self.cadre = UiKit.arrondir(UiKit.creer("TextButton", {
		Name = "Dialogue",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 252, 247),
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(Dialogue.LARGEUR, 80),
		Visible = false,
		ZIndex = 40,
		Parent = parent,
	}), 12)
	-- (un contour sous un bouton suit son texte, vide ici, sauf en mode « Border »)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.cadre })
	self.mise = UiKit.creer("UIScale", { Parent = self.cadre })
	self.nom = UiKit.texte({ Name = "Nom", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.accent, Position = UDim2.fromOffset(MARGE, 8), Size = UDim2.new(1, -2 * MARGE, 0, 20), ZIndex = 41, Parent = self.cadre })
	self.texte = UiKit.texte({ Name = "Texte", TextSize = Dialogue.TAILLE_TEXTE, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(MARGE, HAUT_TEXTE), Size = UDim2.new(1, -2 * MARGE, 0, 20), ZIndex = 41, Parent = self.cadre })
	self.etoiles = UiKit.creer("Frame", { Name = "Etoiles", BackgroundTransparency = 1, Size = UDim2.fromOffset(5 * 28, HAUTEUR_ETOILES), Visible = false, ZIndex = 41, Parent = self.cadre })
	for k = 1, 5 do
		UiKit.texte({ Name = "Etoile" .. k, Text = "★", TextSize = 26, TextColor3 = Dialogue.ETEINTE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset((k - 1) * 28, 0), Size = UDim2.fromOffset(26, HAUTEUR_ETOILES), ZIndex = 41, Parent = self.etoiles })
	end
	self.cadre.Activated:Connect(function()
		self.referme = true
		self:maj()
	end)
	return self
end

-- La cliente dit ce texte (nil : plus rien à dire) ; etoiles : son avis (1 à 5), ou nil
function Dialogue:dire(nom, texte, etoiles)
	self.parole, self.referme = texte, false
	self.paroles += 1
	local numero = self.paroles
	task.delay(Dialogue.DUREE_PAR_DESSUS, function()
		if self.paroles == numero and self.parDessus then
			self.referme = true -- par-dessus la fenêtre : lu, il s'efface
			self:maj()
		end
	end)
	if texte then
		local hauteurTexte = self.UiKit.lignes(texte, Dialogue.LARGEUR - 2 * MARGE, Dialogue.TAILLE_TEXTE) * (Dialogue.TAILLE_TEXTE + 4)
		self.nom.Text = nom or ""
		self.texte.Text = texte
		self.texte.Size = UDim2.new(1, -2 * MARGE, 0, hauteurTexte)
		self.etoiles.Visible = etoiles ~= nil
		self.etoiles.Position = UDim2.fromOffset(MARGE - 2, HAUT_TEXTE + hauteurTexte + 2)
		for k = 1, 5 do
			self.etoiles["Etoile" .. k].TextColor3 = if etoiles and k <= etoiles then Dialogue.OR else Dialogue.ETEINTE
		end
		self.cadre.Size = UDim2.fromOffset(Dialogue.LARGEUR, HAUT_TEXTE + hauteurTexte + (if etoiles then HAUTEUR_ETOILES + 4 else 0) + 10)
	end
	self:maj()
end

-- Fenêtre de l'atelier ouverte (actif) : l'encadré se voit, s'il a quelque chose à dire et n'a pas été refermé
function Dialogue:montrer(actif)
	self.montre = actif
	self:maj()
end

-- Même échelle que la fenêtre (petits écrans)
function Dialogue:echelle(e)
	self.mise.Scale = e
	if self.bord then
		self:caler(self.bord, self.haut)
	end
end

-- La fenêtre a son bord gauche en x = bord et son haut en y = haut (pixels de l'écran) : l'encadré se met à sa
-- gauche s'il y tient, sinon en haut à gauche de l'écran (par-dessus la fenêtre)
function Dialogue:caler(bord, haut)
	self.bord, self.haut = bord, haut
	local largeur = Dialogue.LARGEUR * self.mise.Scale
	self.parDessus = bord - 2 * 16 < largeur
	self.cadre.Position = if self.parDessus then UDim2.fromOffset(16, 10) else UDim2.fromOffset(bord - 16 - largeur, haut)
end

function Dialogue:maj()
	self.cadre.Visible = self.montre and self.parole ~= nil and not self.referme
end

return Dialogue
