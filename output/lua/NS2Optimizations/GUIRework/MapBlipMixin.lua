Script.Load "lua/Globals.lua"

local kMinimapBlipType = kMinimapBlipType

MapBlipMixin = CreateMixin( MapBlipMixin )
MapBlipMixin.type = "MapBlip"

MapBlipMixin.optionalCallbacks =
{
    OnGetMapBlipInfo = "Override for getting the Map Blip Info",
}

local keyIsCyst = 0

function MapBlipMixin:__initmixin()
    assert(Server)
    
	local type, team = self:GetMapBlipInfo()
	if type then
		local mapName = self:isa("Player") and PlayerMapBlip.kMapName or MapBlip.kMapName

		local mapBlip = Server.CreateEntity(mapName)
		if mapBlip then
			mapBlip:SetParent(self)
			mapBlip.isHallucination = self.isHallucination == true or self:isa "Hallucination"
			mapBlip.type, mapBlip.team = type, team
			self.mapBlip = mapBlip
		end
	end

	if self:isa "Cyst" then
		self[keyIsCyst] = true
	end
end

function MapBlipMixin:MarkBlipDirty()
	if self[keyIsCyst] ~= nil then
		self.mapBlip.type = self.connected and kMinimapBlipType.Infestation or kMinimapBlipType.InfestationDying
	end
end

function MapBlipMixin:SetInternalPowerState(powerState)
	local mapBlip = self.mapBlip
	if     powerState == PowerPoint.kPowerState.destroyed then
		mapBlip.type = kMinimapBlipType.DestroyedPowerPoint
	elseif powerState == PowerPoint.kPowerState.unsocketed then
		mapBlip.type = kMinimapBlipType.UnsocketedPowerPoint
	elseif self:GetIsBuilt() then
		mapBlip.type = kMinimapBlipType.PowerPoint
	else
		mapBlip.type = kMinimapBlipType.BlueprintPowerPoint
	end
end

function MapBlipMixin:OnEnterCombat()
	self.mapBlip.inCombat = true
end

function MapBlipMixin:OnLeaveCombat()
	self.mapBlip.inCombat = false
end

local function checkActivity(self)
	self.mapBlip.active = GetIsUnitActive(self)
end
for _, v in ipairs {"OnConstructionComplete", "OnPowerOn", "OnPowerOff", "OnKill"} do
	MapBlipMixin[v] = checkActivity
end

function MapBlipMixin:OnParasited()
	self.mapBlip.isParasited = true
end

function MapBlipMixin:OnParasiteRemoved()
	self.mapBlip.isParasited = false
end

function MapBlipMixin:GetMapBlipInfo()

    if self.OnGetMapBlipInfo then
        return self:OnGetMapBlipInfo()
    end

    local blipType = kMinimapBlipType.Undefined

	for i = 1, #kMinimapBlipType do
		if self:isa(kMinimapBlipType[i]) then
			blipType = i
			goto found
		end
	end

    if self:isa "Cyst" then
    
        blipType = kMinimapBlipType.Infestation
        
    elseif self:isa "Hallucination" then

        local hallucinatedTechId = self:GetAssignedTechId()
 
        if hallucinatedTechId == kTechId.Drifter then
            blipType = kMinimapBlipType.Drifter
        elseif hallucinatedTechId == kTechId.Hive then
            blipType = kMinimapBlipType.Hive
        elseif hallucinatedTechId == kTechId.Harvester then
            blipType = kMinimapBlipType.Harvester
        end 

	end

	do return end

	::found::
    
    return blipType, self.GetTeamNumber and self:GetTeamNumber() or -1
    
end

function MapBlipMixin:SetControllerClient(client)
	self.mapBlip.clientIndex = client:GetId()
end
