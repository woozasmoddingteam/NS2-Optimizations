Script.Load("lua/MapConnector.lua")
local Server = Server
local Shared = Shared
local MapConnector = MapConnector

MinimapConnectionMixin = {
	type = "MinimapConnection",
	expectedMixins = {
		Team = "For team number"
	}
}

function MinimapConnectionMixin:SetConnectionStartPoint(point)
	if point ~= nil then
		if self.__mapconnector == nil then
			local mapconnector = Server.CreateEntity(MapConnector.kMapName)
			mapconnector:SetRelevancyDistance(Math.infinity)

			local mask = 0
			
			if self:GetTeamNumber() == kTeam1Index then
				mask = kRelevantToTeam1
			elseif self:GetTeamNumber() == kTeam2Index then
				mask = kRelevantToTeam2
			end
				
			mapconnector:SetExcludeRelevancyMask(mask)
			self.__mapconnector = mapconnector
		end
		self.__mapconnector:SetOrigin(point)
	elseif self.__mapconnector ~= nil then
		Server.DestroyEntity(self.__mapconnector)
		self.__mapconnector = nil
	end
end

function MinimapConnectionMixin:SetConnectionEndPoint(point)
	self.__mapconnector.endPoint = point
end

MinimapConnectionMixin.OnDestroy = MinimapConnectionMixin.SetConnectionStartPoint

