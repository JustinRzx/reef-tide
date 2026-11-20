--!strict
-- Game.client.luau — client entry for Meme Reef: Tide of the Weird.
-- Requires the shared tier rows from ReplicatedStorage (the same module instance the
-- server reads), then starts the rig, HUD, tide warning and the title screen.
-- The title screen releases the character spawn on dismiss.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- The ONE shared tier/mutation module, published by the server into
-- ReplicatedStorage.Shared.Tiers and required by both sides, so the HUD ladder can
-- never drift from the server's rows. Actual buy prices arrive in the State payload.
local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 30)
assert(sharedFolder ~= nil, "server did not publish ReplicatedStorage.Shared")
local tiersModule = sharedFolder:WaitForChild("Tiers", 30)
assert(tiersModule ~= nil and tiersModule:IsA("ModuleScript"), "server did not publish ReplicatedStorage.Shared.Tiers")
local SharedTiers = require(tiersModule :: ModuleScript)

local CameraRig = require(script.CameraRig)
local Hud = require(script.Hud)
local TideWarning = require(script.TideWarning)
local TitleScreen = require(script.TitleScreen)

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

local function releaseSpawn(): ()
	-- tell the server we dismissed the title screen; the server owns character
	-- loading — Player:LoadCharacter() can only be called on the server, calling
	-- it here throws and leaves the player without a character (join soft-lock)
	local remoteFolder = waitForChild(ReplicatedStorage, "Remotes")
	local state = waitForChild(remoteFolder, "State")
	assert(state:IsA("RemoteEvent"), "Remotes.State is not a RemoteEvent")
	(state :: RemoteEvent):FireServer()
end

CameraRig.start()
Hud.start({ TIERS = SharedTiers.TIERS })
TideWarning.start()
TitleScreen.start(releaseSpawn)

print("[Meme Reef] client started")
