(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

kRelevantToAll = 0x8000000
Script.Load "lua/NS2Optimizations/Table.lua"
Script.Load "lua/NS2Optimizations/Utility.lua"
Script.Load "lua/NS2Optimizations/FastMixin.lua"

if Shared then
	Script.Load "lua/NS2Optimizations/TraceRayCache.lua"
	Script.Load "lua/NS2Optimizations/TraceCapsuleCache.lua"
	Script.Load "lua/NS2Optimizations/TraceBoxCache.lua"
end

ModLoader.SetupFileHook("lua/Mixins/BaseModelMixin.lua", "lua/NS2Optimizations/BaseModelMixin.lua", "post")
ModLoader.SetupFileHook("lua/ScoringMixin.lua", "lua/NS2Optimizations/ScoringMixin.lua", "post")
ModLoader.SetupFileHook("lua/Entity.lua", "lua/NS2Optimizations/Entity.lua", "post")

ModLoader.SetupFileHook("lua/Observatory.lua",              "lua/NS2Optimizations/Observatory.lua", "post")
ModLoader.SetupFileHook("lua/BalanceMisc.lua",              "lua/NS2Optimizations/BalanceMisc.lua", "post")

if Server then
	ModLoader.SetupFileHook("lua/LOSMixin.lua",              "lua/NS2Optimizations/LOSMixin_Server.lua", "post")
	ModLoader.SetupFileHook("lua/Gamerules.lua",             "lua/NS2Optimizations/Gamerules_Server.lua", "post")
	ModLoader.SetupFileHook("lua/Player.lua",                "lua/NS2Optimizations/Player_Server.lua", "post")
end

ModLoader.SetupFileHook("lua/MixinUtility.lua", "lua/NS2Optimizations/MixinUtility.lua", "replace")
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", "", "halt")
