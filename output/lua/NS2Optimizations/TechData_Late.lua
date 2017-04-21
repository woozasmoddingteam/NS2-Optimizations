
local kTechId = kTechId
local kTechData = {}
local kMapNameTechId = {}
local kTechCategories = {}
local tech_data_src = BuildTechData()
for i = 1, #tech_data_src do
	local e = tech_data_src[i]
	kTechData[e[kTechId]] = e
	local map = e[kTechDataMapName]
	if map ~= nil then
		kMapNameTechId[map] = e[kTechId]
	end
	local category = e[kTechDataCategory]
	if category ~= nil then
		local t = kTechCategories[category] or {}
		kTechCategories[category] = t
		table.insert(t, e[kTechId])
	end
end

function LookupTechId(mapname)
	return kMapNameTechId[mapname] or kTechId.None
end

function LookupTechData(id, field, default)
	local v = kTechData[id][field]
	if v == nil then
		return default
	else
		return v
	end
end

function GetTechForCategory(techId)
	return kTechCategories[techId]
end

local function disable(name)
	_G[name] = function()
		error(("'%s' has been disabled!"):format(name))
	end
end

disable "ClearCachedTechData"
disable "GetCachedTechData"
disable "SetCachedTechData"

