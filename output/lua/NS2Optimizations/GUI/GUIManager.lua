assert(Server == nil)

Script.Load("lua/UtilityShared.lua")
Script.Load("lua/GUIAssets.lua")
-- Check required because of material scripts.
if Client and Event then
    Script.Load("lua/menu/WindowManager.lua")
    Script.Load("lua/InputHandler.lua")
end
Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")


local GUI = GUI
local clock = os.clock

kGUILayerDebugText = 0
local kGUILayerDebugText = kGUILayerDebugText
kGUILayerDeathScreen = 1
local kGUILayerDeathScreen = kGUILayerDeathScreen
kGUILayerChat = 3
local kGUILayerChat = kGUILayerChat
kGUILayerPlayerNameTags = 4
local kGUILayerPlayerNameTags = kGUILayerPlayerNameTags
kGUILayerPlayerHUDBackground = 5
local kGUILayerPlayerHUDBackground = kGUILayerPlayerHUDBackground
kGUILayerPlayerHUD = 6
local kGUILayerPlayerHUD = kGUILayerPlayerHUD
kGUILayerPlayerHUDForeground1 = 7
local kGUILayerPlayerHUDForeground1 = kGUILayerPlayerHUDForeground1
kGUILayerPlayerHUDForeground2 = 8
local kGUILayerPlayerHUDForeground2 = kGUILayerPlayerHUDForeground2
kGUILayerPlayerHUDForeground3 = 9
local kGUILayerPlayerHUDForeground3 = kGUILayerPlayerHUDForeground3
kGUILayerPlayerHUDForeground4 = 10
local kGUILayerPlayerHUDForeground4 = kGUILayerPlayerHUDForeground4
kGUILayerCommanderAlerts = 11
local kGUILayerCommanderAlerts = kGUILayerCommanderAlerts
kGUILayerCommanderHUD = 12
local kGUILayerCommanderHUD = kGUILayerCommanderHUD
kGUILayerLocationText = 13
local kGUILayerLocationText = kGUILayerLocationText
kGUILayerMinimap = 14
local kGUILayerMinimap = kGUILayerMinimap
kGUILayerScoreboard = 15
local kGUILayerScoreboard = kGUILayerScoreboard
kGUILayerCountDown = 16
local kGUILayerCountDown = kGUILayerCountDown
kGUILayerTestEvents = 17
local kGUILayerTestEvents = kGUILayerTestEvents
kGUILayerMainMenuNews = 19
local kGUILayerMainMenuNews = kGUILayerMainMenuNews
kGUILayerMainMenu = 20
local kGUILayerMainMenu = kGUILayerMainMenu
kGUILayerMainMenuDialogs = 60
local kGUILayerMainMenuDialogs = kGUILayerMainMenuDialogs
kGUILayerTipVideos = 70
local kGUILayerTipVideos = kGUILayerTipVideos
kGUILayerOptionsTooltips = 100
local kGUILayerOptionsTooltips = kGUILayerOptionsTooltips

do
	local this_value_below_is_in_seconds
end
local kMaxUpdateTime = 0.004
local kUpdateInterval = 0.04

-- The Web layer must be much higher than the MainMenu layer
-- because the MainMenu layer inserts items above
-- kGUILayerMainMenu procedurally.
kGUILayerMainMenuWeb = 50
local kGUILayerMainMenuWeb = kGUILayerMainMenuWeb

GUIManager = {}
local gGUIManager = GUIManager
local scripts
local nextScriptUpdate
local script_to_class = {}
local single_script_inst = {}

do
	local scripts = {}
	Shared.GetMatchingFileNames("lua/*", true, scripts)
	for i = 1, #scripts do
		local script = scripts[i]:sub(5)
		local split = StringSplit(script, "/")
		script_to_class[script] = split[#split]
		Log("Found script %s with class %s at path %s!", script, split[#split], scripts[i])
		Script.Load(scripts[i])
	end
end

function GetGUIManager()
    return gGUIManager
end

function GUIManager.GetNumberScripts()
    return #scripts
end

local function CreateGUIScript(scriptName)
	local script = script_to_class[scriptName]()
	script:Initialize()
	script.updateInterval = script.updateInterval or kUpdateInterval
	script.lastUpdateTime = 0

	table.insert(scripts, script)
	return script
end

function GUIManager.CreateGUIScript(_, s)
	return CreateGUIScript(s)
end

-- Only ever create one of this named script.
-- Just return the already created one if it already exists.
function GUIManager.CreateGUIScriptSingle(_, scriptName)
	if single_script_inst[scriptName] then
		return single_script_inst[scriptName]
	else
		local script = CreateGUIScript(scriptName)
		single_script_inst[scriptName] = script
		return script
	end
end

local function DestroyGUIScript(script)
    if table.removevalue(scripts, script) then
        script:Uninitialize()
		return true
	else
		return false
	end
end

function GUIManager.DestroyGUIScript(_, s)
	return DestroyGUIScript(s)
end

-- Destroy a previously created single named script.
-- Nothing will happen if it hasn't been created yet.
function GUIManager.DestroyGUIScriptSingle(_, scriptName)
	return DestroyGUIScript(single_script_inst[scriptName])
end

function GUIManager.GetGUIScriptSingle(_, scriptName)
	return single_script_inst[scriptName]
end

function GUIManager.NotifyGUIItemDestroyed() end

local function PropagateEvent(action, ...)
	for i = 1, #scripts do
		local script = scripts[i]
		if script[action](script, ...) then
			return true
		end
	end

	return false
end

local function Update(deltaTime)
    PROFILE("GUIManager:Update")
    
	local numScripts = #scripts
    
    local now  = clock()
	local nowt = Shared.GetTime()
	for i = nextScriptUpdate, numScripts do
        local script = scripts[s]
		
		if nowt - script.lastUpdateTime > script.updateInterval then
			script:Update(deltaTime)
			if kMaxUpdateTime < clock() - now then
				nextScriptUpdate = (numScripts == i and 1 or i) + 1
				return
			end
		end
    end

	for i = 1, nextScriptUpdate-1 do
        local script = scripts[s]
		
		if nowt - script.lastUpdateTime > script.updateInterval then
			script:Update(deltaTime)
			if kMaxUpdateTime < clock() - now then
				nextScriptUpdate = i + 1
				return
			end
		end
	end
end

function GUIManager.SendKeyEvent(_, key, down, amount)
	return not Shared.GetIsRunningPrediction() and PropagateEvent("SendKeyEvent", key, down, amount)
end

function GUIManager.SendCharacterEvent(_, character)
	return PropagateEvent("SendCharacterEvent", character)
end

function OnResolutionChanged(_, oldX, oldY, newX, newY)
	PropagateEvent("OnResolutionChanged", oldX, oldY, newX, newY)
end

GUIManager.CreateGraphicITem = GUI.CreateItem

function GUIManager.CreateTextItem()
    local item = GUI.CreateItem()
    item:SetOptionFlag(GUIItem.ManageRender)
    return item
end 

GUIManager.CreateLinesItem = GUIManager.CreateTextItem

-- check required because of material scripts
if Event then
    Event.Hook("UpdateClient", OnUpdate, "GUIManager")
    Event.Hook("ResolutionChanged", OnResolutionChanged)
end
