dofile "../output/lua/NS2Optimizations/Closure.lua"

local clock = os.clock

local function user(f)
	return f(22)
end

local t1 = clock()
local n = 0

for i = 1, 2^24 do
   local f = CLambda [=[
		CLambda [[...]] {} (...)
	]=] {}
	n = n + user(f)
end

print(n)
print(clock() - t1)
