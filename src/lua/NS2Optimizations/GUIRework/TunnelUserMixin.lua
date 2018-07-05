local Cinematic = Cinematic
local RenderScene = RenderScene
local Shared = Shared
local Client = Client
local Server = Server

local old = getupvalue(TunnelUserMixin.OnProcessSpectate, "UpdateTunnelEffects")
local kTunnelUseScreenCinematic = getupvalue(old, "kTunnelUseScreenCinematic")
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

do
	local old = getupvalue(TunnelUserMixin.OnUpdate, "SharedUpdate")
	local UpdateSinkIn = getupvalue(old, "UpdateSinkIn")
	local UpdateExitTunnel = getupvalue(old, "UpdateExitTunnel")
	local kTunnelUseTimeout = getupvalue(old, "kTunnelUseTimeout")

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
