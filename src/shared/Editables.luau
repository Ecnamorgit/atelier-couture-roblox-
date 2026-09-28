-- Editables : le seul module qui touche aux API modifiables de Roblox (client uniquement).
-- Règles tirées du spike (docs/superpowers/spikes/2026-09-28-rendu-editable.md) :
-- - une création renvoie nil quand le budget mémoire est atteint (7 maillages sur PC) ;
-- - CreateDataModelContentAsync renvoie (Enum.CreateContentResult, Content) ;
-- - il faut convertir en contenu statique AVANT de détruire l'objet modifiable.
local AssetService = game:GetService("AssetService")
local dossier = script.Parent
local Maillage = require(dossier:WaitForChild("Maillage"))

local Editables = {}

-- Image modifiable remplie avec un buffer RVBA ; nil si la mémoire est pleine
function Editables.image(buf, largeur, hauteur)
	local ok, image = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(largeur, hauteur) })
	end)
	if not ok or not image then
		return nil
	end
	image:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(largeur, hauteur), buf)
	return image
end

-- Maillage modifiable à partir des données de Maillage.piece (dm), mis à l'échelle (studs par dm)
-- et centré sur sa boîte. Ajoute la doublure (faces inversées, normales opposées).
-- Retourne le maillage (ou nil si la mémoire est pleine) et le centre de la boîte en studs.
function Editables.maillage(donnees, echelle)
	local centreDm = Maillage.boite(donnees)
	local centre = centreDm * echelle
	local ok, em = pcall(function()
		return AssetService:CreateEditableMesh()
	end)
	if not ok or not em then
		return nil, centre
	end
	local sommets, uvs, dehors, dedans = {}, {}, {}, {}
	for i, p in ipairs(donnees.positions) do
		sommets[i] = em:AddVertex(p * echelle - centre)
		uvs[i] = em:AddUV(Vector2.new(donnees.uvs[i][1], donnees.uvs[i][2]))
		dehors[i] = em:AddNormal(donnees.normales[i])
		dedans[i] = em:AddNormal(-donnees.normales[i])
	end
	for _, f in ipairs(donnees.faces) do
		local a, b, c = f[1], f[2], f[3]
		local face = em:AddTriangle(sommets[a], sommets[b], sommets[c])
		em:SetFaceUVs(face, { uvs[a], uvs[b], uvs[c] })
		em:SetFaceNormals(face, { dehors[a], dehors[b], dehors[c] })
		local doublure = em:AddTriangle(sommets[a], sommets[c], sommets[b])
		em:SetFaceUVs(doublure, { uvs[a], uvs[c], uvs[b] })
		em:SetFaceNormals(doublure, { dedans[a], dedans[c], dedans[b] })
	end
	return em, centre
end

-- Contenu statique d'un objet modifiable (l'objet peut ensuite être détruit) ; nil en cas d'échec
function Editables.figer(objet)
	local ok, resultat, contenu = pcall(function()
		return AssetService:CreateDataModelContentAsync(Content.fromObject(objet))
	end)
	if ok and resultat == Enum.CreateContentResult.Success and contenu then
		return contenu
	end
	return nil
end

-- MeshPart à partir d'un contenu statique de maillage ; nil en cas d'échec
function Editables.piece(contenuMaillage)
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(contenuMaillage)
	end)
	return ok and part or nil
end

return Editables
