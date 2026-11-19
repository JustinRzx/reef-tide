--!strict
-- TitleScreen.luau — a real title screen at entry (overlay only): big title not
-- hugging the top edge, subtitle, "click to dive in"; spawns the character on the
-- pad once dismissed.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local TitleScreen = {
	gui = nil :: ScreenGui?,
	dismissed = false,
	onDismiss = nil :: (() -> ())?,
}

function TitleScreen.start(onDismiss: () -> ()): ()
	TitleScreen.onDismiss = onDismiss

	local gui = Instance.new("ScreenGui")
	gui.Name = "TitleScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	TitleScreen.gui = gui

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.BackgroundColor3 = Color3.fromRGB(8, 30, 45)
	backdrop.BackgroundTransparency = 0.25
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.32, 0) -- clearly off the top edge
	title.Size = UDim2.new(1, 0, 0, 90)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextSize = 60
	title.TextColor3 = Color3.fromRGB(140, 255, 220)
	title.TextStrokeTransparency = 0.2
	title.Text = "MEME REEF: TIDE OF THE WEIRD"
	title.Parent = backdrop

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.45, 0)
	subtitle.Size = UDim2.new(1, 0, 0, 36)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextScaled = true
	subtitle.TextColor3 = Color3.fromRGB(220, 245, 255)
	subtitle.Text = "make.fun REEF — buy brainrots at the fountain, dodge the Tide, get rich"
	subtitle.Parent = backdrop

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.Position = UDim2.new(0.5, 0, 0.62, 0)
	hint.Size = UDim2.new(1, 0, 0, 30)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextScaled = true
	hint.TextColor3 = Color3.fromRGB(255, 230, 150)
	hint.Text = "Every 90 s the Tide sweeps the reef — stand on your pad or lose your two rarest brainrots"
	hint.Parent = backdrop

	local button = Instance.new("TextButton")
	button.Name = "DiveIn"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(0.5, 0, 0.74, 0)
	button.Size = UDim2.fromOffset(260, 56)
	button.BackgroundColor3 = Color3.fromRGB(30, 160, 140)
	button.BackgroundTransparency = 0.2
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = "DIVE IN"
	button.Parent = backdrop

	local function dismiss()
		if TitleScreen.dismissed then
			return
		end
		TitleScreen.dismissed = true
		gui:Destroy()
		if TitleScreen.onDismiss ~= nil then
			TitleScreen.onDismiss()
		end
	end

	button.MouseButton1Click:Connect(dismiss)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			dismiss()
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return TitleScreen
