if Server then
	local old = PhaseGate.Update
	function PhaseGate:Update()
		old(self)
		if self.linked then
			self:SetConnectionStartPoint(self:GetOrigin())
			self:SetConnectionEndPoint(self.destinationEndpoint)
		else
			self:SetConnectionStartPoint()
		end
	end
end
