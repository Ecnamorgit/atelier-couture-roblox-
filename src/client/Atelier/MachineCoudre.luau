-- MachineCoudre : logique du mini-jeu de couture (sans affichage), testable seule.
-- Sous-projet 8 : comme à une vraie machine, on fait avancer le tissu sous l'aiguille (tenir « Coudre ») et on le fait
-- pivoter (−1 à 1) pour garder l'aiguille sur le pointillé. L'angle du tissu par rapport au pointillé fait dériver
-- l'aiguille ; le tissu tire un peu en avançant (davantage s'il glisse : la soie, le satin…) ; à l'angle de deux coutures
-- qui se suivent, le pointillé tourne : on s'arrête et on pivote. L'écart entre l'aiguille et le pointillé est relevé
-- tous les 0,1 dm d'avance : c'est ce relevé qui est noté (Notation.noteCouture).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Notation = require(Couture:WaitForChild("Notation"))

local MachineCoudre = {}
MachineCoudre.__index = MachineCoudre

MachineCoudre.VITESSES = { tortue = 0.5, normale = 1, lapin = Catalogue.VITESSE_COUTURE_MAX } -- dm/s
MachineCoudre.ROTATION_MAX = math.rad(90) -- rad/s : le pivot le plus rapide (A / D tenus)
MachineCoudre.ROTATION_ASSISTANCE = math.rad(60) -- rad/s : l'assistance pivote moins vite
MachineCoudre.TIRAGE = 0.35 -- rad par dm cousu : ce que le tissu tire, au plus, en avançant
-- Ce que le tissu tire selon sa matière : les tissus qui glissent tirent davantage
MachineCoudre.GLISSE = {
	coton = 0.8, lin = 0.8, jute = 0.7, laine = 0.8,
	crepe = 1.2, velours = 1.2, brocart = 1,
	soie = 1.5, satin = 1.5, organza = 1.6, tulle = 1.6,
}
MachineCoudre.AVANCE_MIN = 0.2 -- même de travers, le tissu avance au moins d'un cinquième le long du pointillé
MachineCoudre.DT_MAX = 0.1 -- s : une image très lente ne fait pas sauter l'aiguille
local PAS_CALCUL = 0.02 -- dm entre deux calculs de l'écart
local PAS = Catalogue.PAS_MESURE_COUTURE

-- graine : fixe le tirage (même graine, même tissu qui tire) ; matiere (facultative) : celle du tissu de la pièce
function MachineCoudre.nouvelle(idPiece, graine, matiere)
	local segments, longueur = Patron.trajetCouture(idPiece)
	local def = Catalogue.piece(idPiece)
	local longueurs, suites = {}, {}
	for k, seg in ipairs(segments) do
		longueurs[k] = Polygone.longueur(seg)
		-- deux coutures qui se suivent sur le contour forment un angle
		suites[k] = def.coutures[k + 1] ~= nil and def.coutures[k + 1] == def.coutures[k] % #def.contour + 1
	end
	local rng = Random.new(graine or 0)
	return setmetatable({
		idPiece = idPiece,
		segments = segments,
		longueurs = longueurs,
		suites = suites,
		longueur = longueur,
		glisse = MachineCoudre.GLISSE[matiere] or 1,
		phases = { rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0, 2 * math.pi) },
		vitesse = "normale",
		assistance = false,
		assistanceUtilisee = false,
		k = 1, -- couture en cours
		s = 0, -- dm cousus sur la couture en cours
		e = 0, -- écart de l'aiguille au pointillé (dm), mesuré le long de la normale de la couture
		angle = 0, -- angle du tissu par rapport au pointillé (rad) : l'aiguille s'en écarte d'autant
		parcouru = 0, -- dm d'avance en tout
		ecarts = {},
		duree = 0,
		debuts = { { parcouru = 0, mesures = 0 } }, -- où en était le relevé au début de chaque couture
	}, MachineCoudre)
end

-- Ce que le tissu tire (rad par dm cousu) après t dm de couture
function MachineCoudre:tirage(t)
	local p = self.phases
	return MachineCoudre.TIRAGE * self.glisse * (0.6 * math.sin(1.7 * t + p[1]) + 0.4 * math.sin(0.61 * t + p[2]))
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

-- Direction (vecteur unitaire) de la couture k
local function direction(seg, l)
	return (seg.b.x - seg.a.x) / l, (seg.b.y - seg.a.y) / l
end

-- Angle dont tourne le pointillé à l'angle qui suit la couture k (rad, signé), ou nil (pas d'angle)
function MachineCoudre:virage(k)
	if not self.suites[k] or not self.segments[k + 1] then
		return nil
	end
	local ax, ay = direction(self.segments[k], self.longueurs[k])
	local bx, by = direction(self.segments[k + 1], self.longueurs[k + 1])
	return math.atan2(ax * by - ay * bx, ax * bx + ay * by)
end

-- Passe à la couture suivante : dans un angle, le pointillé tourne (l'angle du tissu se décale d'autant, l'écart reste) ;
-- une couture séparée reprend au début de son pointillé, le tissu droit
local function suivante(self)
	local virage = self:virage(self.k)
	self.k += 1
	self.s = 0
	if virage then
		self.angle -= virage
	else
		self.e, self.angle = 0, 0
	end
	self.debuts[self.k] = { parcouru = self.parcouru, mesures = #self.ecarts, e = self.e, angle = self.angle }
end

local function pivoter(self, vitesseAngle, dt)
	self.angle += vitesseAngle * dt
	-- (au-delà d'un demi-tour, l'angle revient de l'autre côté)
	self.angle = (self.angle + math.pi) % (2 * math.pi) - math.pi
end

-- Une image de dt secondes. cousant : le tissu avance ; rotation : le pivot voulu par le joueur (−1 à 1). On peut pivoter
-- sans coudre (l'aiguille plantée, dans un angle) ; l'assistance, elle, ne pivote qu'en cousant.
function MachineCoudre:avancer(dt, cousant, rotation)
	if self:fini() or type(dt) ~= "number" or not (dt > 0) then
		return
	end
	dt = math.min(dt, MachineCoudre.DT_MAX)
	if type(rotation) ~= "number" or rotation ~= rotation then
		rotation = 0
	end
	rotation = math.clamp(rotation, -1, 1)
	if not cousant then
		pivoter(self, rotation * MachineCoudre.ROTATION_MAX, dt)
		return
	end
	if self.assistance then
		self.assistanceUtilisee = true
	end
	self.duree += dt
	local v = MachineCoudre.VITESSES[self.vitesse]
	local reste = v * dt
	while reste > 1e-12 and not self:fini() do
		local d = math.min(PAS_CALCUL, reste)
		local temps = d / v
		local vitesseAngle = rotation * MachineCoudre.ROTATION_MAX
		if self.assistance then
			-- elle vise le pointillé : l'angle qui ramène l'aiguille dessus en 1 dm environ ; plus lente quand le tissu
			-- avance moins vite (à la tortue, elle ne corrige pas davantage par dm cousu)
			local voulu = math.clamp(-self.e, -0.5, 0.5)
			local allure = math.min(1, v / MachineCoudre.VITESSES.normale)
			vitesseAngle += math.clamp((voulu - self.angle) * 4, -1, 1) * MachineCoudre.ROTATION_ASSISTANCE * allure
		end
		pivoter(self, math.clamp(vitesseAngle, -MachineCoudre.ROTATION_MAX, MachineCoudre.ROTATION_MAX), temps)
		self.angle += self:tirage(self.parcouru) * d
		local lk = self.longueurs[self.k]
		local ds = math.min(d * math.max(math.cos(self.angle), MachineCoudre.AVANCE_MIN), lk - self.s)
		local part = ds / math.max(d * math.max(math.cos(self.angle), MachineCoudre.AVANCE_MIN), 1e-12)
		self.e = math.clamp(self.e + d * part * math.sin(self.angle), -Catalogue.ECART_MAX_COUTURE, Catalogue.ECART_MAX_COUTURE)
		self.s += ds
		self.parcouru += ds
		reste -= d * part
		while self.parcouru >= (#self.ecarts + 1) * PAS - 1e-9 do
			table.insert(self.ecarts, self.e)
		end
		if self.s >= lk - 1e-9 then
			suivante(self)
		end
	end
end

-- Découd-vite : défait la couture en cours, ou la précédente si on est au début de celle-ci ; on reprend au début de
-- son pointillé, comme on y était arrivé
function MachineCoudre:decoudre()
	local k = self.k
	if k > #self.segments or self.s <= 1e-9 then
		k -= 1
	end
	if k < 1 then
		return false
	end
	local debut = self.debuts[k]
	self.k, self.s = k, 0
	self.e, self.angle = debut.e or 0, debut.angle or 0
	self.parcouru = debut.parcouru
	for i = #self.ecarts, debut.mesures + 1, -1 do
		self.ecarts[i] = nil
	end
	for j = #self.debuts, k + 1, -1 do
		self.debuts[j] = nil
	end
	if self.parcouru == 0 and not self.assistance then
		self.assistanceUtilisee = false -- tout est décousu : l'essai avec l'assistance ne compte plus
	end
	return true
end

-- Position de l'aiguille pour l'affichage (repère du patron, dm), angle du tissu, et l'angle qui vient
function MachineCoudre:etat()
	local k = math.min(self.k, #self.segments)
	local seg, lk = self.segments[k], self.longueurs[k]
	local dx, dy = direction(seg, lk)
	local s = self:fini() and lk or self.s
	local ix, iy = seg.a.x + dx * s, seg.a.y + dy * s
	local virage = not self:fini() and self:virage(k)
	return {
		segment = k,
		nbSegments = #self.segments,
		avance = s,
		longueurSegment = lk,
		ecart = self.e,
		angle = self.angle,
		ideal = { x = ix, y = iy }, -- point du pointillé sous l'aiguille
		point = { x = ix - dy * self.e, y = iy + dx * self.e }, -- aiguille, décalée de l'écart
		direction = { x = dx, y = dy },
		progression = self.parcouru / self.longueur,
		virage = virage and { angle = virage, distance = lk - s } or nil, -- l'angle au bout de cette couture
	}
end

-- Relevé à envoyer : écarts, durée passée à coudre, et si l'assistance a servi
function MachineCoudre:releve()
	return table.clone(self.ecarts), self.duree, self.assistanceUtilisee
end

-- (plan 26) La couture k, finie, est-elle parfaite ? Tous ses points à 0,05 dm du pointillé au plus (la note entière)
MachineCoudre.PARFAIT = 0.05
function MachineCoudre:coutureParfaite(k)
	local debut, suite = self.debuts[k], self.debuts[k + 1]
	if not debut or not (suite or self:fini()) then
		return false
	end
	local fin = if suite then suite.mesures else #self.ecarts
	if fin <= debut.mesures then
		return false
	end
	for i = debut.mesures + 1, fin do
		if math.abs(self.ecarts[i]) > MachineCoudre.PARFAIT + 1e-9 then
			return false
		end
	end
	return true
end

-- Note de couture de ce qui est déjà cousu (nil si rien)
function MachineCoudre:noteProvisoire()
	if #self.ecarts == 0 then
		return nil
	end
	return Notation.noteCouture(self.ecarts, self.assistanceUtilisee)
end

return MachineCoudre
