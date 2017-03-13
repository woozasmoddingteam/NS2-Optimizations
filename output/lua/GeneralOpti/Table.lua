
// This way LuaJIT can inline only the fast paths, instead of nothing at all

local type = type
local table_insert = table.insert
local table_sort = table.sort
local random = math.random
local max = math.max
local floor = math.floor
local ceil = math.ceil
local elementEqualsElement

local function deep(x, y)
	if #x == #y then
		for i = 1, #x do
			return x[i] == y[i] or type(x[i]) == "table" and type(y[i]) == "table" and deep(x, y)
		end
	end
	return false
end

elementEqualsElement = function(x, y)

	return x == y or type(x) == "table" and type(y) == "table" and deep(x, y)

end

_G.elementEqualsElement = elementEqualsElement

function table.find(findTable, value)

	for i = 1, #findTable do
		if elementEqualsElement(findTable[i], value) then
			return i
		end
	end

    return nil

end

local table_find = table.find

function table.insertunique(t, v)

    if table_find(t, v) == nil then

        table_insert(t, v)
        return true

    end

    return false

end

local table_insertunique = table.insertunique

function table.count(t, log)
	if t then
		return #t
	elseif log then
        Shared.Message("table.count() - Nil table passed in, returning 0.")
	end
end

function table.maxn(t)
	local highest = 0
	for k in pairs(t) do
		if type(k) == "number" then
			highest = max(highest, k)
		end
	end
	return highest
end

--
-- Adds the contents of one table to another. Duplicate elements added.
--
function table.addtable(srcTable, destTable)

	local len = #destTable
	for i = 1, #srcTable do
		destTable[len+i] = srcTable[i]
	end

end

--
-- Adds the contents of onte table to another. Duplicate elements are not inserted.
--
function table.adduniquetable(srcTable, destTable)

	for i = 1, #srcTable do
		table_insertunique(destTable, srcTable[i])
	end

end

function table.dcontains(t, v)
	for k, tv in pairs(t) do
		if tv == v then
			return true
		end
	end
	return false
end

local table_dcontains = table.dcontains

function table.icontains(t, value)
	return table_find(t, value) ~= nil
end

local table_icontains = table.icontains

function table.contains(t, v)

	if #t > 0 then
		return table_icontains(t, v)
	else
		return table_dcontains(t, v)
	end

end

math.randomseed(os.clock())
function table.random(t)
	if #t > 0 then
		return t[random(#t)]
	end
end

table.getIsEquivalent = deep

local original_table_clear = require("table.clear")

function table.clear(t)

	if t then
		original_table_clear(t)
	end

end

table.new = require "table.new"

local table_new = table.new

function table.array(size)
    return table_new(size+1, 0)
end

function table.foreachfunctor(t, functor)

	if not t then return end

    for i = 1, #t do

        functor(t[i])

    end

end


-- Returns a table full of elements that aren't found in both tables
function table.diff()
	assert(false, "Disabled!")
end

-- Returns the numeric median of the given array of numbers
function table.median( t )
    local temp = {}

    --deep copy all numbers
    for i = 1, #t do
        temp[i] = t[i]
    end

    if #temp == 0 then
        return -1
    end

    table_sort(temp)

	start = start or 1
	stop = stop or #t
	if #temp % 2 == 1 then
		return t[floor(#t/2)+1]
	else
		return (t[#t/2] + t[#t/2+1])/2
	end

end

function table.mean( t )
    local sum = 0
    local count = 0

    for i = 1, #t do
		sum = sum + t[i]
    end

    return sum / #t
end

function table.dmode(t)
	local counts = {}
	local keys = {}

	for k, v in pairs(t) do
		if not counts[v] then
			table_insert(keys, v)
			counts[v] = 1
		else
			counts[v] = counts[v] + 1
		end
	end

	local ret = {}

	local biggest = indices[1]
	for i = 2, #indices do
		local k = indices[i]
		if counts[k] > counts[biggest] then
			biggest = k
			table_clear(ret)
		elseif counts[k] == counts[biggest] then
			table_insert(ret, k)
		end
	end

	table_insert(ret, biggest)

	return ret
end
local table_dmode = table.dmode

function table.imode(t)
	local counts = {}
	local indices = {}

	for i = 1, #t do
		local v = t[i]
		if not counts[v] then
			table_insert(indices, v)
			counts[v] = 1
		else
			counts[v] = counts[v] + 1
		end
	end

	local ret = {}

	local biggest = indices[1]
	for i = 2, #indices do
		local k = indices[i]
		if counts[k] > counts[biggest] then
			biggest = k
			table_clear(ret)
		elseif counts[k] == counts[biggest] then
			table_insert(ret, k)
		end
	end

	table_insert(ret, biggest)

	return ret
end
local table_imode = table.imode

-- Get the mode of a table. Returns a table of values.
function table.mode(t)
	if #t > 0 then
		return table_imode(t)
	else
		return table_dmode(t)
	end
end
