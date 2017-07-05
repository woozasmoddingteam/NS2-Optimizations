if Server then
	local old = Tunnel.AddExit
	function Tunnel:AddExit(exit)
		old(self, exit)
		Log "Tunnel.AddExit"
		local a = Shared.GetEntity(self.exitAId)
		local b = Shared.GetEntity(self.exitBId)
		if a and b then
			a.connected = true
			b.connected = true
			a:MarkBlipDirty()
			b:MarkBlipDirty()
		end
	end

	local old = Tunnel.RemoveExit
	function Tunnel:RemoveExit(exit)
		old(self, exit)
		Log "Tunnel.RemoveExit"
		local a = Shared.GetEntity(self.exitAId)
		local b = Shared.GetEntity(self.exitBId)
		if a ~= nil then
			a.connected = false
			a:MarkBlipDirty()
		end
		if b ~= nil then
			b.connected = false
			b:MarkBlipDirty()
		end
	end
end
