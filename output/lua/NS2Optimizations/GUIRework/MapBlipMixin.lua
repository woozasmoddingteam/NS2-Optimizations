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

-- Why is this here? Well, a long time ago this key was actually an integer, which didn't work
-- because at the time the version of LuaJIT NS2 was using had some buggy optimisations for
-- entities, which segfaulted at non-string keys! Very fun.
local qMapBlip = "mapBlip"

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
    
		MapBlipMixin.SetOrigin(self, self:GetOrigin())
		MapBlipMixin.SetAngles(self)
		MapBlipMixin.SetIsSighted(self, self.sighted == true)
		self:MarkBlipDirty()
	else
		Log("Warning! %s does not have a map blip!", self)
	end

	self.__is_cyst = self:isa "Cyst"
end

function MapBlipMixin:OnDestroy()
	Server.DestroyEntity(self[qMapBlip])
end

local function checkActivity(self)
	self[qMapBlip].active = GetIsUnitActive(self) and (self.__is_cyst == false or self.connected)
end
for _, v in ipairs {"OnConstructionComplete", "OnPowerOn", "OnPowerOff", "OnKill", "MarkBlipDirty"} do
	MapBlipMixin[v] = checkActivity
end

function MapBlipMixin:SetInternalPowerState(powerState)
	local mapBlip = self[qMapBlip]

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
	self[qMapBlip].inCombat = true
end

function MapBlipMixin:OnLeaveCombat()
	self[qMapBlip].inCombat = false
end

function MapBlipMixin:SetIsSighted(sighted)
	local mapBlip = self[qMapBlip]
	if not mapBlip then Shared.Message(ToString(self) .. " has no map blip! SetIsSighted"); return end
	if sighted then
		mapBlip:SetExcludeRelevancyMask(bor(kRelevantToTeam1, kRelevantToTeam2))
	elseif mapBlip.team == 1 then
		mapBlip:SetExcludeRelevancyMask(kRelevantToTeam1)
	elseif mapBlip.team == 2 then
		mapBlip:SetExcludeRelevancyMask(kRelevantToTeam2)
	else
		mapBlip:SetExcludeRelevancyMask(bor(kRelevantToTeam1, kRelevantToTeam2))
	end
end

function MapBlipMixin:OnParasited()
	self[qMapBlip].isParasited = true
end

function MapBlipMixin:OnParasiteRemoved()
	self[qMapBlip].isParasited = false
end

function MapBlipMixin:SetControllerClient(client)
	self[qMapBlip].clientIndex = client:GetId()
end

function MapBlipMixin:SetCoords(coords)
	self[qMapBlip]:SetAngles(Angles(0, atan2(coords.zAxis.x, coords.zAxis.z), 0))
end

local SetCoords = MapBlipMixin.SetCoords

function MapBlipMixin:SetAngles()
	SetCoords(self, self:GetCoords())
end

function MapBlipMixin:SetOrigin()
	local mapBlip = self[qMapBlip]
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
