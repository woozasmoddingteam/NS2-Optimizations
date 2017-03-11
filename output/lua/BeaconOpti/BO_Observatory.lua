
-- Pushed the 15/11/16 at 20h47

if (Server) then
   Script.Load("lua/BeaconOpti/BO_Utils.lua")

   local BO_beacon_respawn_step = 0.30
   local BO_beacon_regular_step = 1 / 30

   ---------------- BeaconOpti: Untouched RespawnPlayer function (used as a fallback)

   local function GetIsPlayerNearby(self, player, toOrigin)
      return (player:GetOrigin() - toOrigin):GetLength() < Observatory.kDistressBeaconRange
   end

   local function GetPlayersToBeacon(self, toOrigin)

      local players = { }

      for index, player in ipairs(self:GetTeam():GetPlayers()) do

         -- Don't affect Commanders or Heavies
         if player:isa("Marine") then

            -- Don't respawn players that are already nearby.
            if not GetIsPlayerNearby(self, player, toOrigin) then

               if player:isa("Exo") then
                  table.insert(players, 1, player)
               else
                  table.insert(players, player)
               end

            end

         end

      end

      return players

   end

   -- Spawn players at nearest Command Station to Observatory - not initial marine start like in NS1. Allows relocations and more versatile tactics.
   local function RespawnPlayer(self, player, distressOrigin)

      -- Always marine capsule (player could be dead/spectator)
      local extents = HasMixin(player, "Extents") and player:GetExtents() or LookupTechData(kTechId.Marine, kTechDataMaxExtents)
      local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
      local range = Observatory.kDistressBeaconRange
      local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, distressOrigin, 2, range, EntityFilterAll())

      if spawnPoint then

         if HasMixin(player, "SmoothedRelevancy") then
            player:StartSmoothedRelevancy(spawnPoint)
         end

         player:SetOrigin(spawnPoint)
         if player.TriggerBeaconEffects then
            player:TriggerBeaconEffects()
         end

      end

      return spawnPoint ~= nil, spawnPoint

   end

   --------------------

   local spawn_iterator = 1
   local ObservatoryTriggerDistressBeacon = Observatory.TriggerDistressBeacon
   function Observatory:TriggerDistressBeacon()
      spawn_iterator = 1

      local it = 0
      local nb_added = 0
      local nb_weapon_added = 0
      local step = 0
      local entities = {}
      local nb_entities = 0
      local nearest_CC = nil
      local distressOrigin = self:GetDistressOrigin()

      if (not distressOrigin) then
         return -- Safety check in case be beacon with no CC
      end

      local nearest_CC_locname = nil
      local nearest = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)
      if nearest then
         nearest_CC_locname = nearest:GetLocationName()
      end

      Log("BeaconOpti mod: TriggerDistressBeacon() called on : " .. tostring(nearest_CC_locname))
      Log("BeaconOpti mod: Starting smooth relevancy changes ...")
      -- Include all Human players beaconned
      nb_added = 0
      nb_weapon_added = 0
      for _, p in ipairs(GetEntitiesForTeam("Marine", self:GetTeamNumber()))
      do
         if (p and p.GetIsAlive and p:GetIsAlive()) then
            table.insert(entities, p)
            nb_added = nb_added + 1
            if (p.GetWeapons) then -- Just for safety
               for i, weapon in ipairs(p:GetWeapons()) do
                  table.insert(entities, weapon)
                  nb_weapon_added = nb_weapon_added + 1
               end
            end
         end
      end
      if (nb_added > 0) then
         Log("BeaconOpti mod: Adding " .. tostring(nb_added) .. " marines (and " .. tostring(nb_weapon_added) .. " weapons)")
      end

      -- but only aliens nearby the beacon location
      -- Edit: Take all the aliens: before the 3s delay the aliens are out of relevancy range
      --       so we need to take them into account (and in tunnels)
      for _, teamnb in ipairs({GetEnemyTeamNumber(self:GetTeamNumber()), self:GetTeamNumber()})
      do
         nb_added = 0
         nb_weapon_added = 0
         for _, p in ipairs(GetEntitiesForTeamWithinRange("ScriptActor", teamnb,
                                                          distressOrigin,
                                                          kMaxRelevancyDistance + 10))
         do
            -- Exclude marines, they have already been added (see above)
            if (p and p.GetIsAlive and p:GetIsAlive() and not p:isa("Marine")) then
               table.insert(entities, p)
               nb_added = nb_added + 1
               if (p.GetWeapons) then -- Just for safety
                  for i, weapon in ipairs(p:GetWeapons()) do
                     table.insert(entities, weapon)
                     nb_weapon_added = nb_weapon_added + 1
                  end
               end
            end
         end
         if (nb_added > 0) then
            Log("BeaconOpti mod: Adding " .. tostring(nb_added)
                   .. " team n'" .. tostring(teamnb)
                   .. " ScriptActor entities (and " .. tostring(nb_weapon_added) .. " weapons)")
         end
      end

      -- Add powerconsumers buildings
      nb_added = 0
      for _, p in ipairs(GetEntitiesWithMixinForTeamWithinRange("PowerConsumer", self:GetTeamNumber(),
                                                                self:GetDistressOrigin(),
                                                                kMaxRelevancyDistance))
      do
         if (p and p.GetIsAlive and p:GetIsAlive()) then
            table.insert(entities, p)
            nb_added = nb_added + 1
         end
      end
      if (nb_added > 0) then
         Log("BeaconOpti mod: Adding " .. tostring(nb_added) .. " buildings (powerConsumer)")
      end

      nb_entities = #entities
      -- All entities must be loaded at X% of the beacon delay (so there so room left for stuff to be done)
      step = (Observatory.kDistressBeaconTime * 0.90) / nb_entities
      for _, ent in ipairs(entities)
      do
         local mask = nil

         if (ent:isa("Player") and ent:GetTeamNumber() == 1) then
            -- Only marines/exo needs to be added into relevancy for everyone, other stuff don't get teleported
            mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
         else
            mask = bit.bor(kRelevantToTeam1, 0)
         end

         -- Log("BeaconOpti mod: SmoothBeacon: '" .. EntityToString(ent) .. "(" .. ent:GetId() .. ")" .. "'"
         --     .. " will be added to relevancy mask for everyone in: "
         --        .. tostring(it) .. "")
         ent.BO_relevancy_mask = mask
         ent.BO_beaconTime = Shared.GetTime() + Observatory.kDistressBeaconTime
         Entity.AddTimedCallback(ent, BO_SetIncludeRelevancyMask, it)
         Entity.AddTimedCallback(ent, BO_ResetRelevancyMask, Observatory.kDistressBeaconTime + 10)
         it = it + step
      end
      return ObservatoryTriggerDistressBeacon(self)
   end

   local function BO_RespawnPlayer(self, player, distressOrigin)
      local spawnPoint = nil
      local location = GetLocationForPoint(distressOrigin, self)
      if (location) then
         -- local TP = GetTechPointForLocation(location.name)
         local techpoint_id = FindNearestEntityId("TechPoint", distressOrigin)
         if (techpoint_id) then
            local points = getBeaconSpawnPoints()[techpoint_id]
            local extents = HasMixin(player, "Extents") and player:GetExtents() or LookupTechData(kTechId.Marine, kTechDataMaxExtents)
            local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
            local range = Observatory.kDistressBeaconRange

            local nb_players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
            if (points and #points > 0) then
               local step = Clamp(math.floor(#points / nb_players), 1, 4)
               while (spawn_iterator < #points) do

                  local orig = points[spawn_iterator]

                  -- Log("Testing orig: " .. orig.x .. ":" .. orig.y .. ":" .. orig.z)
                  spawnPoint = ValidateSpawnPoint(orig, capsuleHeight, capsuleRadius, EntityFilterAll(), orig)
                  if spawnPoint then

                     if HasMixin(player, "SmoothedRelevancy") then
                        player:StartSmoothedRelevancy(spawnPoint)
                     end

                     player:SetOrigin(spawnPoint)
                     -- Log("Spawn SUCCESS")
                     if player.TriggerBeaconEffects and math.random() < 0.6 then
                        player:TriggerBeaconEffects()
                     end

                     spawn_iterator = spawn_iterator + step
                     break
                  else
                     -- Move to the next possible spawn orig faster (strong chances points closed are crownd)
                     spawn_iterator = spawn_iterator + 1
                  end
               end
            end
         end
      end

      -- if (not spawnPoint) then
      --    Log("Spawn FAILED")
      -- end
      return spawnPoint ~= nil, spawnPoint
   end

   local lastDistressOrig = nil
   local function BO_BeaconPlayer(player, distressOrigin)

      if (not player or not player:isa("Player") or not player:GetIsAlive()) then
         return
      end

      ---------------------- BO code added to PerformDistressBeacon
      local success, respawnPoint = nil, nil
      -- local distressOrigin = player.BO_distress_orig
      local kDistressBeaconRange = Observatory.kDistressBeaconRange

      if (not distressOrigin) then
         distressOrigin = lastDistressOrig -- Emergency case
      end
      if (distressOrigin) then
         success, respawnPoint = BO_RespawnPlayer(nil, player, distressOrigin)
         if (not success) then -- Fallback
            Log("BeaconOpti mod: Failed to place player " .. player:GetName() .. ". Fallback to ns2 code")
            for i = 1, 10 do
               success, respawnPoint = RespawnPlayer(nil, player, distressOrigin)
               if (success) then
                  break
               end
            end
            if (not success) then
               local nearestPP = GetNearest(distressOrigin, "PowerPoint")
               Log("BeaconOpti mod: Failed to place player " .. player:GetName() .. ". Fallback to backup code")
               if (nearestPP) then
                  for i = 1, 10 do
                     success, respawnPoint = RespawnPlayer(nil, player, nearestPP:GetOrigin())
                     if (success) then
                        Log("BeaconOpti mod: backup code SUCCESS")
                        break
                     end
                  end
               end
            end
         end

         ----------------------

         if (not success) then -- Urgency fallback (should not happen)
            local successfullPositions = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(),
                                                                       distressOrigin, kDistressBeaconRange)
            Log("BeaconOpti mod: Regular code failed too to place player " .. player:GetName() .. ". Last resort: teleport at the same pos than an other marine")
            if (#successfullPositions > 0) then
               if player:isa("Exo") then
                  player:SetOrigin(successfullPositions[math.random(1, #successfullPositions)]:GetOrigin())
               else
                  player:SetOrigin(successfullPositions[math.random(1, #successfullPositions)]:GetOrigin())
                  if player.TriggerBeaconEffects then
                     player:TriggerBeaconEffects()
                  end

               end

               -- end
            end
         end
      else
         Log("BeaconOpti mod: Warning: nil distress origin !")
      end

      -- player.BO_distress_orig = nil
      return
   end

   local function BO_IPRespawnPlayer(ip)
      if (ip and ip:isa("InfantryPortal") and ip:GetIsAlive()) then
         ip:FinishSpawn()
      end
   end

   function Observatory:PerformDistressBeacon()

      self.distressBeaconSound:Stop()

      local anyPlayerWasBeaconed = false
      local successfullPositions = {}
      local successfullExoPositions = {}
      local failedPlayers = {}

      Log("BeaconOpti mod: PerformDistressBeacon called")
      local distressOrigin = self:GetDistressOrigin()
      if distressOrigin then

         local IPs = GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), distressOrigin, kInfantryPortalAttachRange + 1)
         local entities_to_smooth = {}
         local respawn_to_smooth = {}
         local players_to_beacon = GetPlayersToBeacon(self, distressOrigin)

         lastDistressOrig = distressOrigin
         Log("BeaconOpti mod: PerformDistressBeacon called: origin found and "
                .. tostring(#players_to_beacon) .. " players to teleport back")
         for index, player in ipairs(players_to_beacon) do
            table.insert(entities_to_smooth, player)


            -- ---------------------- BO code added to PerformDistressBeacon
            -- local success, respawnPoint = nil, nil
            -- success, respawnPoint = BO_RespawnPlayer(self, player, distressOrigin)
            -- if (not success) then -- Fallback
            --    Log("BO mod: Failed to place player " .. player:GetName() .. ". Fallback to ns2 code")
            --    success, respawnPoint = RespawnPlayer(self, player, distressOrigin)
            -- end
            -- ----------------------

            -- if success then

            --    anyPlayerWasBeaconed = true
            --    if player:isa("Exo") then
            --       table.insert(successfullExoPositions, respawnPoint)
            --    end

            --    table.insert(successfullPositions, respawnPoint)

            -- else
            --    table.insert(failedPlayers, player)
            -- end

         end

         -- Also respawn players that are spawning in at infantry portals near command station (use a little extra range to account for vertical difference)
         for index, ip in ipairs(IPs) do

            -- ip:FinishSpawn()
            -- Log("BeaconOpti mod: PerformDistressBeacon: IPs FinishSpawn() called in " .. tostring(beacon_time_it) .. "s")
            if (ip and ip:GetIsAlive() and GetIsUnitActive(ip) and ip.queuedPlayerId ~= Entity.invalidId) then
               table.insert(respawn_to_smooth, ip)
            end

         end

         -- Interleave the marine player being respawned to reduce the spike lag
         if (#respawn_to_smooth > 0) then
            local final_size = #entities_to_smooth + #respawn_to_smooth
            local interleave_step = math.max(1, final_size / #respawn_to_smooth)
            Log("BeaconOpti: Interleaving respawn and alloc them more time than the rest to reduce lag " ..
                   "(" .. tostring(#respawn_to_smooth) .. " respawn)")
            for i = 1, #respawn_to_smooth do
               table.insert(entities_to_smooth, i * interleave_step, respawn_to_smooth[i])
            end
         end

         local regular_time_it = 0
         local respawn_time_it = BO_beacon_respawn_step -- Start with a small delay
         for index, ent in ipairs(entities_to_smooth) do
            if ent:isa("Player") then
               anyPlayerWasBeaconed = true
               Log("BeaconOpti mod: PerformDistressBeacon: player [" .. ent:GetName() .. "] getting beaconned in " .. tostring(regular_time_it) .. "s")
               -- We don't need the callback anymore the entity is precached in relevancy already
               -- ent.BO_distress_orig = distressOrigin
               -- Entity.AddTimedCallback(ent, BO_BeaconPlayer, regular_time_it)
               BO_BeaconPlayer(ent, distressOrigin)
               regular_time_it = regular_time_it + BO_beacon_regular_step
            elseif ent:isa("InfantryPortal") then
               local queuedPlayer = Shared.GetEntity(ent.queuedPlayerId)
               local spawnPoint = ent:GetAttachPointOrigin("spawn_point")
               if (queuedPlayer and queuedPlayer.GetName) then -- Just for safety I am paranoid
                  Log("BeaconOpti mod: PerformDistressBeacon: player [" .. queuedPlayer:GetName() .. "] getting respawned in " .. tostring(respawn_time_it) .. "s")
               end
               Entity.AddTimedCallback(ent, BO_IPRespawnPlayer, respawn_time_it)
               table.insert(successfullPositions, spawnPoint)
               -- Respawn cost a lot more than being teleported back
               -- (marine + rifle + pistol + axe + builder) to create completly and spread on network
               respawn_time_it = respawn_time_it + BO_beacon_respawn_step
            end
         end

      end



      local usePositionIndex = 1
      local numPosition = #successfullPositions

      for i = 1, #failedPlayers do

         local player = failedPlayers[i]

         if player:isa("Exo") then
            player:SetOrigin(successfullExoPositions[math.random(1, #successfullExoPositions)])
         else

            player:SetOrigin(successfullPositions[usePositionIndex])
            if player.TriggerBeaconEffects then
               player:TriggerBeaconEffects()
            end

            usePositionIndex = Math.Wrap(usePositionIndex + 1, 1, numPosition)

         end

      end

      if anyPlayerWasBeaconed then
         self:TriggerEffects("distress_beacon_complete")
      end
   end

end


