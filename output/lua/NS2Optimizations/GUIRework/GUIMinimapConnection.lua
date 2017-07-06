
class 'GUIMinimapConnection'

local kLineTexture = "ui/mapconnector_line.dds"
local kLineTextureCoord = {0, 0, 64, 16}

function GUIMinimapConnection:Update()

    local animation = Shared.GetTime() % 1
                
    local x1Coord = kLineTextureCoord[1] - animation * (kLineTextureCoord[3] - kLineTextureCoord[1])
    local x2Coord = x1Coord + self.length
    
    local textureIndex = 16
    
    self.line:SetTexturePixelCoordinates(x1Coord, textureIndex, x2Coord, textureIndex + 16)
end

function GUIMinimapConnection:Setup(startPoint, endPoint, parent, mini, teamNumber)
	if startPoint == self.startPoint and endPoint == self.endPoint then return end

	self.startPoint, self.endPoint = startPoint, endPoint
    
	-- Since we're using a texture we need to move the points up a bit so it gets aligned properly
	local align = Vector(0, -4, 0)
	startPoint = startPoint + align
	endPoint = endPoint + align

	local offset = startPoint - endPoint
	local length = offset:GetLength()
	self.length = length
	
	local direction = offset / length
	local rotation = math.atan2(direction.x, direction.y)
	if rotation < 0 then
		rotation = rotation + math.pi * 2.5
	else
		rotation = rotation + math.pi * 0.5
	end

	self.line = GUI.CreateItem()
	self.line:SetTexture(kLineTexture)
	self.line:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.line:SetInheritsParentStencilSettings(true)
	parent:AddChild(self.line)
        
    self.line:SetSize(Vector(length, GUIScale(mini and 6 or 10), 0))
    self.line:SetPosition(startPoint)
    self.line:SetRotationOffset(Vector(-length, 0, 0))
    self.line:SetRotation(Vector(0, 0, rotation))
    self.line:SetColor(teamNumber == kTeam1Index and kMarineFontColor or kAlienFontColor)
end

function GUIMinimapConnection:Uninitialize()
    if self.line then
        GUI.DestroyItem(self.line)
        self.line = nil
    end
end

--[[
local kLineTextureCoord = {0, 0, 64, 16}

function GUIMinimapConnection:UpdateAnimation(teamNumber, modeIsMini)
    local animation = Shared.GetTime() % 1
                
    local x1Coord = kLineTextureCoord[1] - animation * (kLineTextureCoord[3] - kLineTextureCoord[1])
    local x2Coord = x1Coord + (self.length or 0)
    
    -- Don't draw arrows for just 2 PGs, the direction is clear here
    -- Gorge tunnels also don't need this since it is limited to entrance/exit
    local textureIndex = 16
    
    self.line:SetTexturePixelCoordinates(x1Coord, textureIndex, x2Coord, textureIndex + 16)
    self.line:SetColor(ConditionalValue(teamNumber == kTeam1Index, kMarineFontColor, kAlienFontColor))
end

function GUIMinimapConnection:Render()

    if not self.line then

        self.line = GUI.CreateItem()
        self.line:SetTexture(kLineTexture)
        self.line:SetAnchor(GUIItem.Middle, GUIItem.Center)
        self.line:SetStencilFunc(self.stencilFunc)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end
    
    self.line:SetSize(Vector(self.length, GUIScale(self.modeIsMini and 6 or 10), 0))
    self.line:SetPosition(self.startPoint)
    self.line:SetRotationOffset(Vector(-self.length, 0, 0))
    self.line:SetRotation(self.rotationVec)
    
    -- update line parent
    local currentParent = self.line:GetParent()
    if currentParent and currentParent ~= self.parent then
    
        currentParent:RemoveChild(self.line)
        
        if self.parent then
            self.parent:AddChild(self.line)
        end
        
    end

end
--]]
