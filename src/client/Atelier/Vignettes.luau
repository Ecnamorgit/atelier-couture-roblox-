-- Vignettes : images de l'interface (motif d'un tissu, silhouette d'un patron), converties en contenu
-- statique et gardées en cache. Si la mémoire des images est pleine : nil (l'écran affiche une couleur),
-- et on réessaie quelques secondes plus tard.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Pixels = require(Couture:WaitForChild("Pixels"))
local Editables = require(Couture:WaitForChild("Editables"))
local Patron = require(Couture:WaitForChild("Patron"))

local Vignettes = {}
Vignettes.ESSAI_APRES = 5 -- secondes avant de réessayer une image qui n'a pas pu être créée

local cache, echecs = {}, {}

-- fabriquer() renvoie buffer, largeur, hauteur ; n'est appelée que si l'image n'est pas déjà connue
local function figer(cle, fabriquer)
	if cache[cle] then
		return cache[cle]
	end
	if echecs[cle] and os.clock() - echecs[cle] < Vignettes.ESSAI_APRES then
		return nil
	end
	local buf, largeur, hauteur = fabriquer()
	local image = Editables.image(buf, largeur, hauteur)
	local contenu = image and Editables.figer(image)
	if image then
		image:Destroy()
	end
	if contenu then
		cache[cle], echecs[cle] = contenu, nil
	else
		echecs[cle] = os.clock()
	end
	return contenu
end

-- Motif répétable du tissu (256 × 256, soit 8 dm de tissu)
function Vignettes.motif(idTissu)
	return figer("motif:" .. idTissu, function()
		return Pixels.motif(idTissu), Catalogue.TAILLE_MOTIF, Catalogue.TAILLE_MOTIF
	end)
end

-- Silhouette en papier d'une pièce de patron (transparente hors de la pièce)
function Vignettes.silhouette(idPiece)
	return figer("silhouette:" .. idPiece, function()
		return Pixels.silhouette(idPiece, 128)
	end)
end

-- Pièce découpée : le vrai tissu tel qu'il était sous la pièce sur la table, transparent autour.
-- placement = { x, y, angle } sur le rouleau ; plafond = côté maximal de l'image (128 px par défaut).
function Vignettes.piece(idPiece, idTissu, placement, plafond)
	plafond = plafond or 128
	local cle = ("piece:%s:%s:%s:%s:%s:%d"):format(idPiece, idTissu, placement.x, placement.y, placement.angle, plafond)
	return figer(cle, function()
		local copie = Patron.copies(idPiece)[1]
		local buf, l, h = Pixels.imagePiece(Pixels.motif(idTissu), idPiece, placement, copie, plafond)
		return Pixels.decouper(buf, l, h, idPiece), l, h
	end)
end

-- Oublie les images des pièces découpées (commande finie ou recommencée) : elles occupent la mémoire des
-- images et ne resserviront pas. Les motifs et les silhouettes restent.
function Vignettes.oublierPieces()
	for _, t in ipairs({ cache, echecs }) do
		for cle in pairs(t) do
			if string.sub(cle, 1, 6) == "piece:" then
				t[cle] = nil
			end
		end
	end
end

return Vignettes
