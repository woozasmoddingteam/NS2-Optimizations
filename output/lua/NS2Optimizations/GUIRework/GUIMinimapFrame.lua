--[[

This is a rewrite of the minimap.
GUIMinimap and GUIMinimapFrame have been merged.

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
local pi                = math.pi

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


-- kIconColors takes a kMinimapBlipType and returns a team-agnostic color
local kIconColors = {}
do
	local kWorldColor = Color(0, 1, 0)
	local kWhite      = Color(1, 1, 1)
	for k, v in ipairs {
		Scan                 = Color(0.2, 0.8, 1),
		PowerPoint           = Color(1, 1, 0.7),
		UnsocketedPowerPoint = kWhite,
		Infestation          = Color(0.2, 0.7, 0.2, 0.25),
		Drifter              = Color(1, 1, 0),
		MAC                  = Color(0, 1, 0.2),
		BoneWall             = kWhite,
		TechPoint            = kWorldColor,
		ResourcePoint        = kWorldColor,
	} do
		kIconColors[kMinimapBlipType[k]] = v
	end
end

-- Used when kIconColors has no matching entry
-- Keys are teams, but +1
local kTeamColors = {
	[0] = Color(1,   1,       1),   -- No team
	[1] = Color(0.9, 0.9,     0.9), -- Ready room
	[2] = Color(0,   216/255, 1),   -- Marines
	[3] = Color(1,   138/255, 0),   -- Aliens
}

-- Colors used for friends
local kFriendTeamColors = table.dmap(kTeamColors, function(c)
	return Color(
		0.5 + c.r / 2,
		0.5 + c.g / 2,
		0.5 + c.b / 2,
		c.a
	)
end)

-- Colors used for oneself
local kSelfTeamColors   = table.dmap(kTeamColors, function(c)
	return Color(
		0.5  + c.r / 2,
		0.75 * c.g,
		0.5  + c.b / 2,
		c.a
	)
end)

-- Function used for inactive icons
local function ColorInactive(c)
	c.r = c.r / 2
	c.g = c.g / 2
	c.b = c.b / 2
	return c
end

-- Function used to make inactive icons active again
local function ColorActive(c)
	c.r = c.r * 2
	c.g = c.g * 2
	c.b = c.b * 2
	return c
end

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

GUIMinimapFrame.__KeysUsed = 24

-- Is called on SetBackgroundMode, which is called together with SetMode commonly!
function GUIMinimapFrame:OnResolutionChanged()
	self.playerNameSize     = GUIScale(8)
	self.playerNameOffset   = GUIScale( Vector(11.5, -5, 0) )
	--self[qPlayerIconInitSize] = Vector(GUIScale(300), GUIScale(300), 0)
	--self[qBlipSize]           = GUIScale(30)
	self.blipMinSize        = Vector(GUIScale(25), GUIScale(25), 0)
	self.blipMaxSize        = Vector(GUIScale(100), GUIScale(100), 0)

	self.iconSize = GUIScale(Vector(30, 30, 0))

	local size
	if self.mode == kModeZoom then
		size = Vector(190 * kMinimapScale_x, 180 * kMinimapScale_z, 0) * Client.GetScreenHeight() * self.zoom * (3 / 540 / 400)
	else
		size = GUISize(Vector(0.75, 0.75, 0))
		self.minimap:SetPosition(size * -0.5)
	end
	self.minimap:SetSize(size)
	self.minimapPlotScale_x = size.x / kMinimapScale_x * -2
	self.minimapPlotScale_z = size.y / kMinimapScale_z * 2
end

local function PlotToMap(self, x, z)
	return
		(z - kMinimapOrigin_z) * self.minimapPlotScale_z,
		(x - kMinimapOrigin_x) * self.minimapPlotScale_x
end

function GUIMinimapFrame:GetMinimapItem()
	return self.minimap
end

function GUIMinimapFrame:GetBackground()
	return self.minimap
end

local minimapframes = {}

function GUIMinimapFrame.AlertActivity(mapblip)
	for _, self in ipairs(minimapframes) do
		local icon = self.mapBlipIcons[mapblip]
		local activity = mapblip.active
		if icon.active ~= activity then
			icon.active = activity
			local color = icon:GetColor()
			if activity then
				ColorActive(color)
			else
				ColorInactive(color)
			end
			icon:SetColor(color)
		end
	end
end

function GUIMinimapFrame.AlertCombat(mapblip)
	for _, self in ipairs(minimapframes) do
		local icon = self.mapBlipIcons[mapblip]
		local combat = mapblip.inCombat
		icon.inCombat = combat and Shared.GetTime()
	end
end

function GUIMinimapFrame.AlertParasite(mapblip)
	for _, self in ipairs(minimapframes) do
		local icon = self.mapBlipIcons[mapblip]
	end
end

-- Also used for when mapblips change type
function GUIMinimapFrame.AlertNewMapBlip(mapblip)
	for _, self in ipairs(minimapframes) do
		local clientIndex = mapblip.clientIndex
		--if mapblip:isa "PlayerMapBlip" then
		--	Log("Player map blip! its client index: %s, the local player's: %s", clientIndex, Client.GetLocalPlayer().clientIndex)
		--end
		local icon
		if self.mapBlipIcons[mapblip] then
			icon = self.mapBlipIcons[mapblip]
		else
			icon = NewItem()
			local freeslots = self.numFreeIconSlots
			local icons = self.icons
			if freeslots == 0 then    -- no free slots, just expand array
				push(icons, icon)
			else
				self.numFreeIconSlots = freeslots - 1
				local freeslot = self.nextFreeIconSlot
				assert(icons[freeslot] == false, "There isn't supposed to be an icon here!")
				icons[freeslot] = icon
				if freeslots > 1 then -- need to find free slot
					for i = freeslot + 1, #icons do -- self.nextFreeIconSlot is always the lowest free icon slot
						if icons[i] == false then
							self.nextFreeIconSlot = i
							break
						end
					end
				else
					self.nextFreeIconSlot = 2^52
				end
			end

			self.mapBlipIcons[mapblip] = icon
			self.minimap:AddChild(icon)
		end

		local type = mapblip.type
		local color = kIconColors[type] or (
			clientIndex == Client.GetLocalPlayer().clientIndex and kSelfTeamColors
			or
			Client.GetIsSteamFriend(GetSteamIdForClientIndex(clientIndex) or 0) and kFriendTeamColors
			or
			kTeamColors
		)[mapblip.team+1]
		local coords = kClassGrid[kMinimapBlipType[mapblip.type]]
		Log("New MapBlip with type %s", kMinimapBlipType[mapblip.type])
		icon:SetSize(self.iconSize)
		icon:SetInheritsParentStencilSettings(true)
		icon:SetColor(color)
		icon:SetTexture(kIconTexture)
		icon:SetLayer(kPlayerIconLayer)
		icon:SetTexturePixelCoordinates(GUIGetSprite(coords[1], coords[2], kIconWidth, kIconHeight))

		icon.mapBlipId = mapblip:GetId()
		Log("Origin: %s", mapblip:GetOrigin())
		Log("Angles: %s", mapblip:GetAngles().yaw)
	end
end

function GUIMinimapFrame:Initialize()
	Log("Initialize() %s", tostring(self))

	push(minimapframes, self)
	
	-- array of icons
	self.icons = {}
	self.mapBlipIcons = setmetatable({}, {__mode = "kv"})
	self.numFreeIconSlots = 0
	self.nextFreeIconSlot = 2^52

	do
		local minimap = NewItem()
		minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
		minimap:SetColor(Color(
			1, 1, 1, CHUDGetOption("minimapalpha", 0.85)
		))
		minimap:SetLayer(kGUILayerMinimap)
		minimap:SetIsVisible(false)
		self.minimap = minimap
	end

	self.zoom = 1
	self:SetBackgroundMode(kModeBig)

	self.updateInterval = 0
end

function GUIMinimapFrame:ShowMap(b)
	self.minimap:SetIsVisible(b)
end

GUIMinimapFrame.SetIsVisible = GUIMinimapFrame.ShowMap

function GUIMinimapFrame:GetIsVisible()
	return self.minimap:GetIsVisible()
end

function GUIMinimapFrame:SetBackgroundMode(mode)
	if self.mode ~= mode then
		self.mode = mode
		self.minimap:SetStencilFunc(mode == kModeZoom and GUIItem.NotEqual or GUIItem.Always)
		self:OnResolutionChanged()
	end
end

-- Also SetDesiredZoom
function GUIMinimapFrame:SetZoom(zoom)
	self.zoom = zoom
end

GUIMinimapFrame.SetDesiredZoom = GUIMinimapFrame.SetZoom

function GUIMinimapFrame:Uninitialize()
	GUI.DestroyItem(self.minimap)
end

function GUIMinimapFrame:Update()
	if self.mode == kModeZoom then
		local player_pos = Client.GetLocalPlayer():GetOrigin()
		local x, y       = PlotToMap(self, player_pos.x, player_pos.z)
		self.minimap:SetPosition(-Vector(x, y, 0))
	end

	local icons = self.icons
	for i = 1, #icons do
		local icon = icons[i]
		if icon ~= false then
			local mapblip = Shared.GetEntity(icon.mapBlipId)
			if mapblip ~= nil then
				local origin = mapblip:GetOrigin()
				origin.x, origin.y = PlotToMap(self, origin.x, origin.z)
				origin.z           = 0
				local size         = icon:GetSize()
				origin.x           = origin.x - size.x/2
				origin.y           = origin.y - size.y/2
				icon:SetPosition(origin)
				icon:SetRotation(Vector(0, 0, mapblip:GetAngles().yaw))
			else -- need to remove icon!
				icons[i] = false
				DestroyItem(icon)
				self.numFreeIconSlots = self.numFreeIconSlots + 1
				self.nextFreeIconSlot = math_min(self.nextFreeIconSlot, i)
			end
		end
	end
end
