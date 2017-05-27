
Script.Load("lua/UtilityShared.lua")
Script.Load("lua/GUIAssets.lua")
-- Check required because of material scripts.
if Client and Event then
    Script.Load("lua/menu/WindowManager.lua")
    Script.Load("lua/InputHandler.lua")
end
Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")

local
	push,
	pop,
	clock,
	GUI,
	Shared,
	Client =
	table.insert,
	table.remove,
	clock,
	GUI,
	Shared,
	Client

kGUILayerDebugText            = 0
kGUILayerDeathScreen          = 1
kGUILayerChat                 = 3
kGUILayerPlayerNameTags       = 4
kGUILayerPlayerHUDBackground  = 5
kGUILayerPlayerHUD            = 6
kGUILayerPlayerHUDForeground1 = 7
kGUILayerPlayerHUDForeground2 = 8
kGUILayerPlayerHUDForeground3 = 9
kGUILayerPlayerHUDForeground4 = 10
kGUILayerCommanderAlerts      = 11
kGUILayerCommanderHUD         = 12
kGUILayerLocationText         = 13
kGUILayerMinimap              = 14
kGUILayerScoreboard           = 15
kGUILayerCountDown            = 16
kGUILayerTestEvents           = 17
kGUILayerMainMenuNews         = 19
kGUILayerMainMenu             = 20
kGUILayerMainMenuWeb          = 50
kGUILayerMainMenuDialogs      = 60
kGUILayerTipVideos            = 70
kGUILayerOptionsTooltips      = 100

-- Seconds
local kMaxUpdateTime = 0.002 -- If the update time of GUIManager exceeds this value, it will stop updating and wait for the next tick.
local kUpdateInterval = 0.04

local GUIManager = {}
_G.GUIManager = GUIManager

local nextScript

local scripts            = {}
local path_to_script     = {}
local single_script_inst = {}

do
	local files = {}
	Shared.GetMatchingFileNames("lua/*", true, files)
	for i = 1, #files do
		local file = scripts[i]:sub(5)
		local split = string.split(file, "/")
		path_to_script[file] = split[#split]
		Log("Found script %s with class %s at path %s!", file, split[#split], files[i])
	end
end

function GetGUIManager()
	return GUIManager
end

local function link(m, f)
	GUIManager[m] = function(self, ...)
		return f(...)
	end
end

local function CreateGUIScript(path)
	local script = path_to_script[path]()
	script:Initialize()
	script.updateInterval = script.updateInterval or kUpdateInterval
	script.lastUpdateTime = 0

	push(scripts, script)
	return script
end

link("CreateGUIScript", CreateGUIScript)

function GUIManager:CreateGUIScriptSingle(path)
	if single_script_inst[path] ~= nil then
		return single_script_inst[path]
	else
		local script = CreateGUIScript(path)
		single_script_inst[path] = script
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

link("DestroyGUIScript", DestroyGUIScript)

function GUIManager:DestroyGUIScriptSingle(path)
	return DestroyGUIScript(single_script_inst[path])
end

function GUIManager:GetGUIScriptSingle(path)
	return single_script_inst[path]
end

function GUIManager.NotifyGUIItemDestroyed() end

local function Update(deltaTime)
    PROFILE("GUIManager:Update")
    
	local numScripts = #scripts
    
    local now  = clock()
	local nowt = Shared.GetTime() -- nowt(ick)
	for i = nextScript, numScripts do
        local script = scripts[s]
		
		if nowt - script.lastUpdateTime > script.updateInterval then
			script.lastUpdateTime = nowt
			script:Update(deltaTime)
			-- Spent too much time updating
			if kMaxUpdateTime < clock() - now then
				nextScript = (numScripts == i and 1 or i) + 1
				return
			end
		end
    end

	for i = 1, nextScript-1 do
        local script = scripts[s]
		
		if nowt - script.lastUpdateTime > script.updateInterval then
			script.lastUpdateTime = nowt
			script:Update(deltaTime)
			-- Spent too much time updating
			if kMaxUpdateTime < clock() - now then
				nextScript = i + 1
				return
			end
		end
	end
end

function GUIManager:SendKeyEvent(key, down, amount)
	if not Shared.GetIsRunningPrediction() then
		for i = 1, #scripts do
			if scripts[i]:SendKeyEvent(key, down, amount) then
				return true
			end
		end
	end
	return false
end

function GUIManager:SendCharacterEvent(c)
	for i = 1, #scripts do
		if scripts[i]:SendCharacterEvent(c) then
			return true
		end
	end
	return false
end

function GUIManager:OnResolutionChanged(x1, y1, x2, y2)
	for i = 1, #scripts do
		scripts[i]:SendCharacterEvent(x1, y1, x2, y2)
	end
end

link("CreateGraphicItem", GUI.CreateItem)

function GUIManager.CreateTextItem()
	local item = GUI.CreateItem()
	item:SetOptionFlag(GUIItem.ManageRender)
	return item
end

link("CreateLinesItem", GUIManager.CreateTextItem)

if Event then
    Event.Hook("UpdateClient", OnUpdate, "GUIManager")
    Event.Hook("ResolutionChanged", OnResolutionChanged)
end
