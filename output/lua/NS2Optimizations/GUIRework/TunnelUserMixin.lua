local function setupvalue(f, n, v)
	local i = 1
	while assert(debug.getupvalue(f, i)) ~= n do
		i = i + 1
	end
	debug.setupvalue(f, i, v)
end

local function getupvalue(f, n, v)
	local i = 1
	while assert(debug.getupvalue(f, i)) ~= n do
		i = i + 1
	end
	local _, v = debug.getupvalue(f, i)
	return v
end

do
	local function UpdateTunnelEffects(self)

		local isInTunnel = self.inTunnel

		if self.clientIsInTunnel ~= isInTunnel then
		
			local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
			cinematic:SetCinematic(kTunnelUseScreenCinematic)
			cinematic:SetRepeatStyle(Cinematic.Repeat_None)
			
			if isInTunnel then
				self:TriggerEffects("tunnel_enter_2D")
			else
				self:TriggerEffects("tunnel_exit_2D")
			end
			
			self.clientIsInTunnel = isInTunnel
			self.clientTimeTunnelUsed = Shared.GetTime()
		
		end

	end
	setupvalue(TunnelUserMixin.OnProcessSpectate, "UpdateTunnelEffects", UpdateTunnelEffects)
end

do
	local old = getupvalue(TunnelUserMixin.OnUpdate, "SharedUpdate")
	local UpdateSinkIn = getupvalue(old, "UpdateSinkIn")
	local UpdateExitTunnel = getupvalue(old, "UpdateExitTunnel")

	if Server then
		local function SharedUpdate(self, deltaTime)
			if self.canUseTunnel then
				if self:GetIsEnteringTunnel() then
					UpdateSinkIn(self, deltaTime)
				else
					self.timeSinkInStarted = nil
					local tunnel = self.inTunnel
					if tunnel then
						UpdateExitTunnel(self, deltaTime, tunnel)
					end
				end
			end
			
			self.canUseTunnel = self.timeTunnelUsed + kTunnelUseTimeout < Shared.GetTime()
		end
		setupvalue(TunnelUserMixin.OnUpdate, "SharedUpdate", SharedUpdate)
	elseif Client then
		local function SharedUpdate(self, deltaTime)
			if self.canUseTunnel and self:GetIsEnteringTunnel() then
				UpdateSinkIn(self, deltaTime)
			end
			
			if self.GetIsLocalPlayer and self:GetIsLocalPlayer() then    
				self.inTunnel = GetIsPointInGorgeTunnel(self:GetOrigin())
				UpdateTunnelEffects(self)
			end
		end
		setupvalue(TunnelUserMixin.OnUpdate, "SharedUpdate", SharedUpdate)
	end
end

do
	local old = TunnelUserMixin.__initmixin
	function TunnelUserMixin:__initmixin()
		old(self)
		self.inTunnel = false
	end
end
