
local zero = false
local function check(self)
	local state = self.state
	if state == kGameState.WarmUp then
		if zero == false then
			ZeroCosts()
			zero = true
		end
	elseif zero == true then
		RestoreCosts()
		zero = false
	end
end

if Server then
	local old = GameInfo.SetState
	function GameInfo:SetState(state)
		old(self, state)
		check(self)
	end
end

if Client then
	local old = GameInfo.OnInitialized
	function GameInfo:OnInitialized()
		old(self)
		check(self)
		self:AddFieldWatcher("state", check)
	end
end
