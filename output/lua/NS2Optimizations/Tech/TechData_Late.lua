
local kTechId = kTechId
local kTechId_None = kTechId.None
local kTechDataMapName = assert(kTechDataMapName)
local kTechDataId      = assert(kTechDataId)
local kTechData = {}
_G.kTechData = kTechData
local kMapNameTechId = {}
local kTechCategories = {}
local tech_data_src = BuildTechData()

for i = 1, #kTechId do
	kTechData[i] = false
end

for i = #tech_data_src, 1, -1 do
	local e = tech_data_src[i]
	local id = e[kTechDataId]
	kTechData[id] = e
	local map = e[kTechDataMapName]
	if map ~= nil then
		kMapNameTechId[map] = id
	end
	local category = e[kTechDataCategory]
	if category ~= nil then
		local t = kTechCategories[category] or {}
		kTechCategories[category] = t
		table.insert(t, id)
	end
end

local function set(f, v)
	local i = 1
	while assert(debug.getupvalue(f, i), "No such value!") ~= "actual" do
		i = i + 1
	end
	debug.setupvalue(f, i, v)
end

set(LookupTechId_NS2Opti, function(data, field)
	if field == kTechDataMapName then
		local v = kMapNameTechId[data]
		if v == nil then return kTechId_None 
		else             return v
		end
	end
end)

set(LookupTechData_NS2Opti, function(id, field, default)
	local e = kTechData[id]
	if not e then return default end

	local v = e[field]
	if v == nil then
		return default
	else
		return v
	end
end)

set(GetTechForCategory, function(techId)
	local v = kTechCategories[techId]
	if v == nil then
		return {}
	else
		return v
	end
end)

local function disable(name)
	_G[name] = function()
		error(("'%s' has been disabled!"):format(name))
	end
end

disable "ClearCachedTechData"
disable "GetCachedTechData"
disable "SetCachedTechData"
