(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

local default_config = Server and {
	TraceCaching = true,
	TraceCacheSize = {
		Ray     = 64,
		Box     = 32,
		Capsule = 32
	},
	InfinitePlayerRelevancy = false,
	TableOptimisations = false,
	FastMixin = true
} or {
	TraceCaching = true,
	TraceCacheSize = {
		Ray     = 16,
		Box     = 8,
		Capsule = 8,
	}
	TableOptimisations = false,
	FastMixin = true
}

local config = LoadConfigFile(Server and "NS2OptiServer.json" or "NS2OptiClient", default_config)

---[=[
if config.TableOptimisations then
	ModLoader.SetupFileHook("lua/Table.lua", "lua/GeneralOpti/Table.lua", "post")
end
ModLoader.SetupFileHook("lua/Entity.lua", "lua/GeneralOpti/Entity.lua", "post")
if config.InfinitePlayerRelevancy then
	ModLoader.SetupFileHook("lua/Player.lua", "lua/GeneralOpti/Player.lua", "post")
end

if Shared and config.TraceCaching then
	kTraceCachingConfig = config.TraceCacheSize
	Script.Load("lua/GeneralOpti/TraceRayCache.lua")
	Script.Load("lua/GeneralOpti/TraceCapsuleCache.lua")
	Script.Load("lua/GeneralOpti/TraceBoxCache.lua")
end

Script.Load("lua/GeneralOpti/Utility.lua")
--]=]
