--!strict
-- BasePad.luau — assigns one pad per playing player on the reef ring, owns the
-- safe-zone check, the collector display above each pad, respawn-on-fall, and
-- spawn placement on the ground at entry.

local Players = game:GetService("Players")

local Data = require(script.Parent.data)
local World = require(script.Parent.World)
local Economy = require(script.Parent.Economy)

local BasePad = {
	ownerOfSlot = {} :: { [number]: Player },
	slotOfPlayer = {} :: { [Player]: number },
	collectors = {} :: { [Player]: Model },
}

local SAFE_TAG = "SafeZone"

local function padCFrame(slot: number): CFrame
	local pos = World.padSlotPosition(slot)
	return CFrame.new(pos.X, pos.Y, pos.Z)
end

local function stylePad(slot: number, player: Player): ()
	local pad = workspace:FindFirstChild(`PadSlot{slot}`)
	if pad == nil or not pad:IsA("Part") then
		return
	end
	pad.Color = Color3.fromRGB(80, 200, 170)
	pad.Material = Enum.Material.Neon
	pad.Name = `Pad_{player.Name}`

	-- a little name sign on the pad
	local sign = Instance.new("Part")
	sign.Name = "PadSign"
	sign.Anchored = true
	sign.CanCollide = false
	sign.Size = Vector3.new(6, 1.6, 0.3)
	sign.CFrame = padCFrame(slot) * CFrame.new(0, 5, 0)
	sign.Color = Color3.fromRGB(30, 40, 60)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Parent = workspace
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 3
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(180, 255, 230)
	label.Text = `{player.Name}'s pad — safe from the Tide`
	label.Parent = gui
	gui.Parent = sign

	-- invisible safe-zone cylinder above the pad
	local zone = Instance.new("Part")
	zone.Name = SAFE_TAG
	zone.Anchored = true
	zone.CanCollide = false
	zone.Transparency = 1
	zone.Shape = Enum.PartType.Cylinder
	zone.Size = Vector3.new(24, Data.TUNING.padRadius * 2, Data.TUNING.padRadius * 2)
	zone.CFrame = padCFrame(slot) * CFrame.new(0, Data.TUNING.padRadius, 0) * CFrame.Angles(0, 0, math.pi / 2)
	zone.Parent = workspace
end

local function clearCollector(player: Player): ()
	local old = BasePad.collectors[player]
	if old ~= nil then
		old:Destroy()
		BasePad.collectors[player] = nil
	end
end

-- Rebuilds the floating collector stack above the player's pad from their profile.
function BasePad.refreshCollector(player: Player): ()
	clearCollector(player)
	local profile = Economy.profileOf(player)
	if #profile.owned == 0 then
		return
	end
	local slot = BasePad.slotOfPlayer[player]
	if slot == nil then
		return
	end
	local pos = World.padSlotPosition(slot)

	-- stack one built model per owned brainrot (bounded: maxOwnedPerTier * tiers)
	local stack = Instance.new("Model")
	stack.Name = `Collector_{player.Name}`
	local y = 3
	local shown = 0
	for _, o in profile.owned do
		if shown >= 10 then
			break -- keep the pad readable; the HUD list shows the rest
		end
		local tier = Data.tier(o.tier)
		local model = World.buildBrainrot(tier, o.mutation)
		model:PivotTo(CFrame.new(pos.X, pos.Y + y, pos.Z))
		model.Parent = stack
		y += 1.6
		shown += 1
	end
	if shown == 0 then
		stack:Destroy()
		return
	end
	-- floating cash counter above the stack
	local primary = Instance.new("Part")
	primary.Name = "CounterAnchor"
	primary.Anchored = true
	primary.CanCollide = false
	primary.Transparency = 1
	primary.Size = Vector3.new(0.1, 0.1, 0.1)
	primary.CFrame = CFrame.new(pos.X, pos.Y + y + 1.2, pos.Z)
	primary.Parent = stack
	stack.PrimaryPart = primary
	World.buildCounter(stack, "+" .. tostring(math.floor(Economy.rateOf(profile))) .. "/s")
	stack.Parent = workspace
	BasePad.collectors[player] = stack
end

function BasePad.assign(player: Player): ()
	if BasePad.slotOfPlayer[player] ~= nil then
		return
	end
	-- first free slot, else round-robin
	local slot: number? = nil
	for i = 1, World.PAD_SLOTS do
		if BasePad.ownerOfSlot[i] == nil then
			slot = i
			break
		end
	end
	if slot == nil then
		slot = ((#Players:GetPlayers() - 1) % World.PAD_SLOTS) + 1
	end
	BasePad.slotOfSlotFix(slot, player)
	stylePad(slot, player)
	BasePad.refreshCollector(player)
end

function BasePad.slotOfSlotFix(slot: number, player: Player): ()
	BasePad.ownerOfSlot[slot] = player
	BasePad.slotOfPlayer[player] = slot
end

function BasePad.release(player: Player): ()
	local slot = BasePad.slotOfPlayer[player]
	if slot ~= nil then
		BasePad.ownerOfSlot[slot] = nil
	end
	BasePad.slotOfPlayer[player] = nil
	clearCollector(player)
	-- reset the pad visual
	local pad = workspace:FindFirstChild(`Pad_{player.Name}`)
	if pad ~= nil and pad:IsA("Part") then
		pad.Name = `PadSlot{slot or 1}`
		pad.Color = Color3.fromRGB(120, 120, 130)
		pad.Material = Enum.Material.Concrete
	end
end

function BasePad.slotOf(player: Player): number?
	return BasePad.slotOfPlayer[player]
end

-- True when the player's root is inside their own pad safe zone.
function BasePad.isOnOwnPad(player: Player): boolean
	local slot = BasePad.slotOfPlayer[player]
	if slot == nil then
		return false
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	local center = World.padSlotPosition(slot)
	local dx = root.Position.X - center.X
	local dz = root.Position.Z - center.Z
	local dy = root.Position.Y - (center.Y + 1)
	return (dx * dx + dz * dz) <= Data.TUNING.padRadius * Data.TUNING.padRadius and math.abs(dy) <= Data.TUNING.padRadius
end

-- Places a character ON the ground at their pad (or the gate at entry). Never in the sky.
function BasePad.spawnCharacter(player: Player): ()
	local char = player.Character
	if char == nil then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local slot = BasePad.slotOfPlayer[player]
	local pos: Vector3
	if slot ~= nil then
		local p = World.padSlotPosition(slot)
		pos = Vector3.new(p.X, World.WALK_TOP + 1, p.Z)
	else
		pos = World.spawnPoint + Vector3.new(0, 1, 0)
	end
	root.CFrame = CFrame.new(pos)
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid ~= nil and humanoid:IsA("Humanoid") then
		humanoid.Health = humanoid.MaxHealth
	end
end

function BasePad.start(): ()
	Players.PlayerAdded:Connect(function(player)
		BasePad.assign(player)
		player.CharacterAdded:Connect(function()
			BasePad.spawnCharacter(player)
		end)
		if player.Character ~= nil then
			BasePad.spawnCharacter(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		BasePad.release(player)
	end)

	-- Falling into the water respawns the player on their own pad (no kill plane).
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root ~= nil and root:IsA("BasePart") then
					if root.Position.Y < World.WATER_Y + 1 then
						BasePad.spawnCharacter(player)
					end
				end
			end
		end
	end)
end

return BasePad
