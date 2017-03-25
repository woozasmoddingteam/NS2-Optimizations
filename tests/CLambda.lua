dofile "../output/lua/GeneralOpti/Closure.lua"

local clock = os.clock

local function user(f)
	return f(22)
end

local t1 = clock()
local n = 0

for i = 1, 2^24 do
    local f = CLambda [=[args; self[1]]=] {1}
	n = n + user(f)
end

print(clock() - t1)
