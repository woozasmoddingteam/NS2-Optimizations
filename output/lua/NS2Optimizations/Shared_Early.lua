
local old = assert(Class_ReplaceMethod)
function Class_ReplaceMethod(class, method, func)
	if class ~= "GUIManager" then
		return old(class, method, func)
	end
end
