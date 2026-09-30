-- Atelier : script de démarrage du client. Construit la fenêtre de l'atelier, affiche l'écran
-- qui correspond à l'étape de la commande en cours et tient la scène 3D (mannequin, robe) à jour.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Boutique = require(Couture:WaitForChild("Boutique"))
local Vitrines = require(Couture:WaitForChild("Vitrines"))

local UiKit = require(script:WaitForChild("UiKit"))
local Session = require(script:WaitForChild("Session"))
local Scene = require(script:WaitForChild("Scene"))
local Vignettes = require(script:WaitForChild("Vignettes"))
local Sons = require(script:WaitForChild("Sons"))
local Dialogue = require(script:WaitForChild("Dialogue"))
local Confettis = require(script:WaitForChild("Confettis"))

local ECRANS = {
	accueil = require(script:WaitForChild("EcranAccueil")),
	mesures = require(script:WaitForChild("EcranMesures")),
	carnet = require(script:WaitForChild("EcranCarnet")),
	achat = require(script:WaitForChild("EcranAchat")),
	decoupe = require(script:WaitForChild("EcranDecoupe")),
	epinglage = require(script:WaitForChild("EcranEpinglage")),
	couture = require(script:WaitForChild("EcranCouture")),
	decorations = require(script:WaitForChild("EcranDecorations")),
	photo = require(script:WaitForChild("EcranPresentation")),
	refus = require(script:WaitForChild("EcranRefus")),
}
local TITRES = {
	accueil = "Aiguille & Dentelle",
	mesures = "Les mesures",
	carnet = "1. Carnet de croquis",
	achat = "2. Achat du tissu",
	decoupe = "3. Table de découpe",
	epinglage = "4. Épinglage",
	couture = "5. Couture",
	decorations = "6. Décorations",
	photo = "7. Photo et livraison",
	refus = "La cliente refuse la robe",
}
-- Postes autour du mannequin : la fenêtre devient un panneau à droite pour laisser voir la robe
local EN_PANNEAU = { epinglage = true, decorations = true, photo = true, refus = true }

local C = UiKit.COULEURS
local joueur = Players.LocalPlayer

-- La liste des joueurs de Roblox (en haut à droite) cacherait le haut du panneau de l'atelier
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
-- Chaque action passe par le serveur, qui fait foi (attend sa RemoteFunction, puis l'état du joueur)
local session = Session.distante(ReplicatedStorage:WaitForChild("Atelier"))
-- L'atelier est dans la boutique du joueur (numéro posé par le serveur à son arrivée ; 0 : rue pleine)
local numero = joueur:GetAttribute("Boutique")
while numero == nil do
	joueur:GetAttributeChangedSignal("Boutique"):Wait()
	numero = joueur:GetAttribute("Boutique")
end
local origine = if numero > 0 then Boutique.emplacement(numero) else Boutique.HORS_RUE
local scene = Scene.nouvelle(Workspace, { origine = origine })
-- Les vitrines de la rue (la sienne et celles des voisins) : chaque robe est construite près de la caméra
Vitrines.nouveau(Workspace:WaitForChild("Vitrines"), function()
	local camera = Workspace.CurrentCamera
	return camera and camera.CFrame.Position or origine.Position
end)

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
-- Ce que dit la cliente, fenêtre ouverte : l'encadré de dialogue, en haut à gauche (sa bulle est pour la rue)
local dialogue = Dialogue.nouveau(gui, UiKit)
scene.surParole = function(nom, texte, etoiles)
	dialogue:dire(nom, texte, etoiles)
end

-- Mise à l'échelle sur les petits écrans (suit la caméra et la taille de la fenêtre du jeu)
local echelle = UiKit.creer("UIScale", { Parent = fenetre })
local connexionCamera
local function ajuster()
	local camera = workspace.CurrentCamera
	echelle.Scale = UiKit.echelle(camera and camera.ViewportSize or Vector2.new(1280, 720))
	dialogue:echelle(echelle.Scale)
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
-- Message sous la fenêtre (duree : secondes, 3 par défaut)
local function afficherMessage(texte, couleur, duree)
	jeton += 1
	local moi = jeton
	message.Text = texte
	message.TextColor3 = couleur or C.texte
	message.Visible = true
	task.delay(duree or 3, function()
		if moi == jeton then
			message.Visible = false
		end
	end)
end
-- Refus d'une action : en rouge ; un refus passager (serveur occupé ou injoignable) en gris, sans alarmer
local function refus(r)
	afficherMessage(r.erreur, if r.passager then C.texteDoux else C.erreur)
	if not r.passager then
		Sons.jouer("refus")
	end
end
-- Attente du serveur : au-delà de 0,3 s, « Un instant… » en gris sous la fenêtre, jusqu'à la réponse (un
-- message déjà affiché reste)
local DELAI_ATTENTE = 0.3
local appel, jetonAttente = 0, nil
session:surAttente(function(actif)
	appel += 1
	local moi = appel
	if actif then
		task.delay(DELAI_ATTENTE, function()
			if moi == appel and not message.Visible then
				afficherMessage(Session.OCCUPE, C.texteDoux, 60)
				jetonAttente = jeton
			end
		end)
	elseif jetonAttente == jeton then
		message.Visible = false
		jetonAttente = nil
	end
end)

-- « Atelier », à gauche de l'écran, rouvre la fenêtre ; il n'apparaît que fenêtre fermée (sur tablette et
-- téléphone, la fenêtre centrée passerait dessous, et un appui sur son bord la fermerait)
local boutonAtelier = UiKit.bouton({
	Name = "OuvrirAtelier",
	Text = "Atelier",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(140, 44),
	Visible = not fenetre.Visible,
	Parent = gui,
}, function()
	fenetre.Visible = true
end)
fenetre:GetPropertyChangedSignal("Visible"):Connect(function()
	boutonAtelier.Visible = not fenetre.Visible
	dialogue:montrer(fenetre.Visible)
	scene:ouvrir(fenetre.Visible, session.etat)
end)

-- Sons : un petit clic à chaque bouton, un bruit par action réussie, la musique d'ambiance ; le bouton
-- « Son », dans la barre de titre de la fenêtre, coupe tout
UiKit.surClic = function()
	Sons.jouer("clic")
end
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", couper = "couper", epingler = "epingler", abandonner = "echec", vendre = "achat", offrir = "reussite", inviter = "clochette", commandeHistoire = "clochette" }
session:surAction(function(nom, reponse)
	if nom == "rendreCouture" and session.etat.etape == "decorations" then
		-- La dernière pièce cousue : la robe est terminée, une pluie de confettis et un petit son de fête
		Confettis.lancer(gui)
		Sons.jouer("fete")
	elseif nom == "livrer" then
		Sons.jouer(if reponse.reussie then "reussite" else "echec")
	elseif SONS_ACTIONS[nom] then
		Sons.jouer(SONS_ACTIONS[nom])
	end
end)
local boutonSon
boutonSon = UiKit.boutonDoux({
	Name = "Son",
	Text = "Son : oui",
	TextSize = 14,
	Size = UDim2.fromOffset(90, 36),
	Parent = fenetre,
}, function()
	Sons.activer(not Sons.actif)
	boutonSon.Text = if Sons.actif then "Son : oui" else "Son : non"
end)
Sons.boucle("musique", true)

-- Fenêtre au centre, ou panneau à droite (titre et argent sur deux lignes)
local function disposer(enPanneau)
	if enPanneau then
		fenetre.AnchorPoint = Vector2.new(1, 0.5)
		fenetre.Position = UDim2.new(1, -16, 0.5, 0)
		fenetre.Size = UDim2.fromOffset(UiKit.LARGEUR_PANNEAU, UiKit.HAUTEUR)
		titre.Size = UDim2.new(1, -76, 0, 32)
		argent.Position = UDim2.fromOffset(20, 46)
		argent.TextXAlignment = Enum.TextXAlignment.Left
		boutonSon.Position = UDim2.new(1, -150, 0, 46) -- sur la ligne de l'argent, à droite
		contenu.Position = UDim2.fromOffset(20, 84)
		contenu.Size = UDim2.new(1, -40, 1, -118)
	else
		fenetre.AnchorPoint = Vector2.new(0.5, 0.5)
		fenetre.Position = UDim2.fromScale(0.5, 0.5)
		fenetre.Size = UDim2.fromOffset(UiKit.LARGEUR, UiKit.HAUTEUR)
		titre.Size = UDim2.new(1, -360, 0, 32)
		argent.Position = UDim2.new(1, -340, 0, 14)
		argent.TextXAlignment = Enum.TextXAlignment.Right
		boutonSon.Position = UDim2.new(1, -148, 0, 12) -- entre l'argent et la croix
		contenu.Position = UDim2.fromOffset(20, 60)
		contenu.Size = UDim2.new(1, -40, 1, -94)
	end
end

-- Navigation : un écran par étape ; il se reconstruit seul quand l'état change
local etapeAffichee, fermerEcran
local function afficher()
	local etat = session.etat
	argent.Text = ("%d pièces d'or"):format(etat.argent)
	task.spawn(scene.synchroniser, scene, etat, session.derniere) -- la construction des pièces 3D peut prendre un moment
	if etat.etape ~= etapeAffichee then
		if fermerEcran then
			fermerEcran()
		end
		contenu:ClearAllChildren()
		-- Sans pièce découpée (accueil, carnet), leurs images ne resserviront pas : place en mémoire
		if etat.etape == "accueil" or etat.etape == "carnet" then
			Vignettes.oublierPieces()
		end
		disposer(EN_PANNEAU[etat.etape] == true)
		etapeAffichee = etat.etape
		-- (la photo d'une robe libre mène à la vente, pas à une livraison)
		titre.Text = if etat.etape == "photo" and etat.commande and etat.commande.libre then "7. Photo et vente" else TITRES[etat.etape] or etat.etape
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, refus = refus, UiKit = UiKit })
	end
end
session:surChangement(afficher)
afficher()
-- Partie illisible sur le serveur : le joueur est prévenu que ses progrès ne seront pas sauvegardés
if session.avertissement then
	afficherMessage(session.avertissement, C.erreur, 10)
end
