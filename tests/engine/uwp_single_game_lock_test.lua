-- Single-game Xbox packages (Gen1Recomp Red / Ruby / FireRed) pass
-- --lock-game=<id>; the launcher must then offer that game only.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.harness")
local check = T.check
love = love or require("tests.love_stub")

local GameLock = require("src.core.GameLock")
local SecretGames = require("src.import.SecretGames")

local function ids(list) return " " .. table.concat(list, " ") .. " " end

GameLock._set(nil)
local savedArg = rawget(_G, "arg")
_G.arg = { [0] = "Gen1RecompUWP", "gen1recomp.love", "--fused" }
check(GameLock.id() == nil, "no --lock-game leaves every game available")
check(ids(SecretGames.order({ launcher = true })):find(" red ", 1, true)
  and ids(SecretGames.order({ launcher = true })):find(" gold ", 1, true),
  "unlocked launcher lists Red and Gold")

GameLock._set(nil)
_G.arg = { [0] = "Gen1RecompRed", "gen1recomp.love", "--fused", "--game=red", "--lock-game=red" }
check(GameLock.id() == "red", "--lock-game=red is read from the host arguments")
check(ids(SecretGames.order({ launcher = true })) == " red ", "Red package lists Red only")
check(not SecretGames.visible("blue"), "Red package hides Blue")

GameLock._set(nil)
_G.arg = { [0] = "Gen1RecompRuby", "gen1recomp.love", "--fused", "--game=ruby", "--lock-game=Ruby" }
check(GameLock.id() == "ruby", "--lock-game is case-insensitive")
check(ids(SecretGames.order({ launcher = true })) == " ruby ", "Ruby package lists Ruby only")
check(GameLock.allows("ruby") and not GameLock.allows("sapphire"), "Ruby package allows Ruby only")

GameLock._set(nil)
_G.arg = { [0] = "Gen1RecompFireRed", "gen1recomp.love", "--fused", "--game=firered", "--lock-game=firered" }
check(GameLock.id() == "firered", "--lock-game=firered is read from the host arguments")
check(ids(SecretGames.order({ launcher = true })) == " firered ", "FireRed package lists FireRed only")
check(not SecretGames.visible("leafgreen"), "FireRed package hides LeafGreen")

GameLock._set(nil)
_G.arg = { "--lock-game=notagame" }
check(GameLock.id() == nil, "an unknown game id is ignored")

_G.arg = savedArg
GameLock._set(nil)
T.finish("uwp single game lock")
