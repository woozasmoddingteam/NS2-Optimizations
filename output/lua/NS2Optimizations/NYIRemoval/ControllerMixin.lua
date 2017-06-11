Script.Load "lua/CollisionRep.lua"

local Default = CollisionRep.Default
local Damage  = CollisionRep.Damage
local Select  = CollisionRep.Select
local LOS     = CollisionRep.LOS

local origin = Vector.origin
function ControllerMixin:UpdateControllerFromEntity(allowTrigger)

    PROFILE("ControllerMixin:UpdateControllerFromEntity")

    if allowTrigger == nil then
        allowTrigger = true
    end

    if self.controller ~= nil then
    
        local controllerHeight, controllerRadius = self:GetControllerSize()
        
        if controllerHeight ~= self.controllerHeight or controllerRadius ~= self.controllerRadius then
        
            self.controllerHeight = controllerHeight
            self.controllerRadius = controllerRadius
        
            local capsuleHeight = controllerHeight - 2*controllerRadius
        
            if capsuleHeight < 0.001 then
                -- Use a sphere controller
                self.controller:SetupSphere( controllerRadius, self.controller:GetCoords(), allowTrigger )
            else
                -- A flat bottomed cylinder works well for movement since we don't
                -- slide down as we walk up stairs or over other lips. The curved
                -- edges of the cylinder allows players to slide off when we hit them,
                self.controller:SetupCapsule( controllerRadius, capsuleHeight, self.controller:GetCoords(), allowTrigger )
                --self.controller:SetupCylinder( controllerRadius, controllerHeight, self.controller:GetCoords(), allowTrigger )
            end

            if self.controllerOutter then                
                --self.controllerOutter:SetupBox(Vector(self.controllerRadius * 1.3, self.controllerHeight * 0.5, self.controllerRadius * 1.3), self.controller:GetCoords(), allowTrigger)
                self.controllerOutter:SetupCylinder( controllerRadius * 1.5, controllerHeight, self.controller:GetCoords(), allowTrigger )
            end                
            
            -- Remove all collision reps except movement from the controller.
			self.controller:RemoveCollisionRep(Default)
			self.controller:RemoveCollisionRep(Damage)
			self.controller:RemoveCollisionRep(Select)
			self.controller:RemoveCollisionRep(LOS)
			if self.controllerOuter then
				self.controllerOuter:RemoveCollisionRep(Default)
				self.controllerOuter:RemoveCollisionRep(Damage)
				self.controllerOuter:RemoveCollisionRep(Select)
				self.controllerOuter:RemoveCollisionRep(LOS)
			end
            
            self.controller:SetTriggeringCollisionRep(CollisionRep.Move)
            self.controller:SetPhysicsCollisionRep(CollisionRep.Move)
 
        end
        
        -- The origin of the controller is at its center and the origin of the
        -- player is at their feet, so offset it.
        VectorCopy(self:GetOrigin(), origin)
        origin.y = origin.y + self.controllerHeight * 0.5 + kSkinOffset
        
        self.controller:SetPosition(origin, allowTrigger)
        
        if self.controllerOutter then  
            self.controllerOutter:SetPosition(origin, allowTrigger)
        end    
        
    end
    
end
