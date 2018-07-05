if Server then
	local old = PhaseGate.Update
	local GetDestinationGate = getupvalue(old, "GetDestinationGate")
	local ComputeDestinationLocationId = getupvalue(old, "ComputeDestinationLocationId")

	function PhaseGate:Update()
		self.phase = (self.timeOfLastPhase ~= nil) and (Shared.GetTime() < (self.timeOfLastPhase + 0.3))

		local destinationPhaseGate = GetDestinationGate(self)
		if destinationPhaseGate ~= nil and GetIsUnitActive(self) and self.deployed and destinationPhaseGate.deployed then
			self.destinationEndpoint = destinationPhaseGate:GetOrigin()
			self.linked = true
			self.targetYaw = destinationPhaseGate:GetAngles().yaw
			self.destLocationId = ComputeDestinationLocationId(self, destinationPhaseGate)
			self.mapBlip.target = destinationPhaseGate.mapBlip:GetId()
		else
			self.linked = false
			self.targetYaw = 0
			self.destLocationId = Entity.invalidId
			self.mapBlip.target = Entity.invalidId
		end
		return true
	end
end
