-- Vignettes : images de l'interface (motif d'un tissu, silhouette d'un patron), converties en contenu
-- statique et gardées en cache. Si la mémoire des images est pleine : nil (l'écran affiche une couleur),
-- et on réessaie quelques secondes plus tard.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Pixels = require(Couture:WaitForChild("Pixels"))
local Editables = require(Couture:WaitForChild("Editables"))

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

return Vignettes
