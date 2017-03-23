
local table_new = require "table.new"
local max = math.max
local abs = math.abs
local origin = Vector.origin
local function allocate(n)
	return table_new(n+1, 0)
end

local kCacheSize = 20
local kAcceptance = Vector(0.1, 0.1, 0.1)

local cache = allocate(kCacheSize)
local prev_time = 0;

local function clear()
	prev_time = Shared.GetTime()
	cache = allocate(kCacheSize*4)
	cache[0] = 1 -- The zeroeth index points to the oldest value
	for i = 1, #kCacheSize*4, 4 do
		cache[i]   = Vector.origin -- startPoint
		cache[i+1] = Vector.origin -- endPoint
		cache[i+2] = 0             -- collisionRep
	end
end

local function diffover(limit, v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z, v2.z)) > limit
end

local old = Shared.TraceRay

function BetterTraceRay(start, stop, arg3, arg4, arg5)
	if arg4 then -- Unsupported
		if arg5 then
			return old(start, stop, arg3, arg4, arg5)
		else
			return old(start, stop, arg3, arg4)
		end
	end

	for i = 1, #kCacheSize*4, 4 do
		local startdiff = start-cache[i]
		if
		  arg3 == cache[i+2]
		  and not diffover(kAcceptance, start, cache[i])
		  and not diffover(kAcceptance, stop, cache[i+1])
		  then
			return cache[i+3]
		end
	end
	local trace = old(start, stop, arg3)
	local new = cache[0]
	cache[new]   = start
	cache[new+1] = stop
	cache[new+2] = arg3
	cache[new+3] = trace
	return trace
end
