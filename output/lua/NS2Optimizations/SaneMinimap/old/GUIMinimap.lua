-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\GUIMinimap.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages displaying the minimap and icons on the minimap.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIMinimapConnection.lua")
Script.Load("lua/MinimapMappableMixin.lua")

local Shared = Shared
local Client = Client
local table_insert = table.insert
local table_remove = table.remove

class 'GUIMinimap' (GUIScript)

-- how often we update for each activity level
local kBlipActivityUpdateInterval						= {}
kBlipActivityUpdateInterval[kMinimapActivity.Static]	= -1
kBlipActivityUpdateInterval[kMinimapActivity.Low]		= 0
kBlipActivityUpdateInterval[kMinimapActivity.Medium]	= 4
kBlipActivityUpdateInterval[kMinimapActivity.High]		= 9

-- allow update rate to be controlled by console (minimap_rate). 0 = full rate
GUIMinimap.kUpdateIntervalMultipler						= 1


-- update the "other stuff" at 25Hz 
local kMiscUpdateInterval								= 0.04

local kPlayerNameLayer									= 7
local kPlayerNameFontSize								= 8
local kPlayerNameFontName								= Fonts.kAgencyFB_Tiny
local kPlayerNameOffset									= Vector(11.5, -5, 0)
local kPlayerNameColorAlien								= Color(1, 189/255, 111/255, 1)
local kPlayerNameColorMarine							= Color(164/255, 241/255, 1, 1)

local kBlipSize											= GUIScale(30)

local kWaypointColor									= Color(1, 1, 1, 1)
local kEtherealGateColor								= Color(0.8, 0.6, 1, 1)
local kOverviewColor									= Color(1, 1, 1, 0.85)

-- colors are defined in the dds
local kTeamColors										= { }
kTeamColors[kMinimapBlipTeam.Friendly]					= Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Enemy]						= Color(1, 0, 0, 1)
kTeamColors[kMinimapBlipTeam.Neutral]					= Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Alien]						= Color(1, 138/255, 0, 1)
kTeamColors[kMinimapBlipTeam.Marine]					= Color(0, 216/255, 1, 1)
-- steam friend colors
kTeamColors[kMinimapBlipTeam.FriendAlien]				= Color(1, 189/255, 111/255, 1)
kTeamColors[kMinimapBlipTeam.FriendMarine]				= Color(164/255, 241/255, 1, 1)

kTeamColors[kMinimapBlipTeam.InactiveAlien]				= Color(85/255, 46/255, 0, 1, 1)
kTeamColors[kMinimapBlipTeam.InactiveMarine]			= Color(0, 72/255, 85/255, 1)

local kPowerNodeColor									= Color(1, 1, 0.7, 1)
local kDestroyedPowerNodeColor							= Color(0.5, 0.5, 0.35, 1)

local kDrifterColor										= Color(1, 1, 0, 1)
local kMACColor											= Color(0, 1, 0.2, 1)

local kBlinkInterval									= 1

local kScanColor										= Color(0.2, 0.8, 1, 1)
local kScanAnimDuration									= 2

local kFullColor										= Color(1,1,1,1)

local kInfestationColor									= { }
kInfestationColor[kMinimapBlipTeam.Friendly]			= Color(1, 1, 0, .25)
kInfestationColor[kMinimapBlipTeam.Enemy]				= Color(1, 0.67, 0.06, .25)
kInfestationColor[kMinimapBlipTeam.Neutral]				= Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.Alien]				= Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.Marine]				= Color(0.2, 0.7, 0.2, .25)
kInfestationColor[kMinimapBlipTeam.InactiveAlien]		= Color(0.2 /3, 0.7/3, 0.2/3, .25)
kInfestationColor[kMinimapBlipTeam.InactiveMarine]		= Color(0.2/3, 0.7/3, 0.2/3, .25)

local kInfestationDyingColor							= { }
kInfestationDyingColor[kMinimapBlipTeam.Friendly]		= Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Enemy]			= Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Neutral]		= Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Alien]			= Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.Marine]			= Color(1, 0.2, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.InactiveAlien]	= Color(1/3, 0.2/3, 0, .25)
kInfestationDyingColor[kMinimapBlipTeam.InactiveMarine] = Color(1/3, 0.2/3, 0, .25)

local kShrinkingArrowInitSize

local kIconFileName										= "ui/minimap_blip.dds"

local kLargePlayerArrowFileName							= PrecacheAsset("ui/minimap_largeplayerarrow.dds")

local kCommanderPingMinimapSize

local kIconWidth										= 32
local kIconHeight										= 32

local kInfestationBlipsLayer							= 0
local kBackgroundBlipsLayer								= 1
local kStaticBlipsLayer									= 2
local kDynamicBlipsLayer								= 3
local kLocationNameLayer								= 4
local kPingLayer										= 5
local kPlayerIconLayer									= 6

local kBlipTexture										= "ui/blip.dds"

local kBlipTextureCoordinates							= { }
kBlipTextureCoordinates[kAlertType.Attack]				= { X1 = 0, Y1 = 0, X2 = 64, Y2 = 64 }

local kAttackBlipMinSize
local kAttackBlipMaxSize
local kAttackBlipPulseSpeed								= 6
local kAttackBlipTime									= 5
local kAttackBlipFadeInTime								= 4.5
local kAttackBlipFadeOutTime							= 1

local kLocationFontSize									= 8
local kLocationFontName									= Fonts.kAgencyFB_Smaller_Bordered

local kPlayerIconSize

local kBlipColorType									= enum( { 'Team', 'Infestation', 'InfestationDying', 'Waypoint', 'PowerPoint', 'DestroyedPowerPoint', 'Scan', 'Drifter', 'MAC', 'EtherealGate', 'HighlightWorld', 'FullColor' } )
local kBlipSizeType										= enum( { 'Normal', 'TechPoint', 'Infestation', 'Scan', 'Egg', 'Worker', 'EtherealGate', 'HighlightWorld', 'Waypoint', 'BoneWall', 'UnpoweredPowerPoint' } )

local kBlipInfo											= {}
kBlipInfo[kMinimapBlipType.TechPoint]					= { kBlipColorType.HighlightWorld, kBlipSizeType.TechPoint, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.ResourcePoint]				= { kBlipColorType.HighlightWorld, kBlipSizeType.Normal, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.Scan]						= { kBlipColorType.Scan, kBlipSizeType.Scan, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.CommandStation]				= { kBlipColorType.Team, kBlipSizeType.TechPoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.Hive]						= { kBlipColorType.Team, kBlipSizeType.TechPoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.Egg]							= { kBlipColorType.Team, kBlipSizeType.Egg, kStaticBlipsLayer, "Infestation" }
kBlipInfo[kMinimapBlipType.PowerPoint]					= { kBlipColorType.PowerPoint, kBlipSizeType.Normal, kStaticBlipsLayer, "PowerPoint" }
kBlipInfo[kMinimapBlipType.DestroyedPowerPoint]			= { kBlipColorType.DestroyedPowerPoint, kBlipSizeType.Normal, kStaticBlipsLayer, "PowerPoint" }
kBlipInfo[kMinimapBlipType.UnsocketedPowerPoint]		= { kBlipColorType.FullColor, kBlipSizeType.UnpoweredPowerPoint, kStaticBlipsLayer, "UnsocketedPowerPoint" }
kBlipInfo[kMinimapBlipType.BlueprintPowerPoint]			= { kBlipColorType.Team, kBlipSizeType.UnpoweredPowerPoint, kStaticBlipsLayer, "UnsocketedPowerPoint" }
kBlipInfo[kMinimapBlipType.Infestation]					= { kBlipColorType.Infestation, kBlipSizeType.Infestation, kInfestationBlipsLayer, "Infestation" }
kBlipInfo[kMinimapBlipType.InfestationDying]			= { kBlipColorType.InfestationDying, kBlipSizeType.Infestation, kInfestationBlipsLayer, "Infestation" }
kBlipInfo[kMinimapBlipType.MoveOrder]					= { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.AttackOrder]					= { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.BuildOrder]					= { kBlipColorType.Waypoint, kBlipSizeType.Waypoint, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.Drifter]						= { kBlipColorType.Drifter, kBlipSizeType.Worker, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.MAC]							= { kBlipColorType.MAC, kBlipSizeType.Worker, kStaticBlipsLayer }
kBlipInfo[kMinimapBlipType.EtherealGate]				= { kBlipColorType.EtherealGate, kBlipSizeType.EtherealGate, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.HighlightWorld]				= { kBlipColorType.HighlightWorld, kBlipSizeType.HighlightWorld, kBackgroundBlipsLayer }
kBlipInfo[kMinimapBlipType.BoneWall]					= { kBlipColorType.FullColor, kBlipSizeType.BoneWall, kBackgroundBlipsLayer }

local keyIcon         = newproxy()
local icons   = {}
for i = 1, #primary_table do
	icons[i]   = {i = 1}
end

local kClassToGrid = BuildClassToGrid()

local instance
function GetMinimap()
	return instance
end

GUIMinimap.kBackgroundWidth = GUIScale(300)
GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundWidth

local function UpdateItemsGUIScale(self)
	kBlipSize = GUIScale(30)
	kShrinkingArrowInitSize = Vector(kBlipSize * 10, kBlipSize * 10, 0)
	kAttackBlipMinSize = Vector(GUIScale(25), GUIScale(25), 0)
	kAttackBlipMaxSize = Vector(GUIScale(100), GUIScale(100), 0)

	kCommanderPingMinimapSize = GUIScale(Vector(80, 80, 0))
	
	kPlayerIconSize = Vector(kBlipSize, kBlipSize, 0)
	self.playerIcon:SetSize(kPlayerIconSize)
	
	GUIMinimap.kBackgroundWidth = GUIScale(300)
	GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundWidth
	self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
	
	local scale = self:GetScale()
	self:SetScale(scale)
	
	local size = Vector(GUIMinimap.kBackgroundWidth * scale, GUIMinimap.kBackgroundHeight * scale, 0)
	self.minimap:SetSize(size)
	self.minimap:SetPosition(size * -0.5)
	
	for _,v in pairs(self.nameTagMap) do
		GUI.DestroyItem(v)
	end
	self.nameTagMap = {}
end

function GUIMinimap:PlotToMap(posX, posZ)

	local plottedX = (posX + self.plotToMapConstX) * self.plotToMapLinX
	local plottedY = (posZ + self.plotToMapConstY) * self.plotToMapLinY
	
	-- The world space is oriented differently from the GUI space, adjust for that here.
	-- Return 0 as the third parameter so the results can easily be added to a Vector.
	return plottedY, -plottedX, 0
	
end

local gLocationItems = {}

function GUIMinimap:OnResolutionChanged(oldX, oldY, newX, newY)
	UpdateItemsGUIScale(self)
end

function GUIMinimap:Initialize()
	assert(not instance)
	instance = self
	
	-- we update the minimap at full rate, but internally we spread out the
	-- actual load of updating the map so we only do a little bit of work each frame
	self.updateInterval = kUpdateIntervalFull
   
	self.nextMiscUpdateInterval = 0
	self.nextActivityUpdateTime = 0
  
	local player = Client.GetLocalPlayer()
	self.showPlayerNames = false
	self.spectating = false
	self.clientIndex = player:GetClientIndex()
	-- individual update rate multiplier. Set to run at full rate (all intervals are multipled by zero). Set to 1 to run 
	-- at CPU saving rate
	self.updateIntervalMultipler = 0
	-- the rest is untouched in rewrite
  
	self.locationItems = { }
	self.timeMapOpened = 0
	self.stencilFunc = GUIItem.Always
	self.iconFileName = kIconFileName
	self.inUseStaticBlipCount = 0
	self.reuseDynamicBlips = { }
	self.inuseDynamicBlips = { }
	self.scanColor = Color(kScanColor.r, kScanColor.g, kScanColor.b, kScanColor.a)
	self.scanSize = Vector(0, 0, 0)
	self.highlightWorldColor = Color(0, 1, 0, 1)
	self.highlightWorldSize = Vector(0, 0, 0)
	self.etherealGateColor = Color(kEtherealGateColor.r, kEtherealGateColor.g, kEtherealGateColor.b, kEtherealGateColor.a)
	self.blipSizeTable = { }
	self.minimapConnections = { }

	self.playerNameItems = {}
	self.playerNameItemsLookup = {}
	
	self:SetScale(1) -- Compute plot to map transformation
	self:SetBlipScale(1) -- Compute blipSizeTable
	self.blipSizeTable[kBlipSizeType.Scan] = self.scanSize
	self.blipSizeTable[kBlipSizeType.HighlightWorld] = self.highlightWorldSize
	
	-- Initialize blip info lookup table
	local blipInfoTable = {}
	for blipType, _ in ipairs(kMinimapBlipType) do
		local blipInfo = kBlipInfo[blipType]
		local iconCol, iconRow = GetSpriteGridByClass((blipInfo and blipInfo[4]) or EnumToString(kMinimapBlipType, blipType), kClassToGrid)
		local texCoords = table.pack(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
		if blipInfo then
		  blipInfoTable[blipType] = { texCoords, blipInfo[1], blipInfo[2], blipInfo[3] }
		else
		  blipInfoTable[blipType] = { texCoords, kBlipColorType.Team, kBlipSizeType.Normal, kStaticBlipsLayer }
		end
	end
	self.blipInfoTable = blipInfoTable
	
	-- Generate blip color lookup table
	local blipColorTable = {}
	for blipTeam, _ in ipairs(kMinimapBlipTeam) do
		local colorTable = {}
		colorTable[kBlipColorType.Team] = kTeamColors[blipTeam]
		colorTable[kBlipColorType.Infestation] = kInfestationColor[blipTeam]
		colorTable[kBlipColorType.InfestationDying] = kInfestationDyingColor[blipTeam]
		colorTable[kBlipColorType.Waypoint] = kWaypointColor
		colorTable[kBlipColorType.PowerPoint] = kPowerNodeColor
		colorTable[kBlipColorType.DestroyedPowerPoint] = kDestroyedPowerNodeColor
		colorTable[kBlipColorType.Scan] = self.scanColor
		colorTable[kBlipColorType.HighlightWorld] = self.highlightWorldColor
		colorTable[kBlipColorType.Drifter] = kDrifterColor
		colorTable[kBlipColorType.MAC] = kMACColor
		colorTable[kBlipColorType.EtherealGate] = self.etherealGateColor
		colorTable[kBlipColorType.FullColor] = kFullColor
		blipColorTable[blipTeam] = colorTable
	end
	self.blipColorTable = blipColorTable

	self:InitializeBackground()
	
	self.minimap = GUIManager:CreateGraphicItem()
	self.minimap:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.minimap:SetPosition(Vector(0, 0, 0))
	self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
	self.minimap:SetColor(kOverviewColor)
	self.background:AddChild(self.minimap)
	
	-- Used for commander / spectator.
	self:InitializeCameraLines()
	-- Used for normal players.
	self:InitializePlayerIcon()
	
	-- initialize commander ping
	self.commanderPing = GUICreateCommanderPing()
	self.commanderPing.Frame:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.commanderPing.Frame:SetLayer(kPingLayer)
	self.minimap:AddChild(self.commanderPing.Frame)
	
	UpdateItemsGUIScale(self)
end

function GUIMinimap:InitializeBackground()

	self.background = GUIManager:CreateGraphicItem()
	self.background:SetPosition(Vector(0, 0, 0))
	self.background:SetColor(Color(1, 1, 1, 0))
	self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.background:SetLayer(kGUILayerMinimap)
	
	-- Non-commander players assume the map isn't visible by default.
	if not PlayerUI_IsACommander() then
		self.background:SetIsVisible(false)
	end

end

function GUIMinimap:InitializeCameraLines()

	self.cameraLines = GUIManager:CreateLinesItem()
	self.cameraLines:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.cameraLines:SetLayer(kPlayerIconLayer)
	self.minimap:AddChild(self.cameraLines)
	
end

function GUIMinimap:InitializePlayerIcon()
	
	self.playerIcon = GUIManager:CreateGraphicItem()
	self.playerIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.playerIcon:SetTexture(self.iconFileName)
	iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass(), kClassToGrid)
	self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
	self.playerIcon:SetIsVisible(false)
	self.playerIcon:SetLayer(kPlayerIconLayer)
	self.minimap:AddChild(self.playerIcon)

	self.playerShrinkingArrow = GUIManager:CreateGraphicItem()
	self.playerShrinkingArrow:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.playerShrinkingArrow:SetTexture(kLargePlayerArrowFileName)
	self.playerShrinkingArrow:SetLayer(kPlayerIconLayer)
	self.playerIcon:AddChild(self.playerShrinkingArrow)
	
end

local function SetupLocationTextItem(item)

	item:SetScale(GetScaledVector())
	item:SetFontIsBold(false)
	item:SetFontName(kLocationFontName)
	item:SetAnchor(GUIItem.Middle, GUIItem.Center)
	item:SetTextAlignmentX(GUIItem.Align_Center)
	item:SetTextAlignmentY(GUIItem.Align_Center)
	item:SetLayer(kLocationNameLayer)

end

local function SetLocationTextPosition( item, mapPos )

	item.text:SetPosition( Vector(mapPos.x, mapPos.y, 0) )
	local offset = 1

end

function OnCommandSetMapLocationColor(r, g, b, a)

	if gLocationItems ~= nil then

		for _, locationItem in ipairs(gLocationItems) do
			locationItem.text:SetColor( Color(tonumber(r)/255, tonumber(g)/255, tonumber(b)/255, tonumber(a)/255) )
		end

	end

end


function GUIMinimap:InitializeLocationNames()

	self:UninitializeLocationNames()
	local locationData = PlayerUI_GetLocationData()
	
	-- Average the position of same named locations so they don't display
	-- multiple times.
	local multipleLocationsData = { }
	for i, location in ipairs(locationData) do
	
		-- Filter out the ready room.
		if location.Name ~= "Ready Room" then
		
			local locationTable = multipleLocationsData[location.Name]
			if locationTable == nil then
			
				locationTable = { }
				multipleLocationsData[location.Name] = locationTable
				
			end
			table.insert(locationTable, location.Origin)
			
		end
		
	end
	
	local uniqueLocationsData = { }
	for name, origins in pairs(multipleLocationsData) do
	
		local averageOrigin = Vector(0, 0, 0)
		table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
		table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / table.count(origins) })
		
	end
	
	for i, location in ipairs(uniqueLocationsData) do

		local posX, posY = self:PlotToMap(location.Origin.x, location.Origin.z)

		-- Locations only supported on the big mode.
		local locationText = GUIManager:CreateTextItem()
		SetupLocationTextItem(locationText)
		locationText:SetColor(Color(1.0, 1.0, 1.0, 0.65))
		locationText:SetText(location.Name)
		locationText:SetPosition( Vector(posX, posY, 0) )

		self.minimap:AddChild(locationText)

		local locationItem = {text = locationText, origin = location.Origin}
		table.insert(self.locationItems, locationItem)

	end

	gLocationItems = self.locationItems

end

function GUIMinimap:UninitializeLocationNames()

	for _, locationItem in ipairs(self.locationItems) do
		GUI.DestroyItem(locationItem.text)
	end
	
	self.locationItems = {}

end

function GUIMinimap:Uninitialize()

	if self.background then
		GUI.DestroyItem(self.background)
		self.background = nil
	end
	
end

local function UpdatePlayerIcon(self)
	
	if PlayerUI_IsOverhead() and not PlayerUI_IsCameraAnimated() then -- Handle overhead viewplane points

		self.playerIcon:SetIsVisible(false)
		self.cameraLines:SetIsVisible(true)
		
		local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = OverheadUI_ViewFarPlanePoints()
		if topLeftPoint == nil then
			return
		end
		
		topLeftPoint = Vector(self:PlotToMap(topLeftPoint.x, topLeftPoint.z))
		topRightPoint = Vector(self:PlotToMap(topRightPoint.x, topRightPoint.z))
		bottomLeftPoint = Vector(self:PlotToMap(bottomLeftPoint.x, bottomLeftPoint.z))
		bottomRightPoint = Vector(self:PlotToMap(bottomRightPoint.x, bottomRightPoint.z))
		
		self.cameraLines:ClearLines()
		local lineColor = Color(1, 1, 1, 1)
		self.cameraLines:AddLine(topLeftPoint, topRightPoint, lineColor)
		self.cameraLines:AddLine(topRightPoint, bottomRightPoint, lineColor)
		self.cameraLines:AddLine(bottomRightPoint, bottomLeftPoint, lineColor)
		self.cameraLines:AddLine(bottomLeftPoint, topLeftPoint, lineColor)

	elseif PlayerUI_IsAReadyRoomPlayer() then
	
		-- No icons for ready room players.
		self.cameraLines:SetIsVisible(false)
		self.playerIcon:SetIsVisible(false)

	else
	
		-- Draw a player icon representing this player's position.
		local playerOrigin = PlayerUI_GetPositionOnMinimap()
		local playerRotation = PlayerUI_GetMinimapPlayerDirection()

		local posX, posY = self:PlotToMap(playerOrigin.x, playerOrigin.z)

		self.cameraLines:SetIsVisible(false)
		self.playerIcon:SetIsVisible(true)
		
		local playerIconColor = self.playerIconColor
		if playerIconColor ~= nil then
			playerIconColor = Color(playerIconColor.r, playerIconColor.g, playerIconColor.b, playerIconColor.a)
		elseif PlayerUI_IsOnMarineTeam() then
			playerIconColor = Color(kMarineTeamColorFloat)
		elseif PlayerUI_IsOnAlienTeam() then
			playerIconColor = Color(kAlienTeamColorFloat)
		else
			playerIconColor = Color(1, 1, 1, 1)
		end

		local animFraction = 1 - Clamp((Shared.GetTime() - self.timeMapOpened) / 0.5, 0, 1)
		playerIconColor.r = playerIconColor.r + animFraction
		playerIconColor.g = playerIconColor.g + animFraction
		playerIconColor.b = playerIconColor.b + animFraction
		playerIconColor.a = playerIconColor.a + animFraction
		
		local blipScale = self.blipScale
		local overLaySize = kShrinkingArrowInitSize * (animFraction * blipScale)
		local playerIconSize = Vector(kBlipSize * blipScale, kBlipSize * blipScale, 0)
		
		self.playerShrinkingArrow:SetSize(overLaySize)
		self.playerShrinkingArrow:SetPosition(-overLaySize * 0.5)
		local shrinkerColor = Color(playerIconColor.r, playerIconColor.g, playerIconColor.b, 0.35)
		self.playerShrinkingArrow:SetColor(shrinkerColor)

		self.playerIcon:SetSize(playerIconSize)		   
		self.playerIcon:SetColor(playerIconColor)

		-- move the background instead of the playericon in zoomed mode
		if self.moveBackgroundMode then
			local size = self.minimap:GetSize()
			local pos = Vector(-posX + size.x * -0.5, -posY + size.y * -0.5, 0)
			self.background:SetPosition(pos)
		end

		posX = posX - playerIconSize.x * 0.5
		posY = posY - playerIconSize.y * 0.5
		
		self.playerIcon:SetPosition(Vector(posX, posY, 0))
		
		local rotation = Vector(0, 0, playerRotation)
		
		self.playerIcon:SetRotation(rotation)
		self.playerShrinkingArrow:SetRotation(rotation)

		local playerClass = PlayerUI_GetPlayerClass()
		if self.playerClass ~= playerClass then

			local iconCol, iconRow = GetSpriteGridByClass(playerClass, kClassToGrid)
			self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
			self.playerClass = playerClass

		end

	end
	
end

function GUIMinimap:LargeMapIsVisible()
	return self.background:GetIsVisible() and self.comMode == GUIMinimapFrame.kModeBig
end 



local function CreateNewNameTag(self)
	local nameTag = GUIManager:CreateTextItem()

	nameTag:SetFontSize(kPlayerNameFontSize)
	nameTag:SetFontIsBold(false)
	nameTag:SetFontName(kPlayerNameFontName)
	nameTag:SetInheritsParentScaling(false)
	nameTag:SetScale(GetScaledVector())
	GUIMakeFontScale(nameTag)
	nameTag:SetAnchor(GUIItem.Middle, GUIItem.Center)
	nameTag:SetTextAlignmentX(GUIItem.Align_Center)
	nameTag:SetTextAlignmentY(GUIItem.Align_Center)
	nameTag:SetLayer(kPlayerNameLayer)
	nameTag:SetIsVisible(false)
	nameTag.lastUsed = Shared.GetTime()

	self.minimap:AddChild(nameTag)

	return nameTag
end

local GetFreeNameTag, HideUnusedNameTags, GetNameTag
do
	local usedNameTags = {}
	local freeNameTags = {}
	local keyTag       = newproxy()

	function GetFreeNameTag(self, blip)
		local tag = table_remove(freeNameTags)

		if not tag then
			tag = CreateNewNameTag(self)
			tag.blip = clientIndex
			table_insert(nameTags, tag)
		end

		blip[keyTag] = tag
		return tag
	end

	function HideUnusedNameTags(self)
		local now = Shared.GetTime()
		local nameTag = nil
		for _,v in pairs(self.nameTagMap) do
			if now - v.lastUsed > kNameTagReuseTimeout then
				v:SetIsVisible(false)
			end
		end
		
	end

	-- Get the nameTag guiItem for the client
	function GetNameTag(self, clientIndex)
		local nameTag = self.nameTagMap[clientIndex]
		
		if not nameTag then
			nameTag = GetFreeNameTag(self, clientIndex)
		end
		
		return nameTag
		
	end
end

local namePos = Vector(0, 0, 0)
function GUIMinimap:DrawMinimapName(item, mapBlip)
  
	if self.showPlayerNames and clientIndex > 0 and (self.spectating or mapBlip.team == Client.GetLocalPlayer():GetTeamNumber()) then
		
		local record = Scoreboard_GetPlayerRecord(clientIndex)

		if record and record.Name then
		  
			local nameTag = GetNameTag(self, clientIndex)
			
			nameTag:SetIsVisible(true)	  
			nameTag:SetText(record.Name)
			nameTag.lastUsed = Shared.GetTime()
			
			local nameColor = Color(1, 1, 1)
			if isParasited then
				nameColor.b = 0
			elseif self.spectating then
				if MinimapMappableMixin.OnSameMinimapBlipTeam(kMinimapBlipTeam.Marine, blipTeam) then
					nameColor = kPlayerNameColorMarine
				else
					nameColor = kPlayerNameColorAlien
				end
			end

			nameTag:SetColor(nameColor)

			namePos = item:GetPosition() + GUIScale(kPlayerNameOffset)
			nameTag:SetPosition(namePos)

		end

	end

end

local CreateIcon, CreateIconForKey, FreeIcon
do
	local freeIcons = {}

	function CreateIcon(_)

		local icon = table_remove(freeIcons)
		if not icon then
			icon = GUIManager:CreateGraphicItem()
			icon:SetAnchor(GUIItem.Middle, GUIItem.Center)
			icon:SetIsVisible(false)
			instance.minimap:AddChild(icon)
		end

		return icon
	end
	_G.CreateIcon = CreateIcon

	function CreateIconForKey(self, key)
		local icon = CreateIcon(self)
		icon.key = key
		return icon
	end

	function FreeIcon(_, icon)
		icon:SetIsVisible(false)
		table_insert(freeIcons, icon)
	end
	_G.FreeIcon = FreeIcon
end

function AddIcon(entity)
	icon            = CreateIcon(self)
	icon.entity     = entity
	entity[keyIcon] = icon
	entity:InitMinimapItem(instance, icon)
	local activity  = entity:UpdateMinimapActivity(instance, icon)
	table_insert(icons[activity], icon)
end

function RemoveIcon(entity)
end

local min = math.min

local function UpdateActivityBlips_While(self, deltaTime, activity)
	local data  = icons[activity]
	local start = data.i
	local stop  = data.i+kBlipActivityUpdateInterval[activity]
	if stop > #data then
		stop = stop - #data
	end
	for i = start, min(#data, stop) do
		local icon   = data[i]
		local entity = icon.entity
		entity:UpdateMinimapItem(self, icon)
	end
	for i = 1, stop - #data do
		local icon   = data[i]
		local entity = icon.entity
		entity:UpdateMinimapItem(self, icon)
	end
	data.i = stop+1
end

local function UpdateScansAndHighlight(self)
	local blipSize = self.blipSizeTable[kBlipSizeType.Normal]
	
	-- Update scan blip size and color.
	do 
		local scanAnimFraction = (Shared.GetTime() % kScanAnimDuration) / kScanAnimDuration		   
		local scanBlipScale = 1.0 + scanAnimFraction * 9.0 -- size goes from 1.0 to 10.0
		local scanAnimAlpha = 1 - scanAnimFraction
		scanAnimAlpha = scanAnimAlpha * scanAnimAlpha
		
		self.scanColor.a = scanAnimAlpha
		self.scanSize.x = blipSize.x * scanBlipScale -- do not change blipSizeTable reference
		self.scanSize.y = blipSize.y * scanBlipScale -- do not change blipSizeTable reference
	end
	
	local highlightPos, highlightTime = GetHighlightPosition()
	if highlightTime then
	
		local createAnimFraction = 1 - Clamp((Shared.GetTime() - highlightTime) / 1.5, 0, 1)
		local sizeAnim = (1 + math.sin(Shared.GetTime() * 6)) * 0.25 + 2
	
		local blipScale = createAnimFraction * 15 + sizeAnim

		self.highlightWorldSize.x = blipSize.x * blipScale
		self.highlightWorldSize.y = blipSize.y * blipScale
		
		self.highlightWorldColor.a = 0.7 + 0.2 * math.sin(Shared.GetTime() * 5) + createAnimFraction
	
	end
	
	local etherealGateAnimFraction = 0.25 + (1 + math.sin(Shared.GetTime() * 10)) * 0.5 * 0.75
	self.etherealGateColor.a = etherealGateAnimFraction
	
	self.blipSizeTable[kBlipSizeType.Scan] = self.scanSize
	self.blipSizeTable[kBlipSizeType.HighlightWorld] = self.highlightWorldSize
	
end

local function GetFreeDynamicBlip(self, xPos, yPos, blipType)

	local returnBlip
	if table.count(self.reuseDynamicBlips) > 0 then
	
		returnBlip = table.remove(self.reuseDynamicBlips)
		table.insert(self.inuseDynamicBlips, returnBlip)
		
	else
		
		local returnBlipItem = GUIManager:CreateGraphicItem()
		returnBlipItem:SetLayer(kDynamicBlipsLayer) -- Make sure these draw a layer above the minimap so they are on top.
		returnBlipItem:SetTexture(kBlipTexture)
		returnBlipItem:SetBlendTechnique(GUIItem.Add)
		returnBlipItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
		self.minimap:AddChild(returnBlipItem)
		
		returnBlip = { Item = returnBlipItem }
		table.insert(self.inuseDynamicBlips, returnBlip)
		
	end
	
	returnBlip.X = xPos
	returnBlip.Y = yPos
	returnBlip.Type = blipType
	
	local returnBlipItem = returnBlip.Item
	
	returnBlipItem:SetIsVisible(true)
	returnBlipItem:SetColor(Color(1, 1, 1, 1))
	returnBlipItem:SetPosition(Vector(self:PlotToMap(xPos, yPos)))
	GUISetTextureCoordinatesTable(returnBlipItem, kBlipTextureCoordinates[blipType])
	returnBlipItem:SetStencilFunc(self.stencilFunc)
	
	return returnBlip
	
end

-- Initialize a minimap item (icon) from a blipType
function GUIMinimap:InitMinimapIcon(item, blipType, blipTeam)
  
	local blipInfo = self.blipInfoTable[blipType]
	local texCoords, colorType, sizeType, layer = unpack(blipInfo)
	
	item.blipType = blipType
	item.blipSizeType = sizeType
	item.blipSize = self.blipSizeTable[item.blipSizeType]
	item.blipTeam = blipTeam	  
	item.blipColor = self.blipColorTable[item.blipTeam][colorType]
	
	item:SetLayer(layer)
	item:SetTexturePixelCoordinates(unpack(texCoords))
	item:SetSize(item.blipSize)
	item:SetColor(item.blipColor)
	item:SetStencilFunc(self.stencilFunc)
	item:SetTexture(self.iconFileName)
	item:SetIsVisible(true)
	
	return item
end

local _blipPos = Vector(0,0,0) -- avoid GC
local function UpdateBlipPosition(item, origin)
	if origin ~= item.prevBlipOrigin then
		item.prevBlipOrigin = origin
		local xPos, yPos = self:PlotToMap(origin.x, origin.z)
		_blipPos.x = xPos - item.blipSize.x * 0.5
		_blipPos.y = yPos - item.blipSize.y * 0.5
		item:SetPosition(_blipPos)
	end
end

local UpdateLocalBlips
do
	local spawnBlip
	local highlightBlip
	-- update the list of non-entity related mapblips
	function UpdateLocalBlips(self)
		if spawnBlip == nil then
			spawnBlip = self:InitMinimapIcon(CreateIconForKey(self, "spawn"), kMinimapBlipType.MoveOrder, kMinimapBlipTeam.Friendly)
			spawnBlip:SetIsVisible(false)
		end

		local spawn_pos = GetDesiredSpawnPosition()
		if GetPlayerIsSpawning() and spawn_pos then
			spawnBlip:SetIsVisible(true)
			UpdateBlipPosition(self, spawnBlip, spawn_pos)
		end

		if highlightBlip == nil then
			highlightBlip = self:InitMinimapIcon(CreateIconForKey(self, "highlight"), kMinimapBlipType.HighlightWorld, kMinimapBlipTeam.Friendly)
			highlightBlip:SetIsVisible(false)
		end
		
		local highlightPos = GetHighlightPosition()
		if highlightPos then
			UpdateBlipPosition(self, highlightBlip, highlightPos)
		end
	end
end
   
local function RemoveDynamicBlip(self, blip)
	blip.Item:SetIsVisible(false)
	table.removevalue(self.inuseDynamicBlips, blip)
	table.insert(self.reuseDynamicBlips, blip)
end

local function UpdateAttackBlip(self, blip)
	local blipLifeRemaining = blip.Time - Shared.GetTime()
	local blipItem = blip.Item
	-- Fade in.
	if blipLifeRemaining >= kAttackBlipFadeInTime then
	
		local fadeInAmount = ((kAttackBlipTime - blipLifeRemaining) / (kAttackBlipTime - kAttackBlipFadeInTime))
		blipItem:SetColor(Color(1, 1, 1, fadeInAmount))
		
	else
		blipItem:SetColor(Color(1, 1, 1, 1))
	end
	
	-- Fade out.
	if blipLifeRemaining <= kAttackBlipFadeOutTime then
	
		if blipLifeRemaining <= 0 then
			return true
		end
		blipItem:SetColor(Color(1, 1, 1, blipLifeRemaining / kAttackBlipFadeOutTime))
		
	end
	
	local pulseAmount = (math.sin(blipLifeRemaining * kAttackBlipPulseSpeed) + 1) / 2
	local blipSize = LerpGeneric(kAttackBlipMinSize, kAttackBlipMaxSize / 2, pulseAmount)
	
	blipItem:SetSize(blipSize)
	-- Make sure it is always centered.
	local sizeDifference = kAttackBlipMaxSize - blipSize
	local xOffset = (sizeDifference.x / 2) - kAttackBlipMaxSize.x / 2
	local yOffset = (sizeDifference.y / 2) - kAttackBlipMaxSize.y / 2
	local plotX, plotY = self:PlotToMap(blip.X, blip.Y)
	blipItem:SetPosition(Vector(plotX + xOffset, plotY + yOffset, 0))
	
	-- Not done yet.
	return false
	
end

local function UpdateDynamicBlips(self)
	local new_blips = CommanderUI_GetDynamicMapBlips()

	for i = 1, #new_blips, 3 do
		local x, y, type = unpack(new_blips, i, i+2)
		local addedBlip = GetFreeDynamicBlip(self, x, y, type)
		addedBlip.Item:SetSize(Vector.origin)
		addedBlip.Time = Shared.GetTime() + kAttackBlipTime
	end
	
	local in_use = self.inuseDynamicBlips
	for i = 1, #in_use do
		if UpdateAttackBlip(self, in_use[i]) then
			RemoveDynamicBlip(self, in_use[i])
		end
	end
end

local function UpdateMapClick(self)

	if PlayerUI_IsOverhead() then
	
		-- Don't teleport if the command is dragging a selection or pinging.
		if PlayerUI_IsACommander() and (not CommanderUI_GetUIClickable() or GetCommanderPingEnabled()) then
			return
		end
		
		local mouseX, mouseY = Client.GetCursorPosScreen()
		if self.mouseButton0Down then
		
			local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
			if containsPoint then
			
				local minimapSize = self:GetMinimapSize()
				local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
				
				local cameraPosition = Vector(mouseX, mouseY, 0)
				
				cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
				cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y
				
				local horizontalScale = OverheadUI_MapLayoutHorizontalScale()
				local verticalScale = OverheadUI_MapLayoutVerticalScale()
				
				local moveX = (cameraPosition.x / minimapSize.x) * horizontalScale
				local moveY = (cameraPosition.y / minimapSize.y) * verticalScale
				
				OverheadUI_MapMoveView(moveX, moveY)
				
			end
			
		end
		
	end
	
end

local UpdateConnections
do
	local connections = {}
	local Shared_GetEntitiesWithClassname = Shared.GetEntitiesWithClassname
	function UpdateConnections(self)
		local connectors = Shared.GetEntitiesWithClassname "MapConnector"
		for index, connector in ientitylist(connectors) do
		for i = 1, #connectors do

			local connection = connections[i]
			
			if not connection then
				connections[i] = GUIMinimapConnection()
				connections[i]:SetStencilFunc(self.stencilFunc)
				connection = connections[i]
			end

			local origin = connector:GetOrigin()
			local dest   = connector:GetEndPoint()

			connection:Setup(
				Vector( self:PlotToMap(origin.x, origin.y) ),
				Vector( self:PlotToMap(dest.x,   dest.y)   ),
				self.minimap
			)
			
			connection:UpdateAnimation(connector:GetTeamNumber(), self.comMode = GUIMinimapFrame.kModeMini)
		end
		for i = #connections, connectors:GetSize()+1, -1 do
			connections[i]:Uninitialize()
			connections[i] = nil
		end
	end
end

local function UpdateCommanderPing(self)
	-- update commander ping
	if self.commanderPing then

		local entity = Shared.GetEntitiesWithClassname("TeamInfo"):GetEntityAtIndex(0)
		if not entity then return end
	  
		local pingTime = entity:GetPingTime()
		
		if pingTime ~= self.commanderPing.expiredPingTime then
		  
			local player = Client.GetLocalPlayer()
			local timeSincePing, position, distance, locationName = PlayerUI_GetPingInfo(player, entity, true)
			local posX, posY = self:PlotToMap(position.x, position.z)
			self.commanderPing.Frame:SetPosition(Vector(posX, posY, 0))
			self.commanderPing.Frame:SetIsVisible(timeSincePing <= kCommanderPingDuration)
			
			local expired = GUIAnimateCommanderPing(self.commanderPing.Mark, self.commanderPing.Border, self.commanderPing.Location, kCommanderPingMinimapSize, timeSincePing, Color(1, 0, 0, 1), Color(1, 1, 1, 1))
			if expired then
				-- block ping animation now that it has expired
				self.commanderPing.expiredPingTime = pingTime
			end
			
		end
	end
end

-- once we hit the misc update time, we step through each function and do them one per frame... spreads the load a bit
local kMiscUpdateStepFunctions = {
	UpdateDynamicBlips,			
	UpdateConnections,
	UpdateScansAndHighlight,
	UpdateCommanderPing,
	UpdateLocalBlips,
}

function GUIMinimap:Update(deltaTime)
	if self.background:GetIsVisible() then
	
		PROFILE("GUIMinimap:Update")
					
		local now = Shared.GetTime()
		local player = Client.GetLocalPlayer()
		
		local playerTeam = player:GetTeamNumber()
		if playerTeam == kMarineTeamType then
			playerTeam = kMinimapBlipTeam.Marine
		elseif playerTeam == kAlienTeamType then
			playerTeam = kMinimapBlipTeam.Alien
		end
		self.playerTeam = playerTeam
		
		self.playerOrigin = player:GetOrigin()

		kMiscUpdateStepFunctions[self.miscUpdateStep](self)
		self.miscUpdateStep = self.miscUpdateStep + 1
		if self.miscUpdateStep > #kMiscUpdateStepFunctions then
			self.miscUpdateStep = 1
		end

		UpdatePlayerIcon(self)
		UpdateMapClick(self)
				 
		UpdateActivityBlips_While(self, deltaTime, kMinimapActivity.Static)
		UpdateActivityBlips_While(self, deltaTime, kMinimapActivity.Low)
		UpdateActivityBlips_While(self, deltaTime, kMinimapActivity.Medium)
		UpdateActivityBlips_While(self, deltaTime, kMinimapActivity.High)
		
		UpdateBlipActivity(self)
		HideUnusedNameTags(self)
		local optionsMinimapNames = Client.GetOptionBoolean("minimapNames", true)
		self.showPlayerNames = optionsMinimapNames == true and self:LargeMapIsVisible()
		self.spectating = player:GetTeamType() == kNeutralTeamType
		self.clientIndex = player:GetClientIndex()
		
	end
	
end

function GUIMinimap:GetMinimapSize()
	return Vector(GUIMinimap.kBackgroundWidth * self.scale, GUIMinimap.kBackgroundHeight * self.scale, 0)
end

-- Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)

	if self.background:GetIsVisible() ~= showMap then
	
		self.background:SetIsVisible(showMap)
		if showMap then
		
			self.timeMapOpened = Shared.GetTime()
			self:Update(0)
			
		end
		
	end
	
end

function GUIMinimap:OnLocalPlayerChanged(newPlayer)
	self:ShowMap(false)
end

function GUIMinimap:SendKeyEvent(key, down)

	if PlayerUI_IsOverhead() then
	
		local mouseX, mouseY = Client.GetCursorPosScreen()
		local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
		
		if key == InputKey.MouseButton0 then
			self.mouseButton0Down = down
		elseif PlayerUI_IsACommander() and key == InputKey.MouseButton1 then
		
			if down and containsPoint then
			
				if self.buttonsScript then
				
					-- Cancel just in case the user had a targeted action selected before this press.
					CommanderUI_ActionCancelled()
					self.buttonsScript:SetTargetedButton(nil)
					
				end
				
				OverheadUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 1, nil)
				return true
				
			end
			
		end
		
	end
	
	return false

end

function GUIMinimap:ContainsPoint(pointX, pointY)
	return GUIItemContainsPoint(self.background, pointX, pointY) or GUIItemContainsPoint(self.minimap, pointX, pointY)
end

function GUIMinimap:GetBackground()
	return self.background
end

function GUIMinimap:GetMinimapItem()
	return self.minimap
end

function GUIMinimap:SetButtonsScript(setButtonsScript)
	self.buttonsScript = setButtonsScript
end

function GUIMinimap:SetLocationNamesEnabled(enabled)
	for _, locationItem in ipairs(self.locationItems) do
		locationItem.text:SetIsVisible(enabled)
	end
end

function GUIMinimap:ResetAll()
	for i = 1, #icons do
		local data = icons[i]
		for j = 1, #data do
			local icon = data[j]
			icon.entity:InitMinimapItem(self, icon)
		end
	end
end

function GUIMinimap:SetScale(scale)
	if scale ~= self.scale then
		self.scale = scale
		self:ResetAll()
		
		-- compute map to minimap transformation matrix
		local xFactor = 2 * self.scale
		local mapRatio = ConditionalValue(Client.minimapExtentScale.z > Client.minimapExtentScale.x, Client.minimapExtentScale.z / Client.minimapExtentScale.x, Client.minimapExtentScale.x / Client.minimapExtentScale.z)
		local zFactor = xFactor / mapRatio
		self.plotToMapConstX = -Client.minimapExtentOrigin.x
		self.plotToMapConstY = -Client.minimapExtentOrigin.z
		self.plotToMapLinX = GUIMinimap.kBackgroundHeight / (Client.minimapExtentScale.x / xFactor)
		self.plotToMapLinY = GUIMinimap.kBackgroundWidth / (Client.minimapExtentScale.z / zFactor)
		
		-- update overview size
		if self.minimap then
		  local size = Vector(GUIMinimap.kBackgroundWidth * scale, GUIMinimap.kBackgroundHeight * scale, 0)
		  self.minimap:SetSize(size)
		end

		-- reposition location names
		if self.locationItems then
		  for _, locationItem in ipairs(self.locationItems) do
			local mapPos = Vector(self:PlotToMap(locationItem.origin.x, locationItem.origin.z ))
			SetLocationTextPosition( locationItem, mapPos )
		  end
		end
	  
	end
end

function GUIMinimap:GetScale()
	return self.scale
end

function GUIMinimap:SetBlipScale(blipScale)

	if blipScale ~= self.blipScale then
	
		self.blipScale = blipScale
		self:ResetAll()
	
		local blipSizeTable = self.blipSizeTable
		local blipSize = Vector(kBlipSize, kBlipSize, 0)
		blipSizeTable[kBlipSizeType.Normal] = blipSize * (0.7 * blipScale)
		blipSizeTable[kBlipSizeType.TechPoint] = blipSize * blipScale
		blipSizeTable[kBlipSizeType.Infestation] = blipSize * (2 * blipScale)
		blipSizeTable[kBlipSizeType.Egg] = blipSize * (0.7 * 0.5 * blipScale)
		blipSizeTable[kBlipSizeType.Worker] = blipSize * (blipScale)
		blipSizeTable[kBlipSizeType.EtherealGate] = blipSize * (1.5 * blipScale)
		blipSizeTable[kBlipSizeType.Waypoint] = blipSize * (1.5 * blipScale)
		blipSizeTable[kBlipSizeType.BoneWall] = blipSize * (1.5 * blipScale)
		blipSizeTable[kBlipSizeType.UnpoweredPowerPoint] = blipSize * (0.45 * blipScale)
				
	end
	
end

function GUIMinimap:GetBlipScale(blipScale)
	return self.blipScale
end

function GUIMinimap:SetMoveBackgroundEnabled(enabled)
	self.moveBackgroundMode = enabled
end

function GUIMinimap:SetStencilFunc(stencilFunc)

	self.stencilFunc = stencilFunc
	
	self.minimap:SetStencilFunc(stencilFunc)
	self.commanderPing.Mark:SetStencilFunc(stencilFunc)
	self.commanderPing.Border:SetStencilFunc(stencilFunc)
	
	for _, blip in ipairs(self.inuseDynamicBlips) do
		blip.Item:SetStencilFunc(stencilFunc)
	end
	
	for id,icon in pairs(self.iconMap) do
		icon:SetStencilFunc(stencilFunc)
	end
	
	for _, connectionLine in ipairs(self.minimapConnections) do
		connectionLine:SetStencilFunc(stencilFunc)
	end
	
end

function GUIMinimap:SetPlayerIconColor(color)
	self.playerIconColor = color
end

function GUIMinimap:SetIconFileName(fileName)
	local iconFileName = ConditionalValue(fileName, fileName, kIconFileName)
	self.iconFileName = iconFileName
	
	self.playerIcon:SetTexture(iconFileName)
	for id,icon in pairs(self.iconMap) do
		icon:SetTexture(iconFileName)
	end
end

function OnToggleMinimapNames()
	if Client.GetOptionBoolean("minimapNames", true) then
		Client.SetOptionBoolean("minimapNames", false)
		Shared.Message("Minimap Names is now set to OFF")
	else
		Client.SetOptionBoolean("minimapNames", true)
		Shared.Message("Minimap Names is now set to ON")
	end
end

function OnChangeMinimapUpdateRate(mul)
	if Client then
		if mul then
			GUIMinimap.kUpdateIntervalMultipler = Clamp(tonumber(mul), 0, 5)
		end
		Log("Minimap update interval multipler: %s", GUIMinimap.kUpdateIntervalMultipler)
	end
end

function OnCommandUseLoop()
	if Client then
		GUIMinimap.kDebugIndex = GUIMinimap.kDebugIndex == 2 and 0 or GUIMinimap.kDebugIndex + 1
		Log("DebugIndex = %s (0 = unrolled (ok), 1 == loop/while (ok), 2 = loop/for (freeze sometimes))", GUIMinimap.kDebugIndex)
	end
end

Event.Hook("Console_minimap_rate", OnChangeMinimapUpdateRate)
Event.Hook("Console_minimapnames", OnToggleMinimapNames)
Event.Hook("Console_setmaplocationcolor", OnCommandSetMapLocationColor)
