-- Atelier : script de démarrage du client. Construit la fenêtre de l'atelier et affiche l'écran
-- qui correspond à l'étape de la commande en cours (accueil, carnet, achat, découpe, suite).
local Players = game:GetService("Players")

local UiKit = require(script:WaitForChild("UiKit"))
local Session = require(script:WaitForChild("Session"))

local ECRANS = {
	accueil = require(script:WaitForChild("EcranAccueil")),
	carnet = require(script:WaitForChild("EcranCarnet")),
	achat = require(script:WaitForChild("EcranAchat")),
	decoupe = require(script:WaitForChild("EcranDecoupe")),
	epinglage = require(script:WaitForChild("EcranSuite")),
}
local TITRES = {
	accueil = "Atelier de couture",
	carnet = "1. Carnet de croquis",
	achat = "2. Achat du tissu",
	decoupe = "3. Table de découpe",
	epinglage = "Toutes les pièces sont coupées !",
}

local C = UiKit.COULEURS
local joueur = Players.LocalPlayer
local session = Session.nouvelle()

local gui = UiKit.creer("ScreenGui", {
	Name = "Atelier",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui"),
})
local fenetre = UiKit.arrondir(UiKit.creer("Frame", {
	Name = "Fenetre",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(UiKit.LARGEUR, UiKit.HAUTEUR),
	BackgroundColor3 = C.fond,
	Parent = gui,
}), 14)

-- Mise à l'échelle sur les petits écrans (suit la caméra et la taille de la fenêtre du jeu)
local echelle = UiKit.creer("UIScale", { Parent = fenetre })
local connexionCamera
local function ajuster()
	local camera = workspace.CurrentCamera
	echelle.Scale = UiKit.echelle(camera and camera.ViewportSize or Vector2.new(1280, 720))
end
local function suivreCamera()
	if connexionCamera then
		connexionCamera:Disconnect()
	end
	if workspace.CurrentCamera then
		connexionCamera = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajuster)
	end
	ajuster()
end
suivreCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(suivreCamera)

local titre = UiKit.texte({
	Name = "Titre",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	Position = UDim2.fromOffset(20, 14),
	Size = UDim2.new(1, -260, 0, 32),
	Parent = fenetre,
})
local argent = UiKit.texte({
	Name = "Argent",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.new(1, -240, 0, 14),
	Size = UDim2.fromOffset(180, 32),
	Parent = fenetre,
})
UiKit.boutonDoux({
	Name = "Fermer",
	Text = "×",
	TextSize = 26,
	Position = UDim2.new(1, -50, 0, 12),
	Size = UDim2.fromOffset(36, 36),
	Parent = fenetre,
}, function()
	fenetre.Visible = false
end)
local contenu = UiKit.creer("Frame", {
	Name = "Contenu",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 60),
	Size = UDim2.new(1, -40, 1, -94),
	Parent = fenetre,
})
local message = UiKit.texte({
	Name = "Message",
	Font = Enum.Font.GothamBold,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -6),
	Size = UDim2.new(1, -40, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
	Parent = fenetre,
})
local jeton = 0
local function afficherMessage(texte, couleur)
	jeton += 1
	local moi = jeton
	message.Text = texte
	message.TextColor3 = couleur or C.texte
	message.Visible = true
	task.delay(3, function()
		if moi == jeton then
			message.Visible = false
		end
	end)
end

UiKit.bouton({
	Name = "OuvrirAtelier",
	Text = "Atelier",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(140, 44),
	Parent = gui,
}, function()
	fenetre.Visible = not fenetre.Visible
end)

-- Navigation : un écran par étape ; il se reconstruit seul quand l'état change
local etapeAffichee, fermerEcran
local function afficher()
	local etat = session.etat
	argent.Text = ("%d pièces d'or"):format(etat.argent)
	if etat.etape ~= etapeAffichee then
		if fermerEcran then
			fermerEcran()
		end
		contenu:ClearAllChildren()
		etapeAffichee = etat.etape
		titre.Text = TITRES[etat.etape] or etat.etape
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, message = afficherMessage, UiKit = UiKit })
	end
end
session:surChangement(afficher)
afficher()
