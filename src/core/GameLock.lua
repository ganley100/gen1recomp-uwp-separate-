-- Single-game builds: a package that ships one game (the Xbox "Gen1Recomp
-- Red" and "Gen1Recomp Ruby" apps) locks the launcher to that game.
--
--   love . --lock-game=red          -- only Red is offered
--   POKEPORT_LOCK_GAME=ruby love .  -- same, for hosts that only pass env
--
-- The UWP host passes --lock-game=<id> next to --game=<id>, so the package
-- boots straight into its game and, when it returns to the launcher, shows
-- that game's tab and nothing else.  Every other build has no lock and this
-- module answers nil everywhere.

local GameLock = {}

local cached -- false once resolved to "no lock"

local function readArgs()
  local argv = rawget(_G, "arg")
  if type(argv) ~= "table" then return nil end
  for _, a in pairs(argv) do
    if type(a) == "string" then
      local v = a:match("^%-%-lock%-game=(.+)$")
      if v then return v end
    end
  end
  return nil
end

local function normalize(v)
  if type(v) ~= "string" then return nil end
  v = v:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if v == "" then return nil end
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  if ok and type(GameVersion) == "table" and type(GameVersion.VERSIONS) == "table"
      and not GameVersion.VERSIONS[v] then
    return nil
  end
  return v
end

-- The locked game id, or nil when this build offers every game.
function GameLock.id()
  if cached == nil then
    cached = normalize(readArgs()) or normalize(os.getenv("POKEPORT_LOCK_GAME")) or false
  end
  return cached or nil
end

-- True when `version` may be offered by this build.
function GameLock.allows(version)
  local lock = GameLock.id()
  return lock == nil or lock == version
end

-- Tests only.
function GameLock._set(v)
  if v == nil then cached = nil else cached = normalize(v) or false end
end

return GameLock
