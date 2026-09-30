-- Molette (sous-projet 6) : le réglage d'une mesure du mannequin par une molette qu'on fait tourner. Glisser vers le
-- haut l'augmente, vers le bas la diminue : un cran de 0,1 dm tous les PX_PAR_CRAN pixels (le reste est gardé pour
-- le glissement suivant) ; la molette de la souris et les boutons − / + avancent d'un cran. La valeur reste entre
-- ses bornes ; butée contre une borne, le glissement en trop est oublié.
local Molette = {}
Molette.__index = Molette

Molette.PX_PAR_CRAN = 12
Molette.CRAN = 0.1 -- dm de tour
Molette.DEGRES_PAR_CRAN = 15 -- la fente de la molette tourne d'autant à chaque cran

local function arrondi(v)
	return math.round(v * 10) / 10
end

function Molette.nouvelle(valeur, mini, maxi)
	return setmetatable({ valeur = math.clamp(arrondi(valeur), mini, maxi), mini = mini, maxi = maxi, reste = 0, tours = 0 }, Molette)
end

-- Avance de n crans (négatif : recule) ; renvoie la nouvelle valeur
function Molette:crans(n)
	local avant = self.valeur
	self.valeur = math.clamp(arrondi(self.valeur + n * Molette.CRAN), self.mini, self.maxi)
	self.tours += math.round((self.valeur - avant) / Molette.CRAN)
	return self.valeur
end

-- Un glissement de dy pixels (vers le bas positif, comme à l'écran) ; renvoie la nouvelle valeur
function Molette:glisser(dy)
	self.reste -= dy
	local n = if self.reste >= 0 then math.floor(self.reste / Molette.PX_PAR_CRAN) else -math.floor(-self.reste / Molette.PX_PAR_CRAN)
	self.reste -= n * Molette.PX_PAR_CRAN
	self:crans(n)
	-- En butée, le glissement en trop (celui qui pousse vers la borne) ne compte pas ; dans l'autre sens, il est gardé
	if (self.valeur == self.maxi and self.reste > 0) or (self.valeur == self.mini and self.reste < 0) then
		self.reste = 0
	end
	return self.valeur
end

-- Règle directement (reprendre des mesures)
function Molette:regler(valeur)
	self.valeur = math.clamp(arrondi(valeur), self.mini, self.maxi)
	self.reste = 0
	return self.valeur
end

-- L'angle de la fente (degrés) : elle tourne avec la molette
function Molette:angle()
	return self.tours * Molette.DEGRES_PAR_CRAN
end

return Molette
