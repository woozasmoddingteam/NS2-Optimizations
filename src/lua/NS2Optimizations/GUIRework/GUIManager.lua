
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
	find,
	clock,
	GUI,
	Shared,
	Client,
	min,
	max
	=
	table.insert,
	table.remove,
	table.find,
	os.clock,
	GUI,
	Shared,
	Client,
	math.min,
	math.max

kGUILayerDebugText             = 0
kGUILayerDeathScreen           = 1
kGUILayerChat                  = 3
kGUILayerPlayerNameTags        = 4
kGUILayerPlayerHUDBackground   = 5
kGUILayerPlayerHUD             = 6
kGUILayerPlayerHUDForeground1  = 7
kGUILayerPlayerHUDForeground2  = 8
kGUILayerPlayerHUDForeground3  = 9
kGUILayerPlayerHUDForeground4  = 10
kGUILayerCommanderAlerts       = 11
kGUILayerCommanderHUD          = 12
kGUILayerLocationText          = 13
kGUILayerMinimap               = 14
kGUILayerScoreboard            = 15
kGUILayerCountDown             = 16
kGUILayerTestEvents            = 17
kGUILayerMainMenuNews          = 19
kGUILayerMainMenu              = 20
kGUILayerMainMenuServerDetails = 40
kGUILayerMainMenuDialogs       = 60
kGUILayerTipVideos             = 70
kGUILayerOptionsTooltips       = 100

local kMaxUpdateTime = 0.008       -- If the update time of GUIManager exceeds this value, it will stop updating and wait for the next tick.
local qRunTime       = "__runtime" -- Estimation of time a script takes, with bias towards new numbers

local GUIManager = {}
_G.GUIManager    = GUIManager

local nextScript = 1

local scripts                = {}
local path_to_script         = {}
local single_script_inst     = {}

GUIManager.scripts = scripts -- For shine compatility

do
	local files = {}
	Shared.GetMatchingFileNames("lua/*", true, files)
	for i = 1, #files do
		local file = files[i]:sub(5) -- #"lua/" + 1
		if file:sub(-4) == ".lua" then
			file = file:sub(1, -5)
			local name = pop(file:Explode("/"))
			path_to_script[file] = name
		end
	end
end

function GetGUIManager()
	return GUIManager
end

local function CreateGUIScript(path)
	local script_name = path_to_script[path] or path
	local class  = _G[script_name]
	if class == nil then
		Script.Load("lua/" .. path .. ".lua")
		class = _G[script_name]
	end

	if not class then -- gui script failed to load
		_G[script_name] = false -- avoid trying to load script another time
		return
	end

	local script = class()
	script:Initialize()

	script.updateInterval = script.updateInterval or kUpdateInterval
	script.lastUpdateTime = 0

	script._scriptName = path

	script[qRunTime] = 0

	push(scripts, script)
	return script
end

function GUIManager:CreateGUIScript(path)
	return CreateGUIScript(path)
end

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
	local index = find(scripts, script)
	if index then
		pop(scripts, index)
		script:Uninitialize()
		-- When destroying GUI scripts, an update to a script might be missed. Not a huge problem.
		if nextScript > #scripts then
			nextScript = 1
		end
		return true
	else
		return false
	end
end

function GUIManager:DestroyGUIScript(script)
	return DestroyGUIScript(script)
end

function GUIManager:DestroyGUIScriptSingle(path)
	local script = single_script_inst[path]
	single_script_inst[path] = nil
	return DestroyGUIScript(script)
end

function GUIManager:GetGUIScriptSingle(path)
	return single_script_inst[path]
end

function GUIManager.NotifyGUIItemDestroyed() end

local function Update(deltaTime)
	PROFILE("GUIManager:Update")

	local numScripts      = #scripts

	if numScripts == 0 then
	return
	end

	local now             = clock()
	local max_update_time = now + kMaxUpdateTime

	-- The first script is always executed
	do
	local script = scripts[nextScript]
	if script ~= nil and script:GetShouldUpdate() then
		script:Update(deltaTime)
		local new_now = clock(deltaTime)
		script[qRunTime] = new_now - now
	end
	end

	for i = nextScript+1, numScripts do
	local script = scripts[i]

	if script ~= nil and script:GetShouldUpdate() then
		local runtime = script[qRunTime]
		if now + runtime > max_update_time then
		nextScript = i
		return
		end
		script:Update(deltaTime)
		local new_now = clock()

			-- a bit inaccurate if lots of invisible scripts were updated in between
		script[qRunTime] = new_now - now
		now = new_now
	end
	end

	for i = 1, nextScript-1 do
	local script = scripts[i]

	if script ~= nil and script:GetShouldUpdate() then
		local runtime = script[qRunTime]
		if now + runtime > max_update_time then
		nextScript = i
		return
		end
		script:Update(deltaTime)
		local new_now = clock()

		-- a bit inaccurate if lots of invisible scripts were updated in between
		script[qRunTime] = new_now - now
		now = new_now
	end
	end
end

if not Shared.GetIsRunningPrediction() then
	function GUIManager:SendKeyEvent(key, down, amount)
			for i = 1, #scripts do
				if scripts[i]:SendKeyEvent(key, down, amount) then
					return true
				end
			end
		return false
	end
else
	function GUIManager.SendKeyEvent() end
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
		scripts[i]:OnResolutionChanged(x1, y1, x2, y2)
	end
end

function GUIManager.CreateGraphicItem()
	return GUI.CreateItem()
end

function GUIManager.CreateTextItem()
	local item = GUI.CreateItem()
	item:SetOptionFlag(GUIItem.ManageRender)
	return item
end

GUIManager.CreateLinesItem = GUIManager.CreateTextItem

Event.Hook("Console_script_times", function()
	for i, script in ipairs(scripts) do
		Log("%s: %s", script._scriptName, script[qRunTime])
	end
end)

if Event then
	Event.Hook("UpdateClient", Update, "GUIManager")
	Event.Hook("ResolutionChanged", function(...) GUIManager.OnResolutionChanged(nil, ...) end)
end
