--!strict
-- SharedTiers.luau — the ONE copy of the tier/mutation data tables of
-- Meme Reef: Tide of the Weird. init.server.luau publishes this module into
-- ReplicatedStorage.Shared.Tiers at boot, and both the server (through data.luau)
-- and the client (Game.client.luau) require that ReplicatedStorage instance, so the
-- HUD rows can never drift from the server's tables.
-- (default.project.json maps only src/server and src/client, so the canonical file
-- lives beside the server scripts and is cloned into ReplicatedStorage at runtime.)

export type MutationId = "Shiny" | "Glitched" | "ROT"

export type Tier = {
	id: number,
	name: string,
	rate: number, -- cash per second, before mutation and rebirth multipliers
	cost: number, -- BASE cash for the next copy; the server scales it per owned copy (Data.costOf)
	color: Color3,
	accent: Color3,
	bodySize: Vector3,
}

export type Mutation = {
	id: MutationId,
	label: string,
	multiplier: number,
	color: Color3,
}

-- The 10-tier brainrot ladder. Rates and costs are the design law's numbers.
local TIERS: { Tier } = {
	{ id = 1, name = "Soggy Biscuit Guy", rate = 1, cost = 0, color = Color3.fromRGB(222, 184, 135), accent = Color3.fromRGB(150, 111, 51), bodySize = Vector3.new(2.2, 2.6, 1.6) },
	{ id = 2, name = "Microwave Prawn", rate = 4, cost = 50, color = Color3.fromRGB(255, 127, 92), accent = Color3.fromRGB(90, 90, 110), bodySize = Vector3.new(2.4, 1.8, 1.4) },
	{ id = 3, name = "Corona Crab", rate = 12, cost = 220, color = Color3.fromRGB(235, 70, 60), accent = Color3.fromRGB(255, 214, 90), bodySize = Vector3.new(2.6, 1.6, 2.2) },
	{ id = 4, name = "Nyalakan Bae", rate = 35, cost = 900, color = Color3.fromRGB(255, 170, 220), accent = Color3.fromRGB(120, 60, 140), bodySize = Vector3.new(2.2, 2.8, 1.5) },
	{ id = 5, name = "Skibidi Sirens", rate = 100, cost = 3500, color = Color3.fromRGB(120, 120, 130), accent = Color3.fromRGB(240, 240, 250), bodySize = Vector3.new(2.6, 2.4, 1.6) },
	{ id = 6, name = "Womp Womp Whale", rate = 280, cost = 12000, color = Color3.fromRGB(70, 110, 220), accent = Color3.fromRGB(190, 220, 255), bodySize = Vector3.new(4.2, 3.2, 2.4) },
	{ id = 7, name = "Sigma Starfish", rate = 800, cost = 40000, color = Color3.fromRGB(255, 190, 60), accent = Color3.fromRGB(200, 60, 40), bodySize = Vector3.new(3.0, 0.9, 3.0) },
	{ id = 8, name = "Grimace Reef", rate = 2400, cost = 130000, color = Color3.fromRGB(140, 90, 210), accent = Color3.fromRGB(230, 210, 255), bodySize = Vector3.new(3.0, 4.2, 2.0) },
	{ id = 9, name = "Ohio Trench Lord", rate = 7000, cost = 420000, color = Color3.fromRGB(30, 40, 55), accent = Color3.fromRGB(90, 220, 200), bodySize = Vector3.new(3.4, 4.8, 2.2) },
	{ id = 10, name = "The Final Boss of the Sea", rate = 20000, cost = 1500000, color = Color3.fromRGB(20, 20, 30), accent = Color3.fromRGB(255, 60, 90), bodySize = Vector3.new(4.6, 5.6, 2.6) },
}

local MUTATIONS: { Mutation } = {
	{ id = "Shiny", label = "Shiny", multiplier = 1.5, color = Color3.fromRGB(255, 240, 150) },
	{ id = "Glitched", label = "Glitched", multiplier = 2.5, color = Color3.fromRGB(90, 255, 160) },
	{ id = "ROT", label = "ROT", multiplier = 4, color = Color3.fromRGB(255, 70, 200) },
}

local MUTATION_WEIGHTS: { { id: MutationId, weight: number } } = {
	{ id = "Shiny", weight = 70 },
	{ id = "Glitched", weight = 22 },
	{ id = "ROT", weight = 8 },
}

local SharedTiers = {
	TIERS = TIERS,
	MUTATIONS = MUTATIONS,
	MUTATION_WEIGHTS = MUTATION_WEIGHTS,
	MAX_TIER = #TIERS,
}

return SharedTiers
