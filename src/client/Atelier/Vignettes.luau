-- Vignettes : images de l'interface (motif d'un tissu, silhouette d'un patron), converties en contenu
-- statique et gardées en cache. Si la mémoire des images est pleine : nil (l'écran affiche une couleur).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Pixels = require(Couture:WaitForChild("Pixels"))
local Editables = require(Couture:WaitForChild("Editables"))

local Vignettes = {}

local cache = {}

local function figerBuffer(cle, buf, largeur, hauteur)
	if cache[cle] ~= nil then
		return cache[cle] or nil
	end
	local image = Editables.image(buf, largeur, hauteur)
	local contenu = image and Editables.figer(image)
	if image then
		image:Destroy()
	end
	cache[cle] = contenu or false
	return contenu
end

-- Motif répétable du tissu (256 × 256, soit 8 dm de tissu)
function Vignettes.motif(idTissu)
	if cache["motif:" .. idTissu] ~= nil then
		return cache["motif:" .. idTissu] or nil
	end
	return figerBuffer("motif:" .. idTissu, Pixels.motif(idTissu), Catalogue.TAILLE_MOTIF, Catalogue.TAILLE_MOTIF)
end

-- Silhouette en papier d'une pièce de patron (transparente hors de la pièce)
function Vignettes.silhouette(idPiece)
	if cache["silhouette:" .. idPiece] ~= nil then
		return cache["silhouette:" .. idPiece] or nil
	end
	local buf, l, h = Pixels.silhouette(idPiece, 128)
	return figerBuffer("silhouette:" .. idPiece, buf, l, h)
end

return Vignettes
