-- CoutureData : données et règles partagées (serveur + client) du prototype « Atelier de couture ».
local CoutureData = {}

-- Taille du coupon de tissu, en cases
CoutureData.LARGEUR_COUPON = 12
CoutureData.HAUTEUR_COUPON = 10

CoutureData.Teintes = {
	{ id = "rose", masculin = "rose", feminin = "rose" },
	{ id = "bleu", masculin = "bleu", feminin = "bleue" },
	{ id = "vert", masculin = "vert", feminin = "verte" },
	{ id = "jaune", masculin = "jaune", feminin = "jaune" },
	{ id = "noir", masculin = "noir", feminin = "noire" },
	{ id = "blanc", masculin = "blanc", feminin = "blanche" },
}

-- qualite : multiplicateur appliqué à la paie du client
CoutureData.Tissus = {
	{ id = "coton_rose", nom = "Coton rose", teinte = "rose", couleur = Color3.fromRGB(240, 164, 192), prix = 12, qualite = 1 },
	{ id = "soie_rose", nom = "Soie framboise", teinte = "rose", couleur = Color3.fromRGB(214, 84, 146), prix = 28, qualite = 1.3 },
	{ id = "lin_bleu", nom = "Lin bleu ciel", teinte = "bleu", couleur = Color3.fromRGB(128, 166, 216), prix = 14, qualite = 1.05 },
	{ id = "velours_bleu", nom = "Velours bleu nuit", teinte = "bleu", couleur = Color3.fromRGB(46, 62, 130), prix = 26, qualite = 1.25 },
	{ id = "coton_vert", nom = "Coton sauge", teinte = "vert", couleur = Color3.fromRGB(150, 186, 140), prix = 12, qualite = 1 },
	{ id = "satin_vert", nom = "Satin émeraude", teinte = "vert", couleur = Color3.fromRGB(34, 130, 90), prix = 27, qualite = 1.25 },
	{ id = "coton_jaune", nom = "Coton moutarde", teinte = "jaune", couleur = Color3.fromRGB(230, 190, 80), prix = 12, qualite = 1 },
	{ id = "lin_noir", nom = "Lin noir", teinte = "noir", couleur = Color3.fromRGB(40, 38, 44), prix = 15, qualite = 1.05 },
	{ id = "coton_blanc", nom = "Coton blanc", teinte = "blanc", couleur = Color3.fromRGB(244, 240, 232), prix = 10, qualite = 1 },
}

-- Pièces du patron en cases (l = largeur, h = hauteur). Le droit-fil est vertical :
-- une pièce pivotée ne respecte plus le droit-fil et le vêtement tombe mal.
CoutureData.Vetements = {
	{
		id = "jupe",
		nom = "jupe",
		article = "une",
		feminin = true,
		prixBase = 45,
		pieces = {
			{ nom = "Devant", l = 4, h = 5 },
			{ nom = "Dos", l = 4, h = 5 },
			{ nom = "Ceinture", l = 6, h = 1 },
		},
		coutures = { "Côtés", "Ceinture", "Ourlet" },
	},
	{
		id = "haut",
		nom = "haut",
		article = "un",
		feminin = false,
		prixBase = 60,
		pieces = {
			{ nom = "Devant", l = 4, h = 4 },
			{ nom = "Dos", l = 4, h = 4 },
			{ nom = "Manche G", l = 2, h = 3 },
			{ nom = "Manche D", l = 2, h = 3 },
		},
		coutures = { "Épaules", "Manches", "Côtés", "Ourlet" },
	},
	{
		id = "robe",
		nom = "robe",
		article = "une",
		feminin = true,
		prixBase = 85,
		pieces = {
			{ nom = "Corsage devant", l = 4, h = 3 },
			{ nom = "Corsage dos", l = 4, h = 3 },
			{ nom = "Jupe devant", l = 5, h = 5 },
			{ nom = "Jupe dos", l = 5, h = 5 },
			{ nom = "Ceinture", l = 6, h = 1 },
		},
		coutures = { "Pinces", "Épaules", "Taille", "Côtés", "Ourlet" },
	},
}

CoutureData.Decorations = {
	{ id = "dentelle", nom = "Dentelle", avec = "de la dentelle", prix = 8 },
	{ id = "boutons", nom = "Boutons nacrés", avec = "des boutons nacrés", prix = 5 },
	{ id = "ruban", nom = "Ruban de satin", avec = "un ruban de satin", prix = 6 },
	{ id = "broderie", nom = "Broderie florale", avec = "une broderie florale", prix = 12 },
}

CoutureData.Clients = {
	"Madame Lefèvre",
	"Hugo",
	"Inès",
	"Monsieur Bernard",
	"Chloé",
	"Yasmine",
	"Théo",
	"Mamie Jeanne",
}

local function trouver(liste, id)
	for _, element in ipairs(liste) do
		if element.id == id then
			return element
		end
	end
	return nil
end

function CoutureData.getTissu(id)
	return trouver(CoutureData.Tissus, id)
end

function CoutureData.getVetement(id)
	return trouver(CoutureData.Vetements, id)
end

function CoutureData.getDecoration(id)
	return trouver(CoutureData.Decorations, id)
end

function CoutureData.getTeinte(id)
	return trouver(CoutureData.Teintes, id)
end

function CoutureData.prixMinimum()
	local minimum = math.huge
	for _, tissu in ipairs(CoutureData.Tissus) do
		minimum = math.min(minimum, tissu.prix)
	end
	return minimum
end

function CoutureData.phraseCommande(commande)
	local vetement = CoutureData.getVetement(commande.vetement)
	local teinte = CoutureData.getTeinte(commande.teinte)
	local adjectif = vetement.feminin and teinte.feminin or teinte.masculin
	local phrase = ("Bonjour ! Je voudrais %s %s %s"):format(vetement.article, vetement.nom, adjectif)
	local deco = commande.deco and CoutureData.getDecoration(commande.deco)
	if deco then
		return phrase .. ", avec " .. deco.avec .. ", s'il vous plaît."
	end
	return phrase .. ". Pour les finitions, je vous fais confiance !"
end

function CoutureData.taillePiece(piece, pivote)
	if pivote then
		return piece.h, piece.l
	end
	return piece.l, piece.h
end

local function estEntier(n)
	return type(n) == "number" and n == n and n == math.floor(n) and math.abs(n) < 1e6
end

-- placements[i] = { x, y, pivote } (cases, origine en haut à gauche, x et y à partir de 0).
-- Retourne la note de découpe (0 à 1) et le détail par pièce.
function CoutureData.evaluerDecoupe(vetement, placements)
	local largeur, hauteur = CoutureData.LARGEUR_COUPON, CoutureData.HAUTEUR_COUPON
	local details = {}
	local occupation = {}

	local function parcourir(p, l, h, action)
		for x = p.x, p.x + l - 1 do
			for y = p.y, p.y + h - 1 do
				action(y * largeur + x)
			end
		end
	end

	for i, piece in ipairs(vetement.pieces) do
		local p = placements[i]
		local detail = { placee = false, dedans = false, chevauche = false, pivote = false, score = 0 }
		details[i] = detail
		if type(p) == "table" and estEntier(p.x) and estEntier(p.y) then
			local l, h = CoutureData.taillePiece(piece, p.pivote == true)
			detail.placee = true
			detail.pivote = p.pivote == true
			detail.dedans = p.x >= 0 and p.y >= 0 and p.x + l <= largeur and p.y + h <= hauteur
			if detail.dedans then
				parcourir(p, l, h, function(cle)
					occupation[cle] = (occupation[cle] or 0) + 1
				end)
			end
		end
	end

	local total = 0
	for i, piece in ipairs(vetement.pieces) do
		local detail = details[i]
		if detail.dedans then
			local p = placements[i]
			local l, h = CoutureData.taillePiece(piece, detail.pivote)
			parcourir(p, l, h, function(cle)
				if occupation[cle] > 1 then
					detail.chevauche = true
				end
			end)
			local score = detail.chevauche and 0.3 or 1
			if detail.pivote then
				score *= 0.5
			end
			detail.score = score
		end
		total += detail.score
	end

	return total / #vetement.pieces, details
end

return CoutureData
