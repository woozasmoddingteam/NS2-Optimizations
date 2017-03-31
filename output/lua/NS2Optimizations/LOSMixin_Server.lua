
local index = 1
while assert(debug.getupvalue(LOSMixin.OnUpdate, index)) ~= "SharedUpdate" do
	index = index + 1
end

local old = debug.getupvalue(LOSMixin.OnUpdate, index)

local los_disabled_key = newproxy()

local function SharedUpdate(self, deltaTime)
	if not self[los_disabled_key] then
		return old(self, deltaTime)
	end
end

function LOSMixin:SetLOSUpdates(state)
	self[los_disabled_key] = not state
end
