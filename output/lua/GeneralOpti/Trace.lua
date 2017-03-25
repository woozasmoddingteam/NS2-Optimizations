
local table_new = require "table.new"
local max = math.max
local abs = math.abs
local origin = Vector.origin
local type = type
local Shared_GetTime = Shared.GetTime

local function diffunder(limit, v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z, v2.z)) < limit
end

local kCacheSize = 20
local kCacheElements = 8
local keyStartPoint   = 0
local keyStopPoint    = 1
local keyCollisionRep = 2
local keyPhysicsMask  = 3
local keyFilter       = 4
local keyTrace        = 5
local kAcceptance = Vector(0.1, 0.1, 0.1)

local cache = table_new(kCacheSize*kCacheElements, 0)
local prev_time
local last = 0

local function set(i, start, stop, collisionRep, physicsMask, filter, trace)
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

function BetterTraceRay(start, stop, collisionRep, physicsMask, filter)
	if type(physicsMask) ~= "number" then -- Unsupported
		filter = physicsMask
		physicsMask = 0xFFFFFFFF
	end

	if Shared_GetTime() ~= prev_time then
		table_clear(cache)
	else
		local i = 0
		while i < kCacheSize*kCacheElements do
			if
			  collisionRep == cache[i+keyCollisionRep]   and
			  physicsMask  == cache[i+keyPhysicsMask]    and
			  filter       == cache[i+keyFilter]         and
			  diffunder(kAcceptance, start, cache[i+keyStartPoint]) and
			  diffunder(kAcceptance, stop, cache[i+keyStopPoint])
			  then
				return cache[i+keyTrace]
			end
			i = i + kCacheElements
		end
	end

	local trace
	if filter then
		trace = old(start, stop, collisionRep, physicsMask, filter)
	else
		trace = old(start, stop, collisionRep, physicsMask)
	end

	set(last, start, stop, collisionRep, physicsMask, filter, trace)
	last = (last + 1) % kCacheSize
	return trace
end

clear()
