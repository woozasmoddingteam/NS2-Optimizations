--[[

This is a rewrite of the minimap.
GUIMinmap and GUIMinimapFrame have been merged.
We do not check for destroyed blips, but instead rely on the entity responsible telling us.
This is not a problem as the entity can't leave the client's relevancy.

]]

Script.Load "lua/GUIMinimapConnection.lua"
Script.Load "lua/MinimapMappableMixin.lua"

local Shared           = Shared
local Client           = Client
local push             = table.insert
local pop              = table.remove
local math_min         = math.min
local math_max         = math.max
local GUIScale         = GUIScale
local GUIManager       = GUIManager
local GUIItem          = GUIItem
local GUI              = GUI
local Vector           = Vector
local Color            = Color
local kNeutralTeamType = kNeutralTeamType

do
	local left = GUIItem.Left
	local bottom = GUIItem.Bottom
	local function NewItem()
		local i = GUIManager.CreateGraphicItem()
		i:SetAnchor(left, bottom)
		-- What the fuck does stenciling do?
		i:SetInheritsParentStencilSettings(true)
		i:SetIsVisible(false)
		return i
	end
end

local CHUDGetOption
do
	local actual_CHUDGetOption = _G.CHUDGetOption
	if actual_CHUDGetOption then
		function CHUDGetOption(key)
			return actual_CHUDGetOption(key)
		end
	else
		function CHUDGetOption(key, ...)
			return ...
		end
	end
end

class "GUIMinimapFrame" (GUIScript)

for i, v in ipairs {"kModeMini", "kModeZoom", "kModeBig"} do
	GUIMinimapFrame[v] = i
end
local kModeMini = GUIMinimapFrame.kModeMini
local kModeZoom = GUIMinimapFrame.kModeZoom
local kModeBig  = GUIMinimapFrame.kModeBig

-- Player constants
local kPlayerNameLayer       = 7
local playerNameFontSize
local kPlayerNameFontName    = Fonts.kAgencyFB_Tiny
local playerNameOffset       = 
local kPlayerNameColorAlien  = Color(1, 189/255, 111/255, 1)
local kPlayerNameColorMarine = Color(164/255, 241/255, 1, 1)

local blipSize

local kWayPointColor         = Color(1, 1, 1, 1)

local kTeamColors = {
	[kMarineTeamType] = ColorIntToColor(kMarineTeamColor),
	[kAlienTeamType]  = ColorIntToColor(kAlienTeamColor)
}

local function ColorFriend(c)
	c.r = (1 + c.r) / 2
	c.g = (1 + c.g) / 2
	c.b = (1 + c.b) / 2
end

local kPowerNodeColor          = Color(1, 1, 0.7, 1)
local kDestroyedPowerNodeColor = Color(0.5, 0.5, 0.35, 1)

local kDrifterColor = Color(1, 1, 0, 1)
local kMACColor     = Color(0, 1, 0.2, 1)

local kBlinkInterval = 1

local kScanColor        = Color(0.2, 0.8, 1, 1)
local kScanAnimDuration = 2

local kWhite = Color(1, 1, 1, 1)

local kInfestationColor = Color(0.2, 0.7, 0.2, .25)

local shrinkingArrowInitSize

local kIconTexture = "ui/minimap_blip.dds"

local kLargePlayerArrowFileName = PrecacheAsset("ui/minimap_largeplayerarrow.dds")

local commanderPingMinimapSize

local iconWidth
local iconHeight

local kInfestationBlipsLayer = 0
local kBackgroundBlipsLayer  = 1
local kStaticBlipsLayer      = 2
local kDynamicBlipsLayer     = 3
local kLocationNameLayer     = 4
local kPingLayer             = 5
local kPlayerIconLayer       = 6

local kBlipTexture = "ui/blip.dds"

local blipMinSize
local blipMaxSize
local kBlipPulseSpeed
local kBlipTime

local locationFontSize
local kLocationFontName = Fonts.kAgencyFB_Smaller_Bordered

local playerIconSize

local activity = kMinimapActivity
local Static   = activity.Static
local Low      = activity.Low
local Medium   = activity.Medium
local High     = activity.High

local kBlipUpdateCount = {
	[Static] = -1,
	[Low]    = 0,
	[Medium] = 4,
	[High]   = 9,
}

local kBackgroundWidth  = {
	[kModeMini] = 300,
	[kModeZoom] = 380,
}
local kBackgroundHeight = {
	[kModeMini] = 300,
	[kModeZoom] = 360,
}

local background
local minimap
local cameraLines
local playerIcon
local playerShrinkingArrow
local minimapFrame
local chooseSpawnText
local spawnQueueText
local commanderPing
local smokeyBackground

local showMouse = false
local showPlayerNames

local minimapOrigin = Client.minimapExtentOrigin
local minimapScale  = Client.minimapScale
local positionScale = Vector()
local scale         = 1

local mode          = kModeZoom

local function UpdateSizes()
	playerNameFontSize     = GUIScale(8)
	blipSize               = GUIScale(30)
	iconWidth              = GUIScale(32)
	iconHeight             = GUIScale(32)
	playerIconSize         = Vector(blipSize, blipSize, 0)
	playerNameOffset       = GUIScale( Vector(11.5, -5, 0) )
	shrinkingArrowInitSize = Vector(blipSize * 10, blipSize * 10, 0)
	blipMinSize            = Vector(GUIScale(25), GUIScale(25), 0)
	blipMaxSize            = Vector(GUIScale(100), GUIScale(100), 0)
	positionScale.x        = backgroundHeight / minimapScale.x * 2 * scale
	positionScale.z        =
		backgroundWidth / minimapScale.z * 2 * scale
			*
		math_min(minimapScale.x, minimapScale.z) / math_min(minimapScale.x, minimapScale.z)
end
GUIMinimap.OnResolutionChanged = UpdateSizes

local keyIcon = newproxy()
local icons   = {}
for i = 1, #activity do
	icons[i] = {i = 1}
end

local kClassToGrid = BuildClassToGrid()

local isRespawning = false
local desiredSpawnPosition
Client.HookNetworkMessage("SetIsRespawning", function(m)
	isRespawning = m.isRespawning
end)

function GetPlayerIsSpawning()
	return isRespawning
end

function GetDesiredSpawnPosition()
	return desiredSpawnPosition
end

local self
local function PlotToMap(x, z)
	return
		(z - minimapOrigin.z) * positionScale.z
		-(x - minimapOrigin.x) * positionScale.x,
		0
end

do
	local available = {}

	local function CreateNewNameTag(self)
		local nameTag = NewItem()

		nameTag:SetFontSize(playerNameFontSize)
		nameTag:SetFontIsBold(false)
		nameTag:SetFontName(kPlayerNameFontName)
		nameTag:SetTextAlignmentX(GUIItem.Align_Center)
		nameTag:SetTextAlignmentY(GUIItem.Align_Center)
		nameTag:SetLayer(kPlayerNameLayer)
		minimap:AddChild(nameTag)

		return nameTag
	end

	function AllocNameTag()
		return pop(available) or CreateNewNameTag()
	end

	function FreeNameTag(tag)
		tag:SetIsVisible(false)
		push(available, tag)
	end
end

do
	local available = {}

	function AllocateIcon()
		local icon = pop(freeIcons)
		if not icon then
			icon = NewItem()
			minimap:AddChild(icon)
		end

		return icon
	end

	function FreeIcon(_, icon)
		icon:SetIsVisible(false)
		push(freeIcons, icon)
	end
end

do
	local available = {}

	function AllocateBlip()
		local blip = pop(available)
		if not blip then
			blip = NewItem()
			blip:SetLayer(kDynamicBlipsLayer)
			blip:SetTexture(kBlipTexture)
			blip:SetBlendTechnique(GUIItem.Add)
			minimap:AddChild(blip)
		end
		return blip
	end

	function FreeBlip(blip)
		blip:SetIsVisible(false)
		push(available, blip)
	end
end

local function 

local function SetBackgroundMode(mode)
	if     mode == kModeMini then
		background:SetAnchor(GUIItem.left, GUIItem.Bottom)
		background:SetPosition
	elseif mode == kModeZoom then
	elseif mode == kModeBig  then
	end
end

function GUIMinimap.GetMinimapItem()
	return minimap
end

function GUIMinimap.Initialise(_self)
	assert(self == nil)
	self = _self

	do
		background = GUIManager.CreateGraphicItem
		background:SetPosition(Vector.origin)
		background:SetColor(Color(1, 1, 1, 0))
		background:SetAnchor(GUIItem.Left, GUIItem.Top)
		background:SetLayer(kGUILayerMinimap)
		background:SetIsVisible(PlayerUI_IsACommander())
	end

	do
		minimap = GUIManager.CreateGraphicItem()
		minimap:SetAncor(GUIItem.Left, GUIItem.Top)
		minimap:SetPosition(Vector.origin)
		minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
		minimap:SetColor(Color(
			1, 1, 1, CHUDGetOption("minimapalpha", 0.85)
		))
		background:AddChild(minimap)
	end

	do
		cameraLines = GUIManager.CreateLinesItem()
		cameraLines:SetAnchor(GUIItem.Middle, GUIItem.Center)
		cameraLines:SetLayer(kPlayerIconLayer)
		minimap:AddChild(cameraLines)
	end

	do
		playerIcon = NewItem()
		playerIcon:SetTexture(kIconTexture)
		local iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass(), kClassToGrid)
		playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
		playerIcon:SetLayer(kPlayerIconLayer)
		minimap:AddChild(playerIcon)

		playerShrinkingArrow = GUIManager.CreateGraphicItem()
		playerShrinkingArrow:SetAnchor(GUIItem.Middle, GUIItem.Center)
		playerShrinkingArrow:SetTexture(kLargePlayerArrowFileName)
		playerShrinkingArrow:SetLayer(kPlayerIconLayer)
		playerIcon:AddChild(playerShrinkingArrow)
	end

	do
		commanderPing = NewItem()
		commanderPing.Frame:SetLayer(kPingLayer)
		minimap:AddChild(commanderPing.Frame)
	end
	
	do
		smokeyBackground = GUIManager.CreateGraphicItem()
		smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
		smokeyBackground:SetTexture("ui/alien_minimap_smkmask.dds")
		smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
		smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
		smokeyBackground:SetFloatParameter("correctionX", 1)
		smokeyBackground:SetFloatParameter("correctionY", 1.2)
		smokeyBackground:SetIsVisible(false)
		smokeyBackground:SetLayer(-1) 
		background:AddChild(smokeyBackground)
	end

	do
		minimapFrame = GUIManager.CreateGraphicItem()
		minimapFrame:SetAnchor(GUIItem.Left, GUIItem.Bottom)
		minimapFrame:SetTexture(kMarineFrameTexture)
		minimapFrame:SetTexturePixelCoordinates(unpack(kFramePixelCoords))
		minimapFrame:SetIsVisible(false)
		minimapFrame:SetLayer(-1)
		background:AddChild(minimapFrame)
	end

	do
		chooseSpawnText = GUIManager.CreateTextItem()
		chooseSpawnText:SetText(SubstituteBindStrings(Locale.ResolveString("CHOOSE_SPAWN")))
		chooseSpawnText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
		chooseSpawnText:SetTextAlignmentX(GUIItem.Align_Center)
		chooseSpawnText:SetTextAlignmentY(GUIItem.Align_Max)
		chooseSpawnText:SetIsVisible(false)
	end

	do
		spawnQueueText = GUIManager:CreateTextItem()
		spawnQueueText:SetFontIsBold(true)
		spawnQueueText:SetAnchor(GUIItem.Left, GUIItem.Top)
		spawnQueueText:SetTextAlignmentX(GUIItem.Align_Min)
		spawnQueueText:SetTextAlignmentY(GUIItem.Align_Center)
		spawnQueueText:SetColor( Color(1,1,1,1) )
		spawnQueueText:SetIsVisible(true)
		minimapFrame:AddChild(spawnQueueText)
	end

	UpdateSizes()
end

function GUIMinimap.Uninitialize()
	self = nil
	if background then
		GUI.DestroyItem(background)
	end
	if chooseSpawnText then
		GUI.DestroyItem(spawnQueueText)
	end
	if showMouse then
		MouseTracker_SetIsVisible(false)
	end
end

