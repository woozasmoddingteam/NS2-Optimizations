dofile "../output/lua/NS2Optimizations/Closure.lua"

local clock = os.clock

local function user(f)
	return f(22)
end

local s = "self a b; a + b"
local f1 = SLambda(s) (1, 2)
local t1 = clock()
local n = 0

for i = 1, 2^24 do
	local f2 = SLambda(s) (1, 2)
	assert(f2 == f1)
	n = n + user(f2)
end

print(clock() - t1)
