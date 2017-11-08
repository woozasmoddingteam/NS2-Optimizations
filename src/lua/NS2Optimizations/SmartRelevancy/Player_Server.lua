local kRelevantToAll = kRelevantToAll

if kNS2OptiConfig.InfinitePlayerRelevancy then
	function Player:UpdateIncludeRelevancyMask()
		 self:SetIncludeRelevancyMask(0xFFFFFFFF)
	end
end

function Player:UpdateClientRelevancyMask()

	 local mask = 0xFFFFFFFF

	 if self:GetTeamNumber() == 1 then

		  if self:GetIsCommander() then
				mask = kRelevantToTeam1Commander
		  else
				mask = kRelevantToTeam1Unit
		  end

	 elseif self:GetTeamNumber() == 2 then

		  if self:GetIsCommander() then
				mask = kRelevantToTeam2Commander
		  else
				mask = kRelevantToTeam2Unit
		  end

	 -- Spectators should see all map blips.
	 elseif self:GetTeamNumber() == kSpectatorIndex then

		  if self:GetIsOverhead() then
				mask = bit.bor(kRelevantToTeam1Commander, kRelevantToTeam2Commander)
		  else
				mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
		  end

	 -- ReadyRoomPlayers should not see any blips.
	 elseif self:GetTeamNumber() == kTeamReadyRoom then
		  mask = kRelevantToReadyRoom
	 end

	 local client = Server.GetOwner(self)
	 -- client may be nil if the server is shutting down.
	 if client then
		  client:SetRelevancyMask(mask)
	 end
end
