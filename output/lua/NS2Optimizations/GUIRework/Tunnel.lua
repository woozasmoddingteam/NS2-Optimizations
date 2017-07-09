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
			a.mapBlip.target = b.mapBlip:GetId()
		end
	end

	local old = Tunnel.RemoveExit
	function Tunnel:RemoveExit(exit)
		old(self, exit)
		local a = Shared.GetEntity(self.exitAId)
		local b = Shared.GetEntity(self.exitBId)
		if a ~= nil then
			a.connected = false
			a.mapBlip.target = Entity.invalidId
			a:MarkBlipDirty()
		elseif b ~= nil then
			b.connected = false
			a.mapBlip.target = Entity.invalidId
			b:MarkBlipDirty()
		end
	end
end
