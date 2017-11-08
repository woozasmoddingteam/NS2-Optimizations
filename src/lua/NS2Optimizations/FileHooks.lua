(not Predict and Shared.Message or function() end) [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

Script.Load("lua/NS2Optimizations/Closures/Closure.lua")

local kVersion = 6

local default_config = Server and {
	InfinitePlayerRelevancy   = false,
	FastMixin = true,
	__Version = kVersion
} or {
	FastMixin = true,
	SaneMinimap = true,
	__Version = kVersion
}

local function sanitize(a, b)
	local changed = false
	for k in pairs(b) do
		if type(a[k]) ~= type(b[k]) then
			a[k] = b[k]
			changed = true
		elseif type(b[k]) == "table" then
			changed = changed or sanitize(a[k], b[k])
		end
	end
	for k in pairs(a) do
		if b[k] == nil and a[k] ~= nil then
			a[k] = nil
			changed = true
		end
	end
	return changed
end

local kConfigFile = Server and "NS2OptiServer.json" or "NS2OptiClient.json"
kNS2OptiConfig = LoadConfigFile(kConfigFile, default_config)
if kNS2OptiConfig.__Version ~= kVersion then
	Shared.Message [[
---------------------------------------------------------
NS2 Optimizations has been updated!
Please adjust your configuration values accordingly.
---------------------------------------------------------
]]
end
kNS2OptiConfig.__Version = kVersion
if sanitize(kNS2OptiConfig, default_config) then
	Shared.Message [[
--------------------------------------------------------------
Your NS2 Optimizations configuration file has been sanitized!
This means stray keys have been removed, and missing defaults
have been added.
--------------------------------------------------------------
]]
	SaveConfigFile(kConfigFile, kNS2OptiConfig)
end

Script.Load "lua/NS2Optimizations/Closures/Utility.lua"
ModLoader.SetupFileHook("lua/Entity.lua", "lua/NS2Optimizations/Closures/Entity.lua", "post")

Script.Load "lua/NS2Optimizations/FastMixin/init.lua"
ModLoader.SetupFileHook("lua/MixinUtility.lua",           "lua/NS2Optimizations/FastMixin/MixinUtility.lua",   "replace")
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", true,                                                 "halt")

do -- Smart Relevancy
	ModLoader.SetupFileHook("lua/Observatory.lua",              "lua/NS2Optimizations/SmartRelevancy/Observatory.lua", "post")
	--ModLoader.SetupFileHook("lua/BalanceMisc.lua",              "lua/NS2Optimizations/SmartRelevancy/BalanceMisc.lua", "post")
	if Server then
		ModLoader.SetupFileHook("lua/Gamerules.lua", "lua/NS2Optimizations/SmartRelevancy/Gamerules_Server.lua", "post")
		ModLoader.SetupFileHook("lua/Player.lua",    "lua/NS2Optimizations/SmartRelevancy/Player_Server.lua",    "post")
	end
end

ModLoader.SetupFileHook("lua/TechTreeConstants.lua", "lua/NS2Optimizations/Tech/TechTreeConstants.lua", "post")
ModLoader.SetupFileHook("lua/GameInfo.lua",          "lua/NS2Optimizations/Tech/GameInfo.lua",          "post")

for _, v in ipairs {
	"GUIManager",
	--"GUIMinimapFrame",
	--"MapBlip",
	--"MapBlipMixin",
	--"MapConnector",
	--"MinimapConnectionMixin",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/NS2Optimizations/GUIRework/"..v..".lua", "replace")
end
for _, v in ipairs {
	--"GUIUtility",
	"GUIScript",
	"GUIChat",
	--"TunnelEntrance",
	--"Tunnel",
	--"TunnelUserMixin",
	--"PhaseGate",
	--"Globals",
	--"GUIMinimapConnection",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/NS2Optimizations/GUIRework/"..v..".lua", "post")
end
--ModLoader.SetupFileHook("lua/NS2Plus/GUIScripts/GUIMinimap.lua", true, "halt")
ModLoader.SetupFileHook("lua/NS2Plus/Client/CHUDGUI_EndStats.lua", "lua/NS2Optimizations/GUIRework/CHUDGUI_EndStats.lua", "post")

ModLoader.SetupFileHook("lua/Mixins/ControllerMixin.lua", "lua/NS2Optimizations/NYIRemoval/ControllerMixin.lua", "post")
