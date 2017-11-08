
local Client = Client
local min    = math.min
local ceil   = math.ceil

function GUIScale(size)
	return min(Client.GetScreenWidth(), Client.GetScreenHeight()) / 1080 * size
end

function GUIGetSprite(x, y, w, h)
	return (x-1)*w, (y-1)*h, x*w, y*h
end
