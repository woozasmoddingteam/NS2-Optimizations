
class 'GUIMinimapConnection' (GUIItem)

local GUIItem = GUIItem
local GUI = GUI

local kLineTextureCoord = {0, 0, 64, 16}

function GUIMinimapConnection:Update()

	local animation = Shared.GetTime() % 1

	local x1Coord = kLineTextureCoord[1] - animation * (kLineTextureCoord[3] - kLineTextureCoord[1])
	local x2Coord = x1Coord + self.length

	local textureIndex = 16

	self.line:SetTexturePixelCoordinates(x1Coord, textureIndex, x2Coord, textureIndex + 16)
end

function GUIMinimapConnection:Initialize(parent, mini, teamNumber)
	self.line = GUI.CreateItem()
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

end
