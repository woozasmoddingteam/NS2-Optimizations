local Client = Client
local Shared = Shared
local Server = Server
local kType  = kMinimapBlipType

class 'MapBlip' (Entity)

local MapBlip = MapBlip
local Entity  = Entity
local AlertNewMapBlip
local AlertActivity
local AlertCombat
local AlertParasite
local AlertConnectorTarget

MapBlip.kMapName = "mapblip"

local networkVars =
{
	m_origin = "interpolated position (by 0.2 [2 3 5], by 0.2 [2 3 5], by 0.2 [2 3 5])",
	m_angles = "interpolated angles   (by 10 [0],   by 0.1 [3],     by 10 [0])",
	m_parentId = "integer (-1 to -1)",
	m_attachPoint = "integer (-1 to -1)",

	type            = "enum kMinimapBlipType",
	team            = "integer (" .. kTeamInvalid .. " to " .. kSpectatorIndex .. ")",
	hallucination   = "boolean",

	combatant = "boolean",
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

		self:SetUpdates(false)
		self:AddFieldWatcher("type",      AlertNewMapBlip)
		self:AddFieldWatcher("active",    AlertActivity)
		self:AddFieldWatcher("combatant", AlertCombat)
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
		return self.combatant
	end

	function MapBlip:GetIsParasited()
		return self.parasited
	end

	function MapBlip:GetOwnerEntityId()
		return self.ownerId
	end
end

Shared.LinkClassToMap("MapBlip", MapBlip.kMapName, networkVars)

class 'PlayerMapBlip' (MapBlip)

PlayerMapBlip.kMapName = "playermapblip"

local playerNetworkVars =
{
	clientIndex = "entityid",
	parasited   = "boolean",
}

if Client then
	function PlayerMapBlip:OnInitialized()
		MapBlip.OnInitialized(self)

		if AlertParasite == nil then
			AlertParasite = GUIMinimapFrame.AlertParasite
		end

		AlertParasite(self)
		self:AddFieldWatcher("parasited", AlertParasite)
	end
end

Shared.LinkClassToMap("PlayerMapBlip", PlayerMapBlip.kMapName, playerNetworkVars)

class "ConnectorMapBlip" (MapBlip)

ConnectorMapBlip.kMapName = "connectormapblip"

if Client then
	function ConnectorMapBlip:OnInitialized()
		MapBlip.OnInitialized(self)

		if AlertConnectorTarget == nil then
			AlertConnectorTarget = GUIMinimapFrame.AlertConnectorTarget
		end

		AlertConnectorTarget(self)
		self:AddFieldWatcher("target", AlertConnectorTarget)
	end
end

Shared.LinkClassToMap("ConnectorMapBlip", ConnectorMapBlip.kMapName, {
	target = "entityid"
})
