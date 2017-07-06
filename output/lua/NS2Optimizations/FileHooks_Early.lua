function GenerateIntegers(n)
	local t = {}
	for i = 1, n do
		t[i] = i-1
	end
	return unpack(t)
end

function setupvalue(f, n, v)
	local i = 1
	while assert(debug.getupvalue(f, i)) ~= n do
		i = i + 1
	end
	debug.setupvalue(f, i, v)
end

function getupvalue(f, n)
	local i = 1
	while assert(debug.getupvalue(f, i)) ~= n do
		i = i + 1
	end
	local _, v = debug.getupvalue(f, i)
	return v
end

local meta = {__mode = "kv"}
function WkvTable(t)
	return setmetatable(t, meta)
end

local meta = {__mode = "k"}
function WkTable(t)
	return setmetatable(t, meta)
end

local meta = {__mode = "v"}
function WvTable(t)
	return setmetatable(t, meta)
end

Script.Load "lua/NS2Optimizations/DynArray.lua"

ModLoader.SetupFileHook("lua/TechData.lua", "lua/NS2Optimizations/Tech/TechData_Early.lua", "post")
