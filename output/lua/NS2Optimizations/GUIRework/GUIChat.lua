local Shine = Shine

if not Shine then return end

local Hook = Shine.Hook
local SGUI = Shine.GUI
local IsType = Shine.IsType

local Ceil = math.ceil
local Clamp = math.Clamp
local Clock = os.clock
local Floor = math.floor
local Max = math.max
local Min = math.min
local pairs = pairs
local select = select
local StringFind = string.find
local StringFormat = string.format
local StringLen = string.len
local StringSub = string.sub
local StringUTF8Length = string.UTF8Length
local StringUTF8Sub = string.UTF8Sub
local TableEmpty = table.Empty
local TableRemove = table.remove
local type = type

local Enabled, Plugin = Shine:IsExtensionEnabled "chatbox"
if not Enabled then return end

local ChatElement = GUIChat
function ChatElement:SetIsVisible( Vis )
	if self.Vis == Vis then return end

	self.Vis = Vis

	local Messages = self.messages
	if not Messages then return end

	for i = 1, #Messages do
		local Element = Messages[ i ]

		if type(Element) == "table" then
			Element.Background:SetIsVisible( Vis )
		end
	end
end

local OldSendKey = ChatElement.SendKeyEvent

function ChatElement:SendKeyEvent( Key, Down )
	if Plugin.Enabled then return end
	return OldSendKey( self, Key, Down )
end

local OldAddMessage = ChatElement.AddMessage
local function GetTag( Element )
	return {
		Colour = Element:GetColor(),
		Text = Element:GetText()
	}
end

function ChatElement:AddMessage( PlayerColour, PlayerName, MessageColour, MessageName, IsCommander, IsRookie )
	Plugin.GUIChat = self

	OldAddMessage( self, PlayerColour, PlayerName, MessageColour, MessageName, IsCommander, IsRookie )

	if not Plugin.Enabled then return end

	local JustAdded = self.messages[ #self.messages ]
	local Tags
	local Rookie = JustAdded.Rookie and JustAdded.Rookie:GetIsVisible()
	local Commander = JustAdded.Commander and JustAdded.Commander:GetIsVisible()

	if Rookie or Commander then
		Tags = {}

		if Commander then
			Tags[ 1 ] = GetTag( JustAdded.Commander )
		end

		if Rookie then
			Tags[ #Tags + 1 ] = GetTag( JustAdded.Rookie )
		end
	end

	Plugin:AddMessage( PlayerColour, PlayerName, MessageColour, MessageName, Tags )

	if Plugin.Visible and IsType( JustAdded, "table" ) then
		JustAdded.Background:SetIsVisible( false )
	end
end

local old = ChatElement.Initialize
function ChatElement:Initialize()
	old(self)
	Plugin.GUIChat = self
end

