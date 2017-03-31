local toString = function(v)
	local err, str = pcall(ToString, v);
	if type(v) == "table" then
		return tostring(v) .. " " .. str;
	elseif type(v) == "string" then
		return "\"" .. str .. "\"";
	else
		return str;
	end
end

debug.callstack = function(level)
	level = level and level + 1 or 2;
	local str = "Call stack:";
	local i = level;
	local func = debug.getinfo(i);
	while func do
		str = str .. ("\n\t#%d: %s:%i%s:%i"):format(i-level+1, func.name, func.currentline, func.source, func.linedefined);
		local j = 1;
		local name, value = debug.getlocal(i, j);
		while name do
			str = str .. ("\n\t\t%s = %s"):format(name, toString(value));
			j = j + 1;
			name, value = debug.getlocal(i, j);
		end
		i = i + 1;
		func = debug.getinfo(i);
	end
	return str;
end

local oldclass = class;
assert(oldclass);

local reg = debug.getregistry();
local classes = reg.__CLASSES;
if not classes then
	classes = {};
	reg.__CLASSES = classes;
end

local function GetMixinConstants(self)
	return self.__mixindata
end

local function GetMixinConstant(self, constantName)
	return self.__mixindata[constantName]
end

Entity.__is_ent = true;

class = function(name)
	local oldbasesetter = oldclass(name);
	local cls = _G[name];
	local meta = getmetatable(cls);
	meta.name = name;
	meta.mixintypes = {};
	meta.mixindata = {};
	meta.mixinbackup = {};
	meta.mixins = {};
	classes[#classes+1] = cls;

	cls.__is_ent = false;
	cls.GetMixinConstants = GetMixinConstants;
	cls.GetMixinConstant = GetMixinConstant;

	return function(base)
		meta.base = base;
		if base.__is_ent or base == Entity then
			cls.__is_ent = true;
		end
		oldbasesetter(base);
		local backup = getmetatable(base) and getmetatable(base).mixinbackup;
		if backup then
			for k, v in pairs(backup) do
				if type(k) ~= "number" then
					cls[k] = v;
				end
			end
			for i = 1, #backup do
				cls[backup[i]] = nil;
			end
		end
	end
end
