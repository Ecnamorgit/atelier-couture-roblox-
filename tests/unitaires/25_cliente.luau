local Cliente = U.module("Cliente")
local Commandes = U.module("Commandes")

---------------------------------------------------------------------------
-- Tenue : la même pour une commande donnée, variée d'une commande à l'autre
---------------------------------------------------------------------------
local vues = {}
for g = 1, 40 do
	local commande = Commandes.generer(Random.new(g))
	local k = Cliente.choisir(commande)
	U.verifier(k >= 1 and k <= #Cliente.TENUES and k == Cliente.choisir(commande), "tenue stable pour une commande (" .. g .. ")")
	vues[k] = true
end
local nb = 0
for _ in pairs(vues) do
	nb += 1
end
U.verifier(nb >= 3, "au moins trois tenues différentes sur 40 commandes (" .. nb .. ")")

---------------------------------------------------------------------------
-- Description : couleurs de la tenue, silhouette selon la taille
---------------------------------------------------------------------------
local commande = { taille = "M", mesures = { poitrine = 8.8, taille = 7, hanches = 9.4 }, exigences = { { type = "min", style = "chic", valeur = 20 } } }
local tenue = Cliente.TENUES[Cliente.choisir(commande)]
local d = Cliente.description(commande)
U.verifier(d.TorsoColor == tenue.haut and d.LeftLegColor == tenue.bas and d.HeadColor == tenue.peau and d.LeftArmColor == tenue.peau, "couleurs de la tenue : peau, haut, bas")
local dS = Cliente.description({ taille = "S", exigences = commande.exigences })
local dL = Cliente.description({ taille = "L", exigences = commande.exigences })
U.verifier(dS.WidthScale < d.WidthScale and d.WidthScale < dL.WidthScale, "silhouette : S plus fine que M, M plus fine que L")

---------------------------------------------------------------------------
-- Construction : un avatar immobile, coiffé, à sa place
---------------------------------------------------------------------------
local Workspace = M.services.Workspace
local place = CFrame.new(3, 0, 40) * CFrame.Angles(0, math.rad(-120), 0)
local modele = Cliente.construire(commande, place, Workspace)
U.verifier(modele ~= nil and modele.Name == "Cliente" and modele.Parent == Workspace, "la cliente est dans l'atelier")
U.verifier(modele:FindFirstChild("Humanoid") ~= nil and M.derniereDescription ~= nil and M.derniereDescription.TorsoColor == tenue.haut, "avatar construit d'après sa description")
U.verifier(modele.HumanoidRootPart.Anchored, "elle reste en place")
U.verifier(modele:GetScale() == Cliente.ECHELLE and Cliente.ECHELLE < 1, "réduite à la taille du mannequin (un avatar Roblox est plus grand)")
U.verifier(modele.Humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None, "pas d'étiquette de nom au-dessus d'elle")
local cheveux = modele:FindFirstChild("Cheveux")
U.verifier(cheveux ~= nil and cheveux.Color == tenue.cheveux and not cheveux.CanCollide, "coiffée, aux couleurs de la tenue")
local bas = math.huge
for _, d in ipairs(modele:GetDescendants()) do
	if d:IsA("BasePart") and d.Name ~= "Cheveux" then
		bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
	end
end
local pivot = modele:GetPivot().Position
U.verifier(math.abs(bas - place.Position.Y) < 1e-6 and math.abs(pivot.X - 3) < 1e-6 and math.abs(pivot.Z - 40) < 1e-6, "posée à sa place, les pieds au sol")

---------------------------------------------------------------------------
-- Bulle de dialogue
---------------------------------------------------------------------------
Cliente.dire(modele, "Bonjour !")
local bulle = modele.Head:FindFirstChild("Bulle")
U.verifier(bulle ~= nil and bulle:IsA("BillboardGui") and bulle.Texte.Text == "Bonjour !", "la cliente parle")
U.verifier(bulle.Texte.TextSize >= 14, "texte de bulle lisible (14 px au moins)")
Cliente.dire(modele, "Merci !")
local nbBulles = 0
for _, c in ipairs(modele.Head:GetChildren()) do
	if c.Name == "Bulle" then
		nbBulles += 1
	end
end
U.verifier(nbBulles == 1 and modele.Head.Bulle.Texte.Text == "Merci !", "une seule bulle à la fois")
Cliente.dire(modele, nil)
U.verifier(modele.Head:FindFirstChild("Bulle") == nil, "plus rien à dire : la bulle disparaît")

---------------------------------------------------------------------------
-- Panne de Roblox : pas de cliente, sans erreur
---------------------------------------------------------------------------
M.echecAvatar = true
U.verifier(Cliente.construire(commande, place, Workspace) == nil, "avatar impossible : pas de cliente, sans erreur")
M.echecAvatar = false
modele:Destroy()

---------------------------------------------------------------------------
-- Une cliente qui revient (sous-projet 2) : sa propre tenue, son nom au-dessus de la tête
---------------------------------------------------------------------------
local Clientes = U.module("Clientes")
local ines = Clientes.get("ines")
local commandeInes = { cliente = "ines", taille = "S", exigences = { { type = "min", style = "gothique", valeur = 30 } } }
local dInes = Cliente.description(commandeInes)
U.verifier(dInes.TorsoColor == ines.tenue.haut and dInes.LeftLegColor == ines.tenue.bas and dInes.HeadColor == ines.tenue.peau, "Inès : sa tenue")
local modeleInes = Cliente.construire(commandeInes, place, Workspace)
local etiquette = modeleInes.Head:FindFirstChild("Nom")
U.verifier(etiquette ~= nil and etiquette:IsA("BillboardGui") and etiquette.Texte.Text == "Inès Lebrun" and etiquette.Texte.TextSize >= 14, "son nom au-dessus de la tête")
U.verifier(modeleInes.Cheveux.Color == ines.tenue.cheveux, "ses cheveux")
modeleInes:Destroy()
local anonyme = Cliente.construire(commande, place, Workspace)
U.verifier(anonyme.Head:FindFirstChild("Nom") == nil, "cliente anonyme (tests) : pas de nom")
anonyme:Destroy()
