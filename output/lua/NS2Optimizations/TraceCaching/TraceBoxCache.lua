Script.Load("lua/NS2Optimizations/CacheUtility.lua")

local table_new = require "table.new"
local max = math.max
local abs = math.abs
local band = bit.band
local type = type
local Shared_GetTime = Shared.GetTime
local inf = math.huge
local Vector = Vector
local origin = Vector.origin
local function tobit(n)
	return n
end

local diff = CacheUtility.VectorDiff
local near = CacheUtility.ScalarNear

local kCacheSize        = kNS2OptiConfig.TraceCacheSize.Box
do
	local n = math.log(kCacheSize) / math.log(2)
	assert(n == math.floor(n), "kCacheSize has to be a power of two!")
end
if kCacheSize == 0 then
	return
end
local kCacheElements    = 8
local keyStart          = 0
local keyStop           = 1
local keyCollisionRep   = 2
local keyPhysicsMask    = 3
local keyFilter         = 4
local keyTrace          = 5
local keyExtents        = 6

local kAcceptance       = kNS2OptiConfig.TraceAcceptance.Box.Absolute

function SetTraceBoxOptions(abs)
	Log("Setting acceptance for box to: %s", abs)
	kAcceptance = tonumber(abs)
end

function GetTraceBoxOptions()
	return kAcceptance
end

local cache = table_new(kCacheSize*kCacheElements, 0)
local prev_time
local last = 0

local function set(i, extents, start, stop, collisionRep, physicsMask, filter, trace)
	--[=[
	assert(extents:isa "Vector")
	assert(start:isa "Vector")
	assert(stop:isa "Vector")
	assert(type(collisionRep) == "number")
	assert(type(physicsMask) == "number")
	assert(type(filter) == "function" or filter == nil)
	assert(trace == nil or type(trace) == "cdata")
	--]=]
	cache[i+keyStart]        = start
	cache[i+keyStop]         = stop
	cache[i+keyCollisionRep] = collisionRep
	cache[i+keyPhysicsMask]  = physicsMask
	cache[i+keyFilter]       = filter
	cache[i+keyTrace]        = trace
	cache[i+keyExtents] = extents
end

local function clear()
	prev_time = Shared_GetTime()
	last = 0
	local i = 0
	while i < kCacheSize * kCacheElements do
		set(i, origin, origin, origin, 0, 0)
		i = i + kCacheElements
	end
end

local function checkMatch(i, extents, start, stop, collisionRep, physicsMask, filter)
	i = tobit(i)
	return
		tobit(collisionRep) == tobit(cache[i+keyCollisionRep]) and
		tobit(physicsMask)  == tobit(cache[i+keyPhysicsMask])  and
		filter              == cache[i+keyFilter]       and
		diff(extents, cache[i+keyExtents]) < kAcceptance and
		diff(start, cache[i+keyStart])     < kAcceptance and
		diff(stop, cache[i+keyStop])       < kAcceptance
end
local old = Shared.TraceBox

local cache_hits   = 0
local cache_misses = 0
local caching_enabled = true

function Shared.TraceBox(extents, start, stop, collisionRep, physicsMask, filter)
	physicsMask = physicsMask or 0xFFFFFFFF

	if caching_enabled then
		if Shared_GetTime() ~= prev_time then
			clear()
			goto new_trace
		end
		local i = 0
		---[==[
		::loop::
		if checkMatch(i, extents, start, stop, collisionRep, physicsMask, filter) then
			cache_hits = cache_hits + 1
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
		cache_misses = cache_misses + 1
	end

	local trace
	if filter then
		trace = old(extents, start, stop, collisionRep, physicsMask, filter)
	else
		trace = old(extents, start, stop, collisionRep, physicsMask)
	end

	if caching_enabled then
		set(last, Vector(extents), Vector(start), Vector(stop), collisionRep, physicsMask, filter, trace)
		last = band(last + kCacheElements, kCacheSize * kCacheElements - 1)
	end

	return trace
end

function TraceBoxCacheStats()
	return cache_hits, cache_misses
end

clear()
