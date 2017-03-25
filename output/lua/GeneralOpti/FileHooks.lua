(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

ModLoader.SetupFileHook("lua/Table.lua", "lua/GeneralOpti/Table.lua", "post")
ModLoader.SetupFileHook("lua/Entity.lua", "lua/GeneralOpti/Entity.lua", "post")
ModLoader.SetupFileHook("lua/Player.lua", "lua/GeneralOpti/Player.lua", "post")

Script.Load("lua/GeneralOpti/Trace.lua")

Log "Adding test function!"
if Server then
	local function Test(client)
		local player = client:GetControllingPlayer()
		local clock = os.clock
		local arg1, arg2, arg3, arg4 =
			player:GetEyePos(),
			player:GetViewCoords().zAxis * 100 + player:GetEyePos(),
			CollisionRep.Default,
			function(ent) end
		local t1 = clock()
		for i = 1, 2^16 do
			local trace = Shared.TraceRay(arg1, arg2, arg3, arg4)
		end
		local t2 = clock()
		for i = 1, 2^16 do
			local trace = BetterTraceRay(arg1, arg2, arg3, arg4)
		end
		local t3 = clock()
		Log("Ordinary: %s", t2-t1)
		Log("Caching:  %s", t3-t2)
	end
	Event.Hook("Console_testray", Test)
end
