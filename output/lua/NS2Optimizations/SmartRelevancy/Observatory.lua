
do
	function Observatory:FindCommandStation()
		self.nearest_commandstation = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), Lambda [[(...):GetIsBuilt() and (...):GetIsAlive()]]):GetId()
		return Shared.GetEntity(self.nearest_commandstation)
	end

	function Observatory:GetCommandStation()
		return Shared.GetEntity(self.nearest_commandstation) or self:FindCommandStation()
	end

	function Observatory:GetDistressOrigin()
		local cc = self:GetCommandStation()
		return cc and cc:GetModelOrigin()
	end
end

--[[
	Only server
]]
if not Server then return end


local kDistressBeaconTime = Observatory.kDistressBeaconTime
local kDistressBeaconEnd  = kDistressBeaconTime + 10
local kDistressBeaconRange = Observatory.kDistressBeaconRange

local kIgnorePlayers = kNS2OptiConfig.InfinitePlayerRelevancy

local function makeRelevant(self)
	self.__old_include_mask = self:GetIncludeRelevancyMask()
	self:SetIncludeRelevancyMask(0xFFFFFFFF)
end

local function makeIrrelevant(self)
	self:SetIncludeRelevancyMask(self.__old_include_mask)
end

local function prepareBeacon(self, delay, los_time)
	if not kIgnorePlayers then
		self:AddTimedCallback(makeRelevant, delay)
		self:AddTimedCallback(makeIrrelevant, kDistressBeaconEnd)
	end
	self.timeLastLOSDirty   = los_time
	self.timeLastLOSUpdate  = los_time
	self.__x4841 = los_time
end

local oldTriggerDistressBeacon = Observatory.TriggerDistressBeacon

function Observatory:TriggerDistressBeacon()
	self:FindCommandStation()
	local distressOrigin = self:GetDistressOrigin()
	local los_time = Shared.GetTime() + kDistressBeaconEnd

	-- May happen at the end of the game?
	if not distressOrigin or self:GetIsBeaconing() then
		return false, true
	end

	local step = kDistressBeaconTime / Server.GetNumPlayers()
	GetGamerules():GetTeam1():ForEachPlayer(Closure [=[
		self prepareBeacon step los_time
		args player

		if player:isa "Marine" then
			prepareBeacon(player, self.delay, los_time)
			self.delay = self.delay + step
		end
	]=] {prepareBeacon, step, los_time, delay = 0})

	local ips = GetEntities "InfantryPortal"
	local step = (kDistressBeaconTime - 0.1) / #ips
	local delay = 0
	for i = 1, #ips do
		ips[i]:AddTimedCallback(ips[i].FinishSpawn, delay)
		delay = delay + step
	end

	-- We need to check for LiveMixin, since some entities (e.g. map blips)
	-- are not supposed to be relevant unconditionally
	local entities = self:GetCommandStation():GetLocationEntity():GetEntitiesInTrigger()
	if #entities == 0 then
		Shared.Message "Found no entities in the location entity!"
		entities = GetEntitiesWithMixinWithinRange("Live", distressOrigin, 20)
	end
	Shared.Message("Found " .. #entities .. " live entities near distress origin")
	local step = kDistressBeaconTime / #entities
	local delay = 0
	for i = 1, #entities do
		local ent = entities[i]
		if HasMixin(ent, "Live") and ent.__x4841 ~= los_time then
			ent:AddTimedCallback(makeRelevant, delay)
			ent:AddTimedCallback(makeIrrelevant, kDistressBeaconEnd)
			ent.timeLastLOSDirty   = los_time
			ent.timeLastLOSUpdate  = los_time
			delay = delay + step
		end
	end

	return oldTriggerDistressBeacon(self)
end

function Observatory:PerformDistressBeacon()

	self.distressBeaconSound:Stop()

	local distressOrigin = self:GetDistressOrigin()
	if not distressOrigin then
		return
	end

	local spawnPoints = GetBeaconPointsForTechPoint(self:GetCommandStation().attachedId)
	
	if not spawnPoints then
		return
	end

	self:GetTeam():ForEachPlayer(Closure [[
		self toOrigin spawnPoints
		args player
		if player:isa "Marine" and (player:GetOrigin() - toOrigin):GetLengthSquared() > (kDistressBeaconRange*1.1)^2 then
			player:SetOrigin(spawnPoints[i])
			player:TriggerBeaconEffects()
		end
	]] {self:GetDistressOrigin(), spawnPoints})

	self:TriggerEffects("distress_beacon_complete")
end
