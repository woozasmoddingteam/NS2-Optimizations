if Server then
	local old = Tunnel.AddExit
	function Tunnel:AddExit(exit)
		old(self, exit)
		local a = Shared.GetEntity(self.exitAId)
		local b = Shared.GetEntity(self.exitBId)
		if a and b then
			a.connected = true
			b.connected = true
			a:MarkBlipDirty()
			b:MarkBlipDirty()
			self:SetConnectionStartPoint(a:GetOrigin())
			self:SetConnectionEndPoint(b:GetOrigin())
		end
	end

	local old = Tunnel.RemoveExit
	function Tunnel:RemoveExit(exit)
		old(self, exit)
		local a = Shared.GetEntity(self.exitAId)
		local b = Shared.GetEntity(self.exitBId)
		self:SetConnectionStartPoint()
		if a ~= nil then
			a.connected = false
			a:MarkBlipDirty()
		elseif b ~= nil then
			b.connected = false
			b:MarkBlipDirty()
		end
	end
end
