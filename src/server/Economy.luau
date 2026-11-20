--!strict
-- Economy.luau — per-player cash, owned brainrots, purchases and the cash tick.
-- The server never trusts numbers from the client: every RemoteEvent validates its args.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Data = require(script.Parent.data)
local World = require(script.Parent.World)

type MutationId = Data.MutationId

export type Owned = {
	tier: number,
	mutation: MutationId,
}

export type Profile = {
	cash: number,
	owned: { Owned },
	rebirths: number,
	cashMultiplier: number, -- 1 + rebirths * (rebirthMultiplier - 1) style, kept across rebirth
	totalEarned: number,
}

local TUNING = Data.TUNING

local Economy = {
	profiles = {} :: { [Player]: Profile },
	remotes = {} :: { [string]: RemoteEvent },
}

local function makeRemotes(): { [string]: RemoteEvent }
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local out: { [string]: RemoteEvent } = {}
	for _, name in { "BuyBrainrot", "Rebirth", "State", "CashTick", "TideState", "OrbTaken" } do
		local r = folder:FindFirstChild(name)
		if r == nil or not r:IsA("RemoteEvent") then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
		out[name] = r :: RemoteEvent
	end
	return out
end

Economy.remotes = makeRemotes()

local function newProfile(): Profile
	return {
		cash = TUNING.startCash,
		owned = {},
		rebirths = 0,
		cashMultiplier = 1,
		totalEarned = 0,
	}
end

function Economy.profileOf(player: Player): Profile
	local p = Economy.profiles[player]
	if p == nil then
		p = newProfile()
		Economy.profiles[player] = p
	end
	return p
end

function Economy.ownedCount(profile: Profile): number
	return #profile.owned
end

-- How many copies of one tier the profile currently owns (drives costOf pricing).
local function ownedOfTier(profile: Profile, tierId: number): number
	local n = 0
	for _, o in profile.owned do
		if o.tier == tierId then
			n += 1
		end
	end
	return n
end

-- Income per second across every owned brainrot (tier rate * mutation * rebirth multiplier).
function Economy.rateOf(profile: Profile): number
	local sum = 0
	for _, o in profile.owned do
		local tier = Data.tier(o.tier)
		local mutation = Data.mutation(o.mutation)
		sum += tier.rate * mutation.multiplier
	end
	return sum * profile.cashMultiplier
end

function Economy.addCash(profile: Profile, amount: number): number
	profile.cash += amount
	profile.totalEarned += amount
	return profile.cash
end

local function validateTierId(v: unknown): number?
	if typeof(v) ~= "number" then
		return nil
	end
	local id = math.floor(v)
	if id < 1 or id > Data.MAX_TIER then
		return nil
	end
	return id
end

-- Rate-limited, validated purchase. Returns true when the purchase happened.
local lastBuyAt: { [Player]: number } = {}
local BUY_COOLDOWN = 0.25

function Economy.tryBuy(player: Player, tierIdRaw: unknown): boolean
	local tierId = validateTierId(tierIdRaw)
	if tierId == nil then
		return false
	end
	local now = os.clock()
	if (lastBuyAt[player] or 0) + BUY_COOLDOWN > now then
		return false
	end
	-- purchases happen at the fountain (design law), not from anywhere
	if not World.nearFountain(player) then
		return false
	end
	local profile = Economy.profileOf(player)
	local ownedCount = ownedOfTier(profile, tierId)
	if ownedCount >= TUNING.maxOwnedPerTier then
		return false
	end
	local cost = Data.costOf(tierId, ownedCount)
	if profile.cash < cost then
		return false
	end
	lastBuyAt[player] = now
	profile.cash -= cost
	local mutation = Data.rollMutation()
	table.insert(profile.owned, { tier = tierId, mutation = mutation.id })
	Economy.broadcastState(player)
	return true
end

function Economy.tryRebirth(player: Player): boolean
	local profile = Economy.profileOf(player)
	if #profile.owned < TUNING.rebirthAtOwned then
		return false
	end
	profile.rebirths += 1
	-- keeps a cash-rate multiplier and resets the base
	profile.cashMultiplier = 1 + profile.rebirths * (Data.TUNING.rebirthMultiplier - 1)
	profile.owned = {}
	profile.cash = math.max(profile.cash, TUNING.startCash)
	Economy.broadcastState(player)
	return true
end

function Economy.serialize(profile: Profile): { any }
	local owned: { any } = {}
	for i, o in profile.owned do
		owned[i] = { tier = o.tier, mutation = o.mutation }
	end
	-- The ACTUAL current price per tier (costOf = base * 1.6^owned), so the client
	-- HUD can show what a buy would really cost right now, not the base prices.
	local prices: { number } = {}
	for tierId = 1, Data.MAX_TIER do
		prices[tierId] = Data.costOf(tierId, ownedOfTier(profile, tierId))
	end
	return {
		cash = profile.cash,
		rate = Economy.rateOf(profile),
		owned = owned,
		prices = prices,
		rebirths = profile.rebirths,
		cashMultiplier = profile.cashMultiplier,
		totalEarned = profile.totalEarned,
	}
end

function Economy.broadcastState(player: Player): ()
	local profile = Economy.profileOf(player)
	Economy.remotes.State:FireClient(player, Economy.serialize(profile))
end

function Economy.start(): ()
	Economy.remotes.BuyBrainrot.OnServerEvent:Connect(function(player, tierIdRaw)
		Economy.tryBuy(player, tierIdRaw)
	end)
	Economy.remotes.Rebirth.OnServerEvent:Connect(function(player)
		Economy.tryRebirth(player)
	end)
	Economy.remotes.State.OnServerEvent:Connect(function(player)
		Economy.broadcastState(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		Economy.profileOf(player)
		Economy.broadcastState(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		Economy.profiles[player] = nil
		lastBuyAt[player] = nil
	end)

	-- Cash ticks once per second per player; the client also gets a tick payload
	-- so its floating counter can animate smoothly.
	task.spawn(function()
		while true do
			local dt = task.wait(TUNING.cashTick)
			for _, player in Players:GetPlayers() do
				local profile = Economy.profiles[player]
				if profile ~= nil then
					local rate = Economy.rateOf(profile)
					if rate > 0 then
						Economy.addCash(profile, rate * dt)
					end
					Economy.remotes.CashTick:FireClient(player, profile.cash, rate)
				end
			end
		end
	end)
end

return Economy
