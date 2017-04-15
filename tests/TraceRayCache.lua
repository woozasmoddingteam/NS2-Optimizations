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

--[=[
	Inspired by asm.js, but tobit is actually defined for fractions: it truncates it.
	Sad that it doesn't follow the specification.
]=]
local function tobit(n)
	return n
end
local max = math.max
local abs = math.abs
local band = bit.band
local origin = Vector(0, 0, 0)
local type = type
local abs = math.abs
local max = math.max
local inf = 1/0
assert(inf == inf)

local function diff(v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z - v2.z))
end

local kCacheSize      = 4
do
	local n = math.log(kCacheSize) / math.log(2)
	assert(n == math.floor(n), "kCacheSize has to be a power of two!")
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

local kAcceptance       = 0.1

local cache = table_new(kCacheSize*kCacheElements, 0)
local prev_time
local last = 0

local function set(i, start, stop, collisionRep, physicsMask, filter, trace)
	i = tobit(i)
	cache[i+keyStart]        = start
	cache[i+keyStop]         = stop
	cache[i+keyCollisionRep] = tobit(collisionRep)
	cache[i+keyPhysicsMask]  = tobit(physicsMask)
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

function Shared_GetTime()
	return 0
end

math.randomseed(os.clock())

local function old(a, b, c, d)
	return math.random(math.floor(a.x + b.x)) * math.random(math.ceil(a.y * b.y)) / math.random(math.ceil(a.z - b.z)) + c / d * math.random()
end

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

function TraceRay(start, stop, collisionRep, physicsMask, filter)
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
		---[==[
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

for i = 1, 1000 do
	local t = TraceRay(Vector(2, 2, 2), Vector(3, 3, 3), 2)
end

print(cache_hits)
print(cache_misses)
