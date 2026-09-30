-- Portrait (sous-projet 7) : le portrait d'une cliente dans un médaillon — l'illustration de sa fiche si elle en a une
-- (champ image), sinon son dessin au crayon (Vignettes.portrait) ; si la mémoire des images est pleine, l'initiale de
-- son prénom. Le médaillon porte les attributs « Cliente » et « Expression » de ce qu'il montre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local Portrait = {}
Portrait.FOND = Color3.fromRGB(245, 236, 226)

-- L'expression d'une parole : l'avis en étoiles (4 ou 5 : contente ; 2 ou 3 : neutre ; 1 : déçue), sinon ses mots de
-- remerciement (contente) ou de déception (déçue), sinon neutre
function Portrait.expression(fiche, texte, etoiles)
	if etoiles then
		return if etoiles >= 4 then "contente" elseif etoiles <= 1 then "decue" else "neutre"
	elseif fiche and texte == fiche.repliques.merci then
		return "contente"
	elseif fiche and texte == fiche.repliques.deception then
		return "decue"
	end
	return "neutre"
end

-- Un médaillon vide ; props : Name, Position, Size, ZIndex, Parent (comme un cadre de UiKit)
function Portrait.creer(UiKit, props)
	local cadre = UiKit.arrondir(UiKit.creer("Frame", props), 8)
	cadre.BackgroundColor3 = Portrait.FOND
	cadre.Visible = false
	UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = cadre.ZIndex + 1, Parent = cadre })
	UiKit.texte({
		Name = "Initiale",
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = math.max(14, math.floor(cadre.Size.Y.Offset * 0.45)),
		TextColor3 = UiKit.COULEURS.accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = cadre.ZIndex + 1,
		Parent = cadre,
	})
	return cadre
end

-- Montre cette cliente, avec cette expression (idCliente nil ou inconnue : le médaillon se cache). (Relecture) Ne bloque
-- jamais : l'initiale tout de suite, le dessin dès qu'il est prêt (le premier dessin attend le moteur) ; le dessin d'une
-- demande dépassée entre-temps est laissé
local demandes = setmetatable({}, { __mode = "k" })
function Portrait.maj(cadre, idCliente, expression)
	local fiche = idCliente and Clientes.get(idCliente)
	expression = expression or "neutre"
	local numero = (demandes[cadre] or 0) + 1
	demandes[cadre] = numero
	cadre.Visible = fiche ~= nil
	cadre.Image.Visible, cadre.Initiale.Visible = false, false
	cadre:SetAttribute("Cliente", fiche and fiche.id)
	cadre:SetAttribute("Expression", fiche and expression)
	if not fiche then
		return
	end
	if fiche.image then
		cadre.Image.Image = fiche.image
		cadre.Image.Visible = true
		return
	end
	cadre.Initiale.Text = string.sub(fiche.nom, 1, 1)
	cadre.Initiale.Visible = true
	task.spawn(function()
		local contenu = Vignettes.portrait(fiche.id, expression)
		if contenu and demandes[cadre] == numero and cadre.Parent then
			cadre.Image.ImageContent = contenu
			cadre.Image.Visible, cadre.Initiale.Visible = true, false
		end
	end)
end

return Portrait
