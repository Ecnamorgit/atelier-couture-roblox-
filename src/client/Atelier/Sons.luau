-- Sons : les bruits de l'atelier et la musique. Tout vient de la bibliothèque libre de Roblox : sons de
-- l'interface de Roblox, effets de Pro Sound Effects, musique d'APM Music (sous licence pour les jeux
-- Roblox) ; le ronron du chat, lui, est un envoi d'un créateur de la boutique de Roblox (« cat purring », de
-- Bloonkii) : il pourrait être retiré, le chat se tairait alors. Rien n'est repris de Dressmaker. Chaque son est
-- un objet Sound de SoundService (entendu par ce joueur seulement), créé une fois. « actif » coupe tout (bouton
-- « Son » à gauche de l'écran).
local SoundService = game:GetService("SoundService")

local Sons = {}

Sons.IDS = {
	clic = 17208396156, -- Roblox GUI - Select
	clochette = 9120288444, -- Pro Sound Effects : diapason frappé, son clair
	achat = 17208380755, -- Roblox GUI - Purchase
	refus = 17208353912, -- Roblox GUI - Negative
	couper = 9118830451, -- Pro Sound Effects : ciseaux
	epingler = 17208323435, -- Roblox GUI - Equip
	couture = 9126029570, -- Pro Sound Effects : cliquetis de machine à coudre (en boucle)
	decoudre = 9113827551, -- Pro Sound Effects : tissu de lin qui se déchire
	decoration = 17208204604, -- Roblox GUI - Bubble
	photo = 17208312548, -- Roblox GUI - Camera Shutter
	reussite = 1839881844, -- APM Music : « Spinning Around (b) », 2 s enjouées
	ronron = 17867246413, -- boutique des créateurs (Bloonkii) : « cat purring », 3 s, le chat qu'on caresse
	fete = 9045129322, -- APM Music : « It's All A Big Joke - Tag2 », 3 s de bois et de guitare sautillants (robe terminée)
	echec = 17208214688, -- Roblox GUI - Call Decline
	musique = 1837589367, -- APM Music : « Fishing For Compliments », jazz tranquille (en boucle)
}
Sons.VOLUMES = { clic = 0.25, musique = 0.12, couture = 0.45 } -- 0,6 pour les autres

Sons.actif = true
local objets, voulues = {}, {}

local function objet(nom)
	local s = objets[nom]
	if not s then
		s = Instance.new("Sound")
		s.Name = "Atelier_" .. nom
		s.SoundId = "rbxassetid://" .. Sons.IDS[nom]
		s.Volume = Sons.VOLUMES[nom] or 0.6
		s.Parent = SoundService
		objets[nom] = s
	end
	return s
end

-- Un son ponctuel (vitesse : 1 par défaut)
function Sons.jouer(nom, vitesse)
	if not Sons.actif then
		return
	end
	local s = objet(nom)
	s.PlaybackSpeed = vitesse or 1
	s.TimePosition = 0
	s:Play()
end

-- Un son en boucle (machine à coudre, musique), lancé ou arrêté ; vitesse : son rythme
function Sons.boucle(nom, actif, vitesse)
	voulues[nom] = actif or nil
	local s = objet(nom)
	s.Looped = true
	s.PlaybackSpeed = vitesse or 1
	if actif and Sons.actif then
		if not s.IsPlaying then
			s:Play()
		end
	elseif s.IsPlaying then
		s:Stop()
	end
end

-- Coupe ou rétablit tout le son ; au retour, les boucles voulues reprennent (la musique)
function Sons.activer(actif)
	Sons.actif = actif
	for nom, s in pairs(objets) do
		if not actif and s.IsPlaying then
			s:Stop()
		elseif actif and voulues[nom] and not s.IsPlaying then
			s:Play()
		end
	end
end

return Sons
