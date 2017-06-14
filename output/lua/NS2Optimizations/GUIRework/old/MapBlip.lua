-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/MapBlip.lua
--
-- MapBlips are displayed on player minimaps based on relevancy.
--
-- Created by Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MinimapMappableMixin.lua")

local Client = Client
local Shared = Shared
local Server = Server

class 'MapBlip' (Entity)

MapBlip.kMapName = "MapBlip"

local networkVars =
{
	m_origin = "position (by 10000 [0], by 10000 [0], by 10000 [0])",
	m_angles = "angles (by 10000 [0], by 10000 [0], by 10000 [0])",

    type = "enum kMinimapBlipType",
    team = "integer (" .. kTeamInvalid .. " to " .. kSpectatorIndex .. ")",

	inCombat        = "boolean",
	isParasited     = "boolean",
	isHallucination = "boolean",
	active          = "boolean",
}

function MapBlip:OnCreate()
    Entity.OnCreate(self)
    
    self:SetUpdates(false)
    
    self:SetRelevancyDistance(Math.infinity)

    local mask = 0

	local parent = self:GetParent()
	if parent and HasMixin(parent, "LOS") and parent:GetIsSighted() then
		mask = bit.bor(mask, kRelevantToTeam1, kRelevantToTeam2)
	elseif self.team == kTeam1Index then
		mask = bit.bor(mask, kRelevantToTeam1)
	elseif self.mapblipTeam == kTeam2Index then
		mask = bit.bor(mask, kRelevantToTeam2)
	else
		mask = bit.bor(mask, kRelevantToTeam1, kRelevantToTeam2)
	end
    
    self:SetExcludeRelevancyMask(mask)
    
    if Client then
        InitMixin(self, MinimapMappableMixin)
    end
end

-- used by bot brains
function MapBlip:GetType()
    return self.type
end

-- required by minimapmappable
function MapBlip:GetMapBlipType()
    return self.type
end

function MapBlip:GetTeamNumber()
    return self.team
end

function MapBlip:GetRotation()
    return 0
end

function MapBlip:GetIsActive()
    return self.active
end

function MapBlip:GetIsInCombat()
    return self.isInCombat
end

function MapBlip:GetIsParasited()
    return self.isParasited
end

MapBlip.GetMapBlipOriginOverride = MapBlip.GetWorldOrigin

if Client then
    
    local kFastMoverTypes = {}
    kFastMoverTypes[kMinimapBlipType.Drifter] = true
    kFastMoverTypes[kMinimapBlipType.MAC]     = true

    function MapBlip:GetMapBlipColor(minimap, item)
        return self.color
    end

	function MapBlip:UpdateMinimapItem(minimap, item)
		if Client.GetLocalPlayer():GetTeamNumber() == self.team or minimap.spectating then
			if self.isHallucination then
				self.color = kHallucinationColor
			elseif self.isInCombat then
				self.color = self.active and self.PulseRed(1) or self.PulseDarkRed(item.blipColor)
			else
				self.color = item.blipColor
			end
		end
	end
    
    function MapBlip:GetMapBlipTeam(minimap)
      
        local playerTeam = minimap.playerTeam
        local blipTeam = kMinimapBlipTeam.Neutral

        local blipTeamNumber = self:GetTeamNumber()
        local isSteamFriend = false
        
        if self.clientIndex and self.clientIndex > 0 and blipTeamNumber ~= GetEnemyTeamNumber(playerTeam) then

            local steamId = GetSteamIdForClientIndex(self.clientIndex)
            if steamId then
                isSteamFriend = Client.GetIsSteamFriend(steamId)
            end

        end
        
        if not self:GetIsActive() then

            if blipTeamNumber == kMarineTeamType then
                blipTeam = kMinimapBlipTeam.InactiveMarine
            elseif blipTeamNumber== kAlienTeamType then
                blipTeam = kMinimapBlipTeam.InactiveAlien
            end

        elseif isSteamFriend then
        
            if blipTeamNumber == kMarineTeamType then
                blipTeam = kMinimapBlipTeam.FriendMarine
            elseif blipTeamNumber== kAlienTeamType then
                blipTeam = kMinimapBlipTeam.FriendAlien
            end
        
        else

            if blipTeamNumber == kMarineTeamType then
                blipTeam = kMinimapBlipTeam.Marine
            elseif blipTeamNumber== kAlienTeamType then
                blipTeam = kMinimapBlipTeam.Alien
            end
            
        end  

        return blipTeam
    end
     
    function MapBlip:InitActivityDefaults()
        -- default; these usually don't move, and if they move they move slowly. They may be attacked though, and then they
        -- need to animate at a higher rate
        self.combatActivity = kMinimapActivity.Medium
        self.movingActivity = kMinimapActivity.Low
        self.defaultActivity = kMinimapActivity.Static
        
        local isFastMover = kFastMoverTypes[self.type]
        
        if isFastMover then
            self.defaultActivity = kMinimapActivity.Low
            self.movingActivity = kMinimapActivity.Medium
        end
        
    end
    
    function MapBlip:UpdateMinimapActivity(minimap, item)
        if self.combatActivity == nil then
            self:InitActivityDefaults()
        end
        -- type can change (see infestation)
        local blipType = self:GetMapBlipType()            
        -- the blipTeam can change if power changes
        local blipTeam = self:GetMapBlipTeam(minimap)
        if blipType ~= item.blipType or blipTeam ~= item.blipTeam then
            item.resetMinimapItem = true
        end
        local origin = self:GetOrigin()
        local isMoving = item.prevOrigin ~= origin
        item.prevOrigin = origin
        local result = (self.isInCombat and self.combatActivity) or  
              (isMoving and self.movingActivity) or 
              self.defaultActivity
        if self.type == kMinimapBlipType.Scan then
            -- the scan blip are animating.
            -- TODO: make a ScanMapBlip subclass and handle things there instead... right now, the animation is handled
            -- by the GUIMinimap changing the blipsize for all scans at the same time... which looks slightly silly, but
            -- multiple scans are not used all that much.
            item.resetMinimapItem = true
            return kMinimapActivity.High
        end
        return result
    end

end -- Client


Shared.LinkClassToMap("MapBlip", MapBlip.kMapName, networkVars)

class 'PlayerMapBlip' (MapBlip)

PlayerMapBlip.kMapName = "PlayerMapBlip"

local playerNetworkVars =
{
    clientIndex = "entityid",
}

if Client then
      function PlayerMapBlip:InitActivityDefaults()
        self.isInCombatActivity = kMinimapActivity.Medium
        self.movingActivity = kMinimapActivity.Medium
        self.defaultActivity = kMinimapActivity.Medium
      end
 
    -- the local player has a special marker; do not show his mapblip 
    function PlayerMapBlip:UpdateMinimapActivity(minimap, item)
        return self.clientIndex == minimap.clientIndex and MapBlip.UpdateMinimapActivity(self, minimap, item)
    end
    
    -- players can show their names on the minimap
    function PlayerMapBlip:UpdateHook(minimap, item)
        minimap:DrawMinimapName(item, self:GetMapBlipTeam(minimap), self.clientIndex, self.isParasited)
    end

end


Shared.LinkClassToMap("PlayerMapBlip", PlayerMapBlip.kMapName, playerNetworkVars)
