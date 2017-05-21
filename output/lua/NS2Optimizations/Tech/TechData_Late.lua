
local kTechId = kTechId
local kTechData = {}
_G.kTechData = kTechData
local kMapNameTechId = {}
local kTechCategories = {}
local tech_data_src = BuildTechData()

for i = 1, #kTechId do
	kTechData[i] = {}
end

for i = 1, #tech_data_src do
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

if kNS2OptiConfig.UnsafeTechIdOptimizations then
	set(LookupTechId_NS2Opti, function(mapname)
		return kMapNameTechId[mapname] or kTechId.None
	end)
end

set(LookupTechData_NS2Opti, function(id, field, default)
	if id == nil then
		return default
	end

	local v = kTechData[id][field]
	if v == nil then
		return default
	else
		return v
	end
end)

set(GetTechForCategory, function(techId)
	return kTechCategories[techId] or {}
end)

local function disable(name)
	do return end
	_G[name] = function()
		error(("'%s' has been disabled!"):format(name))
	end
end

disable "ClearCachedTechData"
disable "GetCachedTechData"
disable "SetCachedTechData"

Log "Loaded TechData_Late.lua!"
