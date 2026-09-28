-- ConstructeurRobe : construit une robe 3D à partir d'une recette (client uniquement).
-- Chaîne par pièce (voir le spike) : maillage et image modifiables → contenu statique → MeshPart,
-- puis destruction immédiate des objets modifiables : jamais plus d'un maillage et d'une image vivants.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))
local Pixels = require(dossier:WaitForChild("Pixels"))
local Maillage = require(dossier:WaitForChild("Maillage"))
local Recette = require(dossier:WaitForChild("Recette"))
local Editables = require(dossier:WaitForChild("Editables"))

local ConstructeurRobe = {}

local PLAFONDS = { robe = 256, vitrine = 128 } -- taille maximale des images de pièces (px)
local DECOLLEMENT = 0.05 -- dm : les accessoires sont posés juste au-dessus du tissu
local PAS_GARNITURE = 0.4 -- dm entre deux points d'une garniture
local JAUNE = Color3.fromRGB(255, 214, 90)

---------------------------------------------------------------------------
-- Motifs de tissu en cache (8 au plus)
---------------------------------------------------------------------------
local motifs, ordreMotifs = {}, {}
local function motif(idTissu)
	if not motifs[idTissu] then
		motifs[idTissu] = Pixels.motif(idTissu)
		table.insert(ordreMotifs, idTissu)
		if #ordreMotifs > 8 then
			motifs[table.remove(ordreMotifs, 1)] = nil
		end
	end
	return motifs[idTissu]
end

local avertis = {}
local function avertirUneFois(cle, message)
	if not avertis[cle] then
		avertis[cle] = true
		warn("[Atelier] " .. message)
	end
end

local function couleur(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

---------------------------------------------------------------------------
-- Pièces de tissu
---------------------------------------------------------------------------
local function construirePiece(p, copie, mesures, cadre, finesse)
	local tissu = Catalogue.tissu(p.tissu)
	local em, centre = Editables.maillage(Maillage.piece(p.id, copie, mesures, finesse), Catalogue.STUDS_PAR_DM)
	if not em then
		avertirUneFois("maillage", "Mémoire des maillages pleine : pièce non affichée.")
		return nil
	end
	local contenuMaillage = Editables.figer(em)
	em:Destroy()
	local part = contenuMaillage and Editables.piece(contenuMaillage)
	if not part then
		avertirUneFois("figer", "Conversion du maillage impossible : pièce non affichée.")
		return nil
	end
	local buf, largeur, hauteur = Pixels.imagePiece(motif(p.tissu), p.id, p, copie, PLAFONDS[finesse])
	local image = Editables.image(buf, largeur, hauteur)
	local contenuImage = image and Editables.figer(image)
	if image then
		image:Destroy()
	end
	if contenuImage then
		part.TextureContent = contenuImage
	else
		part.Color = couleur(tissu.motif.couleurs[1])
		avertirUneFois("image", "Mémoire des images pleine : pièce en couleur unie.")
	end
	local matiere = Catalogue.MATIERES[tissu.matiere]
	part.Material = Enum.Material[matiere.materiau]
	part.Reflectance = matiere.reflet
	part.Name = ("Piece_%s_%s"):format(p.id, copie)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = cadre * CFrame.new(centre)
	return part
end

---------------------------------------------------------------------------
-- Accessoires
---------------------------------------------------------------------------
-- Fonction (u, v) → position et normale (dm, repère du corps) sur la pièce de l'accessoire
local function surPiece(recette, a)
	local p = recette.pieces[a.piece]
	local copie = Recette.copieAccessoire(recette, a)
	local b = Polygone.boite(Catalogue.piece(p.id).contour)
	return function(u, v)
		local x, y = b.minX + u * (b.maxX - b.minX), b.minY + v * (b.maxY - b.minY)
		return Patron.point(p.id, copie, x, y, recette.mesures), Patron.normale(p.id, copie, x, y, recette.mesures)
	end
end

-- Repère posé sur le tissu : face avant (−Z) tournée vers l'extérieur
local function repere(cadre, pos, normale)
	local e = Catalogue.STUDS_PAR_DM
	local ici = cadre * ((pos + normale * DECOLLEMENT) * e)
	local direction = cadre * ((pos + normale * (DECOLLEMENT + 1)) * e) - ici
	local haut = math.abs(direction.Unit.Y) > 0.99 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	return CFrame.lookAt(ici, ici + direction, haut)
end

local function bloc(parent, taille, cf, teinte, reflet, forme)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	if forme then
		part.Shape = forme
	end
	part.Size = taille
	part.CFrame = cf
	part.Color = teinte
	part.Reflectance = reflet or 0
	part.Parent = parent
	return part
end

local FORMES = {}
function FORMES.boule(g, cf, s, c, r)
	bloc(g, Vector3.new(s, s, s), cf, c, r, Enum.PartType.Ball)
end
function FORMES.bloc(g, cf, s, c, r)
	bloc(g, Vector3.new(s, s, s * 0.3), cf, c, r)
end
function FORMES.cylindre(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.3, s, s), cf * CFrame.Angles(0, math.pi / 2, 0), c, r, Enum.PartType.Cylinder)
end
function FORMES.noeud(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.45, s * 0.3, s * 0.12), cf * CFrame.new(-s * 0.25, 0, 0) * CFrame.Angles(0, 0, 0.35), c, r)
	bloc(g, Vector3.new(s * 0.45, s * 0.3, s * 0.12), cf * CFrame.new(s * 0.25, 0, 0) * CFrame.Angles(0, 0, -0.35), c, r)
	bloc(g, Vector3.new(s * 0.16, s * 0.16, s * 0.16), cf * CFrame.new(0, 0, -s * 0.03), c, r, Enum.PartType.Ball)
end
function FORMES.fleur(g, cf, s, c, r)
	for k = 0, 4 do
		local a = k * 2 * math.pi / 5
		bloc(g, Vector3.new(s * 0.4, s * 0.4, s * 0.4), cf * CFrame.new(math.cos(a) * s * 0.28, math.sin(a) * s * 0.28, 0), c, r, Enum.PartType.Ball)
	end
	bloc(g, Vector3.new(s * 0.3, s * 0.3, s * 0.3), cf * CFrame.new(0, 0, -s * 0.05), JAUNE, 0, Enum.PartType.Ball)
end
function FORMES.croix(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.2, s, s * 0.1), cf, c, r)
	bloc(g, Vector3.new(s * 0.6, s * 0.2, s * 0.1), cf * CFrame.new(0, s * 0.2, 0), c, r)
end

local function construireAccessoire(recette, a, cadre, parent)
	local def = Catalogue.accessoire(a.id)
	local ap = def.apparence
	local groupe = Instance.new("Model")
	groupe.Name = "Accessoire_" .. a.id
	local surface = surPiece(recette, a)
	local e = Catalogue.STUDS_PAR_DM
	if def.genre == "objet" then
		local pos, n = surface(a.u, a.v)
		local cf = repere(cadre, pos, n) * CFrame.Angles(0, 0, math.rad(a.angle))
		FORMES[ap.forme](groupe, cf, ap.taille * a.echelle * e, couleur(ap.couleur), ap.reflet)
	else
		-- Garniture : ruban de petites plaques qui suivent le tissu, la face large contre la pièce
		local points = {}
		for k = 1, #a.trajet - 1 do
			local p0, p1 = a.trajet[k], a.trajet[k + 1]
			local b = Polygone.boite(Catalogue.piece(recette.pieces[a.piece].id).contour)
			local du, dv = (p1.u - p0.u) * (b.maxX - b.minX), (p1.v - p0.v) * (b.maxY - b.minY)
			local etapes = math.max(1, math.ceil(math.sqrt(du * du + dv * dv) / PAS_GARNITURE))
			for s = (k == 1 and 0 or 1), etapes do
				local t = s / etapes
				local pos, n = surface(p0.u + (p1.u - p0.u) * t, p0.v + (p1.v - p0.v) * t)
				table.insert(points, { ici = cadre * ((pos + n * DECOLLEMENT) * e), haut = cadre * ((pos + n * (DECOLLEMENT + 1)) * e) })
			end
		end
		for k = 1, #points - 1 do
			local q0, q1 = points[k].ici, points[k + 1].ici
			local longueur = (q1 - q0).Magnitude
			if longueur > 1e-6 then
				local milieu = (q0 + q1) / 2
				local normale = points[k].haut - points[k].ici
				local part = bloc(groupe, Vector3.new(ap.largeur * e, 0.02, longueur), CFrame.lookAt(milieu, q1, normale), couleur(ap.couleur), 0)
				part.Transparency = ap.transparence
			end
		end
	end
	groupe.Parent = parent
	return groupe
end

---------------------------------------------------------------------------
-- Robe complète
---------------------------------------------------------------------------
-- recette : recette valide (Recette.valider). cadre : CFrame de la taille du mannequin (studs).
-- options : { finesse = "robe" | "vitrine", etaler = bool (une pièce par image),
--             surProgres = function(fait, total) }
-- Retourne le Model « Robe » (parenté tout de suite : les pièces apparaissent au fur et à mesure).
function ConstructeurRobe.construire(recette, cadre, parent, options)
	local ok, erreur = Recette.valider(recette)
	assert(ok, "recette invalide : " .. tostring(erreur))
	options = options or {}
	local finesse = options.finesse or "robe"
	assert(PLAFONDS[finesse], "finesse inconnue : " .. tostring(finesse))
	local modele = Instance.new("Model")
	modele.Name = "Robe"
	modele.Parent = parent
	local copies = {}
	for _, p in ipairs(recette.pieces) do
		for _, copie in ipairs(Patron.copies(p.id)) do
			table.insert(copies, { piece = p, copie = copie })
		end
	end
	local accessoires = recette.accessoires or {}
	local total = #copies + #accessoires
	for k, c in ipairs(copies) do
		local part = construirePiece(c.piece, c.copie, recette.mesures, cadre, finesse)
		if part then
			part.Parent = modele
		end
		if options.surProgres then
			options.surProgres(k, total)
		end
		if options.etaler then
			task.wait()
		end
		if modele.Parent == nil then
			return modele -- robe détruite pendant la construction (vitrine quittée)
		end
	end
	for k, a in ipairs(accessoires) do
		construireAccessoire(recette, a, cadre, modele)
		if options.surProgres then
			options.surProgres(#copies + k, total)
		end
	end
	return modele
end

return ConstructeurRobe
