
if Server then
	local Shared = Shared
	local GetEntitiesWithMixinWithinRange = GetEntitiesWithMixinWithinRange
	local DestroyEntity = DestroyEntity

	local old = TunnelEntrance.OnUpdate
	local ComputeDestinationLocationId = getupvalue(old, "ComputeDestinationLocationId")
	local CheckForClogs                = getupvalue(old, "CheckForClogs")
	function TunnelEntrance:OnUpdate(deltaTime)

		ScriptActor.OnUpdate(self, deltaTime)

		self.beingUsed = self.timeLastInteraction + 0.1 > Shared.GetTime()
		self.destLocationId = ComputeDestinationLocationId(self)

		-- temp fix: push AI units away to prevent players getting stuck
		if self:GetIsAlive() and ( not self.timeLastAIPushUpdate or self.timeLastAIPushUpdate + 1.4 < Shared.GetTime() ) then

			local baseYaw = 0
			self.timeLastAIPushUpdate = Shared.GetTime()

			for i, entity in ipairs(GetEntitiesWithMixinWithinRange("Repositioning", self:GetOrigin(), 1.4)) do

				if entity:GetCanReposition() then

					entity.isRepositioning = true
					entity.timeLeftForReposition = 1

					baseYaw = entity:FindBetterPosition( GetYawFromVector(entity:GetOrigin() - self:GetOrigin()), baseYaw, 0 )

					if entity.RemoveFromMesh ~= nil then
						entity:RemoveFromMesh()
					end

				end

			end

		end

		local destructionAllowedTable = { allowed = true }
		if self.GetDestructionAllowed then
			self:GetDestructionAllowed(destructionAllowedTable)
		end

		if destructionAllowedTable.allowed then
			DestroyEntity(self)
		end

		if CheckForClogs(self) then
			self.clogNearMouth = true
		end

	end

	function TunnelEntrance:SuckinEntity(entity)
		if entity and HasMixin(entity, "TunnelUser") and self.tunnelId then
			local tunnelEntity = Shared.GetEntity(self.tunnelId)
			if tunnelEntity then
				tunnelEntity:MovePlayerToTunnel(entity, self)
				entity:SetVelocity(Vector(0, 0, 0))

				if entity.OnUseGorgeTunnel then
					entity:OnUseGorgeTunnel()
				end

				entity.inTunnel = tunnelEntity
			end
		end
	end

	function TunnelEntrance:OnEntityExited(entity)
		self.timeLastExited = Shared.GetTime()
		self:TriggerEffects("tunnel_exit_3D")
		entity.inTunnel = false
	end
end
