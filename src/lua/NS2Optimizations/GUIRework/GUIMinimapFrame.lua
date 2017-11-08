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
Script.Load "lua/Hud/Marine/GUIMarineHUD.lua"

local Shared            = Shared
local Client            = Client
local push              = table.insert
local pop               = table.remove
local find              = table.find
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
local kType             = kMinimapBlipType -- For convenience
local origin            = Vector.origin
local top               = GUIItem.Top
local bottom            = GUIItem.Bottom
local middle            = GUIItem.Middle
local center            = GUIItem.Center
local left              = GUIItem.Left
local right             = GUIItem.Right
local atan2             = math.atan2
local cos               = math.cos
local abs               = math.abs
local pi                = math.pi
local type              = type

local function GUISize(size)
	return math_min(Client.GetScreenWidth(), Client.GetScreenHeight()) * size
end

local offscreen = Vector(-2^20, -2^20, 0)
local function NewItem()
	local i = CreateGraphicItem()
	i:SetAnchor(middle, center)
	i:SetIsVisible(true)
	i:SetPosition(offscreen)
	i:SetInheritsParentStencilSettings(true)
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

GUIMinimap = {}
local GUIMinimap = GUIMinimap
GUIMinimap.kBackgroundWidth = GUIScale(300)
Event.Hook("ResolutionChanged", function()
	GUIMinimap.kBackgroundWidth = GUIScale(300)
end)

for i, v in ipairs {"kModeMini", "kModeZoom", "kModeBig"} do
	GUIMinimapFrame[v] = i
end
local kModeMini = GUIMinimapFrame.kModeMini
local kModeZoom = GUIMinimapFrame.kModeZoom
local kModeBig  = GUIMinimapFrame.kModeBig

-- Player constants
local kPlayerNameFontName    = Fonts.kAgencyFB_Tiny

local ColorForMapBlip
	-- kIconColors takes a kMinimapBlipType and returns a team-agnostic color
	local kIconColors = table.array(#kMinimapBlipType)
	do
		local kWorldColor = Color(0, 1, 0)
		local kWhite      = Color(1, 1, 1)
		for k, v in pairs {
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
	local kScanColor = Color(0.2, 0.8, 1)

	-- Used when kIconColors has no matching entry
	-- Keys are teams, but +1
	local kTeamColors = {
		[0] = Color(1,   1,       1),   -- No team
		[1] = Color(0.9, 0.9,     0.9), -- Ready room
		[2] = Color(0,   216/255, 1),   -- Marines
		[3] = Color(1,   138/255, 0),   -- Aliens
	}
	-- 7 tunnel colors
	local kMaxTunnelColor = kTeamColors[3]
	local kMinTunnelColor = Color(0.7, 128/255, 0)
	local kTunnelColorStep = Color(-0.05, 0, 0)

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

	function ColorForMapBlip(mapblip)
		local type = mapblip.type
		local clientIndex = mapblip.clientIndex
		return kIconColors[type] or (
			clientIndex == Client.GetLocalPlayer().clientIndex and kSelfTeamColors
			or
			Client.GetIsSteamFriend(GetSteamIdForClientIndex(clientIndex) or 0) and kFriendTeamColors
			or
			kTeamColors
		)[mapblip.team+1]
	end

-- Function used for inactive icons
local function ColorInactive(c)
	return Color(
		c.r / 2,
		c.g / 2,
		c.b / 2,
		c.a
	)
end

local kIconLayers = table.array(#kType)
do
	for i = 1, kType.UnsocketedPowerPoint do
		kIconLayers[i] = 0
	end
	for i = kType.Sentry, kType.Door do
		kIconLayers[i] = 1
	end
	for i = kType.SentryBattery, kType.Embryo do
		kIconLayers[i] = 2
	end
	for i = kType.Marine, kType.Scan do
		kIconLayers[i] = 3
	end
end

local kIconSizes = table.array(#kType)
do
	for i = 1, #kType do
		kIconSizes[i] = 0.7
	end
	for k, v in pairs {
		UnsocketedPowerPoint = 0.45,
		Infestation = 2,
		Drifter = 1,
		MAC = 1,
		TechPoint = 1,
		CommandStation = 1,
		Hive = 1,
		BoneWall = 1.5,
		Egg = 0.35,
	} do
		kIconSizes[kMinimapBlipType[k]] = v
	end
end

-- Always present, never moving, practically a part of the map.
local kEternalIcons = table.array(#kType)
do
	for i = 1, #kType do
		kEternalIcons[i] = false
	end
	for _, v in ipairs {
		"TechPoint",
		"ResourcePoint",
		"Door"
	} do
		kEternalIcons[kType[v]] = true
	end
end

-- Not actually used
local kStaticIcons = table.array(#kType)
do
	for i = 1, #kType do
		kStaticIcons[i] = false
	end
	for i = kType.Sentry, kType.BoneWall do
		kStaticIcons[i] = true
	end
end

local kIconTexture = "ui/minimap_blip.dds"
local kIconWidth   = 32
local kIconHeight  = 32

local kLineTexture = "ui/mapconnector_line.dds"

local kMapOrigin_x = Client.minimapExtentOrigin.x
local kMapOrigin_z = Client.minimapExtentOrigin.z
local kMapSize  = Client.minimapExtentScale.x
local kMapScale = kMapSize / 400

local kModeZoom_x_max = GUIMarineHUD.kMinimapBackgroundSize.x / 2 + 24
local kModeZoom_y_max = GUIMarineHUD.kMinimapBackgroundSize.y / 2 + 24

Event.Hook("Console_mapinfo", function()
	Shared.Message(
		"Size: "     .. ToString(Client.minimapExtentScale) ..
		"\nCenter: " .. ToString(Client.minimapExtentOrigin)
	)
end)

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

local function PlotToMap(self, x, z)
	return
		(z - kMapOrigin_z) * self.minimapPlotScale,
		(kMapOrigin_x - x) * self.minimapPlotScale
end

-- Yes, bad naming
local function PositionIcon2(self, origin, icon)
	local size         = icon:GetSize()
	origin.x           = origin.x - size.x/2
	origin.y           = origin.y - size.y/2
	icon:SetPosition(origin)
end

local function PositionIcon(self, origin, icon)
	origin.z, origin.x, origin.y = 0, PlotToMap(self, origin.x, origin.z)
	PositionIcon2(self, origin, icon)
end

function GUIMinimapFrame:GetMinimapItem()
	return self.minimap
end

function GUIMinimapFrame:GetBackground()
	return self.minimap
end

local minimapframes = {}

local function ResetColor(self, mapblip)
	local icon = self.icons:Get(mapblip)
	if icon ~= nil and icon.active ~= mapblip.active then
		icon.active = mapblip.active
		local color = ColorForMapBlip(mapblip)
		icon.color = color
		icon:SetColor(mapblip.active and color or ColorInactive(color))
	end
end

function GUIMinimapFrame.AlertActivity(mapblip)
	Log("AlertActivity(%s:%s)", mapblip, kType[mapblip.type])
	for _, self in ipairs(minimapframes) do
		ResetColor(self, mapblip)
	end
	return true
end

local function AlertConnectorTarget(self, mapblip)
	if mapblip.team ~= Client.GetLocalPlayer():GetTeamNumber() then return end
	local connectors = self.connectors
	local icons      = self.icons
	local target = Shared.GetEntity(mapblip.target) -- also ConnectorMapBlip

	local connector, i = connectors:Get(mapblip)
	if connector ~= nil and target == nil then
		Shared.Message "Destroying connector!"
		connectors:Free(i)
		DestroyItem(connector)
	elseif target ~= nil then
		Shared.Message "Connect!"
		if connector == nil then
			Shared.Message "Connector does not exist"
			connector = NewItem()
			self.connectors:Allocate(mapblip, connector)

			connector:SetTexture(kLineTexture)
			if mapblip.team == 2 then
				Shared.Message "Connector is a tunnel"
				local color = self.nextTunnelColor
				self.nextTunnelColor = color - kTunnelColorStep
				if self.nextTunnelColor.x < kMinTunnelColor.x then -- You can't actually compare vectors
					self.nextTunnelColor = kMaxTunnelColor
				end

				local icon = icons:Get(mapblip)
				icon.color = color
				icon:SetColor(color)
				icon.active = true -- We need to do this so that the color doesn't get overridden, might be unneeded
				connector:SetColor(color)
			else
				Shared.Message "Connector is a phase gate"
				connector:SetColor(kTeamColors[2]) -- Marines
			end
		end

		if mapblip.team == 2 then
			local color = connector:GetColor()
			local icon = icons:Get(target)
			icon.color = color
			icon:SetColor(color)
			icon.active = true -- We need to do this so that the color doesn't get overridden, might be unneeded
		end

		local startpoint = mapblip:GetOrigin()
		local endpoint   = target:GetOrigin()
		startpoint.z, startpoint.x, startpoint.y = 0, PlotToMap(self, startpoint.x, startpoint.z)
		endpoint.z,   endpoint.x,   endpoint.y   = 0, PlotToMap(self, endpoint.x,   endpoint.z)

		startpoint.y, endpoint.y = startpoint.y - 4, endpoint.y - 4

		local offset = startpoint - endpoint
		local length = offset:GetLength()
		connector.length = length

		local normal = offset / length
		local rotation = math.atan2(normal.x, normal.y)
		if rotation < 0 then
			rotation = rotation + pi * 2.5
		else
			rotation = rotation + pi * 0.5
		end

		local size = Vector(length, self.scale * GUIScale(self.mode == kModeMini and 6 or 10), 0)
		connector:SetSize(size)
		connector:SetPosition(startpoint)
		-- reuse size vector
		size.x = -length
		size.y = 0
		connector:SetRotationOffset(size)
		-- reuse size vector
		size.x = 0
		size.z = rotation
		connector:SetRotation(size)
		connector:SetTexturePixelCoordinates(0, 0, length, 16)

		connector.mapBlipId = mapblip:GetId()
		self.minimap:AddChild(connector)
	else
		Shared.Message "Nothing to do."
	end
end

function GUIMinimapFrame.AlertConnectorTarget(mapblip)
	Log("AlertConnectorTarget(%s:%s)", mapblip, kType[mapblip.type])
	for _, self in ipairs(minimapframes) do
		AlertConnectorTarget(self, mapblip)
	end
	return true
end

local function AlertCombat(self, mapblip)
	local icon = self.icons:Get(mapblip)
	if icon == nil then
		return
	elseif mapblip.combatant == false then
		icon:SetColor(icon.color)
	end
end
function GUIMinimapFrame.AlertCombat(mapblip)
	Log("AlertCombat(%s:%s)", mapblip, kType[mapblip.type])
	for _, self in ipairs(minimapframes) do
		AlertCombat(self, mapblip)
	end
	return true
end

local function AlertParasite(self, mapblip)
	local icon = self.icons:Get(mapblip)
	if icon == nil then
		return
	end
	icon.parasited = mapblip.parasited
end

function GUIMinimapFrame.AlertParasite(mapblip)
	Log("AlertParasite(%s:%s)", mapblip, kType[mapblip.type])
	for _, self in ipairs(minimapframes) do
		AlertParasite(self, mapblip)
	end
	return true
end

local function AlertNewMapBlip(self, mapblip)
	local icons = self.icons

	local type = mapblip.type
	local icon = icons:Get(mapblip)
	if icon == nil then
		icon = NewItem()
		if type == kType.Scan then
			self.scans:Allocate(mapblip, icon)
		elseif kEternalIcons[type] then
			push(self.eternals, icon)
		else
			icons:Allocate(mapblip, icon)
		end

		icon:SetTexture(kIconTexture)

		icon.mapBlipId = mapblip:GetId()
		self.minimap:AddChild(icon)
	elseif icon.type == type then
		return
	else
		Shared.Message(ToString(mapblip) .. ".type: " .. kType[icon.type] .. " -> " .. kType[type])
	end

	local coords = kClassGrid[kType[type]]
	icon:SetSize(self.iconSizes[type])
	if kEternalIcons[type] then
		local size = self.iconSizes[type]
		PositionIcon(self, mapblip:GetOrigin(), icon)
	end
	icon:SetLayer(kIconLayers[type])
	icon:SetTexturePixelCoordinates(GUIGetSprite(coords[1], coords[2], kIconWidth, kIconHeight))

	icon.type = type

	ResetColor(self, mapblip)
end

-- Also used for when mapblips change type
function GUIMinimapFrame.AlertNewMapBlip(mapblip)
	Log("AlertNewMapBlip(%s:%s)", mapblip, kType[mapblip.type])
	for _, self in ipairs(minimapframes) do
		AlertNewMapBlip(self, mapblip)
	end
	return true
end

function GUIMinimapFrame:Initialize()
	Log("Initialize() %s", tostring(self))

	push(minimapframes, self)

	-- array of icons
	self.icons      = DynArray(32)
	self.connectors = DynArray(8)
	self.scans      = DynArray(2)
	self.eternals   = table.array(16)

	do
		local minimap = NewItem()
		minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
		minimap:SetColor(Color(
			1, 1, 1, CHUDGetOption("minimapalpha", 0.85)
		))
		minimap:SetLayer(kGUILayerMinimap)
		minimap:SetIsVisible(false)
		minimap:SetInheritsParentStencilSettings(false)
		self.minimap = minimap
	end

	self.zoom = 1
	self.mode = kModeBig
	self.nextTunnelColor = kMaxTunnelColor
	self:OnResolutionChanged()

	local mapblips = Shared.GetEntitiesWithClassname "MapBlip"
	for _, mapblip in ientitylist(mapblips) do
		AlertNewMapBlip(self, mapblip)
		if mapblip:isa "PlayerMapBlip" then
			AlertParasite(self, mapblip)
		elseif mapblip:isa "ConnectorMapBlip" then
			AlertConnectorTarget(self, mapblip)
		end
	end
end

function GUIMinimapFrame:SetBackgroundMode(mode)
	if mode == false or self.mode ~= mode then
		mode = mode or self.mode
		self.mode = mode
		self.minimap:SetStencilFunc(mode == kModeZoom and GUIItem.NotEqual or GUIItem.Always)

		if mode == kModeMini then
			self.minimap:SetAnchor(left, bottom)
		else
			self.minimap:SetAnchor(middle, center)
		end

		local size
		if self.mode == kModeZoom then
			size = GUISize(1) * kMapScale * self.zoom
		elseif self.mode == kModeMini then
			size = GUIScale(300)
			self.minimap:SetPosition(Vector(0, -size, 0))
		else
			size = GUISize(
				--(1-1/((kMapScale+0.25)^3+1))*0.75+0.25
				math_min(1, kMapScale/1.25)
			)
			self.minimap:SetPosition(Vector(size, size, 0) * -0.5)
			--self.scale = kMapScale^-1
		end
		Shared.Message("Minimap size: " .. size)

		self.scale = size / GUISize(0.75) / kMapScale

		local iconSizes = table.array(#kIconSizes)
		for i = 1, #kIconSizes do
			local size = GUIScale(30) * kIconSizes[i] * self.scale
			iconSizes[i] = Vector(size, size, 0)
		end
		self.iconSizes = iconSizes

		for i, icon in self.icons:Iterate() do
			icon:SetSize(self.iconSizes[icon.type])
		end
		for i, connector in self.connectors:Iterate() do
			AlertConnectorTarget(self, Shared.GetEntity(connector.mapBlipId))
		end
		for i, icon in ipairs(self.eternals) do
			icon:SetSize(self.iconSizes[icon.type])
			PositionIcon(self, Shared.GetEntity(icon.mapBlipId):GetOrigin(), icon)
		end

		self.minimap:SetSize(Vector(size, size, 0))
		self.minimapPlotScale = size / kMapSize * 2
	end
end

function GUIMinimapFrame:OnResolutionChanged()
	self:SetBackgroundMode(false)
	--self.playerNameSize     = GUIScale(8)
	--self.playerNameOffset   = GUIScale( Vector(11.5, -5, 0) )
	--self[qPlayerIconInitSize] = Vector(GUIScale(300), GUIScale(300), 0)
end

function GUIMinimapFrame:ShowMap(b)
	self.minimap:SetIsVisible(b)
end

GUIMinimapFrame.SetIsVisible = GUIMinimapFrame.ShowMap

function GUIMinimapFrame:GetIsVisible()
	return self.minimap:GetIsVisible()
end

-- Also SetDesiredZoom
-- Applies only to kModeZoom
function GUIMinimapFrame:SetZoom(zoom)
	self.zoom = zoom
end

GUIMinimapFrame.SetDesiredZoom = GUIMinimapFrame.SetZoom

function GUIMinimapFrame:Uninitialize()
	pop(minimapframes, find(minimapframes, self))
	GUI.DestroyItem(self.minimap)
end

do
	local function UpdateIcon(self, anim, icons, origin, mapblip, icon)
		icon:SetRotation(Vector(0, 0, mapblip:GetAngles().yaw))
		local owner = Shared.GetEntity(mapblip.ownerId)
		-- Owner is relevant; we don't need to rely on the mapblip's inaccurate netvars
		-- Computing atan2 is expensive though, so we don't do it client-side
		if owner ~= nil then
			local porigin = owner:GetOrigin()
			if porigin.z - kMapOrigin_z < kMapSize and porigin.x - kMapOrigin_x < kMapSize then -- Make sure it's within the map
				origin.x, origin.y = PlotToMap(self, porigin.x, porigin.z)
			end
		end
		PositionIcon2(self, origin, icon)
		if mapblip.combatant then
			local color = Color(icon.color)
			color.r = color.r * (2 - anim)
			color.g = color.g * anim
			color.b = color.b * anim
			icon:SetColor(color)
		end
	end

	function GUIMinimapFrame:Update()
		local local_player = Client.GetLocalPlayer()
		local team = local_player:GetTeamNumber()
		local time = Shared.GetTime()

		local icons      = self.icons
		local connectors = self.connectors
		local scans      = self.scans

		local combat_animation = cos(time * 10) * 0.5 + 0.5

		if self.mode == kModeZoom then
			local player_pos = local_player:GetOrigin()
			local x, y       = PlotToMap(self, player_pos.x, player_pos.z)
			self.minimap:SetPosition(-Vector(x, y, 0))
			for i, icon in icons:Iterate() do
				local mapblip = Shared.GetEntity(icon.mapBlipId)
				if icons:Get(mapblip) ~= icon then
					-- Can happen if an entity leaves and reenters relevancy
					-- without the original icon being processed.
					-- Also handles removing icons for non-existent mapblips.
					DestroyItem(icon)
					icons:Free(i)
				else
					local origin = mapblip:GetOrigin()
					origin.z, origin.x, origin.y = 0, PlotToMap(self, origin.x, origin.z)
					-- Don't do this if it's too far away
					if abs(origin.x - x) < kModeZoom_x_max and abs(origin.y - y) < kModeZoom_y_max then
						UpdateIcon(self, combat_animation, icons, origin, mapblip, icon)
					end
				end
			end
		else
			for i, icon in icons:Iterate() do
				local mapblip = Shared.GetEntity(icon.mapBlipId)
				if icons:Get(mapblip) ~= icon then
					-- Can happen if an entity leaves and reenters relevancy
					-- without the original icon being processed.
					-- Also handles removing icons for non-existent mapblips.
					DestroyItem(icon)
					icons:Free(i)
				else
					local origin = mapblip:GetOrigin()
					origin.z, origin.x, origin.y = 0, PlotToMap(self, origin.x, origin.z)
					UpdateIcon(self, time, icons, origin, mapblip, icon)
				end
			end
		end

		if team == 1 then
			local animation = time % 1 * -64
			for i, connector in connectors:Iterate() do
				local mapblip = Shared.GetEntity(connector.mapBlipId)
				if connectors:Get(mapblip) ~= connector then
					DestroyItem(connector)
					connectors:Free(i)
				else
					connector:SetTexturePixelCoordinates(animation, 16, animation + connector.length, 32)
				end
			end
		else
			for i, connector in connectors:Iterate() do
				local mapblip = Shared.GetEntity(connector.mapBlipId)
				if connectors:Get(mapblip) ~= connector then
					DestroyItem(connector)
					connectors:Free(i)
				end
			end
		end

		-- Aliens don't have scans
		if team == 1 then
			local animation = time / 2 % 1
			local size = Vector(1 + animation * 9, 1 + animation * 9, 0)
			local color = Color(kScanColor.r, kScanColor.g, kScanColor.b, (1 - animation)^2)
			for i, scan in scans:Iterate() do
				local mapblip = Shared.GetEntity(scan.mapBlipId)
				if scans:Get(mapblip) ~= scan then
					DestroyItem(scan)
					scans:Free(i)
				else
					scan:SetSize(size)
					scan:SetColor(color)
					PositionIcon(self, mapblip:GetOrigin(), scan)
				end
			end
		end
	end
end

function GUIMinimapFrame:SetButtonsScript() end
