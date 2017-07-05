Script.Load "lua/Globals.lua"

local kMinimapBlipType = kMinimapBlipType
local atan2            = math.atan2
local pi               = math.pi
local Server           = Server
local Shared           = Shared
local bor              = bit.bor

MapBlipMixin = CreateMixin( MapBlipMixin )
MapBlipMixin.type = "MapBlip"

local MapBlipMixin = MapBlipMixin

MapBlipMixin.optionalCallbacks =
{
    OnGetMapBlipInfo = "Override for getting the Map Blip Info",
}

function MapBlipMixin:__initmixin()
    assert(Server)

	local type, team = self:GetMapBlipInfo()
	if type then
		local mapName = self:isa("Player") and PlayerMapBlip.kMapName or MapBlip.kMapName

		local mapBlip = Server.CreateEntity(mapName)

		mapBlip.isHallucination = self.isHallucination == true or self:isa "Hallucination"
		mapBlip.type, mapBlip.team = type, team
		self.mapBlip = mapBlip
		mapBlip.ownerId = self:GetId()
		self.__needs_connection = self:isa "Cyst" or self:isa "TunnelEntrance"
    
		MapBlipMixin.SetOrigin(self, self:GetOrigin())
		MapBlipMixin.SetAngles(self)
		MapBlipMixin.OnSighted(self, self.sighted == true)
		self:MarkBlipDirty()
		if self:isa "PowerPoint" then
			MapBlipMixin.SetInternalPowerState(self, self.powerState)
		end
	else
		Log("Warning! %s does not have a map blip!", self)
	end
end

function MapBlipMixin:OnDestroy()
	if self.mapBlip then
		Server.DestroyEntity(self.mapBlip)
	end
end

MapBlipMixin.OnKill = MapBlipMixin.OnDestroy

local function checkActivity(self)
	local old = self.mapBlip.active
	self.mapBlip.active =
		GetIsUnitActive(self) and
		(self.__needs_connection == false or self.connected)
	Log("%s (%s): %s -> %s", self.mapBlip, self, old, self.mapBlip.active)
end
for _, v in ipairs {"OnConstructionComplete", "OnPowerOn", "OnPowerOff", "OnKill", "MarkBlipDirty"} do
	MapBlipMixin[v] = checkActivity
end

function MapBlipMixin:SetInternalPowerState(powerState)
	local mapBlip = self.mapBlip

	if     powerState == PowerPoint.kPowerState.destroyed then
		mapBlip.type = kMinimapBlipType.PowerPoint
	elseif powerState == PowerPoint.kPowerState.unsocketed then
		mapBlip.type = kMinimapBlipType.UnsocketedPowerPoint
	elseif self:GetIsBuilt() then
		mapBlip.type = kMinimapBlipType.PowerPoint
	else
		mapBlip.type = kMinimapBlipType.UnsocketedPowerPoint
	end
end

function MapBlipMixin:OnEnterCombat()
	self.mapBlip.inCombat = true
end

function MapBlipMixin:OnLeaveCombat()
	self.mapBlip.inCombat = false
end

do
	local Log = function() end
	function MapBlipMixin:OnSighted(sighted)
		local mapblip = self.mapBlip
		if not mapblip then return end
		if sighted then
			Log("%s (%s) is now sighted!", mapblip, kMinimapBlipType[mapblip.type])
			mapblip:SetExcludeRelevancyMask(bor(kRelevantToTeam1, kRelevantToTeam2))
		elseif mapblip.team == 1 then
			Log("%s (%s) is now not sighted!", mapblip, kMinimapBlipType[mapblip.type])
			mapblip:SetExcludeRelevancyMask(kRelevantToTeam1)
		elseif mapblip.team == 2 then
			Log("%s (%s) is now not sighted!", mapblip, kMinimapBlipType[mapblip.type])
			mapblip:SetExcludeRelevancyMask(kRelevantToTeam2)
		else
			Log("%s (%s) is now not sighted!", mapblip, kMinimapBlipType[mapblip.type])
			mapblip:SetExcludeRelevancyMask(bor(kRelevantToTeam1, kRelevantToTeam2))
		end
	end
end

function MapBlipMixin:OnParasited()
	self.mapBlip.isParasited = true
end

function MapBlipMixin:OnParasiteRemoved()
	self.mapBlip.isParasited = false
end

function MapBlipMixin:SetControllerClient(client)
	self.mapBlip.clientIndex = client:GetId()
end

function MapBlipMixin:SetCoords(coords)
	self.mapBlip:SetAngles(Angles(0, atan2(coords.zAxis.x, coords.zAxis.z), 0))
end

local SetCoords = MapBlipMixin.SetCoords

function MapBlipMixin:SetAngles()
	SetCoords(self, self:GetCoords())
end

function MapBlipMixin:SetOrigin()
	local mapBlip = self.mapBlip
	if mapBlip == nil then return end
	local tunnel  = self.inTunnel
	local origin  = self:GetOrigin()
	if tunnel then
		mapBlip:SetOrigin(tunnel:GetRelativePosition(origin))
	else
		mapBlip:SetOrigin(origin)
	end
end

function MapBlipMixin:GetMapBlipInfo()
    if self.OnGetMapBlipInfo then
        local _, type, team = self:OnGetMapBlipInfo()
		return type, team
    end

	local classname = self:GetClassName()
	local blipType
	if classname == "Hallucination" then
		blipType = kMinimapBlipType[kTechId[self:GetAssignedTechId()]]
	elseif classname == "Cyst" then
		blipType = kMinimapBlipType.Infestation
	else
		blipType = kMinimapBlipType[classname]
	end
	blipType = blipType or kMinimapBlipType.Undefined
	return blipType, self.GetTeamNumber and self:GetTeamNumber() or -1
end
