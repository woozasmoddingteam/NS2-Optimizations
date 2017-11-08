
function GUIScript:GetIsVisible()
	return true
end

function GUIScript:GetShouldUpdate()
	return self:GetIsVisible()
end
