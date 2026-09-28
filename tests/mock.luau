-- Faux Roblox minimal pour exécuter les scripts du jeu hors de Studio.
-- Les propriétés, événements et méthodes sont validés d'après les définitions de l'API (apidb).
local API = APIDB

local M = {}
M.horloge = 0
M.taches = {}
M.erreurs = {}
M.avertissements = {}

local function typeDe(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt and mt.__type then
			return mt.__type
		end
	end
	return type(v)
end
M.typeof = typeDe

---------------------------------------------------------------------------
-- Types de données
---------------------------------------------------------------------------
local V3 = {}
V3.__type = "Vector3"
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return v3(v.X / m, v.Y / m, v.Z / m)
	elseif k == "Dot" then
		return function(a, b)
			return a.X * b.X + a.Y * b.Y + a.Z * b.Z
		end
	elseif k == "Cross" then
		return function(a, b)
			return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
	elseif k == "x" or k == "y" or k == "z" then
		error("Vector3 : utiliser X/Y/Z en majuscules")
	end
	error("Vector3 : membre inconnu " .. tostring(k))
end
V3.__add = function(a, b)
	assert(typeDe(a) == "Vector3" and typeDe(b) == "Vector3", "Vector3 + type invalide")
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	assert(typeDe(a) == "Vector3" and typeDe(b) == "Vector3", "Vector3 - type invalide")
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		a, b = b, a
	end
	if type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	assert(typeDe(b) == "Vector3", "Vector3 * type invalide")
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	assert(type(b) == "number", "Vector3 / type invalide")
	return v3(a.X / b, a.Y / b, a.Z / b)
end
V3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(v)
	return ("%.3f, %.3f, %.3f"):format(v.X, v.Y, v.Z)
end
local Vector3 = { new = v3 }
Vector3.zero = v3(0, 0, 0)
Vector3.one = v3(1, 1, 1)
Vector3.xAxis, Vector3.yAxis, Vector3.zAxis = v3(1, 0, 0), v3(0, 1, 0), v3(0, 0, 1)

local V2 = { __type = "Vector2" }
V2.__index = V2
local Vector2 = {
	new = function(x, y)
		return setmetatable({ X = x or 0, Y = y or 0 }, V2)
	end,
}

-- CFrame : position p + matrice de rotation r (lignes), colonnes = X (droite), Y (haut), Z (arrière)
local CF = { __type = "CFrame" }
local function cf(p, r)
	return setmetatable({ p = p, r = r }, CF)
end
local IDENT = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mulR(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return r
end
local function appliquerR(r, v)
	return v3(r[1] * v.X + r[2] * v.Y + r[3] * v.Z, r[4] * v.X + r[5] * v.Y + r[6] * v.Z, r[7] * v.X + r[8] * v.Y + r[9] * v.Z)
end
local function transposer(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
local CFM = {}
function CFM.Inverse(c)
	local rt = transposer(c.r)
	return cf(-appliquerR(rt, c.p), rt)
end
function CFM.ToObjectSpace(c, autre)
	return CFM.Inverse(c) * autre
end
function CFM.ToWorldSpace(c, autre)
	return c * autre
end
function CFM.PointToWorldSpace(c, v)
	return c * v
end
CF.__index = function(c, k)
	if CFM[k] then
		return CFM[k]
	elseif k == "Position" then
		return c.p
	elseif k == "X" then
		return c.p.X
	elseif k == "Y" then
		return c.p.Y
	elseif k == "Z" then
		return c.p.Z
	elseif k == "LookVector" then
		return v3(-c.r[3], -c.r[6], -c.r[9])
	elseif k == "RightVector" then
		return v3(c.r[1], c.r[4], c.r[7])
	elseif k == "UpVector" then
		return v3(c.r[2], c.r[5], c.r[8])
	end
	error("CFrame : membre inconnu " .. tostring(k))
end
CF.__mul = function(a, b)
	assert(typeDe(a) == "CFrame", "CFrame * : opérande gauche invalide")
	if typeDe(b) == "CFrame" then
		return cf(a.p + appliquerR(a.r, b.p), mulR(a.r, b.r))
	elseif typeDe(b) == "Vector3" then
		return a.p + appliquerR(a.r, b)
	end
	error("CFrame * type invalide : " .. typeDe(b))
end
local CFrame = {}
function CFrame.new(x, y, z, ...)
	if x == nil then
		return cf(v3(0, 0, 0), IDENT)
	end
	if typeDe(x) == "Vector3" then
		assert(y == nil, "CFrame.new(Vector3, …) non simulé")
		return cf(x, IDENT)
	end
	assert(select("#", ...) == 0, "CFrame.new à 12 nombres non simulé")
	return cf(v3(x, y, z), IDENT)
end
local function rotX(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function rotY(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rotZ(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
function CFrame.Angles(x, y, z)
	return cf(v3(0, 0, 0), mulR(mulR(rotX(x), rotY(y)), rotZ(z)))
end
function CFrame.fromMatrix(p, vx, vy, vz)
	assert(vz ~= nil, "fromMatrix : vZ requis dans cette simulation")
	return cf(p, { vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z })
end
function CFrame.lookAt(de, vers, haut)
	haut = haut or v3(0, 1, 0)
	local regard = (vers - de).Unit
	local droite = regard:Cross(haut).Unit
	local h = droite:Cross(regard)
	return CFrame.fromMatrix(de, droite, h, -regard)
end

local C3 = { __type = "Color3" }
C3.__index = function(c, k)
	if k == "Lerp" then
		return function(a, b, t)
			return setmetatable({ R = a.R + (b.R - a.R) * t, G = a.G + (b.G - a.G) * t, B = a.B + (b.B - a.B) * t }, C3)
		end
	end
	error("Color3 : membre inconnu " .. tostring(k))
end
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
local Color3 = {}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
function Color3.fromRGB(r, g, b)
	for _, v in ipairs({ r, g, b }) do
		assert(type(v) == "number" and v >= 0 and v <= 255, "fromRGB hors limites")
	end
	return Color3.new(r / 255, g / 255, b / 255)
end

local U = { __type = "UDim" }
U.__index = U
local UDim = {
	new = function(s, o)
		return setmetatable({ Scale = s or 0, Offset = o or 0 }, U)
	end,
}
local U2 = { __type = "UDim2" }
U2.__index = U2
local UDim2 = {}
function UDim2.new(a, b, c, d)
	return setmetatable({ X = UDim.new(a, b), Y = UDim.new(c, d) }, U2)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end

-- Enum : chaque élément est unique (comparaison par identité), comme dans Roblox
local cacheEnum = {}
local EI = { __type = "EnumItem" }
EI.__index = EI
local Enum = setmetatable({}, {
	__index = function(_, nomEnum)
		return setmetatable({}, {
			__index = function(_, nom)
				local cle = nomEnum .. "." .. nom
				if not cacheEnum[cle] then
					cacheEnum[cle] = setmetatable({ EnumType = nomEnum, Name = nom, Value = #cacheEnum + 1 }, EI)
				end
				return cacheEnum[cle]
			end,
		})
	end,
})

-- Random déterministe
local RNG = { __type = "Random" }
RNG.__index = RNG
local graineGlobale = 12345
local Random = {}
function Random.new(graine)
	if graine == nil then
		graineGlobale += 7919
		graine = graineGlobale
	end
	return setmetatable({ etat = math.floor(graine) % 2147483647 + 1 }, RNG)
end
function RNG:_suivant()
	self.etat = (self.etat * 16807) % 2147483647
	return self.etat / 2147483647
end
function RNG:NextNumber(a, b)
	a, b = a or 0, b or 1
	return a + (b - a) * self:_suivant()
end
function RNG:NextInteger(a, b)
	assert(a <= b, "NextInteger : min > max")
	return a + math.floor(self:_suivant() * (b - a + 1))
end

---------------------------------------------------------------------------
-- Signaux
---------------------------------------------------------------------------
local SIG = { __type = "RBXScriptSignal" }
SIG.__index = SIG
local function signal()
	return setmetatable({ connexions = {} }, SIG)
end
function SIG:Connect(f)
	assert(type(f) == "function", "Connect attend une fonction")
	local c = { f = f, actif = true }
	c.Disconnect = function()
		c.actif = false
	end
	table.insert(self.connexions, c)
	return c
end
function SIG:Fire(...)
	for _, c in ipairs(table.clone(self.connexions)) do
		if c.actif then
			c.f(...)
		end
	end
end
function SIG:Wait()
	error("Signal:Wait non simulé")
end
M.signal = signal

---------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------
local function classeDeclaree(classe)
	return API[classe] ~= nil
end
local function estUn(classe, cible)
	local c = classe
	while c do
		if c == cible then
			return true
		end
		c = API[c] and API[c].parent
	end
	return false
end
local function propDeclaree(classe, nom)
	local c = classe
	while c do
		local d = API[c]
		if d and d.props[nom] then
			return d.props[nom]
		end
		c = d and d.parent
	end
	return nil
end
local function methodeDeclaree(classe, nom)
	local c = classe
	while c do
		local d = API[c]
		if d and d.methods[nom] then
			return true
		end
		c = d and d.parent
	end
	return false
end

local SIMPLES = {
	number = "number",
	boolean = "boolean",
	string = "string",
	Vector3 = "Vector3",
	Vector2 = "Vector2",
	UDim2 = "UDim2",
	UDim = "UDim",
	Color3 = "Color3",
	CFrame = "CFrame",
}

local INST = { __type = "Instance" }
local methodes = {}

local function nouvelleInstance(classe)
	assert(classeDeclaree(classe), "Instance.new : classe inconnue " .. tostring(classe))
	local obj = setmetatable({ __classe = classe, __props = { Name = classe }, __enfants = {}, __signaux = {}, __attr = {} }, INST)
	return obj
end
M.nouvelleInstance = nouvelleInstance

local DEFAUTS = {
	Visible = true,
	Text = "",
	Value = 0,
	Anchored = false,
	Transparency = 0,
}

INST.__index = function(self, k)
	local classe = rawget(self, "__classe")
	if k == "ClassName" then
		return classe
	end
	local props = rawget(self, "__props")
	if methodes[k] then
		if not methodeDeclaree(classe, k) and not methodes[k .. "__libre"] then
			error(("%s:%s n'existe pas dans l'API"):format(classe, k))
		end
		return methodes[k]
	end
	local typeProp = propDeclaree(classe, k)
	if typeProp and typeProp:sub(1, 15) == "RBXScriptSignal" then
		local s = rawget(self, "__signaux")
		s[k] = s[k] or signal()
		return s[k]
	end
	if props[k] ~= nil then
		return props[k]
	end
	if typeProp then
		if k == "C0" or k == "C1" or k == "CFrame" then
			return CFrame.new()
		elseif k == "Size" and estUn(classe, "BasePart") then
			return v3(4, 1, 2)
		end
		return DEFAUTS[k]
	end
	for _, enfant in ipairs(rawget(self, "__enfants")) do
		if enfant.Name == k then
			return enfant
		end
	end
	error(("%s n'est pas un membre valide de %s « %s »"):format(tostring(k), classe, tostring(props.Name)))
end

local function verifierType(classe, nom, typeProp, valeur)
	if valeur == nil or type(valeur) == "function" then
		return
	end
	local t = typeProp:gsub("%?$", "")
	local attendu = SIMPLES[t]
	if attendu then
		assert(typeDe(valeur) == attendu, ("%s.%s attend %s, reçu %s"):format(classe, nom, attendu, typeDe(valeur)))
	elseif t:sub(1, 4) == "Enum" and API[t] == nil then
		assert(typeDe(valeur) == "EnumItem", ("%s.%s attend un %s"):format(classe, nom, t))
		assert("Enum" .. valeur.EnumType == t, ("%s.%s attend %s, reçu Enum.%s"):format(classe, nom, t, valeur.EnumType))
	elseif API[t] then
		assert(typeDe(valeur) == "Instance" and estUn(valeur.__classe, t), ("%s.%s attend une instance %s"):format(classe, nom, t))
	end
end

INST.__newindex = function(self, k, v)
	local classe = rawget(self, "__classe")
	local props = rawget(self, "__props")
	if k == "Parent" then
		local ancien = props.Parent
		if ancien then
			local liste = rawget(ancien, "__enfants")
			for i, e in ipairs(liste) do
				if e == self then
					table.remove(liste, i)
					break
				end
			end
		end
		if v ~= nil then
			assert(typeDe(v) == "Instance", "Parent doit être une instance")
			table.insert(rawget(v, "__enfants"), self)
		end
		props.Parent = v
		return
	end
	local typeProp = propDeclaree(classe, k)
	if not typeProp then
		error(("Propriété inexistante : %s.%s"):format(classe, tostring(k)))
	end
	verifierType(classe, k, typeProp, v)
	if classe == "Part" or classe == "SpawnLocation" then
		if k == "Size" then
			assert(v.X > 0 and v.Y > 0 and v.Z > 0, "Taille de pièce nulle ou négative")
		end
	end
	props[k] = v
	local s = rawget(self, "__signaux")
	if s.Changed and k == "Value" then
		s.Changed:Fire(v)
	end
	local sp = rawget(self, "__signauxProp")
	if sp and sp[k] then
		sp[k]:Fire()
	end
end
INST.__tostring = function(self)
	return rawget(self, "__props").Name
end

function methodes.FindFirstChild(self, nom)
	for _, e in ipairs(rawget(self, "__enfants")) do
		if e.Name == nom then
			return e
		end
	end
	return nil
end
function methodes.WaitForChild(self, nom)
	local e = methodes.FindFirstChild(self, nom)
	if not e then
		error(("WaitForChild bloquerait : %s absent de %s"):format(nom, tostring(self)))
	end
	return e
end
function methodes.GetChildren(self)
	return table.clone(rawget(self, "__enfants"))
end
function methodes.GetDescendants(self)
	local out = {}
	local function parcourir(i)
		for _, e in ipairs(rawget(i, "__enfants")) do
			table.insert(out, e)
			parcourir(e)
		end
	end
	parcourir(self)
	return out
end
function methodes.IsA(self, nom)
	return estUn(rawget(self, "__classe"), nom)
end
function methodes.Destroy(self)
	self.Parent = nil
	rawset(self, "__detruit", true)
end
function methodes.ClearAllChildren(self)
	for _, e in ipairs(table.clone(rawget(self, "__enfants"))) do
		methodes.Destroy(e)
	end
end
function methodes.SetAttribute(self, nom, valeur)
	rawget(self, "__attr")[nom] = valeur
end
function methodes.GetAttribute(self, nom)
	return rawget(self, "__attr")[nom]
end
function methodes.GetPropertyChangedSignal(self, nom)
	assert(propDeclaree(rawget(self, "__classe"), nom), "GetPropertyChangedSignal : propriété inconnue " .. nom)
	local sp = rawget(self, "__signauxProp") or {}
	rawset(self, "__signauxProp", sp)
	sp[nom] = sp[nom] or signal()
	return sp[nom]
end
function methodes.GetService(_, nom)
	return M.services[nom] or error("Service non simulé : " .. nom)
end
function methodes.BindToClose(_, f)
	M.fermeture = f
end
function methodes.GetPlayers()
	return table.clone(M.joueurs)
end
function methodes.GetDataStore()
	local store = {}
	function store.GetAsync()
		error("Studio access to API services is not allowed")
	end
	function store.SetAsync()
		error("Studio access to API services is not allowed")
	end
	return setmetatable(store, {
		__index = function(_, k)
			error("DataStore : méthode " .. k)
		end,
	})
end
function methodes.GetNetworkPing()
	return M.ping or 0
end
function methodes.InvokeServer(remote, ...)
	local rappel = rawget(remote, "__props").OnServerInvoke
	assert(rappel, "OnServerInvoke non défini")
	local args = M.transmettre({ ... })
	local resultats = table.pack(rappel(M.joueurLocal, table.unpack(args)))
	M.dernierAppel = { action = args[1], argument = args[2], reponse = resultats[1] }
	return table.unpack(M.transmettre({ table.unpack(resultats, 1, resultats.n) }))
end
function methodes.BindActionAtPriority(_, nom, f, bouton, priorite, ...)
	assert(type(nom) == "string" and type(f) == "function" and type(bouton) == "boolean" and type(priorite) == "number")
	M.actions[nom] = { f = f, touches = { ... } }
end
function methodes.UnbindAction(_, nom)
	M.actions[nom] = nil
end

-- Copie « réseau » : refuse ce que Roblox ne peut pas transmettre
function M.transmettre(v, profondeur)
	profondeur = profondeur or 0
	assert(profondeur < 20, "table trop profonde / cyclique")
	local t = typeDe(v)
	if t == "function" then
		error("fonction envoyée par le réseau")
	elseif t == "table" then
		local n = #v
		local aTableau, aDico = n > 0, false
		for cle in pairs(v) do
			if type(cle) == "number" then
				assert(cle >= 1 and cle <= n and cle == math.floor(cle), "tableau à trous envoyé par le réseau")
			elseif type(cle) == "string" then
				aDico = true
			else
				error("clé non transmissible : " .. typeDe(cle))
			end
		end
		assert(not (aTableau and aDico), "table mixte (tableau + dictionnaire) envoyée par le réseau")
		local copie = {}
		for cle, val in pairs(v) do
			copie[cle] = M.transmettre(val, profondeur + 1)
		end
		return copie
	end
	return v
end

---------------------------------------------------------------------------
-- Planificateur et temps
---------------------------------------------------------------------------
local task = {}
function task.spawn(f, ...)
	f(...)
end
function task.defer(f, ...)
	table.insert(M.taches, { t = M.horloge, f = f, args = { ... } })
end
function task.delay(d, f, ...)
	table.insert(M.taches, { t = M.horloge + d, f = f, args = { ... } })
end
function task.wait()
	error("task.wait non simulé")
end
M.task = task

function M.avancer(duree)
	local fin = M.horloge + duree
	local pas = 1 / 60
	while M.horloge < fin - 1e-9 do
		M.horloge = math.min(fin, M.horloge + pas)
		table.sort(M.taches, function(a, b)
			return a.t < b.t
		end)
		while M.taches[1] and M.taches[1].t <= M.horloge + 1e-9 do
			local tache = table.remove(M.taches, 1)
			tache.f(table.unpack(tache.args))
		end
		M.services.RunService.RenderStepped:Fire(pas)
	end
end

M.os = setmetatable({
	clock = function()
		return M.horloge
	end,
}, { __index = os })

---------------------------------------------------------------------------
-- Monde
---------------------------------------------------------------------------
function M.initialiser()
	M.joueurs = {}
	M.actions = {}
	local game = nouvelleInstance("DataModel")
	rawget(game, "__props").Name = "Game"
	M.game = game
	M.services = {}
	for _, nom in ipairs({
		"Workspace",
		"Players",
		"ReplicatedStorage",
		"DataStoreService",
		"UserInputService",
		"RunService",
		"ContextActionService",
		"ProximityPromptService",
		"ServerScriptService",
	}) do
		local s = nouvelleInstance(nom)
		s.Parent = game
		M.services[nom] = s
	end
	local camera = nouvelleInstance("Camera")
	rawget(camera, "__props").ViewportSize = Vector2.new(1280, 720)
	camera.Parent = M.services.Workspace
	M.services.Workspace.CurrentCamera = camera
	return game
end

-- Personnage debout, pieds à y = 0, tourné de « lacet » autour de Y
function M.personnage(type_, lacet)
	local modele = nouvelleInstance("Model")
	modele.Name = "Personnage"
	local rot = CFrame.Angles(0, lacet or 0, 0)
	local function partie(nom, taille, pos)
		local p = nouvelleInstance("Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = rot * CFrame.new(pos)
		p.Parent = modele
		return p
	end
	if type_ == "R15" then
		partie("LeftFoot", v3(1, 0.3, 1), v3(-0.5, 0.15, 0))
		partie("RightFoot", v3(1, 0.3, 1), v3(0.5, 0.15, 0))
		partie("LeftLowerLeg", v3(1, 1.2, 1), v3(-0.5, 0.9, 0))
		partie("RightLowerLeg", v3(1, 1.2, 1), v3(0.5, 0.9, 0))
		partie("LeftUpperLeg", v3(1, 1.2, 1), v3(-0.5, 2.1, 0))
		partie("RightUpperLeg", v3(1, 1.2, 1), v3(0.5, 2.1, 0))
		partie("LowerTorso", v3(2, 0.4, 1), v3(0, 2.9, 0))
		partie("UpperTorso", v3(2, 1.6, 1), v3(0, 3.9, 0))
		partie("HumanoidRootPart", v3(2, 2, 1), v3(0, 3.7, 0))
		partie("LeftUpperArm", v3(1, 1.2, 1), v3(-1.5, 4.1, 0))
		partie("RightUpperArm", v3(1, 1.2, 1), v3(1.5, 4.1, 0))
		partie("LeftLowerArm", v3(1, 1.1, 1), v3(-1.5, 2.95, 0))
		partie("RightLowerArm", v3(1, 1.1, 1), v3(1.5, 2.95, 0))
		partie("Head", v3(1.2, 1.2, 1.2), v3(0, 5.3, 0))
	else
		partie("Left Leg", v3(1, 2, 1), v3(-0.5, 1, 0))
		partie("Right Leg", v3(1, 2, 1), v3(0.5, 1, 0))
		partie("Torso", v3(2, 2, 1), v3(0, 3, 0))
		partie("HumanoidRootPart", v3(2, 2, 1), v3(0, 3, 0))
		partie("Left Arm", v3(1, 2, 1), v3(-1.5, 3, 0))
		partie("Right Arm", v3(1, 2, 1), v3(1.5, 3, 0))
		partie("Head", v3(2, 1, 1), v3(0, 4.5, 0))
	end
	nouvelleInstance("Humanoid").Parent = modele
	return modele
end

function M.nouveauJoueur(nom)
	local joueur = nouvelleInstance("Player")
	joueur.Name = nom
	rawget(joueur, "__props").UserId = 42
	local gui = nouvelleInstance("PlayerGui")
	gui.Parent = joueur
	joueur.Parent = M.services.Players
	table.insert(M.joueurs, joueur)
	return joueur
end

M.env = {
	Vector3 = Vector3,
	Vector2 = Vector2,
	CFrame = CFrame,
	Color3 = Color3,
	UDim = UDim,
	UDim2 = UDim2,
	Enum = Enum,
	Random = Random,
	Instance = { new = nouvelleInstance },
	typeof = typeDe,
	task = task,
}

return M
