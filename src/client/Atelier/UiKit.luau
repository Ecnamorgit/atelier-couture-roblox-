-- UiKit : outils d'interface communs (couleurs, création d'objets, boutons, messages, mise à l'échelle).
local UiKit = {}

UiKit.COULEURS = {
	fond = Color3.fromRGB(253, 244, 247),
	panneau = Color3.fromRGB(255, 255, 255),
	accent = Color3.fromRGB(214, 76, 128),
	secondaire = Color3.fromRGB(240, 214, 224),
	texte = Color3.fromRGB(58, 36, 48),
	texteDoux = Color3.fromRGB(130, 100, 115),
	ok = Color3.fromRGB(70, 160, 100),
	alerte = Color3.fromRGB(230, 140, 40),
	erreur = Color3.fromRGB(210, 60, 60),
}
UiKit.LARGEUR, UiKit.HAUTEUR = 900, 560 -- taille de référence de la fenêtre (mise à l'échelle sur petit écran)

function UiKit.creer(classe, props, enfants)
	local instance = Instance.new(classe)
	local parent
	for cle, valeur in pairs(props or {}) do
		if cle == "Parent" then
			parent = valeur
		else
			instance[cle] = valeur
		end
	end
	for _, enfant in ipairs(enfants or {}) do
		enfant.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UiKit.arrondir(instance, rayon)
	UiKit.creer("UICorner", { CornerRadius = UDim.new(0, rayon or 8), Parent = instance })
	return instance
end

local function fusionner(defaut, props)
	for cle, valeur in pairs(props or {}) do
		defaut[cle] = valeur
	end
	return defaut
end

function UiKit.texte(props)
	return UiKit.creer("TextLabel", fusionner({
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = UiKit.COULEURS.texte,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, props))
end

UiKit.DELAI_NOUVEAU = 0.4 -- s : un bouton qui vient d'apparaître ignore les clics (second clic d'un double clic)

-- Bouton ; auClic est appelé par Activated (souris, doigt, manette). calme (s, facultatif) : délai
-- pendant lequel un nouveau clic est ignoré, pour les actions à ne pas répéter par un double clic.
function UiKit.bouton(props, auClic, calme)
	local b = UiKit.creer("TextButton", fusionner({
		BackgroundColor3 = UiKit.COULEURS.accent,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = true,
		Size = UDim2.fromOffset(180, 40),
	}, props))
	UiKit.arrondir(b, 8)
	if auClic then
		local apparu, dernier = os.clock(), -math.huge
		b.Activated:Connect(function(...)
			local maintenant = os.clock()
			if maintenant - apparu < UiKit.DELAI_NOUVEAU or maintenant - dernier < (calme or 0) then
				return
			end
			dernier = maintenant
			auClic(...)
		end)
	end
	return b
end

-- Bouton secondaire (fond clair)
function UiKit.boutonDoux(props, auClic, calme)
	return UiKit.bouton(fusionner({ BackgroundColor3 = UiKit.COULEURS.secondaire, TextColor3 = UiKit.COULEURS.texte }, props), auClic, calme)
end

-- Échelle d'une fenêtre de taille de référence pour tenir dans l'écran (téléphones)
function UiKit.echelle(tailleEcran)
	return math.min(1, (tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR)
end

-- Couleur Color3 d'un triplet { r, v, b }
function UiKit.couleur(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Texte lisible d'une exigence de commande
function UiKit.exigence(e, Catalogue)
	if e.type == "min" then
		return ("Au moins %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
	elseif e.type == "max" then
		return ("Au plus %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
	elseif e.type == "qualite" then
		return ("Qualité d'au moins %d %%"):format(math.floor(e.valeur * 100 + 0.5))
	elseif e.type == "teinte" then
		return "Couleur dominante : " .. e.teinte
	elseif e.type == "accessoire" then
		return "Avec : " .. Catalogue.accessoire(e.id).nom
	end
	return "?"
end

return UiKit
