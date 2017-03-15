if (Server) then
   function BO_ResetRelevancyMask(self)
      local id = self.GetId and self:GetId() or 0
      -- Log("BeaconOpti mod: Reseting relevancy for '" .. EntityToString(self) .. "' (id " .. tostring(id) .. ")")
      if (self and self.UpdateIncludeRelevancyMask) then
         self:UpdateIncludeRelevancyMask()
      end
      if (self and self:isa("Weapon") and self.SetIncludeRelevancyMask) then
         self:SetIncludeRelevancyMask(0)
      end
      if (self and self:isa("Weapon") and self.SetRelevancy) then
         self:SetRelevancy(false)
      end
      return
   end

   function BO_SetIncludeRelevancyMask(self)
      local mask = self.BO_relevancy_mask

      self.BO_relevancy_mask = nil
      if mask and self.SetIncludeRelevancyMask then
         -- local id = self.GetId and self:GetId() or 0
         -- Log("BeaconOpti mod: Include into relevancy '" .. EntityToString(self) .. "' (id " .. tostring(id) .. ")")
         self:SetIncludeRelevancyMask(mask)
      end
      return
   end
end
