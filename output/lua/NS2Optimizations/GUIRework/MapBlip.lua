local Client            = Client
local Shared            = Shared
local Server            = Server

class 'MapBlip' (Entity)

local MapBlip = MapBlip
local Entity  = Entity

MapBlip.kMapName = "MapBlip"

local networkVars =
{
	--m_origin = "position (by 10000 [0], by 10000 [0], by 10000 [0])",
	--m_angles = "angles (by 10000 [0], by 10000 [0], by 10000 [0])",

    type = "enum kMinimapBlipType",
    team = "integer (" .. kTeamInvalid .. " to " .. kSpectatorIndex .. ")",

	inCombat        = "boolean",
	isParasited     = "boolean",
	isHallucination = "boolean",
	active          = "boolean",
}

if Server then
	function MapBlip:OnCreate()
		Entity.OnCreate(self)
		
		self:SetUpdates(false)
		
		self:SetRelevancyDistance(Math.infinity)

		local mask 

		if self.team == kTeam1Index then
			mask = kRelevantToTeam1
		elseif self.team == kTeam2Index then
			mask = kRelevantToTeam2
		else
			mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
		end
		
		self:SetExcludeRelevancyMask(mask)
	end
elseif Client then
	function MapBlip:OnCreate()
		Entity.OnCreate(self)

		self:SetUpdates(false)
	end
end

-- used by bot brains
do
	function MapBlip:GetType()
		return self.type
	end

	function MapBlip:GetTeamNumber()
		return self.team
	end

	function MapBlip:GetRotation()
		return self:GetAngles().yaw
	end

	function MapBlip:GetIsActive()
		return self.active
	end

	function MapBlip:GetIsSighted()
		local parent = self:GetParent()
		if parent == nil then return false end
		local GetIsSighted = parent.GetIsSighted
		if GetIsSighted == nil then return false end
		return GetIsSighted(parent)
	end

	function MapBlip:GetIsInCombat()
		return self.inCombat
	end

	function MapBlip:GetIsParasited()
		return self.isParasited
	end

	MapBlip.GetOwnerEntityId = MapBlip.GetParentId
end

Shared.LinkClassToMap("MapBlip", MapBlip.kMapName, networkVars)

class 'PlayerMapBlip' (MapBlip)

PlayerMapBlip.kMapName = "PlayerMapBlip"

local playerNetworkVars =
{
    clientIndex = "entityid",
}

Shared.LinkClassToMap("PlayerMapBlip", PlayerMapBlip.kMapName, playerNetworkVars)
