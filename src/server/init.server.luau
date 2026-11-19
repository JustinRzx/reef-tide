--!strict
-- init.server.luau — server entry for Meme Reef: Tide of the Weird.
-- Builds the world, then starts the base pads and the economy.

local World = require(script.World)
local BasePad = require(script.BasePad)
local Economy = require(script.Economy)

World.build()
BasePad.start()
Economy.start()

print("[Meme Reef] server started: reef built, pads assigned, economy ticking")
