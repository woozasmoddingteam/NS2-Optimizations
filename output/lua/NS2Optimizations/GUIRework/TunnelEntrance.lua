
if Server then
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
		entity.inTunnel = nil
    end
end
