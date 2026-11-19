--!strict
-- Rebirth.luau — rebirth at 8 brainrots owned: keeps a cash-rate multiplier and
-- resets the base. The actual purchase logic lives in Economy (validated there);
-- this module watches profiles and refreshes pad collectors after a rebirth.

local Players = game:GetService("Players")

local Data = require(script.Parent.data)
local Economy = require(script.Parent.Economy)
local BasePad = require(script.Parent.BasePad)

local TUNING = Data.TUNING

local Rebirth = {}

function Rebirth.canRebirth(player: Player): boolean
	local profile = Economy.profileOf(player)
	return #profile.owned >= TUNING.rebirthAtOwned
end

function Rebirth.start(): ()
	-- After every state broadcast, if a rebirth happened the collector was already
	-- refreshed by Economy; here we just keep a light watchdog so pads stay in sync
	-- (bounded loop, no decoration work inside any touch handler).
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				local profile = Economy.profileOf(player)
				if profile.rebirths > 0 and BasePad.slotOf(player) ~= nil then
					-- collector refresh is idempotent and cheap; only when the pad is empty
					-- (right after a rebirth) do we rebuild
					if BasePad.collectors[player] == nil and #profile.owned > 0 then
						BasePad.refreshCollector(player)
					end
				end
			end
		end
	end)
end

return Rebirth
