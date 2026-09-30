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
	ferme = Color3.fromRGB(226, 220, 223), -- un élément du catalogue pas encore ouvert
}
UiKit.LARGEUR, UiKit.HAUTEUR = 900, 560 -- taille de référence de la fenêtre (mise à l'échelle sur petit écran)
UiKit.LARGEUR_PANNEAU = 380 -- fenêtre rangée à droite pendant les postes autour du mannequin

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
			if UiKit.surClic then
				pcall(UiKit.surClic) -- (le petit clic des boutons, réglé par le script du client)
			end
			auClic(...)
		end)
	end
	return b
end

-- Un élément du catalogue pas encore ouvert (déblocages) : grisé, marqué par l'attribut « Ferme »
function UiKit.griser(bouton, ferme)
	bouton:SetAttribute("Ferme", ferme)
	if ferme then
		bouton.BackgroundColor3 = UiKit.COULEURS.ferme
		bouton.TextColor3 = UiKit.COULEURS.texteDoux
	end
end

-- Bouton secondaire (fond clair)
function UiKit.boutonDoux(props, auClic, calme)
	return UiKit.bouton(fusionner({ BackgroundColor3 = UiKit.COULEURS.secondaire, TextColor3 = UiKit.COULEURS.texte }, props), auClic, calme)
end

-- Bouton d'une action qu'on ne peut pas annuler (recommencer, livrer la robe) : le premier appui demande
-- confirmation, un second appui (au moins 0,4 s après, dans les 3 s) agit ; sinon il revient à la normale.
-- principal (facultatif) : l'allure d'un bouton principal (fond de couleur) au lieu d'un bouton doux.
UiKit.DELAI_CONFIRMATION = 3
UiKit.TEXTE_CONFIRMATION = "Vraiment ? Touche encore"
function UiKit.boutonConfirme(props, auClic, principal)
	local b
	local texte = props.Text
	local jeton = 0
	local function normal()
		b.Text = texte
		b.BackgroundColor3 = if principal then UiKit.COULEURS.accent else UiKit.COULEURS.secondaire
		b.TextColor3 = if principal then Color3.new(1, 1, 1) else UiKit.COULEURS.texte
	end
	b = (if principal then UiKit.bouton else UiKit.boutonDoux)(props, function()
		jeton += 1
		if b.Text == UiKit.TEXTE_CONFIRMATION then
			normal()
			auClic()
			return
		end
		local moi = jeton
		b.Text = UiKit.TEXTE_CONFIRMATION
		b.BackgroundColor3 = UiKit.COULEURS.alerte
		b.TextColor3 = Color3.new(1, 1, 1)
		task.delay(UiKit.DELAI_CONFIRMATION, function()
			if moi == jeton then
				normal()
			end
		end)
	end, 0.4)
	return b
end

-- Échelle d'une fenêtre de taille de référence pour tenir dans l'écran (téléphones)
-- (jamais sous 0,35 : au démarrage, Roblox peut annoncer un écran de 1 × 1)
function UiKit.echelle(tailleEcran)
	return math.clamp(math.min((tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR), 0.35, 1)
end

-- Couleur Color3 d'un triplet { r, v, b }
function UiKit.couleur(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Texte lisible d'une exigence de commande ; styles (facultatif) : scores actuels de la robe,
-- ajoutés aux exigences de style pour savoir ce qu'il reste à faire
function UiKit.exigence(e, Catalogue, styles)
	-- Arrondi du côté de la comparaison : le chiffre affiché ne contredit jamais le jugement de la cliente
	local actuel = ""
	if styles and e.style then
		local arrondi = e.type == "max" and math.ceil(styles[e.style] - 1e-9) or math.floor(styles[e.style] + 1e-9)
		actuel = (" (actuel : %d)"):format(arrondi)
	end
	if e.type == "min" then
		return ("Au moins %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style]) .. actuel
	elseif e.type == "max" then
		return ("Au plus %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style]) .. actuel
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
