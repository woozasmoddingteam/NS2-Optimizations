
do
	local nearest_commandstation_key = newproxy()

	local oldOnInitialized = Observatory.OnInitialized
	function Observatory:OnInitialized()
		oldOnInitialized(self)

		self[nearest_commandstation_key] = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), Lambda [[(...):GetIsBuilt() and (...):GetIsAlive()]])
	end

	function Observatory:SetOrigin(origin)
		Entity.SetOrigin(self, origin)

		Log("Finding commandstation for %s!", self)
		self[nearest_commandstation_key] = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), Lambda [[(...):GetIsBuilt() and (...):GetIsAlive()]])
	end

	function Observatory:GetCommandStation()
		return self[nearest_commandstation_key]
	end

	function Observatory:GetDistressOrigin()
		return self:GetCommandStation():GetModelOrigin()
	end
end

--[[
	Only server
]]
if not Server then return end


local kDistressBeaconTime = Observatory.kDistressBeaconTime
local kDistressBeaconRange = Observatory.kDistressBeaconRange

local kIgnorePlayers = kNS2OptiConfig.InfinitePlayerRelevancy

local kRelevantToAll = kRelevantToAll
local oldUpdateIncludeRelevancyMask_key = newproxy()
local old_include_mask = newproxy()

local function GetPlayersToBeacon(self)
	local players = { }

	self:GetTeam():ForEachPlayer(Closure [[
		self toOrigin players
		args player
		if not player:isa "Marine" or (player:GetOrigin() - toOrigin):GetLengthSquared() < (kDistressBeaconRange*1.1)^2 then
			return
		end

		table.insert(players, player)
	]] {self:GetDistressOrigin(), players})

	return players
end

local function altUpdateIncludeRelevancyMask(self)
	self:SetIncludeRelevancyMask(kRelevantToAll)
end

local function makeRelevant(self)
	self[old_include_mask] = self:GetIncludeRelevancyMask()
	self:SetIncludeRelevancyMask(kRelevantToAll)
end

local function makePlayerRelevant(self)
	Log("%s made relevant!", self)
	self[oldUpdateIncludeRelevancyMask_key] = self.UpdateClientRelevancyMask
	self.UpdateIncludeRelevancyMask = altUpdateIncludeRelevancyMask
	self:UpdateIncludeRelevancyMask()
end

local function makeIrrelevant(self)
	self:SetIncludeRelevancyMask(self[old_include_mask])
	self[old_include_mask] = nil
end

local makePlayerIrrelevant

if kIgnorePlayers then
	function makePlayerIrrelevant(self)
		Log("%s made irrelevant!", self)
		self:SetLOSUpdates(true)
	end
else
	function makePlayerIrrelevant(self)
		Log("%s made irrelevant!", self)
		self.UpdateIncludeRelevancyMask = self[oldUpdateIncludeRelevancyMask_key]
		self[oldUpdateIncludeRelevancyMask_key] = nil
		self:UpdateIncludeRelevancyMask()
		self:SetLOSUpdates(true)
	end
end

local function beaconStart(self, target, delay)
	Log("Starting beacon transition for player %s!", self)
	if not kIgnorePlayers then
		self:AddTimedCallback(makePlayerRelevant, delay)
	end
	self:AddTimedCallback(makePlayerIrrelevant, kDistressBeaconTime + 5)
	self:SetLOSUpdates(false)
end

local oldTriggerDistressBeacon = Observatory.TriggerDistressBeacon

function Observatory:TriggerDistressBeacon()
	local distressOrigin = self:GetDistressOrigin()

	-- May happen at the end of the game?
	if not distressOrigin or self:GetIsBeaconing() then
		return false, true
	end

	local step = kDistressBeaconTime / Server.GetNumPlayers()
	local closure_self = {beaconStart, step, distressOrigin, delay = 0}

	local functor = Closure [=[
		self beaconStart step target
		args player

		if player:isa "Marine" then
			beaconStart(player, target, self.delay)
			self.delay = self.delay + step
		end
	]=] (closure_self)

	GetGamerules():GetTeam1():ForEachPlayer(functor) -- Marines
	GetGamerules():GetTeam2():ForEachPlayer(functor) -- Aliens

	local entities = self:GetCommandStation():GetLocationEntity():GetEntitiesInTrigger()
	local constructs = {}
	local ips = {}
	if #entities == 0 then
		entities = GetEntitiesWithMixinWithinRange("Construct", distressOrigin, 20)
		constructs = entities
		for i = 1, #constructs do
			if constructs[i]:isa "InfantryPortal" then
				table.insert(ips, constructs[i])
			end
		end
	else
		for i = 1, #entities do
			if entities[i]:isa "InfantryPortal" then
				table.insert(ips, entities[i])
				table.insert(constructs, entities[i])
			elseif HasMixin(entities[i], "Construct") then
				table.insert(constructs, entities[i])
			end
		end
	end
	local step = kDistressBeaconTime / #constructs

	Log("Found %s constructs and %s IPs; step: %s", #constructs, #ips, step)

	local delay = 0
	for i = 1, #constructs do
		local construct = constructs[i]

		ent:AddTimedCallback(makeRelevant, delay)
		ent:AddTimedCallback(makeIrrelevant, kDistressBeaconTime + 5)
		delay = delay + step
	end

	local step = kDistressBeaconTime / #ips
	local delay = 0
	for i = 1, #ips do
		ips[i]:AddTimedCallback(ips[i].FinishSpawn, delay)
		delay = delay + step
	end

	return oldTriggerDistressBeacon(self)
end

function Observatory:PerformDistressBeacon()

	self.distressBeaconSound:Stop()

	local distressOrigin = self:GetDistressOrigin()
	if not distressOrigin then
		return false
	end

	local to_beacon = GetPlayersToBeacon(self)

	local spawnPoints = GetBeaconPointsForTechPoint(self:GetCommandStation().attachedId)
	Log("attached: %s", Shared.GetEntity(self:GetCommandStation().attachedId))
	for k in pairs(BeaconPoints) do
		Log("tech point: %s", k)
	end
	if not spawnPoints then
		Log "No spawnpoints!"
	end

	for i = 1, #to_beacon do
		local player = to_beacon[i]

		player:SetOrigin(spawnPoints[i])
		player:TriggerBeaconEffects()
	end

	self:TriggerEffects("distress_beacon_complete")

end
