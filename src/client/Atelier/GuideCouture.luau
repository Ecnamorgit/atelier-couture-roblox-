-- GuideCouture (sous-projet 8) : les conseils pas à pas de la couture, à la première robe (et sur demande, « ? »).
-- Chaque conseil s'efface quand le joueur l'a fait : avancer, pivoter en cousant, passer un angle en s'arrêtant pour
-- redresser le tissu, puis coudre quelques secondes ; enfin « Bravo ». Logique pure, sans affichage.
local GuideCouture = {}
GuideCouture.__index = GuideCouture

GuideCouture.CONSEILS = {
	"Tiens « Coudre » (ou Espace) : le tissu avance sous l'aiguille.",
	"Le tissu tourne un peu en avançant : fais-le pivoter avec ◀ ▶ (ou A / D) pour garder l'aiguille sur le pointillé.",
	"Un angle arrive : couds jusqu'au rond, puis lâche « Coudre » et fais pivoter le tissu jusqu'à ce que le pointillé remonte droit.",
	"Ralentis dans les courbes (W / S, ou Tortue), accélère dans les lignes droites : ta précision s'affiche en direct.",
}
GuideCouture.BRAVO = "Bravo, tu sais coudre ! « ? » rappelle ces conseils."
GuideCouture.AVANCE = 0.5 -- dm cousus pour le premier conseil
GuideCouture.PIVOT = 0.3 -- s à pivoter en cousant pour le deuxième
GuideCouture.DROIT = math.rad(10) -- passé un angle, le tissu est redressé à moins de 10°
GuideCouture.PRATIQUE = 5 -- s de couture pour le dernier
GuideCouture.DUREE_BRAVO = 4 -- s
GuideCouture.AFFICHAGE_MIN = 2 -- s : un conseil reste au moins ce temps, même si son geste est déjà fait (le lire)

function GuideCouture.nouveau()
	return setmetatable({ etape = 1, pivot = 0, pratique = 0, bravo = 0, affiche = 0 }, GuideCouture)
end

-- Reste-t-il un angle à passer sur cette pièce, à partir de la couture k ?
local function angleAVenir(machine, k)
	for j = k, #machine.segments - 1 do
		if machine:virage(j) then
			return true
		end
	end
	return false
end

-- Une image de dt secondes : machine (MachineCoudre), cousant, rotation (le pivot voulu par le joueur)
function GuideCouture:suivre(dt, machine, cousant, rotation)
	if machine ~= self.machine then -- une autre pièce : l'angle à passer se compte sur elle
		self.machine, self.couture = machine, machine.k
	end
	self.affiche += dt
	-- (le conseil suivant, une fois celui-ci affiché le temps de le lire)
	local function passer(etape)
		if self.affiche < GuideCouture.AFFICHAGE_MIN then
			return false
		end
		self.etape, self.affiche = etape, 0
		return true
	end
	if self.etape == 1 then
		if machine.parcouru >= GuideCouture.AVANCE then
			passer(2)
		end
	elseif self.etape == 2 then
		if cousant and rotation ~= 0 then
			self.pivot += dt
		end
		if self.pivot >= GuideCouture.PIVOT and passer(3) then
			self.couture = machine.k
		end
	elseif self.etape == 3 then
		-- un angle passé (le pointillé a tourné), puis le tissu redressé en cousant de nouveau ; sans angle à venir sur
		-- cette pièce, le conseil attendra une autre pièce : on passe au suivant
		local passe = machine.k > self.couture and machine:virage(machine.k - 1) ~= nil
		if (passe and cousant and math.abs(machine.angle) < GuideCouture.DROIT) or (not passe and not angleAVenir(machine, machine.k)) then
			passer(4)
		end
	elseif self.etape == 4 then
		if cousant then
			self.pratique += dt
		end
		if self.pratique >= GuideCouture.PRATIQUE or machine:fini() then
			passer(5)
		end
	elseif self.etape == 5 then
		self.bravo += dt
		if self.bravo >= GuideCouture.DUREE_BRAVO then
			passer(6)
		end
	end
end

-- Le texte à montrer, ou nil (les conseils sont finis)
function GuideCouture:texte()
	if self.etape <= #GuideCouture.CONSEILS then
		return GuideCouture.CONSEILS[self.etape]
	elseif self.etape == 5 then
		return GuideCouture.BRAVO
	end
	return nil
end

return GuideCouture
