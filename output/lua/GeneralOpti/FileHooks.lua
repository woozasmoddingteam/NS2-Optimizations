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

if Shared then
	Script.Load("lua/GeneralOpti/TraceRayCache.lua")
	Script.Load("lua/GeneralOpti/TraceCapsuleCache.lua")
	Script.Load("lua/GeneralOpti/TraceBoxCache.lua")
end

Script.Load("lua/GeneralOpti/Utility.lua")
