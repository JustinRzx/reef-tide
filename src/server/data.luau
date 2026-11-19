--!strict
-- data.luau — every data-driven row of Meme Reef: Tide of the Weird.
-- Tiers, mutations and tuning constants live here only; the rest of the server reads them.

export type MutationId = "Shiny" | "Glitched" | "ROT"

export type Tier = {
	id: number,
	name: string,
	rate: number, -- cash per second, before mutation and rebirth multipliers
	cost: number, -- cash to buy the next copy at the fountain
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

local TUNING = {
	-- The Tide
	tidePeriod = 90, -- seconds between sweeps
	tideWarning = 10, -- klaxon seconds before the wall hits
	orbLifetime = 15, -- seconds a dropped brainrot orb stays grabbable
	orbPickupRadius = 5,

	-- Bases and pads
	padRadius = 9, -- safe-zone radius of a base pad
	padSize = Vector3.new(16, 2, 16),
	reefRingRadius = 46, -- pads sit on this ring around the fountain

	-- Economy
	startCash = 25,
	cashTick = 1, -- seconds between cash ticks
	maxOwnedPerTier = 99,
	fountainBuyRadius = 14,

	-- Rebirth
	rebirthAtOwned = 8, -- total brainrots owned that unlocks rebirth
	rebirthMultiplier = 2, -- cash-rate multiplier kept per rebirth

	-- Raid / jetty
	jettyLength = 30,

	-- Safety
	waterLevel = -6, -- the sea; below every pad
	fallRespawnDelay = 1.2,
}

local Data = {
	TIERS = TIERS,
	MUTATIONS = MUTATIONS,
	MUTATION_WEIGHTS = MUTATION_WEIGHTS,
	TUNING = TUNING,
	MAX_TIER = #TIERS,
}

function Data.tier(id: number): Tier
	assert(id >= 1 and id <= #TIERS, "tier id out of range")
	return TIERS[id]!
end

function Data.tierByName(name: string): Tier?
	for _, t in TIERS do
		if t.name == name then
			return t
		end
	end
	return nil
end

function Data.mutation(id: MutationId): Mutation
	for _, m in MUTATIONS do
		if m.id == id then
			return m
		end
	end
	error(`unknown mutation {id}`)
end

-- Weighted random mutation roll on purchase.
function Data.rollMutation(): Mutation
	local total = 0
	for _, w in MUTATION_WEIGHTS do
		total += w.weight
	end
	local roll = math.random() * total
	local acc = 0
	for _, w in MUTATION_WEIGHTS do
		acc += w.weight
		if roll <= acc then
			return Data.mutation(w.id)
		end
	end
	return Data.mutation("Shiny")
end

function Data.costOf(tierId: number, ownedCount: number): number
	local base = Data.tier(tierId).cost
	if base <= 0 then
		return 0
	end
	-- each owned copy raises the price of the next
	return math.floor(base * (1.6 ^ ownedCount))
end

return Data
