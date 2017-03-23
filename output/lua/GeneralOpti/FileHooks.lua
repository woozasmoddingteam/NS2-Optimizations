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
ModLoader.SetupFileHook("lua/Utility.lua", "lua/GeneralOpti/Utility.lua", "post")

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
		local time1 = clock()
		for i = 1, 2^15 do
			local trace = Shared.TraceRay(arg1, arg2, arg3, arg4)
		end
		local time2 = clock()
		for i = 1, 2^15 do
			local trace = Shared.TraceRay(arg1, arg2, arg3)
		end
		local time3 = clock()
		Log("Total: %s", time2-time1)
		Log("Better: %s", time3-time2)
	end
	Event.Hook("Console_testents", Test)
end
