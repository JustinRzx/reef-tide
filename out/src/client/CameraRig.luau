--!strict
-- CameraRig.luau — a real 3D camera: a smooth third-person follow rig anchored on
-- the player's character, with a slight tide-sway. No ScreenGui camera tricks.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CameraRig = {
	distance = 26,
	height = 10,
	angle = 0, -- orbit angle, Q/E or mouse-drag rotates
	pitch = 0.35,
}

function CameraRig.start(): ()
	local camera = workspace.CurrentCamera
	assert(camera ~= nil)
	camera.CameraType = Enum.CameraType.Scriptable

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q then
			CameraRig.angle += 0.35
		elseif input.KeyCode == Enum.KeyCode.E then
			CameraRig.angle -= 0.35
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			return
		end
		local focus = root.Position
		local sway = math.sin(os.clock() * 0.5) * 0.4
		local dist = CameraRig.distance
		local h = CameraRig.height + sway
		local a = CameraRig.angle
		local camPos = focus + Vector3.new(math.cos(a) * dist, h, math.sin(a) * dist)
		camera.CFrame = CFrame.lookAt(camPos, focus + Vector3.new(0, 2, 0))
		camera.FieldOfView = 60
	end)
end

return CameraRig
