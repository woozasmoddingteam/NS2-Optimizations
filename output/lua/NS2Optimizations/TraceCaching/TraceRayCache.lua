Script.Load("lua/NS2Optimizations/TraceCaching/CacheUtility.lua")

local table_new = require "table.new"
local max = math.max
local abs = math.abs
local band = bit.band
local origin = Vector.origin
local type = type
local Shared_GetTime = Shared.GetTime
local Vector = Vector
local function tobit(n)
	return n
end

local diff = CacheUtility.VectorDiff

local kCacheSize      = kNS2OptiConfig.TraceCacheSize.Ray
do
	local n = math.log(kCacheSize) / math.log(2)
	if n ~= math.floor(n) then
		Shared.Message "kCacheSize has to be a power of two!"
		return
	end
end
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

local kAcceptance       = kNS2OptiConfig.TraceAcceptance.Ray.Absolute

function SetTraceRayOptions(abs)
	Log("Setting acceptance for ray to: %s", abs)
	kAcceptance = tonumber(abs)
end

function GetTraceRayOptions()
	return kAcceptance
end

local cache = table_new(kCacheSize*kCacheElements, 0)
local prev_time
local last = 0

local function set(i, start, stop, collisionRep, physicsMask, filter, trace)
	cache[i+keyStart]        = start
	cache[i+keyStop]         = stop
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
Shared.OriginalTraceRay = old

local cache_hits   = 0
local cache_misses = 0
local caching_enabled = true

local function checkMatch(i, start, stop, collisionRep, physicsMask, filter)
	i = tobit(i)
	return
		tobit(collisionRep) == tobit(cache[i+keyCollisionRep]) and
		tobit(physicsMask)  == tobit(cache[i+keyPhysicsMask])  and
		filter              == cache[i+keyFilter]       and
		diff(start, cache[i+keyStart]) < kAcceptance and
		diff(stop, cache[i+keyStop])   < kAcceptance
end

function Shared.TraceRay(start, stop, collisionRep, physicsMask, filter)
	if type(physicsMask) ~= "number" then
		filter = physicsMask
		physicsMask = 0xFFFFFFFF
	end

	physicsMask = tobit(physicsMask)
	collisionRep = tobit(collisionRep)

	if caching_enabled then
		if Shared_GetTime() ~= prev_time then
			clear()
			goto new_trace
		end
		local i = 0
		::loop::
		if checkMatch(i, start, stop, collisionRep, physicsMask, filter) then
			cache_hits = tobit(cache_hits) + 1
			return cache[i+keyTrace]
		end
		i = i + kCacheElements
		if i < kCacheSize*kCacheElements then
			goto new_trace
		end
		goto loop
	end

	::new_trace::
	if caching_enabled then
		cache_misses = tobit(cache_misses) + 1
	end

	local trace
	if filter then
		trace = old(start, stop, collisionRep, physicsMask, filter)
	else
		trace = old(start, stop, collisionRep, physicsMask)
	end

	if caching_enabled then
		last = tobit(last)

		set(last, start, stop, collisionRep, physicsMask, filter, trace)

		last = band(last + kCacheElements, kCacheSize * kCacheElements - 1)
	end

	return trace
end

function TraceRayCacheStats()
	return cache_hits, cache_misses
end

clear()
