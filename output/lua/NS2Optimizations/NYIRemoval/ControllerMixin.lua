Log "ControllerMixin.lua"

local Default     = Shared.GetCollisionRepId("default")
local Move        = Shared.GetCollisionRepId("move")
local Damage      = Shared.GetCollisionRepId("damage")
local Select      = Shared.GetCollisionRepId("select")
local LOS         = Shared.GetCollisionRepId("los")

local kSkinOffset = 0.1

function ControllerMixin:UpdateControllerFromEntity(allowTrigger)

    PROFILE("ControllerMixin:UpdateControllerFromEntity")

    if allowTrigger == nil then
        allowTrigger = true
    end

	local controller = self.controller

    if controller ~= nil then

		local outer = self.controllerOutter
    
        local controllerHeight, controllerRadius = self:GetControllerSize()
        
        if controllerHeight ~= self.controllerHeight or controllerRadius ~= self.controllerRadius then
        
            self.controllerHeight = controllerHeight
            self.controllerRadius = controllerRadius
        
            local capsuleHeight = controllerHeight - 2*controllerRadius

			local coords = controller:GetCoords()
        
            if capsuleHeight < 0.001 then
                -- Use a sphere controller
                controller:SetupSphere( controllerRadius, coords, allowTrigger )
            else
                -- A flat bottomed cylinder works well for movement since we don't
                -- slide down as we walk up stairs or over other lips. The curved
                -- edges of the cylinder allows players to slide off when we hit them,
                controller:SetupCapsule( controllerRadius, capsuleHeight, coords, allowTrigger )
            end

            if controllerOutter then                
                controllerOutter:SetupCylinder( controllerRadius * 1.5, controllerHeight, coords, allowTrigger )
            end                
            
            -- Remove all collision reps except movement from the controller.
			controller:RemoveCollisionRep(LOS)
			controllerOutter:RemoveCollisionRep(LOS)
			controller:RemoveCollisionRep(Default)
			controllerOutter:RemoveCollisionRep(Default)
			controller:RemoveCollisionRep(Damage)
			controllerOutter:RemoveCollisionRep(Damage)
			controller:RemoveCollisionRep(Select)
			controllerOutter:RemoveCollisionRep(Select)
            
            controller:SetTriggeringCollisionRep(CollisionRep.Move)
            controller:SetPhysicsCollisionRep(CollisionRep.Move)
 
        end
        
        -- The origin of the controller is at its center and the origin of the
        -- player is at their feet, so offset it.
        VectorCopy(self:GetOrigin(), origin)
		local origin = self:GetOrigin()
        origin.y = origin.y + controllerHeight * 0.5 + kSkinOffset
        
        controller:SetPosition(origin, allowTrigger)
        
        if controllerOutter then  
            controllerOutter:SetPosition(origin, allowTrigger)
        end    
        
    end
    
end
