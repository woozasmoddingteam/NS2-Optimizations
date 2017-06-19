--[[

This is a rewrite of the minimap.
GUIMinmap and GUIMinimapFrame have been merged.
We do not check for destroyed blips, but instead rely on the entity responsible telling us.
This is not a problem as the entity can't leave the client's relevancy.

]]

--[[

Nomenclature:

A blip is what was referred to in the previous version as dynamic blips.
It is a dynamic icon that seeks to bring attention to a spot on the map.
The only type of blip is currently the attack blip: a red circle that grows bigger and smaller.
Thus the term `blip` refers to an attack blip.

An icon is the icon that represents an entity on the map, e.g. a tech point, a player, a commandstructure, etc.

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
local CreateGraphicItem = GUIManager.CreateGraphicItem

local function GUISize(size)
	return math_min(Client.GetScreenWidth(), Client.GetScreenHeight()) * size
end

local origin = Vector.origin
local left   = GUIItem.Left
local top    = GUIItem.Top
local middle = GUIItem.Middle
local center = GUIItem.Center
local function NewItem()
	local i = CreateGraphicItem()
	i:SetAnchor(left, top)
	i:SetIsVisible(false)
	i:SetPosition(origin)
	return i
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
local kPlayerNameFontName    = Fonts.kAgencyFB_Tiny
local kPlayerNameColorAlien  = Color(1, 189/255, 111/255, 1)
local kPlayerNameColorMarine = Color(164/255, 241/255, 1, 1)

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
local kIconWidth   = 32
local kIconHeight  = 32

local kLargePlayerArrowFileName = PrecacheAsset("ui/minimap_largeplayerarrow.dds")

local kInfestationBlipsLayer = 0
local kBackgroundBlipsLayer  = 1
local kStaticBlipsLayer      = 2
local kDynamicBlipsLayer     = 3
local kLocationNameLayer     = 4
local kPingLayer             = 5
local kPlayerIconLayer       = 6

local kBlipTexture = "ui/blip.dds"

--[[
local kBlipPulseSpeed
local kBlipTime

local locationFontSize
local kLocationFontName = Fonts.kAgencyFB_Smaller_Bordered

local kMinimapActivity = kMinimapActivity
local Static   = kMinimapActivity.Static
local Low      = kMinimapActivity.Low
local Medium   = kMinimapActivity.Medium
local High     = kMinimapActivity.High

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
--]]

local kMinimapOrigin_x = Client.minimapExtentOrigin.x
local kMinimapOrigin_z = Client.minimapExtentOrigin.z
local kMinimapScale_x = Client.minimapExtentScale.x
local kMinimapScale_z = Client.minimapExtentScale.z

local kClassGrid = BuildClassToGrid()

local desiredSpawnPosition
local isRespawning = false
local function OnIsRespawning(b)
	isRespawning = b
end
Client.HookNetworkMessage("SetIsRespawning", function(m)
	OnIsRespawning(m.isRespawning)
end)

function GetPlayerIsSpawning()
	return isRespawning
end

function GetDesiredSpawnPosition()
	return desiredSpawnPosition
end

--[=[
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
local AllocNameTag, FreeNameTag = AllocNameTag, FreeNameTag

do
	local available = {}

	function AllocIcon()
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
local AllocIcon, FreeIcon = AllocIcon, FreeIcon

do
	local available = {}

	function AllocBlip()
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
local AllocBlip, FreeBlip = AllocBlip, FreeBlip

--]=]
local function GenerateIntegers(n)
	local t = {}
	for i = 1, n do
		t[i] = i-1
	end
	return unpack(t)
end

-- These are keys used instead of strings
-- This should theoretically be faster
-- Since k is used for constant, q is used for key.
-- Qey
local
	qPlayerNameSize,
	qPlayerNameOffset,
	qPlayerIcon,
	qPlayerIconSize,
	qPlayerIconInitSize,
	qBlipMinSize,
	qBlipMaxSize,
	qPositionScale,
	qMinimap,
	qMinimapPlotScale_x,
	qMinimapPlotScale_z,
	qMinimapFrame,
	qCameraLines,
	qChooseSpawnText,
	qSpawnQueueText,
	qCommanderPing,
	qSmokeyBackground,
	qShowMouse,
	qShowPlayerNames,
	qScale,
	qMode
	= GenerateIntegers(21)

-- Is called on SetBackgroundMode, which is called together with SetMode commonly!
function GUIMinimapFrame:OnResolutionChanged()
	self[qPlayerNameSize]     = GUIScale(8)
	self[qPlayerNameOffset]   = GUIScale( Vector(11.5, -5, 0) )
	self[qPlayerIconSize]     = Vector(GUIScale(30), GUIScale(30), 0)
	self[qPlayerIconInitSize] = Vector(GUIScale(300), GUIScale(300), 0)
	--self[qBlipSize]           = GUIScale(30)
	self[qBlipMinSize]        = Vector(GUIScale(25), GUIScale(25), 0)
	self[qBlipMaxSize]        = Vector(GUIScale(100), GUIScale(100), 0)

	local size
	if self[qMode] == kModeZoom then
		-- black magic incoming
		local scale = Client.GetScreenHeight() / 540
		size = Vector(190 * scale, 180 * scale, 0)
	else
		size = GUISize(Vector(0.75, 0.75, 0))
		self[qMinimap]:SetPosition(size * -0.5)
	end
	self[qMinimap]:SetSize(size)
	self[qMinimapPlotScale_x] = size.x / kMinimapScale_x
	self[qMinimapPlotScale_z] = size.y / kMinimapScale_z
end

function GUIMinimapFrame:PlotToMap(x, z)
	local size = self[qMinimap]
	return
		(x - kMinimapOrigin_x) * self[qMinimapPlotScale_x],
		(z - kMinimapOrigin_z) * self[qMinimapPlotScale_z]
end

function GUIMinimapFrame:GetMinimapItem()
	return self[qMinimap]
end

function GUIMinimapFrame:GetBackground()
	return self[qMinimap]
end

function GUIMinimapFrame:Initialize()
	do
		local minimap = NewItem()
		minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
		minimap:SetColor(Color(
			1, 1, 1, CHUDGetOption("minimapalpha", 0.85)
		))
		minimap:SetLayer(kGUILayerMinimap)
		self[qMinimap] = minimap
	end

	do
		local playerIcon = NewItem()
		playerIcon:SetTexture(kIconTexture)
		local iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass(), kClassGrid)
		playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
		playerIcon:SetLayer(kPlayerIconLayer)
		self[qMinimap]:AddChild(playerIcon)
		self[qPlayerIcon] = playerIcon
	end

	self:SetBackgroundMode(kModeBig)

	self:OnResolutionChanged()
end

function GUIMinimapFrame:ShowMap(b)
	self[qMinimap]:SetIsVisible(b)
end

function GUIMinimapFrame:SetBackgroundMode(mode)
	self[qMode] = mode
	if mode == kModeZoom then
		self[qMinimap]:SetAnchor(left, top)
		self[qMinimap]:SetPosition(origin)
	elseif mode == kModeBig then
		self[qMinimap]:SetAnchor(middle, center)
	end
	self:OnResolutionChanged()
	-- TODO: Implement completely
end

function GUIMinimapFrame:SetDesiredZoom(zoom)
	-- TODO: Implement
end

function GUIMinimapFrame:Uninitialize()
	GUI.DestroyItem(self[qMinimap])
end

