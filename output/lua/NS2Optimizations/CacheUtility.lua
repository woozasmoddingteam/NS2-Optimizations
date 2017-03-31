
local abs = math.abs
local max = math.max
local inf = 1/0
assert(inf == inf)

CacheUtility = {}

function CacheUtility.VectorDiff(v1, v2)
	return max(abs(v1.x - v2.x), abs(v1.y - v2.y), abs(v1.z - v2.z))
end

function CacheUtility.ScalarNear(a, inv_b, limit)
	return
		a == 0 and
		inv_b == inf
		or
		a * inv_b >= (1 / (1 + limit)) and
		a * inv_b <= (1 + limit)
end
