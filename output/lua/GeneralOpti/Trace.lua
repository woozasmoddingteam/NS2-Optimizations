
local table_new = require "table.new"
local max = math.max
local abs = math.abs
local band = bit.band
local origin = Vector.origin
local type = type
local Shared_GetTime = Shared.GetTime
local Vector = Vector
local ffi = require "ffi"

local function diffunder(limit, v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z - v2.z)) < limit
end

local kCacheSize = 4
local kCacheElements = 8
local keyStartPoint   = 0
local keyStopPoint    = 1
local keyCollisionRep = 2
local keyPhysicsMask  = 3
local keyFilter       = 4
local keyTrace        = 5
local kAcceptance = 0.1

local cache = table_new(kCacheSize*kCacheElements, 0)
--[=[
local cache = setmetatable({}, {
	__index = _cache,
	__newindex = function(self, key, value)
		if band(key, 0x7) == keyStartPoint then
			Log("Trace assigned to keyStartPoint: %s", value)
			--Log(debug.callstack())
		end
		_cache[key] = value
	end
})
--]=]
local prev_time
local last = 0

local function set(i, start, stop, collisionRep, physicsMask, filter, trace)
	--[=[
	assert(start:isa("Vector"))
	assert(stop:isa("Vector"))
	assert(type(collisionRep) == "number")
	assert(type(physicsMask) == "number")
	assert(type(filter) == "function" or filter == nil)
	assert(trace == nil or type(trace) == "cdata")
	--]=]
	cache[i+keyStartPoint]   = start
	cache[i+keyStopPoint]    = stop
	cache[i+keyCollisionRep] = collisionRep
	cache[i+keyPhysicsMask]  = physicsMask
	cache[i+keyFilter]       = filter
	cache[i+keyTrace]        = trace
end

local function clear()
	prev_time = Shared_GetTime()
	local i = 0
	while i < kCacheSize * kCacheElements do
		set(i, origin, origin, 0, 0xFFFFFFFF)
		i = i + kCacheElements
	end
end

local old = Shared.TraceRay

local cache_hits   = 0
local cache_misses = 0

function Shared.TraceRay(start, stop, collisionRep, physicsMask, filter)
	if type(physicsMask) ~= "number" then -- Unsupported
		filter = physicsMask
		physicsMask = 0xFFFFFFFF
	end

	if Shared_GetTime() ~= prev_time then
		--Log "Clearing!"
		clear()
	else
		local i = 0
		while i < kCacheSize*kCacheElements do
			---[=[
			if not diffunder(kAcceptance, start, cache[i+keyStartPoint]) then
				Log "startPoint mismatch!"
				Log("(%s) vs (%s)", start, cache[i+keyStartPoint])
			elseif not diffunder(kAcceptance, stop, cache[i+keyStopPoint]) then
				Log "stopPoint mismatch!"
				Log("(%s) vs (%s)", stop, cache[i+keyStopPoint])
			elseif collisionRep ~= cache[i+keyCollisionRep] then
				Log "collisionRep mismatch!"
				Log("%s vs %s", collisionRep, cache[i+keyCollisionRep])
			elseif physicsMask ~= cache[i+keyPhysicsMask] then
				Log "physicsMask mismatch!"
				Log("%s vs %s", bit.tohex(physicsMask), bit.tohex(cache[i+keyPhysicsMask]))
			elseif filter ~= cache[i+keyFilter] then
				Log "filter mismatch!"
				Log("%s vs %s", filter, cache[i+keyFilter])
			else
				Log "cache hit!"
				cache_hits = cache_hits + 1
				return cache[i+keyTrace]
			end
			--]=]
			--[=[
			if
			  collisionRep == cache[i+keyCollisionRep] and
			  physicsMask  == cache[i+keyPhysicsMask]  and
  			  filter       == cache[i+keyFilter] and
  			  diffunder(kAcceptance, start, cache[i+keyStartPoint]) and
  			  diffunder(kAcceptance, stop, cache[i+keyStopPoint])
			  then
				cache_hits = cache_hits + 1
				return cache[i+keyTrace]
			end
			--]=]
			i = i + kCacheElements
		end
		cache_misses = cache_misses + 1
	end

	local trace
	if filter then
		trace = old(start, stop, collisionRep, physicsMask, filter)
	else
		trace = old(start, stop, collisionRep, physicsMask)
	end

	set(last, Vector(start), Vector(stop), collisionRep, physicsMask, filter, trace)
	last = (last + kCacheElements) % (kCacheSize * kCacheElements)

	return trace
end

Event.Hook("Console_cache_stats", function()
	Log("Cache hits:   %s", cache_hits)
	Log("Cache misses: %s", cache_misses)
end)

clear()
