-- MachineCoudre : logique du mini-jeu de couture (sans affichage), testable seule.
-- L'aiguille suit les coutures de la pièce l'une après l'autre. Le tissu tire d'un côté ou de l'autre
-- (la dérive) ; le joueur corrige en glissant (direction de −1 à 1). On relève l'écart entre l'aiguille
-- et le pointillé tous les 0,1 dm de trajet : c'est ce relevé qui est noté (Notation.noteCouture).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Notation = require(Couture:WaitForChild("Notation"))

local MachineCoudre = {}
MachineCoudre.__index = MachineCoudre

MachineCoudre.VITESSES = { tortue = 0.5, normale = 1, lapin = Catalogue.VITESSE_COUTURE_MAX } -- dm/s
MachineCoudre.PENTE_MAX = 0.8 -- écart corrigé par dm cousu quand on glisse à fond (direction ±1)
MachineCoudre.AMPLITUDE_DERIVE = 0.3 -- écart pris par dm cousu quand le tissu tire le plus
MachineCoudre.DT_MAX = 0.1 -- s : une image très lente ne fait pas sauter l'aiguille
local PAS_CALCUL = 0.02 -- dm entre deux calculs de l'écart
local PAS = Catalogue.PAS_MESURE_COUTURE

-- graine : fixe la dérive (même graine, même tissu qui tire)
function MachineCoudre.nouvelle(idPiece, graine)
	local segments, longueur = Patron.trajetCouture(idPiece)
	local longueurs = {}
	for k, seg in ipairs(segments) do
		longueurs[k] = Polygone.longueur(seg)
	end
	local rng = Random.new(graine or 0)
	return setmetatable({
		idPiece = idPiece,
		segments = segments,
		longueurs = longueurs,
		longueur = longueur,
		phases = { rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0, 2 * math.pi) },
		vitesse = "normale",
		assistance = false,
		assistanceUtilisee = false,
		k = 1, -- couture en cours
		s = 0, -- dm cousus sur la couture en cours
		e = 0, -- écart de l'aiguille au pointillé (dm), mesuré le long de la normale de la couture
		parcouru = 0, -- dm cousus en tout
		ecarts = {},
		duree = 0,
		debuts = { { parcouru = 0, mesures = 0 } }, -- où en était le relevé au début de chaque couture
	}, MachineCoudre)
end

-- Dérive du tissu (écart pris par dm cousu) après t dm de couture
function MachineCoudre:derive(t)
	local p = self.phases
	return MachineCoudre.AMPLITUDE_DERIVE * (0.6 * math.sin(1.7 * t + p[1]) + 0.4 * math.sin(0.61 * t + p[2]))
end

function MachineCoudre:fini()
	return self.k > #self.segments
end

function MachineCoudre:choisirVitesse(nom)
	if MachineCoudre.VITESSES[nom] then
		self.vitesse = nom
		return true
	end
	return false
end

function MachineCoudre:activerAssistance(actif)
	self.assistance = actif == true
end

-- Coud pendant dt secondes ; direction = correction du joueur (−1 à 1), ignorée avec l'assistance
function MachineCoudre:avancer(dt, direction)
	if self:fini() or type(dt) ~= "number" or not (dt > 0) then
		return
	end
	dt = math.min(dt, MachineCoudre.DT_MAX)
	if type(direction) ~= "number" or direction ~= direction then
		direction = 0
	end
	direction = math.clamp(direction, -1, 1)
	if self.assistance then
		self.assistanceUtilisee = true
	end
	self.duree += dt
	local reste = MachineCoudre.VITESSES[self.vitesse] * dt
	while reste > 1e-12 and not self:fini() do
		local lk = self.longueurs[self.k]
		local ds = math.min(PAS_CALCUL, reste, lk - self.s)
		local pente
		if self.assistance then
			pente = math.clamp(-self.e / math.max(ds, 1e-9), -MachineCoudre.PENTE_MAX, MachineCoudre.PENTE_MAX)
		else
			pente = self:derive(self.parcouru) + direction * MachineCoudre.PENTE_MAX
		end
		self.e = math.clamp(self.e + pente * ds, -Catalogue.ECART_MAX_COUTURE, Catalogue.ECART_MAX_COUTURE)
		self.s += ds
		self.parcouru += ds
		reste -= ds
		while self.parcouru >= (#self.ecarts + 1) * PAS - 1e-9 do
			table.insert(self.ecarts, self.e)
		end
		if self.s >= lk - 1e-9 then
			-- Couture suivante : l'aiguille est remise au début de son pointillé
			self.k += 1
			self.s, self.e = 0, 0
			self.debuts[self.k] = { parcouru = self.parcouru, mesures = #self.ecarts }
		end
	end
end

-- Découd-vite : défait la couture en cours, ou la précédente si on est au début de celle-ci
function MachineCoudre:decoudre()
	local k = self.k
	if k > #self.segments or self.s <= 1e-9 then
		k -= 1
	end
	if k < 1 then
		return false
	end
	local debut = self.debuts[k]
	self.k, self.s, self.e = k, 0, 0
	self.parcouru = debut.parcouru
	for i = #self.ecarts, debut.mesures + 1, -1 do
		self.ecarts[i] = nil
	end
	if self.parcouru == 0 and not self.assistance then
		self.assistanceUtilisee = false -- tout est décousu : l'essai avec l'assistance ne compte plus
	end
	return true
end

-- Position de l'aiguille pour l'affichage (repère du patron, dm)
function MachineCoudre:etat()
	local k = math.min(self.k, #self.segments)
	local seg, lk = self.segments[k], self.longueurs[k]
	local dx, dy = (seg.b.x - seg.a.x) / lk, (seg.b.y - seg.a.y) / lk
	local s = self:fini() and lk or self.s
	local ix, iy = seg.a.x + dx * s, seg.a.y + dy * s
	return {
		segment = k,
		nbSegments = #self.segments,
		avance = s,
		longueurSegment = lk,
		ecart = self.e,
		ideal = { x = ix, y = iy }, -- point du pointillé sous l'aiguille
		point = { x = ix - dy * self.e, y = iy + dx * self.e }, -- aiguille, décalée de l'écart
		direction = { x = dx, y = dy },
		progression = self.parcouru / self.longueur,
	}
end

-- Relevé à envoyer : écarts, durée passée à coudre, et si l'assistance a servi
function MachineCoudre:releve()
	return table.clone(self.ecarts), self.duree, self.assistanceUtilisee
end

-- Note de couture de ce qui est déjà cousu (nil si rien)
function MachineCoudre:noteProvisoire()
	if #self.ecarts == 0 then
		return nil
	end
	return Notation.noteCouture(self.ecarts, self.assistanceUtilisee)
end

return MachineCoudre
