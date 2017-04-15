
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
local keyInvRadius      = 6
local keyInvHeight      = 7

local kAcceptance       = 0.1
local kScalarAcceptance = 0.2

function SetTraceCapsuleOptions(abs, rel)
	Log("Setting acceptance for capsule to: %s, %s", abs, rel)
	kAcceptance, kScalarAcceptance = tonumber(abs), tonumber(rel)
end

function GetTraceCapsuleOptions()
	return kAcceptance, kScalarAcceptance
end

local cache = table_new(kCacheSize*kCacheElements, 0)
local prev_time
local last = 0

local function set(i, start, stop, inv_radius, inv_height, collisionRep, physicsMask, filter, trace)
	--[=[
	assert(start:isa "Vector")
	assert(stop:isa "Vector")
	assert(type(inv_radius) == "number")
	assert(type(inv_height) == "number")
	assert(type(collisionRep) == "number")
	assert(type(physicsMask) == "number")
	assert(type(filter) == "function" or filter == nil)
	assert(trace == nil or type(trace) == "cdata")
	--]=]
	cache[i+keyStart]        = start
	cache[i+keyStop]         = stop
	cache[i+keyInvRadius]    = inv_radius
	cache[i+keyInvHeight]    = inv_height
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
		set(i, origin, origin, 0, 0, 0, 0)
		i = i + kCacheElements
	end
end

function Shared_GetTime()
	return 0
end

local cache_hits   = 0
local cache_misses = 0
local caching_enabled = true

local function old(a, b, c, d)
	return math.random(math.floor(a.x + b.x)) * math.random(math.ceil(a.y * b.y)) / math.random(math.ceil(a.z - b.z)) + c / d * math.random()
end

function TraceCapsule(start, stop, radius, height, collisionRep, physicsMask, filter)
	physicsMask = physicsMask or 0xFFFFFFFF

	if caching_enabled then
		if Shared_GetTime() ~= prev_time then
			clear()
		else
			local i = 0
			::loop::
			if --[=[ Cheapest operations ]=]
			  collisionRep == cache[i+keyCollisionRep] and
			  physicsMask  == cache[i+keyPhysicsMask] and
  			  filter       == cache[i+keyFilter] and
			  diff(start, cache[i+keyStart]) < kAcceptance and
			  diff(stop, cache[i+keyStop]) < kAcceptance
			  then
				goto slow_path --[=[ Ignoring a jump is cheaper than taking one. 1/kCacheSize cache entries will match.]=]
			end
			::loop_step::
			i = i + kCacheElements
			if i >= kCacheSize*kCacheElements then
				goto cache_miss
			end
			goto loop

			::slow_path::
			if
			  near(radius, cache[i+keyInvRadius], kScalarAcceptance) and
			  near(height, cache[i+keyInvHeight], kScalarAcceptance)
			  then
				cache_hits = cache_hits + 1
				return cache[i+keyTrace]
			end

			goto loop_step
		end

		::cache_miss::
		cache_misses = cache_misses + 1
	end

	local trace
	if filter then
		trace = old(start, stop, radius, height, collisionRep, physicsMask, filter)
	else
		trace = old(start, stop, radius, height, collisionRep, physicsMask)
	end

	if caching_enabled then
		set(last, Vector(start), Vector(stop), 1/radius, 1/height, collisionRep, physicsMask, filter, trace)
		last = band(last + kCacheElements, kCacheSize * kCacheElements - 1)
	end

	return trace
end

function TraceCapsuleCacheStats()
	return cache_hits, cache_misses
end

clear()

for i = 1, 1000 do
	local t = TraceCapsule(Vector(2, 2, 2), Vector(3, 3, 3), 2, 5, 19)
end

print(cache_hits)
print(cache_misses)
