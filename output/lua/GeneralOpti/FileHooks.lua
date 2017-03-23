Shared.Message [=[
------------------------------
NS2 Optimizations - FastMixin:
You will see warnings of the type:
WARNING: Improperly initialized!
These just mean that an entity creation took longer than normal.
They indicate badly written code, and help debugging.
------------------------------
]=]

ModLoader.SetupFileHook("lua/Table.lua", "lua/GeneralOpti/Table.lua", "post")
ModLoader.SetupFileHook("lua/Entity.lua", "lua/GeneralOpti/Entity.lua", "post")
ModLoader.SetupFileHook("lua/Player.lua", "lua/GeneralOpti/Player.lua", "post")
ModLoader.SetupFileHook("lua/Utility.lua", "lua/GeneralOpti/Utility.lua", "post")
