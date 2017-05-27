
local Client = Client
local min    = math.min
local ceil   = math.ceil

function GUIScale(size)
	return min(Client.GetScreenWidth(), Client.GetScreenHeight()) / 1080 * size
end
