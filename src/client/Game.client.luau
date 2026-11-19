--!strict
-- Game.client.luau — client entry for Meme Reef: Tide of the Weird.
-- Loads the shared data rows for the HUD, then starts the rig, HUD, tide warning
-- and the title screen. The title screen releases the character spawn on dismiss.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local CameraRig = require(script.CameraRig)
local Hud = require(script.Hud)
local TideWarning = require(script.TideWarning)
local TitleScreen = require(script.TitleScreen)

-- The tier rows for the HUD list: mirrored from server data via a small module in
-- ReplicatedStorage is overkill for the ladder (it is static design data), so the
-- client builds its own copy from the same design-law numbers.
local TIERS = {
	{ id = 1, name = "Soggy Biscuit Guy", rate = 1, cost = 0 },
	{ id = 2, name = "Microwave Prawn", rate = 4, cost = 50 },
	{ id = 3, name = "Corona Crab", rate = 12, cost = 220 },
	{ id = 4, name = "Nyalakan Bae", rate = 35, cost = 900 },
	{ id = 5, name = "Skibidi Sirens", rate = 100, cost = 3500 },
	{ id = 6, name = "Womp Womp Whale", rate = 280, cost = 12000 },
	{ id = 7, name = "Sigma Starfish", rate = 800, cost = 40000 },
	{ id = 8, name = "Grimace Reef", rate = 2400, cost = 130000 },
	{ id = 9, name = "Ohio Trench Lord", rate = 7000, cost = 420000 },
	{ id = 10, name = "The Final Boss of the Sea", rate = 20000, cost = 1500000 },
}

local function releaseSpawn(): ()
	-- ask the server to (re)spawn us; CharacterAutoLoads is off, so load the character now
	local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
	local state = remoteFolder:WaitForChild("State", 10) :: RemoteEvent
	state:FireServer()
	player:LoadCharacter()
end

CameraRig.start()
Hud.start({ TIERS = TIERS })
TideWarning.start()
TitleScreen.start(releaseSpawn)

print("[Meme Reef] client started")
