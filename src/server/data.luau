--!strict
-- data.luau — server-side data facade of Meme Reef: Tide of the Weird.
-- The tier/mutation tables live in ONE shared module (ReplicatedStorage.Shared.Tiers,
-- published from src/server/SharedTiers.luau by init.server.luau and required by both
-- server and client); this file keeps the tuning constants and the server-side helpers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Static types come from the seed copy (full type inference); runtime values come
-- from the ReplicatedStorage instance that both sides share.
local SharedTiersSeed = require(script.Parent.SharedTiers)

export type MutationId = SharedTiersSeed.MutationId
export type Tier = SharedTiersSeed.Tier
export type Mutation = SharedTiersSeed.Mutation

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
local tiersModule = sharedFolder and sharedFolder:FindFirstChild("Tiers")
if tiersModule == nil or not tiersModule:IsA("ModuleScript") then
	error("ReplicatedStorage.Shared.Tiers missing — init.server.luau publishes it at boot")
end
local SharedTiers = require(tiersModule :: ModuleScript)

local TIERS: { Tier } = SharedTiers.TIERS
local MUTATIONS: { Mutation } = SharedTiers.MUTATIONS
local MUTATION_WEIGHTS: { { id: MutationId, weight: number } } = SharedTiers.MUTATION_WEIGHTS

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
