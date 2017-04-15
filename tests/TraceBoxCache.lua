local ffi = require "ffi"
local Vector
Vector = ffi.metatype([[struct {
	double x;
	double y;
	double z;
}]], {
	__add = function(l, r)
		return Vector(l.x + r.x, l.y + r.y, l.z + r.z)
	end,
	__sub = function(l, r)
		return Vector(l.x - r.x, l.y - r.y, l.z - r.z)
	end,
})

local table_new = require "table.new"
local max = math.max
local abs = math.abs
local band = bit.band
--[=[
	Inspired by asm.js, but tobit is actually defined for fractions: it truncates it.
	Sad that it doesn't follow the specification.
]=]
local function tobit(n)
	return n
end
local type = type
local Vector = Vector
local origin = Vector(0, 0, 0)
local inf = 1/0
assert(inf == inf)

local function diff(v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z - v2.z))
end

local function near(a, inv_b, limit)
	return
		a == 0 and
		inv_b == inf
		or
		a * inv_b >= (1 / (1 + limit)) and
		a * inv_b <= (1 + limit)
end

local kCacheSize        = 4
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

local kAcceptance       = 0.1

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

function Shared_GetTime()
	return 0
end

math.randomseed(os.clock())

local function old(x, a, b, c, d)
	return x.x / math.random(math.floor(a.x + b.x)) * math.random(math.ceil(a.y * b.y)) / math.random(math.ceil(a.z - b.z)) + c / d * math.random() * x.y - x.z
end

local cache_hits   = 0
local cache_misses = 0
local caching_enabled = true

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

function TraceBox(extents, start, stop, collisionRep, physicsMask, filter)
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

for i = 1, 1000 do
	local t = TraceBox(Vector(5, 5, 5), Vector(2, 2, 2), Vector(3, 3, 3), 2)
end

print(cache_hits)
print(cache_misses)
