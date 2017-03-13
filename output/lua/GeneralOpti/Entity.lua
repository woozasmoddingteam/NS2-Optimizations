
Script.Load("lua/Table.lua")

local function ientitylist_it(entityList, currentIndex)

    local numEntities = entityList:GetSize()

    while currentIndex < numEntities do
        -- Check if the entity was deleted after we created the list
        local currentEnt = entityList:GetEntityAtIndex(currentIndex)
        currentIndex = currentIndex + 1
		if currentEnt ~= nil then
	        return currentIndex, currentEnt
		end
    end

end

function ientitylist(entityList)

    return ientitylist_it, entityList, 0

end

local list = newproxy()
local table_insert = table.insert

function EntityListToTable(entityList)

    PROFILE("EntityListToTable")

	local result = {}

	local index = 1;

	for _, ent in ientitylist( entityList ) do
		table_insert(result, ent)
	end

    return result

end

local table_insert = table.insert

function GetEntitiesWithFilter(entityList, filterFunction)

    PROFILE("Entity:GetEntitiesWithFilter")

    local numEntities = entityList:GetSize()
    local result = {}

	local i = 0
	while i < numEntities do
        local entity = entityList:GetEntityAtIndex(i)

        if entity and filterFunction(entity) then

			table_insert(result, entity)

        end

		i = i + 1

    end

    return result

end

function AltGetEntitiesWithFilter(ents, filter)
	local result = {}
	for i = 1, #ents do
		local ent = ents[i]
		if ent and filter(ent) then
			table_insert(result, ent)
		end
	end
	return result
end

local GetEntitiesWithFilter = GetEntitiesWithFilter
local AltGetEntitiesWithFilter = AltGetEntitiesWithFilter
local Shared_GetEntitiesWithClassname = Shared.GetEntitiesWithClassname
local Shared_GetEntitiesWithTagInRange = Shared.GetEntitiesWithTagInRange
local Shared_GetEntitiesWithTag = Shared.GetEntitiesWithTag
local Shared_GetEntitiesWithControllersInRange = Shared.GetEntitiesWithControllersInRange
local Shared_GetEntitiesInRange = Shared.GetEntitiesInRange

function GetEntitiesForTeam(className, teamNumber)

    local teamFilterFunction = CLambda [=[args ent; HasMixin(ent, "Team") and ent:GetTeamNumber() == self[1]]=] {teamNumber}
    return GetEntitiesWithFilter(Shared_GetEntitiesWithClassname(className), teamFilterFunction)

end

function GetEntitiesForTeamByLocation( className, teamNumber, locationId )

	local filterFunction = CLambda [=[
		HasMixin(..., "Team")
		and (...):isa("ScriptActor")
		and (...):GetTeamNumber() == self[1]
		and (...).locationId == self[2]
	]=] {teamNumber, locationId}

    return GetEntitiesWithFilter( Shared_GetEntitiesWithClassname(className), filterFunction )

end


function GetEntities(className)

    return EntityListToTable(Shared_GetEntitiesWithClassname(className))

end


function GetEntitiesForTeamWithinRange(className, teamNumber, origin, range)

	local TeamFilterFunction = CLambda [=[
		HasMixin(..., "Team")
		and (...):GetTeamNumber() == self[1]
	]=] {teamNumber}

	return AltGetEntitiesWithFilter(Shared_GetEntitiesWithTagInRange("class:" .. className, origin, range), TeamFilterFunction)

end


function GetEntitiesWithinRange(className, origin, range)

    PROFILE("Entity:GetEntitiesWithinRange")

    return Shared_GetEntitiesWithTagInRange("class:" .. className, origin, range)

end


function GetEntitiesForTeamWithinXZRange(className, teamNumber, origin, range)

	local inRangeXZFilterFunction = Closure [=[
		self teamNumber, origin, range
		args entity
		local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
		return inRange and HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
	]=] {teamNumber, origin, range}

    return GetEntitiesWithFilter(Shared_GetEntitiesWithClassname(className), inRangeXZFilterFunction)

end


function GetEntitiesForTeamWithinRangeAreVisible(className, teamNumber, origin, range, visibleState)

	local teamAndVisibleStateFilterFunction = CLambda [==[
		self teamNumber, visibleState
		args entity
		HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber and entity:GetIsVisible() == visibleState
	]==] {teamNumber, visibileState}

    return AltGetEntitiesWithFilter(Shared_GetEntitiesWithTagInRange("class:" .. className, origin, range), teamAndVisibleStateFilterFunction)

end



function GetEntitiesWithinRangeAreVisible(className, origin, range, visibleState)

	local visibleStateFilterFunction = CLambda [=[
		self visibleState
		args entity
		return entity:GetIsVisible() == visibleState
	]=] {visibleState}

    return AltGetEntitiesWithFilter(Shared_GetEntitiesWithTagInRange("class:" .. className, origin, range), visibleStateFilterFunction)

end

function GetEntitiesWithinXZRangeAreVisible(className, origin, range, visibleState)

	local func = Closure [=[
		self visibleState, origin, range
		args entity
		local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
        return inRange and entity:GetIsVisible() == visibleState
	]=] {visibleState, origin, range}

    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), func)

end

function GetEntitiesWithinRangeInView(className, range, player)

	assert(false, "Disabled!")

end

function GetEntitiesMatchAnyTypesForTeam(typeList, teamNumber)

	local teamFilter = CLambda [=[
		self teamNumber
		args entity
		HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
	]=] {teamNumber}

    local allMatchingEntsList = { }

	for i = 1, #typeList do

		local type = typeList[i]

        local matchingEntsForType = GetEntitiesWithFilter(Shared_GetEntitiesWithClassname(type), teamFilter)
        table.adduniquetable(matchingEntsForType, allMatchingEntsList)

    end

    return allMatchingEntsList

end


function GetEntitiesMatchAnyTypes(typeList)

    local allMatchingEntsList = { }

    for i = 1, #typeList do
		local type = typeList[i]
        for i, entity in ientitylist(Shared_GetEntitiesWithClassname(type)) do
            table.insertunique(allMatchingEntsList, entity)
        end
    end

    return allMatchingEntsList

end

function GetEntitiesWithMixinForTeam(mixinType, teamNumber)

	local func = CLambda [[
		self teamNumber
		args entity
		HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
	]] {teamNumber}

    return GetEntitiesWithFilter(Shared_GetEntitiesWithTag(mixinType), func)

end


function GetEntitiesWithMixinWithinRange(mixinType, origin, range)

    return Shared_GetEntitiesWithTagInRange(mixinType, origin, range)

end

function GetEntitiesWithMixinWithinRangeAreVisible(mixinType, origin, range, visibleState)

	local func = CLambda [[
		self visibleState
		(...):GetIsVisible() == visibleState
	]] {visibleState}

    return AltGetEntitiesWithFilter(Shared_GetEntitiesWithTagInRange(mixinType, origin, range), func)

end

function GetEntitiesWithMixinForTeamWithinRange(mixinType, teamNumber, origin, range)

	local func = CLambda [[
		self teamNumber
		args entity
		HasMixin(entity, "Team") and entity:GetTeamNumber() == teamNumber
	]] {teamNumber}

    return AltGetEntitiesWithFilter(Shared_GetEntitiesWithTagInRange(mixinType, origin, range), func)
end
