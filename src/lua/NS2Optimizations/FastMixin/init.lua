local kUnsafe = kNS2OptiConfig.FastMixin

local oldclass = class

local reg = debug.getregistry()
local classes = reg.__CLASSES
if not classes then
	classes = {}
	reg.__CLASSES = classes
end

local function GetMixinConstants(self)
	return self.__mixindata
end

local function GetMixinConstant(self, constantName)
	return self.__mixindata[constantName]
end

Entity.__is_ent = true

class = function(name)
	local oldbasesetter = oldclass(name)
	local cls = _G[name]
	local meta = getmetatable(cls)
	meta.name = name
	meta.mixintypes = {}
	meta.mixindata = {}
	if kUnsafe then
		meta.mixinbackup = {}
	end
	meta.mixins = {}
	classes[#classes+1] = cls

	cls.__is_ent = false
	cls.GetMixinConstants = GetMixinConstants
	cls.GetMixinConstant = GetMixinConstant

	return function(base)
		assert(type(base) == "table", "Not a valid base class!")
		meta.base = base
		if base.__is_ent or base == Entity then
			cls.__is_ent = true
		end
		oldbasesetter(base)
		local backup = getmetatable(base) and getmetatable(base).mixinbackup
		if backup then
			for k, v in pairs(backup) do
				if type(k) ~= "number" then
					cls[k] = v
				end
			end
			for i = 1, #backup do
				cls[backup[i]] = nil
			end
		end
	end
end
