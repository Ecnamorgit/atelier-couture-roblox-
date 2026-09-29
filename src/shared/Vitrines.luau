-- Vitrines : construit les robes exposées près du joueur et les libère quand il s'éloigne (client).
-- Contrat avec le serveur (plan 4) : chaque socle de vitrine est une BasePart rangée dans un dossier
-- (workspace.Vitrines), avec l'attribut « Recette » = Recette.encoder(recette). Le mannequin est posé
-- sur le dessus du socle, face à l'avant du socle (−Z).
local dossierModules = script.Parent
local Catalogue = require(dossierModules:WaitForChild("Catalogue"))
local Recette = require(dossierModules:WaitForChild("Recette"))
local Mannequin = require(dossierModules:WaitForChild("Mannequin"))
local ConstructeurRobe = require(dossierModules:WaitForChild("ConstructeurRobe"))

local Vitrines = {}
Vitrines.RAYON_CONSTRUIRE = 60 -- studs
Vitrines.RAYON_LIBERER = 80
Vitrines.PERIODE = 0.5 -- secondes entre deux vérifications

-- Cadre de la taille du mannequin posé sur un socle
function Vitrines.cadre(socle)
	local hauteur = socle.Size.Y / 2 + Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM
	return socle.CFrame * CFrame.new(0, hauteur, 0)
end

-- dossier : Instance qui contient les socles. position : fonction qui renvoie la position du joueur.
-- options : { etaler = bool (défaut vrai) }. Retourne { mettreAJour = function(), arreter = function() }.
function Vitrines.nouveau(dossier, position, options)
	options = options or {}
	local etats = {} -- [socle] = { texte, groupe? }
	local enCours = false
	local avertis = {}

	local function liberer(socle)
		local etat = etats[socle]
		if etat and etat.groupe then
			etat.groupe:Destroy()
		end
		etats[socle] = nil
	end

	local function construire(socle, texte)
		local recette = Recette.decoder(texte)
		local ok, erreur = false, "texte illisible"
		if recette then
			ok, erreur = Recette.valider(recette)
		end
		if not ok then
			etats[socle] = { texte = texte } -- on ne réessaie pas tant que le texte ne change pas
			if not avertis[texte] then
				avertis[texte] = true
				warn("[Atelier] Vitrine ignorée : " .. tostring(erreur))
			end
			return
		end
		local groupe = Instance.new("Model")
		groupe.Name = "Exposition"
		groupe.Parent = socle
		etats[socle] = { texte = texte, groupe = groupe }
		local cadre = Vitrines.cadre(socle)
		Mannequin.construire(recette.mesures, cadre, groupe)
		enCours = true
		task.spawn(function()
			local okC, err = pcall(ConstructeurRobe.construire, recette, cadre, groupe, {
				finesse = "vitrine",
				etaler = options.etaler ~= false,
			})
			enCours = false
			if not okC then
				warn("[Atelier] Vitrine non construite : " .. tostring(err))
			end
		end)
	end

	local function mettreAJour()
		local ici = position()
		for socle in pairs(etats) do
			if socle.Parent ~= dossier then
				liberer(socle)
			end
		end
		for _, socle in ipairs(dossier:GetChildren()) do
			if socle:IsA("BasePart") then
				local distance = (socle.CFrame.Position - ici).Magnitude
				local texte = socle:GetAttribute("Recette")
				local etat = etats[socle]
				if etat and (distance > Vitrines.RAYON_LIBERER or etat.texte ~= texte) then
					liberer(socle)
					etat = nil
				end
				-- Une seule robe en construction à la fois : budget mémoire et fluidité
				if not etat and not enCours and distance <= Vitrines.RAYON_CONSTRUIRE and type(texte) == "string" then
					construire(socle, texte)
				end
			end
		end
	end

	local cumul = 0
	local connexion = game:GetService("RunService").RenderStepped:Connect(function(dt)
		cumul += dt
		if cumul >= Vitrines.PERIODE then
			cumul = 0
			mettreAJour()
		end
	end)

	return {
		mettreAJour = mettreAJour,
		arreter = function()
			connexion:Disconnect()
			for socle in pairs(etats) do
				liberer(socle)
			end
		end,
	}
end

return Vitrines
