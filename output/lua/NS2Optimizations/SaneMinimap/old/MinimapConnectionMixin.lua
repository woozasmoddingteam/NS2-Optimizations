-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MinimapConnectionMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
--    Used for rendering connections on the minimap.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

MinimapConnectionMixin = CreateMixin( MinimapConnectionMixin )
MinimapConnectionMixin.type = "MinimapConnection"

MinimapConnectionMixin.expectedMixins =
{
    Team = "For team number."
}

MinimapConnectionMixin.expectedCallbacks =
{
    GetConnectionStartPoint = "For map connector.",
    GetConnectionEndPoint = "For map connector."
}

if Server then
	local keyEndPoint   = newproxy()
    local function OnUpdate(self, deltaTime)
		local connector = self.connector

        local endPoint = self:GetConnectionEndPoint()

		if endPoint ~= self[keyEndPoint] then
			self[keyEndPoint] = endPoint
			connector:SetEndPoint(endPoint)
		end
		return 1
    end
	function MinimapConnectionMixin:__initmixin()
		self.connector = CreateEntity(MapConnector.kMapName)
		self:AddTimedCallback(OnUpdate, 0)
	end
	function MinimapConnectionMixin:SetTeamNumber(n)
		self.connector:SetTeamNumber(n)
	end
	function MinimapConnectionMixin:SetOrigin(origin)
		self.connector:SetOrigin(origin)
	end
    function MinimapConnectionMixin:OnDestroy()
		DestroyEntity(self.connector)
    end
else
	function MinimapConnectionMixin:__initmixin()
	end
end
