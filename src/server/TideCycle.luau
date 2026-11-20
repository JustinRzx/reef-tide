--!strict
-- TideCycle.luau — "The Tide": every 90 s a tsunami wall sweeps the reef after a
-- 10 s klaxon. Players caught off their own pad lose their two rarest brainrots,
-- which fly up as collectible orbs for 15 s; anyone can grab them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Data = require(script.Parent.data)
local World = require(script.Parent.World)
local BasePad = require(script.Parent.BasePad)
local Economy = require(script.Parent.Economy)

local TUNING = Data.TUNING

local TideCycle = {
	phase = "calm" :: "calm" | "warning" | "sweep",
	timeLeft = TUNING.tidePeriod,
	wall = nil :: Part?,
	orbs = {} :: { { model: Model, owner: Player, tier: number, mutation: Data.MutationId, expiresAt: number } },
}

-- The wall part is created hidden and unparented: it only becomes visible when
-- the sweep phase sizes and parents it, so no neon 1x1x1 cube idles at the
-- origin between cycles.
local function makeWall(): Part
	local wall = Instance.new("Part")
	wall.Name = "TideWall"
	wall.Anchored = true
	wall.CanCollide = false
	wall.Transparency = 1
	wall.Size = Vector3.new(0, 0, 0)
	wall.Color = Color3.fromRGB(70, 200, 255)
	wall.Material = Enum.Material.Neon
	wall.Shape = Enum.PartType.Block
	return wall
end

local function setPhase(phase: "calm" | "warning" | "sweep", timeLeft: number): ()
	TideCycle.phase = phase
	TideCycle.timeLeft = timeLeft
	Economy.remotes.TideState:FireAllClients(phase, timeLeft, TUNING.tidePeriod)
end

-- Two rarest = highest tier ids; ties broken by mutation multiplier.
local function twoRarest(profile: Economy.Profile): { Economy.Owned }
	local sorted = table.clone(profile.owned)
	table.sort(sorted, function(a, b)
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		return Data.mutation(a.mutation).multiplier > Data.mutation(b.mutation).multiplier
	end)
	return { sorted[1], sorted[2] }
end

local function spawnOrb(player: Player, owned: Economy.Owned, at: Vector3): ()
	local tier = Data.tier(owned.tier)
	local model = World.buildBrainrot(tier, owned.mutation)
	model.Name = `Orb_{tier.name}`
	model:PivotTo(CFrame.new(at + Vector3.new(0, 4, 0)))
	model.Parent = workspace
	local orb = {
		model = model,
		owner = player,
		tier = owned.tier,
		mutation = owned.mutation,
		expiresAt = os.clock() + TUNING.orbLifetime,
	}
	table.insert(TideCycle.orbs, orb)
	-- float + spin
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		if model.Parent == nil or t > orb.expiresAt then
			conn:Disconnect()
			return
		end
		model:PivotTo(CFrame.new(at.X, at.Y + 4 + math.sin(t * 3) * 0.6, at.Z) * CFrame.Angles(0, t * 2, 0))
	end)
end

local function sweep(): ()
	for _, player in Players:GetPlayers() do
		local profile = Economy.profileOf(player)
		if #profile.owned >= 1 and not BasePad.isOnOwnPad(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local at = if root ~= nil and root:IsA("BasePart") then root.Position else World.spawnPoint
			local rarest = twoRarest(profile)
			for _, o in rarest do
				if o == nil then
					continue
				end
				spawnOrb(player, o, at)
				-- remove that owned entry
				for i, owned in profile.owned do
					if owned.tier == o.tier and owned.mutation == o.mutation then
						table.remove(profile.owned, i)
						break
					end
				end
			end
			Economy.broadcastState(player)
			BasePad.refreshCollector(player)
		end
		end
	end
end

-- Anyone touching an orb grabs it (validated server-side, bounded distance).
local function startOrbTouch(): ()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for i = #TideCycle.orbs, 1, -1 do
			local orb = TideCycle.orbs[i]!
			if now > orb.expiresAt or orb.model.Parent == nil then
				orb.model:Destroy()
				table.remove(TideCycle.orbs, i)
			else
				for _, player in Players:GetPlayers() do
					local char = player.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root ~= nil and root:IsA("BasePart") then
						local d = (root.Position - orb.model:GetPivot().Position).Magnitude
						if d <= TUNING.orbPickupRadius then
							local profile = Economy.profileOf(player)
							if #profile.owned < TUNING.maxOwnedPerTier * Data.MAX_TIER then
								table.insert(profile.owned, { tier = orb.tier, mutation = orb.mutation })
								Economy.broadcastState(player)
								BasePad.refreshCollector(player)
								Economy.remotes.OrbTaken:FireAllClients(player.Name, orb.tier)
							end
							orb.model:Destroy()
							table.remove(TideCycle.orbs, i)
							break
						end
					end
				end
			end
		end
	end)
end

function TideCycle.start(): ()
	startOrbTouch()
	task.spawn(function()
		while true do
			-- calm phase
			setPhase("calm", TUNING.tidePeriod)
			local t0 = os.clock()
			while os.clock() - t0 < TUNING.tidePeriod - TUNING.tideWarning do
				local left = TUNING.tidePeriod - (os.clock() - t0)
				TideCycle.timeLeft = left
				task.wait(1)
			end
			-- warning phase: klaxon, rebroadcast so the client countdown ticks
			setPhase("warning", TUNING.tideWarning)
			t0 = os.clock()
			while os.clock() - t0 < TUNING.tideWarning do
				local left = TUNING.tideWarning - (os.clock() - t0)
				TideCycle.timeLeft = left
				Economy.remotes.TideState:FireAllClients("warning", left, TUNING.tidePeriod)
				task.wait(0.5)
			end
			-- sweep: animate the wall across the reef as a shrinking ring; the wall
			-- is created only now and shown immediately at full size, so nothing
			-- sits visible at the origin during calm/warning
			setPhase("sweep", 0)
			local radius = 140
			local wall = makeWall()
			TideCycle.wall = wall
			wall.Shape = Enum.PartType.Cylinder
			wall.Size = Vector3.new(radius * 2, 30, radius * 2)
			wall.CFrame = CFrame.new(0, World.WATER_Y + 12, 0)
			wall.Transparency = 0.25
			wall.Parent = workspace
			local swept = false
			for step = 1, 30 do
				local r = radius * (1 - step / 30)
				wall.Size = Vector3.new(r * 2, 30, r * 2)
				wall.CFrame = CFrame.new(0, World.WATER_Y + 12, 0)
				-- punish when the wall VISUALLY reaches the pad ring radius, not
				-- after the whole shrink animation has finished
				if not swept and r <= World.RING_RADIUS then
					swept = true
					sweep()
				end
				task.wait(0.12)
			end
			wall:Destroy()
			TideCycle.wall = nil
			if not swept then
				sweep() -- safety net: the ring was already inside RING_RADIUS
			end
		end
	end)
end

return TideCycle
