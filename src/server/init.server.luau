--!strict
-- init.server.luau — server entry for Meme Reef: Tide of the Weird.
-- Publishes the one shared tier/mutation module into ReplicatedStorage (both the
-- server and the client require that instance), builds the world, then starts
-- the base pads and the economy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- default.project.json maps only src/server and src/client, so the canonical shared
-- file lives at src/server/SharedTiers.luau; clone it into ReplicatedStorage at boot
-- so server and client require the very same module under ReplicatedStorage.
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if sharedFolder == nil then
	sharedFolder = Instance.new("Folder")
	sharedFolder.Name = "Shared"
	sharedFolder.Parent = ReplicatedStorage
end
if sharedFolder:FindFirstChild("Tiers") == nil then
	local seed = script:FindFirstChild("SharedTiers")
	if seed == nil or not seed:IsA("ModuleScript") then
		error("SharedTiers seed missing from Server")
	end
	local published = seed:Clone()
	published.Name = "Tiers"
	published.Parent = sharedFolder
end

local World = require(script.World)
local BasePad = require(script.BasePad)
local Economy = require(script.Economy)
local TideCycle = require(script.TideCycle)
local Rebirth = require(script.Rebirth)

World.build()
BasePad.start()
Economy.start()
TideCycle.start()
Rebirth.start()

print("[Meme Reef] server started: reef built, pads assigned, economy ticking")
