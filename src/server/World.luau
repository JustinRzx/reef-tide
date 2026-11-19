--!strict
-- World.luau — builds the whole floating reef hub over open water, densely:
-- hub disc, 8 pad slots on the ring with walkways, donation fountain, raiders' jetty,
-- start gate, coral towers, salvage lamps, signposts, flags, tethered balloons,
-- drifting sky-junk, clouds, water and seabed. Also builds the brainrot models.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Data = require(script.Parent.data)

type Tier = Data.Tier
type MutationId = Data.MutationId

local World = {
	CENTER = Vector3.new(0, 0, 0),
	WALK_TOP = 2, -- y of every walkable surface
	RING_RADIUS = 46,
	PAD_SLOTS = 8,
	HUB_RADIUS = 26,
	WATER_Y = -6,
	JETTY_ANGLE = math.pi / 8, -- radians; the jetty points between two pads
	padSlots = {} :: { Vector3 },
	fountainTop = Vector3.new(0, 6, 0),
	spawnPoint = Vector3.new(0, 0, 0),
	jettyEnd = Vector3.new(0, 0, 0),
}

-- ---------------------------------------------------------------- helpers

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Parent = workspace
	return p
end

local function noCollide(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = part(name, size, cframe, color, material)
	p.CanCollide = false
	return p
end

local function cylinder(name: string, radius: number, height: number, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = part(name, Vector3.new(radius * 2, height, radius * 2), cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function sphere(name: string, radius: number, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local p = part(name, Vector3.new(radius * 2, radius * 2, radius * 2), cframe, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- A beam (box) spanning from point a to point b; thickness is its X/Y size.
local function beam(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material): Part
	local dist = (b - a).Magnitude
	local cf = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
	return part(name, Vector3.new(thickness, thickness, dist), cf, color, material)
end

-- A walkable deck beam from a to b whose top surface sits exactly at WALK_TOP, so the
-- hub, spokes, ring walkway, pads and jetty form one continuous flat surface.
local function deck(name: string, a: Vector3, b: Vector3, width: number, color: Color3): Part
	local y = World.WALK_TOP - width / 2
	return beam(name, Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z), width, color, Enum.Material.WoodPlanks)
end

local function flatCFrame(center: Vector3, sizeY: number): CFrame
	return CFrame.new(center.X, center.Y - sizeY / 2, center.Z)
end

local function signText(parent: BasePart, text: string, textSize: number, color: Color3, face: Enum.NormalId): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.LightInfluence = 0
	gui.Brightness = 3
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui
	gui.Parent = parent
	return gui
end



-- ---------------------------------------------------------------- brainrot models

local EYE_WHITE = Color3.fromRGB(255, 255, 255)
local PUPIL = Color3.fromRGB(20, 20, 30)

local function addEyes(head: BasePart, width: number): ()
	local offset = width * 0.28
	for _, side in { -1, 1 } do
		local eye = sphere("Eye", width * 0.16, head.CFrame * CFrame.new(side * offset, width * 0.1, -width * 0.42), EYE_WHITE, Enum.Material.SmoothPlastic)
		eye.CanCollide = false
		local pupil = sphere("Pupil", width * 0.07, eye.CFrame * CFrame.new(0, 0, -width * 0.1), PUPIL, Enum.Material.SmoothPlastic)
		pupil.CanCollide = false
		pupil.Parent = eye
	end
end

local function addEmitter(parent: BasePart, mutation: MutationId): ()
	local emitter = Instance.new("ParticleEmitter")
	if mutation == "Shiny" then
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150))
		emitter.Rate = 20
		emitter.Lifetime = NumberRange.new(0.4, 0.9)
		emitter.Speed = NumberRange.new(2, 5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Transparency = NumberSequence.new(0.2, 1)
	elseif mutation == "Glitched" then
		emitter.Color = ColorSequence.new({ Color3.fromRGB(90, 255, 160), Color3.fromRGB(160, 90, 255), Color3.fromRGB(90, 200, 255) })
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(0.2, 0.5)
		emitter.Speed = NumberRange.new(4, 9)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Transparency = NumberSequence.new(0, 0.8)
		emitter.Acceleration = Vector3.new(0, 6, 0)
	else -- ROT
		emitter.Color = ColorSequence.new({ Color3.fromRGB(255, 70, 200), Color3.fromRGB(120, 20, 60) })
		emitter.Rate = 25
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Speed = NumberRange.new(1, 4)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.Transparency = NumberSequence.new(0.1, 0.9)
		emitter.Acceleration = Vector3.new(0, 8, 0)
	end
	emitter.Parent = parent
end

-- Builds one brainrot model for a tier + mutation (original characters, built from parts).
function World.buildBrainrot(tier: Tier, mutationId: MutationId): Model
	local mutation = Data.mutation(mutationId)
	local bodyColor = tier.color
	local accent = tier.accent
	if mutationId == "Shiny" then
		bodyColor = Color3.fromRGB(255, 236, 140)
	elseif mutationId == "Glitched" then
		bodyColor = Color3.fromRGB(90, 255, 160)
	elseif mutationId == "ROT" then
		bodyColor = Color3.fromRGB(120, 30, 70)
	end

	local model = Instance.new("Model")
	model.Name = tier.name

	local s = tier.bodySize
	local body = part("Body", s, CFrame.new(0, s.Y / 2 + 0.2, 0), bodyColor, Enum.Material.SmoothPlastic)
	body.Parent = model
	model.PrimaryPart = body

	local headSize = math.min(s.X, s.Z) * 0.9
	local head = part("Head", Vector3.new(headSize, headSize, headSize), CFrame.new(0, s.Y + headSize / 2 + 0.2, 0), accent, Enum.Material.SmoothPlastic)
	head.Parent = model
	addEyes(head, headSize)

	-- little arms and feet so it reads as a creature
	local armSize = Vector3.new(0.5, s.Y * 0.7, 0.5)
	for _, side in { -1, 1 } do
		local arm = part("Arm", armSize, CFrame.new(side * (s.X / 2 + 0.3), s.Y * 0.6, 0), bodyColor, Enum.Material.SmoothPlastic)
		arm.Parent = model
		local foot = part("Foot", Vector3.new(0.7, 0.4, 1), CFrame.new(side * s.X * 0.25, 0.4, 0), accent, Enum.Material.SmoothPlastic)
		foot.Parent = model
	end

	-- tier-flavoured hat / crown
	if tier.id >= 7 then
		local crown = cylinder("Crown", headSize * 0.55, 0.5, CFrame.new(0, s.Y + headSize + 0.45, 0), mutation.color, Enum.Material.Neon)
		crown.Parent = model
	elseif tier.id >= 4 then
		local cap = sphere("Cap", headSize * 0.55, CFrame.new(0, s.Y + headSize * 0.9, 0), mutation.color, Enum.Material.Neon)
		cap.Parent = model
	else
		local sprout = cylinder("Sprout", 0.12, 0.8, CFrame.new(0, s.Y + headSize + 0.6, 0), Color3.fromRGB(80, 200, 90), Enum.Material.Neon)
		sprout.Parent = model
	end

	addEmitter(head, mutationId)
	return model
end

-- Floating counter above a collector (a brainrot model).
function World.buildCounter(model: Model, rateText: string): BillboardGui
	local primary = model.PrimaryPart
	assert(primary ~= nil, "counter needs a PrimaryPart")
	local gui = Instance.new("BillboardGui")
	gui.Name = "CashCounter"
	gui.Adornee = primary
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(140, 36)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(180, 255, 170)
	label.TextStrokeTransparency = 0.3
	label.Text = rateText
	label.Parent = gui
	gui.Parent = primary
	return gui
end

-- ---------------------------------------------------------------- the world

local CORAL_COLORS = {
	Color3.fromRGB(255, 120, 160),
	Color3.fromRGB(255, 170, 90),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(90, 230, 200),
	Color3.fromRGB(255, 100, 110),
}

local function coralTower(pos: Vector3, height: number, seed: number): ()
	local color = CORAL_COLORS[(seed % #CORAL_COLORS) + 1]!
	local segments = 3 + (seed % 3)
	local y = pos.Y
	for i = 1, segments do
		local r = 1.6 - i * 0.3 + (seed % 2) * 0.2
		local h = height / segments
		local seg = cylinder(`Coral{i}`, math.max(0.4, r), h, CFrame.new(pos.X + math.sin(seed * i) * 0.3, y + h / 2, pos.Z + math.cos(seed * i) * 0.3), color, Enum.Material.Rock)
		seg.Parent = workspace
		y += h
	end
	sphere("CoralTip", 0.9, CFrame.new(pos.X, y + 0.4, pos.Z), Color3.fromRGB(255, 220, 160), Enum.Material.Neon).Parent = workspace
end

local function salvageLamp(pos: Vector3): ()
	cylinder("LampPole", 0.18, 6, CFrame.new(pos.X, pos.Y + 3, pos.Z), Color3.fromRGB(70, 70, 85), Enum.Material.Metal).Parent = workspace
	local bulb = sphere("LampBulb", 0.7, CFrame.new(pos.X, pos.Y + 6.4, pos.Z), Color3.fromRGB(255, 230, 140), Enum.Material.Neon)
	bulb.Parent = workspace
end

local function signpost(pos: Vector3, text: string, yaw: number): ()
	cylinder("SignPole", 0.14, 3.4, CFrame.new(pos.X, pos.Y + 1.7, pos.Z), Color3.fromRGB(120, 90, 60), Enum.Material.Wood).Parent = workspace
	local board = part("SignBoard", Vector3.new(3.4, 1.2, 0.25), CFrame.new(pos.X, pos.Y + 3.6, pos.Z) * CFrame.Angles(0, yaw, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	board.Parent = workspace
	signText(board, text, 40, Color3.fromRGB(255, 250, 220), Enum.NormalId.Front)
end

local function flag(pos: Vector3, color: Color3): ()
	cylinder("FlagPole", 0.12, 7, CFrame.new(pos.X, pos.Y + 3.5, pos.Z), Color3.fromRGB(200, 200, 210), Enum.Material.Metal).Parent = workspace
	local f = part("Flag", Vector3.new(2.2, 1.3, 0.1), CFrame.new(pos.X + 1.1, pos.Y + 6.4, pos.Z), color, Enum.Material.Neon)
	f.Parent = workspace
end

local function balloon(pos: Vector3, color: Color3): ()
	sphere("Balloon", 1.8, CFrame.new(pos.X, pos.Y + 12, pos.Z), color, Enum.Material.Neon).Parent = workspace
	beam("BalloonString", pos + Vector3.new(0, 12 - 1.8, 0), pos + Vector3.new(0, 1, 0), 0.06, Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic).Parent = workspace
end

local function cloud(pos: Vector3, scale: number): ()
	for i = 1, 5 do
		sphere(`Cloud{i}`, scale * (0.9 + (i % 3) * 0.4), CFrame.new(pos.X + (i - 3) * scale * 1.6, pos.Y + (i % 2) * scale * 0.5, pos.Z + math.sin(i * 2) * scale), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic).CanCollide = false
	end
end

local skyJunk: { Model } = {}

local function skyJunkPiece(pos: Vector3, size: Vector3, color: Color3, seed: number): ()
	local model = Instance.new("Model")
	model.Name = "SkyJunk"
	local p = part("Junk", size, CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(seed, seed * 2, seed * 0.5), color, Enum.Material.Metal)
	p.Parent = model
	if seed % 3 == 0 then
		sphere("JunkBit", size.X * 0.3, CFrame.new(0, size.Y * 0.8, 0), Color3.fromRGB(255, 200, 80), Enum.Material.Neon).Parent = model
	end
	model.Parent = workspace
	table.insert(skyJunk, model)
end

function World.build(): ()
	local top = World.WALK_TOP

	-- The sea: an animated water slab far below every pad; no kill plane, falls respawn.
	local water = noCollide("Sea", Vector3.new(4000, 1, 4000), CFrame.new(0, World.WATER_Y, 0), Color3.fromRGB(50, 200, 220), Enum.Material.Water)
	water.Transparency = 0.35
	-- Deep seabed far below, purely visual.
	cylinder("Seabed", 320, 4, CFrame.new(0, -32, 0), Color3.fromRGB(10, 40, 70), Enum.Material.Rock).Parent = workspace

	-- Central hub disc (floating reef), with a rocky underside.
	cylinder("Hub", World.HUB_RADIUS, 5, flatCFrame(World.CENTER, 5), Color3.fromRGB(196, 150, 110), Enum.Material.Rock).Parent = workspace
	cylinder("HubTop", World.HUB_RADIUS + 1.5, 2, CFrame.new(0, top - 1, 0), Color3.fromRGB(230, 205, 160), Enum.Material.Sand).Parent = workspace
	-- hanging coral under the hub so it reads as floating
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local r = World.HUB_RADIUS * (0.5 + (i % 4) * 0.12)
		local tip = Vector3.new(math.cos(a) * r, -2.5 - (i % 3), math.sin(a) * r)
		beam(`UnderCoral{i}`, tip, tip + Vector3.new(0, -3 - (i % 5), 0), 0.5, CORAL_COLORS[(i % #CORAL_COLORS) + 1]!, Enum.Material.Rock).Parent = workspace
	end

	-- Ring of pad slots + spokes + ring walkway between adjacent slots.
	local slotCount = World.PAD_SLOTS
	for i = 0, slotCount - 1 do
		local a = i / slotCount * math.pi * 2
		local pos = Vector3.new(math.cos(a) * World.RING_RADIUS, top - 1, math.sin(a) * World.RING_RADIUS)
		World.padSlots[i + 1] = pos
	end
	for i = 1, slotCount do
		local pos = World.padSlots[i]!
		local nextPos = World.padSlots[(i % slotCount) + 1]!
		-- pad platform (BasePad recolors/activates it per player)
		local pad = part(`PadSlot{i}`, Data.TUNING.padSize, CFrame.new(pos.X, pos.Y, pos.Z), Color3.fromRGB(120, 120, 130), Enum.Material.Concrete)
		pad.Parent = workspace
		CollectionService:AddTag(pad, "PadSlot")
		-- spoke walkway from hub to pad (deck top flush with the hub top)
		local spokeStart = Vector3.new(math.cos((i - 1) / slotCount * math.pi * 2) * (World.HUB_RADIUS - 2), top, math.sin((i - 1) / slotCount * math.pi * 2) * (World.HUB_RADIUS - 2))
		deck(`Spoke{i}`, spokeStart, pos, 6, Color3.fromRGB(210, 190, 150)).Parent = workspace
		-- ring walkway chord between adjacent pads
		deck(`RingWalk{i}`, pos, nextPos, 6, Color3.fromRGB(210, 190, 150)).Parent = workspace
	end

	-- Central donation fountain (the shop).
	local fountain = Instance.new("Model")
	fountain.Name = "DonationFountain"
	local base = cylinder("FountainBase", 7, 1.6, CFrame.new(0, top + 0.8, 0), Color3.fromRGB(180, 180, 200), Enum.Material.Marble)
	base.Parent = fountain
	local rim = cylinder("FountainRim", 6, 1.2, CFrame.new(0, top + 2.2, 0), Color3.fromRGB(140, 140, 170), Enum.Material.Metal)
	rim.Parent = fountain
	local waterBowl = cylinder("FountainWater", 5.2, 0.8, CFrame.new(0, top + 2.4, 0), Color3.fromRGB(90, 220, 255), Enum.Material.Neon)
	waterBowl.CanCollide = false
	waterBowl.Parent = fountain
	local statue = part("FountainStatue", Vector3.new(1.6, 4.5, 1.6), CFrame.new(0, top + 4.6, 0), Color3.fromRGB(255, 215, 120), Enum.Material.Neon)
	statue.Parent = fountain
	sphere("FountainTop", 1, CFrame.new(0, top + 7.2, 0), Color3.fromRGB(160, 240, 255), Enum.Material.Neon).Parent = fountain
	fountain.Parent = workspace
	World.fountainTop = Vector3.new(0, top + 7.5, 0)
	CollectionService:AddTag(fountain, "Fountain")

	-- The banner over the fountain.
	local bannerY = top + 12
	beam("BannerPostL", Vector3.new(-9, top, -9), Vector3.new(-9, bannerY, -9), 0.5, Color3.fromRGB(90, 90, 110), Enum.Material.Metal).Parent = workspace
	beam("BannerPostR", Vector3.new(9, top, -9), Vector3.new(9, bannerY, -9), 0.5, Color3.fromRGB(90, 90, 110), Enum.Material.Metal).Parent = workspace
	local banner = part("Banner", Vector3.new(19, 2.6, 0.4), CFrame.new(0, bannerY, -9), Color3.fromRGB(30, 30, 50), Enum.Material.SmoothPlastic)
	banner.Parent = workspace
	signText(banner, "make.fun REEF — the Tide is coming", 60, Color3.fromRGB(255, 90, 120), Enum.NormalId.Front)
	banner.CFrame = banner.CFrame * CFrame.Angles(0, math.pi, 0)
	signText(banner, "make.fun REEF — the Tide is coming", 60, Color3.fromRGB(255, 90, 120), Enum.NormalId.Back)

	-- Raiders' jetty: a wooden pier out from the ring at angle 0, ending in the start gate.
	local jettyDir = Vector3.new(math.cos(World.JETTY_ANGLE), 0, math.sin(World.JETTY_ANGLE))
	local jettyStart = jettyDir * (World.RING_RADIUS - 4) + Vector3.new(0, top - 1, 0)
	local jettyEnd = jettyDir * (World.RING_RADIUS + Data.TUNING.jettyLength) + Vector3.new(0, top - 1, 0)
	World.jettyEnd = jettyEnd + Vector3.new(0, 1, 0)
	deck("Jetty", jettyStart, jettyEnd, 7, Color3.fromRGB(150, 110, 70)).Parent = workspace
	for i = 1, 6 do
		local t = i / 7
		local p = jettyStart + (jettyEnd - jettyStart) * t
		cylinder("JettyPile", 0.4, 8, CFrame.new(p.X, p.Y - 4, p.Z), Color3.fromRGB(110, 80, 50), Enum.Material.Wood).Parent = workspace
	end
	-- start gate arch at the jetty end (spawn stands under it)
	local gatePos = jettyEnd + jettyDir * 4
	-- a small platform under the gate so the entry spawn is ON the ground, over the jetty
	-- deck extended to the gate, never over open water
	deck("GateDeck", jettyEnd, gatePos, 7, Color3.fromRGB(150, 110, 70)).Parent = workspace
	beam("GatePillarL", gatePos + Vector3.new(0, 0, -4), gatePos + Vector3.new(0, 9, -4), 0.9, Color3.fromRGB(255, 200, 60), Enum.Material.Neon).Parent = workspace
	beam("GatePillarR", gatePos + Vector3.new(0, 0, 4), gatePos + Vector3.new(0, 9, 4), 0.9, Color3.fromRGB(255, 200, 60), Enum.Material.Neon).Parent = workspace
	local gateBeam = beam("GateBeam", gatePos + Vector3.new(0, 9, -4), gatePos + Vector3.new(0, 9, 4), 0.9, Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
	gateBeam.Parent = workspace
	local gateSign = part("GateSign", Vector3.new(1, 2.2, 9.5), CFrame.new(gatePos.X, gatePos.Y + 10.6, gatePos.Z), Color3.fromRGB(25, 25, 45), Enum.Material.SmoothPlastic)
	gateSign.Parent = workspace
	signText(gateSign, "make.fun REEF", 90, Color3.fromRGB(140, 255, 220), Enum.NormalId.Front)
	World.spawnPoint = gatePos + Vector3.new(0, top, 0) - jettyDir * 1
	-- the spawn must rest on the gate deck, not float: clamp to the deck top
	World.spawnPoint = Vector3.new(World.spawnPoint.X, top, World.spawnPoint.Z)

	-- Two billboards.
	local billboardTexts = { "Built by an AI agent for make.fun", "Built by an AI agent for make.fun" }
	for i, text in billboardTexts do
		local a = (i / #billboardTexts) * math.pi * 2 + 0.8
		local pos = Vector3.new(math.cos(a) * (World.HUB_RADIUS + 6), top + 7, math.sin(a) * (World.HUB_RADIUS + 6))
		local board = part(`Billboard{i}`, Vector3.new(14, 7, 0.6), CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, -a + math.pi / 2, 0), Color3.fromRGB(20, 20, 40), Enum.Material.SmoothPlastic)
		board.Parent = workspace
		signText(board, text, 60, Color3.fromRGB(160, 240, 255), Enum.NormalId.Front)
		cylinder(`BillboardPole{i}`, 0.3, pos.Y - top, CFrame.new(pos.X, (pos.Y + top) / 2, pos.Z), Color3.fromRGB(80, 80, 100), Enum.Material.Metal).Parent = workspace
	end

	-- Density: coral towers around the hub rim and the ring.
	for i = 1, 18 do
		local a = i / 18 * math.pi * 2
		local r = World.HUB_RADIUS - 2.5 - (i % 3)
		coralTower(Vector3.new(math.cos(a) * r, top - 2, math.sin(a) * r), 4 + (i % 5) * 1.5, i * 7)
	end
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2 + 0.3
		coralTower(Vector3.new(math.cos(a) * (World.RING_RADIUS + 7), top - 2, math.sin(a) * (World.RING_RADIUS + 7)), 3 + (i % 4) * 1.2, i * 13)
	end

	-- Salvage lamps along every spoke.
	for i = 1, slotCount do
		local a = (i - 0.5) / slotCount * math.pi * 2
		local r = (World.HUB_RADIUS + World.RING_RADIUS) / 2
		salvageLamp(Vector3.new(math.cos(a) * r, top, math.sin(a) * r))
	end
	-- and along the jetty
	for i = 1, 3 do
		local p = jettyStart + (jettyEnd - jettyStart) * (i / 4)
		salvageLamp(p + Vector3.new(0, 0, 4))
	end

	-- Signposts.
	signpost(Vector3.new(8, top, 6), "Fountain: buy brainrots", 0.6)
	signpost(jettyStart + jettyDir * 6 + Vector3.new(0, top, 4.5), "Raiders' jetty ahead", 1.6)
	signpost(Vector3.new(-10, top, -8), "Your pad: safe from the Tide", 2.4)
	signpost(Vector3.new(0, top, 14), "make.fun REEF", 0)

	-- Flags on the hub rim and jetty.
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + 0.4
		flag(Vector3.new(math.cos(a) * (World.HUB_RADIUS - 1), top, math.sin(a) * (World.HUB_RADIUS - 1)), CORAL_COLORS[(i % #CORAL_COLORS) + 1]!)
	end
	flag(jettyEnd + Vector3.new(0, top, -4), Color3.fromRGB(255, 80, 80))

	-- Tethered balloons.
	local balloonColors = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 220, 100), Color3.fromRGB(170, 255, 150) }
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		balloon(Vector3.new(math.cos(a) * 34, top, math.sin(a) * 34), balloonColors[(i % #balloonColors) + 1]!)
	end
	balloon(jettyStart + jettyDir * 10, Color3.fromRGB(255, 150, 220))

	-- Drifting sky-junk.
	local junkColors = { Color3.fromRGB(150, 150, 170), Color3.fromRGB(180, 120, 80), Color3.fromRGB(90, 110, 140), Color3.fromRGB(200, 180, 90) }
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local r = 90 + (i % 5) * 30
		local pos = Vector3.new(math.cos(a) * r, 38 + (i % 7) * 6, math.sin(a) * r)
		skyJunkPiece(pos, Vector3.new(2 + (i % 4), 1.5 + (i % 3), 2 + (i % 5)), junkColors[(i % #junkColors) + 1]!, i)
	end

	-- Clouds.
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2 + 0.5
		local r = 70 + (i % 4) * 40
		cloud(Vector3.new(math.cos(a) * r, 75 + (i % 5) * 8, math.sin(a) * r), 3 + (i % 3))
	end

	-- Buoys bobbing on the open water around the reef (visual only).
	local buoyColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 220, 80), Color3.fromRGB(90, 255, 160) }
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2 + 0.25
		local r = 70 + (i % 4) * 22
		local p = Vector3.new(math.cos(a) * r, World.WATER_Y + 0.4, math.sin(a) * r)
		sphere(`Buoy{i}`, 1.1, CFrame.new(p.X, p.Y, p.Z), buoyColors[(i % #buoyColors) + 1]!, Enum.Material.Neon).Parent = workspace
	end

	-- Scattered rocks on the hub for texture.
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2 + 0.15
		local r = World.HUB_RADIUS - 4 + (i % 3) * 2
		local p = Vector3.new(math.cos(a) * r, top - 2, math.sin(a) * r)
		local rock = part(`Rock{i}`, Vector3.new(1 + (i % 3), 0.8 + (i % 2) * 0.6, 1 + (i % 4) * 0.4), CFrame.new(p.X, p.Y + 0.4, p.Z) * CFrame.Angles(0, i, 0), Color3.fromRGB(150, 130, 110), Enum.Material.Rock)
		rock.Parent = workspace
	end

	-- Sky-junk drifts slowly (a small bounded loop, not per-frame decoration inside a touch handler).
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for i, model in skyJunk do
			local p = model:GetPivot()
			model:PivotTo(p * CFrame.Angles(0, dt * 0.15, 0) + Vector3.new(0, math.sin(t * 0.4 + i) * dt * 0.6, 0))
		end
	end)
end

-- Distance check helpers used by the server (fountain shop, pad safety).
function World.nearFountain(player: Player): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - World.fountainTop).Magnitude <= Data.TUNING.fountainBuyRadius + 6
end

function World.padSlotPosition(slot: number): Vector3
	return World.padSlots[slot] or World.spawnPoint
end

return World
