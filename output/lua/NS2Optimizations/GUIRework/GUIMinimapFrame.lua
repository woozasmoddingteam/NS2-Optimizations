--[[

This is a rewrite of the minimap.
GUIMinimap and GUIMinimapFrame have been merged.

Notable things about the implementation:
We do not check map blips on each update, to see if we
need to remove old ones.
Instead, we delegate this task to the GC.

On each update, the script iterates through all relevant
map blips, and updates their icon's position.
If the icon does not exist, it is created.

Once a mapblip is no longer relevant (or destroyed), the
icon will be destroyed at the new GC cycle, since
the table, in which they are contained, is set to have weak keys.
The keys are the map blip instances, **not** their IDs.
Once a map blip is destroyed, its table entry will also be destroyed.
The icon will thus also be unreferenced, and will thus also be
destroyed.

Nomenclature:

A blip is what was referred to in the previous version as dynamic blips.
It is a dynamic icon that seeks to bring attention to a spot on the map.
The only type of blip is currently the attack blip: a red circle that grows bigger and smaller.
Thus the term `blip` refers to an attack blip.

An icon is the icon that represents an entity on the map, e.g. a tech point, a player, a commandstructure, etc.

]]

Script.Load "lua/GUIMinimapConnection.lua"
Script.Load "lua/MinimapMappableMixin.lua"
Script.Load "lua/GUIManager.lua"

local Shared            = Shared
local Client            = Client
local push              = table.insert
local pop               = table.remove
local math_min          = math.min
local math_max          = math.max
local GUIScale          = GUIScale
local GUIGetSprite      = GUIGetSprite
local GUIManager        = GUIManager
local GUIItem           = GUIItem
local GUI               = GUI
local DestroyItem       = GUI.DestroyItem
local Vector            = Vector
local Color             = Color
local kNeutralTeamType  = kNeutralTeamType
local CreateGraphicItem = GUIManager.CreateGraphicItem
local kMinimapBlipType  = kMinimapBlipType
local origin            = Vector.origin
local left              = GUIItem.Left
local top               = GUIItem.Top
local middle            = GUIItem.Middle
local center            = GUIItem.Center

local function GUISize(size)
	return math_min(Client.GetScreenWidth(), Client.GetScreenHeight()) * size
end

local function NewItem()
	local i = CreateGraphicItem()
	i:SetAnchor(middle, center)
	i:SetIsVisible(true)
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
local kPlayerNameFontName    = Fonts.kAgencyFB_Tiny

assert(Color().a == 1)

local kTeamColors = {
	[0] = Color(1, 1, 1),
	[1] = Color(0.9, 0.9, 0.9),
	[2] = Color(0, 216/255, 1, 1),
	[3] = Color(1, 138/255, 0, 1),
}

local kFriendTeamColors = table.dmap(kTeamColors, function(c)
	return Color(
		0.5 + c.r / 2,
		0.5 + c.g / 2,
		0.5 + c.b / 2,
		c.a
	)
end)

local kSelfTeamColors   = table.dmap(kTeamColors, function(c)
	return Color(
		0.5  + c.r / 2,
		0.75 * c.g,
		0.5  + c.b / 2,
		c.a
	)
end)

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
local kPlayerNameLayer       = 7

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

local function GenerateIntegers(n)
	local t = {}
	for i = 1, n do
		t[i] = i-1
	end
	return unpack(t)
end

GUIMinimapFrame.__KeysUsed = 21

-- These are keys used instead of strings
-- This should theoretically be faster
-- Since k is used for constant, q is used for key.
-- Qey
local
	qPlayerNameSize,
	qPlayerNameOffset,
	qIconSize,
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
	qMode,
	qZoom,
	qIcons
	= GenerateIntegers(GUIMinimapFrame.__KeysUsed)

-- Is called on SetBackgroundMode, which is called together with SetMode commonly!
function GUIMinimapFrame:OnResolutionChanged()
	self[qPlayerNameSize]     = GUIScale(8)
	self[qPlayerNameOffset]   = GUIScale( Vector(11.5, -5, 0) )
	--self[qPlayerIconInitSize] = Vector(GUIScale(300), GUIScale(300), 0)
	--self[qBlipSize]           = GUIScale(30)
	self[qBlipMinSize]        = Vector(GUIScale(25), GUIScale(25), 0)
	self[qBlipMaxSize]        = Vector(GUIScale(100), GUIScale(100), 0)

	self[qIconSize] = GUIScale(Vector(30, 30, 0))

	local size
	if self[qMode] == kModeZoom then
		size = Vector(190 * kMinimapScale_x, 180 * kMinimapScale_z, 0) * Client.GetScreenHeight() * self[qZoom] * (3 / 540 / 400)
	else
		size = GUISize(Vector(0.75, 0.75, 0))
		self[qMinimap]:SetPosition(size * -0.5)
	end
	self[qMinimap]:SetSize(size)
	self[qMinimapPlotScale_x] = size.x / kMinimapScale_x * -2
	self[qMinimapPlotScale_z] = size.y / kMinimapScale_z * 2
end

local function PlotToMap(self, x, z)
	return
		(z - kMinimapOrigin_z) * self[qMinimapPlotScale_z],
		(x - kMinimapOrigin_x) * self[qMinimapPlotScale_x]
end

function GUIMinimapFrame:GetMinimapItem()
	return self[qMinimap]
end

function GUIMinimapFrame:GetBackground()
	return self[qMinimap]
end

function GUIMinimapFrame:Initialize()
	Log("Initialize() %s", tostring(self))
	
	-- key: mapblip instance, value: icon
	self[qIcons] = setmetatable({}, {__mode = "k"})

	do
		local minimap = NewItem()
		minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
		minimap:SetColor(Color(
			1, 1, 1, CHUDGetOption("minimapalpha", 0.85)
		))
		minimap:SetLayer(kGUILayerMinimap)
		minimap:SetIsVisible(false)
		self[qMinimap] = minimap
	end

	self[qZoom] = 1
	self:SetBackgroundMode(kModeBig)

	self.updateInterval = 0
end

function GUIMinimapFrame:ShowMap(b)
	self[qMinimap]:SetIsVisible(b)
end

GUIMinimapFrame.SetIsVisible = GUIMinimapFrame.ShowMap

function GUIMinimapFrame:GetIsVisible()
	return self[qMinimap]:GetIsVisible()
end

function GUIMinimapFrame:SetBackgroundMode(mode)
	if self[qMode] ~= mode then
		self[qMode] = mode
		self[qMinimap]:SetStencilFunc(mode == kModeZoom and GUIItem.NotEqual or GUIItem.Always)
		self:OnResolutionChanged()
	end
end

-- Also SetDesiredZoom
function GUIMinimapFrame:SetZoom(zoom)
	self[qZoom] = zoom
end

GUIMinimapFrame.SetDesiredZoom = GUIMinimapFrame.SetZoom

function GUIMinimapFrame:Uninitialize()
	GUI.DestroyItem(self[qMinimap])
end

function GUIMinimapFrame:Update()
	if self[qMode] == kModeZoom then
		local player_pos = Client.GetLocalPlayer():GetOrigin()
		local x, y       = PlotToMap(self, player_pos.x, player_pos.z)
		self[qMinimap]:SetPosition(-Vector(x, y, 0))
	end

	local mapblips = Shared.GetEntitiesWithClassname "MapBlip"
	local GetEntityAtIndex = mapblips.GetEntityAtIndex
	for i = 0, mapblips:GetSize()-1 do
		local mapblip = GetEntityAtIndex(mapblips, i)
		-- truth branch should always be the rare one, due to how both luajit and processors work
		if mapblip == nil then
		else
			local icon = self[qIcons][mapblip]
			if icon == nil then
				local clientIndex = mapblip.clientIndex
				if mapblip:isa "PlayerMapBlip" then
					Log("Player map blip! its client index: %s, the local player's: %s", clientIndex, Client.GetLocalPlayer().clientIndex)
				end
				local colors = (
					mapblip:isa "PlayerMapBlip" and (
						clientIndex == Client.GetLocalPlayer().clientIndex and kSelfTeamColors
						or
						Client.GetIsSteamFriend(GetSteamIdForClientIndex(clientIndex) or 0) and kFriendTeamColors
					) or kTeamColors
				)
				local color = colors[mapblip.team+1]
				local coords = kClassGrid[kMinimapBlipType[mapblip.type]]
				Log("New MapBlip with type %s", kMinimapBlipType[mapblip.type])
				icon = NewItem()
				icon:SetSize(self[qIconSize])
				icon:SetInheritsParentStencilSettings(true)
				icon:SetColor(color)
				icon:SetTexture(kIconTexture)
				icon:SetLayer(kPlayerIconLayer)
				icon:SetTexturePixelCoordinates(GUIGetSprite(coords[1], coords[2], kIconWidth, kIconHeight))
				self[qIcons][mapblip] = icon
				self[qMinimap]:AddChild(icon)
				Log("Origin: %s; %s", mapblip:GetWorldOrigin(), mapblip:GetParent())
			end
			local origin = mapblip:GetWorldOrigin()
			origin.x, origin.y = PlotToMap(self, origin.x, origin.z)
			origin.z = 0
			local size   = icon:GetSize()
			origin.x = origin.x - size.x/2
			origin.y = origin.y - size.y/2
			icon:SetPosition(origin)
		end
	end
end
