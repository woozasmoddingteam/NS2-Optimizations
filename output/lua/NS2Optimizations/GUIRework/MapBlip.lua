local Client            = Client
local Shared            = Shared
local Server            = Server

class 'MapBlip' (Entity)

local MapBlip = MapBlip
local Entity  = Entity
local AlertNewMapBlip
local AlertActivity
local AlertCombat
local AlertParasite

MapBlip.kMapName = "MapBlip"

local networkVars =
{
	m_origin = "interpolated position (by 0.2 [2 3 5], by 0.2 [2 3 5], by 0.2 [2 3 5]",
    m_angles = "interpolated angles   (by 10 [0],      by 0.1 [3],     by 10 [0])",

    type            = "enum kMinimapBlipType",
    team            = "integer (" .. kTeamInvalid .. " to " .. kSpectatorIndex .. ")",
	isHallucination = "boolean",

	inCombat = "boolean",
	active   = "boolean",

	ownerId = "entityid",
}

if Server then
	function MapBlip:OnCreate()
		Entity.OnCreate(self)
		
		self:SetUpdates(false)
		
		self:SetRelevancyDistance(Math.infinity)
	end
elseif Client then
	function MapBlip:OnInitialized()
		Entity.OnInitialized(self)

		if AlertNewMapBlip  == nil then
			AlertNewMapBlip  = GUIMinimapFrame.AlertNewMapBlip
		end
		if AlertActivity    == nil then
			AlertActivity    = GUIMinimapFrame.AlertActivity
		end
		if AlertCombat      == nil then
			AlertCombat      = GUIMinimapFrame.AlertCombat
		end
		AlertNewMapBlip(self)
		AlertActivity(self)
		AlertCombat(self)

		self.old_active = self.active

		self:SetUpdates(true)
		self:AddFieldWatcher("type",        AlertNewMapBlip)
		--self:AddFieldWatcher("active",      self.AlertActivity)
		self:AddFieldWatcher("inCombat",    AlertCombat)
	end

	function MapBlip:AlertActivity()
		Log("AlertActivity(%s:%s)", self, kMinimapBlipType[self.type])
	end

	function MapBlip:OnUpdate()
		if self.old_active ~= self.active then
			self.old_active = self.active
			Log("%s:%s.active <- %s", self, kMinimapBlipType[self.type], self.active)
		end
	end
end

-- used by bot brains
if Server then
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
		local owner = Shared.GetEntity(self.ownerId)
		if owner == nil then return false end
		local GetIsSighted = owner.GetIsSighted
		if GetIsSighted == nil then return false end
		return GetIsSighted(owner)
	end

	function MapBlip:GetIsInCombat()
		return self.inCombat
	end

	function MapBlip:GetIsParasited()
		return self.isParasited
	end

	function MapBlip:GetOwnerEntityId()
		return self.ownerId
	end
end

Shared.LinkClassToMap("MapBlip", MapBlip.kMapName, networkVars)

class 'PlayerMapBlip' (MapBlip)

PlayerMapBlip.kMapName = "PlayerMapBlip"

local playerNetworkVars =
{
    clientIndex = "entityid",
	isParasited = "boolean",
}

if Client then
	function PlayerMapBlip:OnInitialized()
		MapBlip.OnInitialized(self)

		if AlertParasite == nil then
			AlertParasite = GUIMinimapFrame.AlertParasite
		end
		AlertParasite(self)
		self:AddFieldWatcher("isParasited", AlertParasite)
	end
end

Shared.LinkClassToMap("PlayerMapBlip", PlayerMapBlip.kMapName, playerNetworkVars)
