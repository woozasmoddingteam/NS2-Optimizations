Script.Load("lua/NS2Optimizations/CacheUtility.lua")

local table_new = require "table.new"
local max = math.max
local abs = math.abs
local band = bit.band
local origin = Vector.origin
local type = type
local Shared_GetTime = Shared.GetTime
local Vector = Vector

local diff = CacheUtility.VectorDiff

local kCacheSize      = kNS2OptiConfig.TraceCacheSize.Ray
if kCacheSize == 0 then
	return
end
local kCacheElements  = 8
local keyStart        = 0
local keyStop         = 1
local keyCollisionRep = 2
local keyPhysicsMask  = 3
local keyFilter       = 4
local keyTrace        = 5
local kAcceptance     = 0.3

local cache = table_new(kCacheSize*kCacheElements, 0)
--[=[
local cache = setmetatable({}, {
	__index = _cache,
	__newindex = function(self, key, value)
		if band(key, 0x7) == keyStart then
			Log("Trace assigned to keyStart: %s", value)
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
	assert(start:isa "Vector")
	assert(stop:isa "Vector")
	assert(type(collisionRep) == "number")
	assert(type(physicsMask) == "number")
	assert(type(filter) == "function" or filter == nil)
	assert(trace == nil or type(trace) == "cdata")
	--]=]
	cache[i+keyStart]   = start
	cache[i+keyStop]    = stop
	cache[i+keyCollisionRep] = collisionRep
	cache[i+keyPhysicsMask]  = physicsMask
	cache[i+keyFilter]       = filter
	cache[i+keyTrace]        = trace
end

local function clear()
	prev_time = Shared_GetTime()
	last = 0
	local i = 0
	while i < kCacheSize * kCacheElements do
		set(i, origin, origin, 0, 0)
		i = i + kCacheElements
	end
end

local old = Shared.TraceRay

local cache_hits   = 0
local cache_misses = 0
local caching_enabled = true

function Shared.TraceRay(start, stop, collisionRep, physicsMask, filter)
	if type(physicsMask) ~= "number" then
		filter = physicsMask
		physicsMask = 0xFFFFFFFF
	end

	if caching_enabled then
		if Shared_GetTime() ~= prev_time then
			clear()
		else
			local i = 0
			while i < kCacheSize*kCacheElements do
				if
				  collisionRep == cache[i+keyCollisionRep] and
				  physicsMask  == cache[i+keyPhysicsMask]  and
	  			  filter       == cache[i+keyFilter] and
	  			  diff(start, cache[i+keyStart]) < kAcceptance and
	  			  diff(stop, cache[i+keyStop]) < kAcceptance
				  then
					cache_hits = cache_hits + 1
					return cache[i+keyTrace]
				end
				i = i + kCacheElements
			end
		end
		cache_misses = cache_misses + 1
	end

	local trace
	if filter then
		trace = old(start, stop, collisionRep, physicsMask, filter)
	else
		trace = old(start, stop, collisionRep, physicsMask)
	end

	if caching_enabled then
		set(last, Vector(start), Vector(stop), collisionRep, physicsMask, filter, trace)
		last = (last + kCacheElements) % (kCacheSize * kCacheElements)
	end

	return trace
end

Event.Hook("Console_ray_cache_stats", function()
	Log("Ray Cache hits:   %s", cache_hits)
	Log("Ray Cache misses: %s", cache_misses)
	Log("Ray Cache hit percentage: %s", cache_hits / (cache_hits + cache_misses))
end)

--[=[
Event.Hook("Console_toggle_tracer", function()
	caching_enabled = not caching_enabled
	Log("Caching is now %s", caching_enabled and "on!" or "off.")
end)
--]=]

clear()
