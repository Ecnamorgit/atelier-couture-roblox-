-- Polygone : géométrie 2D des pièces de patron.
-- Un polygone est une liste de points { x = number, y = number } en décimètres
-- (x vers la droite, y vers le bas, comme sur la table de découpe).
local Polygone = {}

-- Aire signée (formule du lacet) : son signe dépend du sens de parcours
function Polygone.aireSignee(points)
	local s = 0
	for i, a in ipairs(points) do
		local b = points[i % #points + 1]
		s += a.x * b.y - b.x * a.y
	end
	return s / 2
end

function Polygone.aire(points)
	return math.abs(Polygone.aireSignee(points))
end

function Polygone.boite(points)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, p in ipairs(points) do
		minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
		minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
	end
	return { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

function Polygone.centre(points)
	local b = Polygone.boite(points)
	return { x = (b.minX + b.maxX) / 2, y = (b.minY + b.maxY) / 2 }
end

-- Point dans le polygone (règle pair-impair)
function Polygone.contient(points, x, y)
	local dedans = false
	local n = #points
	local j = n
	for i = 1, n do
		local a, b = points[i], points[j]
		if (a.y > y) ~= (b.y > y) then
			local xi = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)
			if x < xi then
				dedans = not dedans
			end
		end
		j = i
	end
	return dedans
end

-- Extrémités gauche et droite du contour sur la ligne horizontale y (nil si la ligne ne coupe pas)
function Polygone.etendueLigne(points, y)
	local xmin, xmax = math.huge, -math.huge
	local n = #points
	for i = 1, n do
		local a, b = points[i], points[i % n + 1]
		if y >= math.min(a.y, b.y) and y <= math.max(a.y, b.y) then
			if a.y == b.y then
				xmin, xmax = math.min(xmin, a.x, b.x), math.max(xmax, a.x, b.x)
			else
				local x = a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)
				xmin, xmax = math.min(xmin, x), math.max(xmax, x)
			end
		end
	end
	if xmin > xmax then
		return nil, nil
	end
	return xmin, xmax
end

-- Pose d'une pièce : le point « centre » du patron va en (placement.x, placement.y),
-- puis la pièce tourne de placement.angle degrés autour de ce point.
-- Rotation : x' = c·dx − s·dy, y' = s·dx + c·dy (sens horaire à l'écran, y vers le bas).
function Polygone.poserPoint(p, placement, centre)
	local a = math.rad(placement.angle or 0)
	local c, s = math.cos(a), math.sin(a)
	local dx, dy = p.x - centre.x, p.y - centre.y
	return { x = placement.x + c * dx - s * dy, y = placement.y + s * dx + c * dy }
end

function Polygone.poser(points, placement, centre)
	local out = {}
	for i, p in ipairs(points) do
		out[i] = Polygone.poserPoint(p, placement, centre)
	end
	return out
end

-- Symétrique par rapport à la droite verticale x = axe (sens de parcours inversé)
function Polygone.miroir(points, axe)
	local out = {}
	for i = #points, 1, -1 do
		local p = points[i]
		table.insert(out, { x = 2 * axe - p.x, y = p.y })
	end
	return out
end

-- Arête i (du point i au point i+1) décalée de d vers l'intérieur : { a = point, b = point }
function Polygone.areteDecalee(points, i, d)
	local a, b = points[i], points[i % #points + 1]
	local dx, dy = b.x - a.x, b.y - a.y
	local longueur = math.sqrt(dx * dx + dy * dy)
	-- Normale à gauche du parcours ; l'intérieur est à gauche si l'aire signée est positive
	local signe = Polygone.aireSignee(points) > 0 and 1 or -1
	local nx, ny = -dy / longueur * signe, dx / longueur * signe
	return {
		a = { x = a.x + nx * d, y = a.y + ny * d },
		b = { x = b.x + nx * d, y = b.y + ny * d },
	}
end

function Polygone.longueur(segment)
	local dx, dy = segment.b.x - segment.a.x, segment.b.y - segment.a.y
	return math.sqrt(dx * dx + dy * dy)
end

return Polygone
