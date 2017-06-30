function GenerateIntegers(n)
	local t = {}
	for i = 1, n do
		t[i] = i-1
	end
	return unpack(t)
end

ModLoader.SetupFileHook("lua/TechData.lua", "lua/NS2Optimizations/Tech/TechData_Early.lua", "post")
