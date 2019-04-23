function Observatory:FindCommandStation()
	self.nearest_commandstation = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), Lambda [[(...):GetIsBuilt() and (...):GetIsAlive()]]):GetId()
	return Shared.GetEntity(self.nearest_commandstation)
end

function Observatory:GetCommandStation()
	return self.nearest_commandstation and Shared.GetEntity(self.nearest_commandstation) or self:FindCommandStation()
end

function Observatory:GetDistressOrigin()
	local cc = self:GetCommandStation()
	return cc and cc:GetModelOrigin()
end

local kDistressBeaconTime = Observatory.kDistressBeaconTime

local old = Observatory.TriggerDistressBeacon

function Observatory:TriggerDistressBeacon()
	self:FindCommandStation()

	-- May happen at the end of the game?
	if self:GetIsBeaconing() then
		return false, true
	end

	local ips = GetEntities "InfantryPortal"
	local step = (kDistressBeaconTime * .5) / #ips
	local delay = 0
	for i = 1, #ips do
		ips[i]:AddTimedCallback(ips[i].FinishSpawn, delay)
		delay = delay + step
	end

	return old(self)
end

function Observatory:PerformDistressBeacon()
	self.distressBeaconSound:Stop()

	local commandStation = self:GetCommandStation()

	local spawnPoints = GetBeaconPointsForTechPoint(commandStation.attachedId)

	if not spawnPoints then
		return
	end

	self:GetTeam():ForEachPlayer(Closure [[
		self toOrigin spawnPoints
		args player
		if player:isa "Marine" and (player:GetOrigin() - toOrigin):GetLengthSquared() > (kDistressBeaconRange*1.1)^2 then
			if Server then
				local f = player.MarkNearbyDirtyImmediately
				if f then
					f(player)
				end
				local f = player.OnPreBeacon
				if f then
					f(player)
				end
			end
			player:SetOrigin(spawnPoints[self.i])
			player:TriggerBeaconEffects()
			self.i = self.i + 1
		end
	]] {self:GetDistressOrigin(), spawnPoints, i = 1})

	for _, ip in ipairs(GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), commandStation:GetOrigin(), kInfantryPortalAttachRange)) do
		ip:FinishSpawn()
	end

	self:TriggerEffects("distress_beacon_complete")
end
