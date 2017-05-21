dofile "../output/lua/NS2Optimizations/Table.lua"

local dump = require "jit.dump"

local clock = os.clock

-- Fill table
local t = {}
for i = 1, 2^24 do
	t[i] = math.random(2^31)
end

dump.on()

local acc    = 0
local time_1 = clock()
for i = 1, 2^24-5 do
	local a, b, c, d, e, f = unpack(t, i, i+5)
	acc = acc + a + b + c + d + e + f
end
local time_2 = clock()
print(acc)
local acc    = 0
for i = 1, 2^24-5 do
	local a, b, c, d, e, f = oldunpack(t, i, i+5)
	acc = acc + a + b + c + d + e + f
end
local time_3 = clock()
dump.off()
print(acc)
print("Time with unpack:    " .. time_2 - time_1)
print("Time with oldunpack: " .. time_3 - time_2)
