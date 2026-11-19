--!strict
-- TideWarning.luau — the klaxon banner bottom-center while the Tide is coming,
-- plus the countdown. Semi-transparent (~0.45).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local TideWarning = {
	banner = nil :: Frame?,
	label = nil :: TextLabel?,
	visible = false,
}

local TRANSPARENCY = 0.45

function TideWarning.start(): ()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TideWarningGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5

	local banner = Instance.new("Frame")
	banner.Name = "KlaxonBanner"
	banner.AnchorPoint = Vector2.new(0.5, 1)
	banner.Position = UDim2.new(0.5, 0, 1, -70) -- bottom-center
	banner.Size = UDim2.fromOffset(560, 54)
	banner.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
	banner.BackgroundTransparency = TRANSPARENCY
	banner.BorderSizePixel = 0
	banner.Visible = false
	banner.Parent = gui
	TideWarning.banner = banner

	local label = Instance.new("TextLabel")
	label.Name = "KlaxonText"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 235, 235)
	label.TextStrokeTransparency = 0.3
	label.Text = "THE TIDE IS COMING — GET TO YOUR PAD!"
	label.Parent = banner
	TideWarning.label = label

	gui.Parent = player:WaitForChild("PlayerGui")

	local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
	local tideState = folder:WaitForChild("TideState", 10) :: RemoteEvent
	tideState.OnClientEvent:Connect(function(phase: string, timeLeft: number, period: number)
		if phase == "warning" then
			banner.Visible = true
			TideWarning.visible = true
		elseif phase == "sweep" then
			banner.Visible = true
			label.Text = "THE TIDE SWEEPS THE REEF!"
		elseif phase == "calm" then
			banner.Visible = false
			TideWarning.visible = false
		end
	end)

	-- live countdown while warning
	local RunService = game:GetService("RunService")
	RunService.RenderStepped:Connect(function()
		if TideWarning.visible and TideWarning.label ~= nil then
			local phase = TideWarning.banner and TideWarning.banner.Visible
			if phase then
				-- timeLeft arrives on events; show a shrinking hint via a local clock is
				-- unreliable, so the label text is refreshed from the last event below
			end
		end
	end)

	-- refresh countdown text on each state event with the remaining seconds
	local lastLeft = 0
	tideState.OnClientEvent:Connect(function(phase: string, timeLeft: number)
		lastLeft = timeLeft
		if phase == "warning" and TideWarning.label ~= nil then
			TideWarning.label.Text = `THE TIDE IS COMING — {math.ceil(timeLeft)}s — GET TO YOUR PAD!`
		end
	end)
end

return TideWarning
