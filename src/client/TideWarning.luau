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
			if TideWarning.label ~= nil then
				TideWarning.label.Text = `THE TIDE IS COMING — {math.ceil(timeLeft)}s — GET TO YOUR PAD!`
			end
		elseif phase == "sweep" then
			banner.Visible = true
			TideWarning.visible = true
			if TideWarning.label ~= nil then
				TideWarning.label.Text = "THE TIDE SWEEPS THE REEF!"
			end
		elseif phase == "calm" then
			banner.Visible = false
			TideWarning.visible = false
		end
	end)
end

return TideWarning
