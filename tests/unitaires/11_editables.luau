local Catalogue = U.module("Catalogue")
local Maillage = U.module("Maillage")
local Editables = U.module("Editables")

local e = Catalogue.STUDS_PAR_DM
M.budget.images, M.budget.maillages = 64, 7

-- Image
local buf = buffer.create(4 * 3 * 4)
local img = Editables.image(buf, 4, 3)
U.verifier(img ~= nil and img.pixels == buf and img.Size.X == 4, "image remplie avec le buffer")
img:Destroy()
M.budget.images = 0
U.verifier(Editables.image(buf, 4, 3) == nil, "mémoire des images pleine : nil, sans erreur")
M.budget.images = 64

-- Maillage : doublure, normales, centrage
local donnees = Maillage.piece("jupe_trapeze_devant", "unique", Catalogue.TAILLES.M, "vitrine")
local em, centre = Editables.maillage(donnees, e)
U.verifier(em ~= nil and #em.sommets == #donnees.positions, "un sommet par point du maillage")
U.verifier(#em.faces == 2 * #donnees.faces, "chaque triangle a sa doublure")
local centreDm = Maillage.boite(donnees)
U.verifier(U.proche((centre - centreDm * e).Magnitude, 0), "centre en studs")
local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
for _, p in ipairs(em.sommets) do
	mn = Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
	mx = Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
end
U.verifier(U.proche(((mn + mx) / 2).Magnitude, 0, 1e-9), "maillage centré sur sa boîte (indépendant du recentrage de Roblox)")
for f = 1, #em.faces, 2 do
	local exterieur, doublure = em.faces[f], em.faces[f + 1]
	U.verifier(exterieur[1] == doublure[1] and exterieur[2] == doublure[3] and exterieur[3] == doublure[2], "doublure = triangle inversé")
	local nExt = em.normales[em.normalesFaces[f][1]]
	local nInt = em.normales[em.normalesFaces[f + 1][1]]
	U.verifier(U.proche((nExt + nInt).Magnitude, 0), "normales de la doublure opposées")
	U.verifier(em.uvsFaces[f] ~= nil and em.uvsFaces[f + 1] ~= nil, "UV sur les deux faces")
end

-- Conversion en contenu statique, puis destruction : la pièce garde sa forme
local contenu = Editables.figer(em)
U.verifier(contenu ~= nil and contenu.statique, "contenu statique obtenu")
em:Destroy()
local part = Editables.piece(contenu)
U.verifier(part ~= nil and part.ClassName == "MeshPart", "MeshPart créé depuis le contenu statique")
U.verifier(rawget(part, "__contenu").statique, "la forme vient d'un contenu statique")
U.verifier(U.proche((part.Size - (mx - mn)).Magnitude, 0, 1e-9), "taille du MeshPart = boîte du maillage")

-- Mémoire des maillages pleine : nil et le centre, sans erreur
M.budget.maillages = 0
local vide, c2 = Editables.maillage(donnees, e)
U.verifier(vide == nil and c2 ~= nil, "mémoire des maillages pleine : nil, sans erreur")
M.budget.maillages = 7
U.verifier(M.editables.images == 0 and M.editables.maillages == 0, "aucun objet modifiable oublié")
