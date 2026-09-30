local Scene = U.module("Scene")
local Boutique = U.module("Boutique")

local Workspace = M.services.Workspace
local Players = M.services.Players
local origine = Boutique.emplacement(6)

-- Un joueur et son avatar (racine et tête), placé dans le repère de la boutique
local function placer(perso, positionLocale)
	perso.HumanoidRootPart.CFrame = origine * CFrame.new(positionLocale)
	perso.Head.CFrame = origine * CFrame.new(positionLocale + Vector3.new(0, 1.5, 0))
end
local function avatar(nom, positionLocale)
	local j = M.nouveauJoueur(nom)
	local perso = M.nouvelleInstance("Model")
	for _, n in ipairs({ "HumanoidRootPart", "Head" }) do
		local p = M.nouvelleInstance("Part")
		p.Name = n
		p.Parent = perso
	end
	placer(perso, positionLocale)
	perso.Parent = Workspace
	rawget(j, "__props").Character = perso
	return j, perso
end
local function efface(perso)
	return perso.HumanoidRootPart.LocalTransparencyModifier == 1 and perso.Head.LocalTransparencyModifier == 1
end
local function visible(perso)
	return perso.HumanoidRootPart.LocalTransparencyModifier ~= 1 and perso.Head.LocalTransparencyModifier ~= 1
end

local ancienLocal = rawget(Players, "__props").LocalPlayer
local moi, monAvatar = avatar("Moi", Vector3.new(0, 3, 37))
rawget(Players, "__props").LocalPlayer = moi
local _, visiteuse = avatar("Visiteuse", Vector3.new(0, 3, 37)) -- entre la caméra du poste et le mannequin
local _, passant = avatar("Passant", Vector3.new(0, 3, 20)) -- dans la rue

local scene = Scene.nouvelle(Workspace, { etaler = false, controles = function() end, origine = origine })
U.verifier(visible(visiteuse) and visible(passant), "caméra du joueur : tout le monde est visible")
scene:regarder(true)
U.verifier(efface(visiteuse), "caméra du poste : une visiteuse dans la boutique est effacée (elle cacherait la robe et entrerait dans la photo)")
U.verifier(visible(passant), "un passant dans la rue reste visible")
U.verifier(efface(monAvatar), "caméra du poste : l'avatar du joueur est effacé lui aussi (les caméras de Roblox ne l'effacent pas quand la caméra est fixe : il cachait la robe et entrait dans la photo)")

-- Allées et venues pendant la caméra du poste
placer(visiteuse, Vector3.new(0, 3, 15))
placer(passant, Vector3.new(3, 3, 45))
M.avancer(0.5)
U.verifier(visible(visiteuse) and efface(passant), "on suit les allées et venues : la visiteuse sortie réapparaît, le passant entré est effacé")

scene:regarder(false)
U.verifier(visible(passant) and visible(monAvatar), "caméra rendue au joueur : tout le monde est visible de nouveau, lui compris")
scene:detruire()
rawget(Players, "__props").LocalPlayer = ancienLocal
