--!strict
-- Hud.luau — the overlay ScreenGui: cash top-center-right, tier list on the right
-- edge, all semi-transparent (~0.45). Nothing in the top-left corner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local HUD_TRANSPARENCY = 0.45

local Hud = {
	gui = nil :: ScreenGui?,
	cashLabel = nil :: TextLabel?,
	tierList = nil :: Frame?,
	tierRows = {} :: { [number]: { row: TextButton, index: number, tier: { any } } },
	ownedLabel = nil :: TextLabel?,
	rebirthLabel = nil :: TextLabel?,
	notifyLabel = nil :: TextLabel?,
	state = nil :: { any }?,
}

-- WaitForChild with a timeout returns nil when the server has not created the
-- child yet (slow start); loop-retry instead of indexing a possible nil.
local function waitForChild(parent: Instance, name: string): Instance
	while true do
		local child: Instance? = parent:WaitForChild(name, 10)
		if child ~= nil then
			return child
		end
	end
end

local function remotes(): { [string]: RemoteEvent }
	local folder = waitForChild(ReplicatedStorage, "Remotes")
	local out: { [string]: RemoteEvent } = {}
	for _, name in { "BuyBrainrot", "Rebirth", "State", "CashTick", "TideState", "OrbTaken" } do
		local r = waitForChild(folder, name)
		assert(r:IsA("RemoteEvent"), `Remotes.{name} is not a RemoteEvent`)
		out[name] = r :: RemoteEvent
	end
	return out
end

local function makeLabel(parent: Instance, name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(240, 255, 245)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Parent = parent
	return label
end

-- Row text for the ladder: name + rate + the ACTUAL current price from the last State
-- payload (the server's costOf = base * 1.6^owned). Only before the first State
-- arrives does it fall back to the shared base cost.
local function tierText(index: number, tier: { any }): string
	local price = tier.cost
	local state = Hud.state
	if state ~= nil and typeof(state.prices) == "table" then
		local p = state.prices[tier.id]
		if typeof(p) == "number" then
			price = p
		end
	end
	return `{index}. {tier.name}  —  {tier.rate}/s  —  ${price}`
end

-- The 10-tier ladder list on the right edge, click-to-buy at the fountain.
function Hud.buildTierList(container: Frame, data: { any }): ()
	local tiers = data.TIERS
	local list = Instance.new("Frame")
	list.Name = "TierList"
	list.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	list.BackgroundTransparency = HUD_TRANSPARENCY
	list.BorderSizePixel = 0
	list.AnchorPoint = Vector2.new(1, 0.5)
	list.Position = UDim2.new(1, -8, 0.5, 0)
	list.Size = UDim2.fromOffset(240, 420)
	list.Parent = container
	Hud.tierList = list

	local title = makeLabel(list, "TierTitle")
	title.Text = "BRAINROT LADDER — click to buy at the fountain"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.fromOffset(0, 0)
	title.TextSize = 14

	for i, tier in tiers do
		local row = Instance.new("TextButton")
		row.Name = `Tier{tier.id}`
		row.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
		row.BackgroundTransparency = HUD_TRANSPARENCY
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, -8, 0, 34)
		row.Position = UDim2.fromOffset(4, 34 + (i - 1) * 38)
		row.Font = Enum.Font.Gotham
		row.TextColor3 = Color3.fromRGB(235, 250, 255)
		row.TextSize = 14
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = tierText(i, tier)
		row.Parent = list
		Hud.tierRows[tier.id] = { row = row, index = i, tier = tier }
		row.MouseButton1Click:Connect(function()
			local r = remotes()
			r.BuyBrainrot:FireServer(tier.id)
		end)
	end
end

function Hud.start(data: { any }): ()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReefHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Hud.gui = gui

	-- Cash, top-center-right (never top-left; the Roblox menu owns that corner).
	local cashFrame = Instance.new("Frame")
	cashFrame.Name = "Cash"
	cashFrame.AnchorPoint = Vector2.new(1, 0)
	cashFrame.Position = UDim2.new(1, -260, 0, 40) -- title must not hug the top edge
	cashFrame.Size = UDim2.fromOffset(250, 44)
	cashFrame.BackgroundColor3 = Color3.fromRGB(15, 35, 30)
	cashFrame.BackgroundTransparency = HUD_TRANSPARENCY
	cashFrame.BorderSizePixel = 0
	cashFrame.Parent = gui
	local cashLabel = makeLabel(cashFrame, "CashLabel")
	cashLabel.Text = "$0"
	cashLabel.Size = UDim2.fromScale(1, 1)
	cashLabel.TextSize = 22
	Hud.cashLabel = cashLabel

	-- Owned + rebirth, under the cash.
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "Info"
	infoFrame.AnchorPoint = Vector2.new(1, 0)
	infoFrame.Position = UDim2.new(1, -260, 0, 92)
	infoFrame.Size = UDim2.fromOffset(250, 66)
	infoFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
	infoFrame.BackgroundTransparency = HUD_TRANSPARENCY
	infoFrame.BorderSizePixel = 0
	infoFrame.Parent = gui
	local ownedLabel = makeLabel(infoFrame, "OwnedLabel")
	ownedLabel.Text = "Owned: 0  (rebirth at 8)"
	ownedLabel.Size = UDim2.new(1, 0, 0.5, 0)
	ownedLabel.Position = UDim2.fromOffset(6, 2)
	ownedLabel.TextSize = 14
	ownedLabel.TextXAlignment = Enum.TextXAlignment.Left
	Hud.ownedLabel = ownedLabel
	local rebirthLabel = makeLabel(infoFrame, "RebirthLabel")
	rebirthLabel.Text = "Rebirths: 0  (x1.0 cash)"
	rebirthLabel.Size = UDim2.new(1, 0, 0.5, 0)
	rebirthLabel.Position = UDim2.new(0, 6, 0.5, 0)
	rebirthLabel.TextSize = 14
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
	Hud.rebirthLabel = rebirthLabel
	local rebirthBtn = Instance.new("TextButton")
	rebirthBtn.Name = "RebirthButton"
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 160)
	rebirthBtn.BackgroundTransparency = HUD_TRANSPARENCY
	rebirthBtn.BorderSizePixel = 0
	rebirthBtn.Size = UDim2.fromOffset(110, 24)
	rebirthBtn.AnchorPoint = Vector2.new(1, 1)
	rebirthBtn.Position = UDim2.new(1, -6, 1, -4)
	rebirthBtn.Font = Enum.Font.GothamBold
	rebirthBtn.TextColor3 = Color3.fromRGB(255, 240, 255)
	rebirthBtn.TextSize = 13
	rebirthBtn.Text = "REBIRTH"
	rebirthBtn.Parent = infoFrame
	rebirthBtn.MouseButton1Click:Connect(function()
		remotes().Rebirth:FireServer()
	end)

	-- Notification line (orb pickups etc.), top-center — its OWN label, so it
	-- never overwrites the cash label.
	local notifyLabel = makeLabel(gui, "NotifyLabel")
	notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
	notifyLabel.Position = UDim2.new(0.5, 0, 0, 8)
	notifyLabel.Size = UDim2.new(1, -20, 0, 26)
	notifyLabel.TextSize = 16
	notifyLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
	notifyLabel.Text = ""
	Hud.notifyLabel = notifyLabel

	Hud.buildTierList(gui, data)

	gui.Parent = player:WaitForChild("PlayerGui")

	local r = remotes()
	r.State.OnClientEvent:Connect(function(state)
		Hud.state = state
		if Hud.cashLabel then
			Hud.cashLabel.Text = `$${math.floor(state.cash)}  (+${math.floor(state.rate)}/s)`
		end
		if Hud.ownedLabel then
			Hud.ownedLabel.Text = `Owned: {#state.owned}  (rebirth at 8)`
		end
		if Hud.rebirthLabel then
			Hud.rebirthLabel.Text = `Rebirths: {state.rebirths}  (x{state.cashMultiplier}) cash`
		end
		-- refresh the ladder with the actual current prices from the State payload
		for _, entry in Hud.tierRows do
			entry.row.Text = tierText(entry.index, entry.tier)
		end
	end)
	r.CashTick.OnClientEvent:Connect(function(cash, rate)
		if Hud.cashLabel then
			Hud.cashLabel.Text = `$${math.floor(cash)}  (+${math.floor(rate)}/s)`
		end
	end)
	local notifySeq = 0
	r.OrbTaken.OnClientEvent:Connect(function(takerName, tierId)
		-- write to the separate notification label; cashLabel keeps showing cash
		local label = Hud.notifyLabel
		if label == nil then
			return
		end
		notifySeq += 1
		local seq = notifySeq
		label.Text = `{takerName} grabbed a brainrot orb!`
		task.delay(3, function()
			if notifySeq == seq and label.Parent ~= nil then
				label.Text = ""
			end
		end)
	end)

	-- ask for the initial state
	r.State:FireServer()
end

return Hud
