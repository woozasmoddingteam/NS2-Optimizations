
local type = type
local table_insert = table.insert
local table_sort = table.sort
local table_remove = table.remove
local random = math.random
local max = math.max
local floor = math.floor
local ceil = math.ceil
local print = Shared and Shared.Message or print
local kEnableUnsafe = kNS2OptiConfig and kNS2OptiConfig.UnsafeTableOptimizations or true

local elementEqualsElement

local original_table_clear = require("table.clear")

function table.clear(t)

	if t then
		original_table_clear(t)
	end

end

local table_clear = table.clear

table.new = require "table.new"

local table_new = table.new

function table.array(size)
	return table_new(size+1, 0)
end

function table.dict(size)
	return table_new(0, size)
end

function table.dictionary(slots)
	return table_new(0, slots)
end

local function isArray(t)
	return #t > 0
end

local function isDictionary(t)
	for k in pairs(t) do
		if type(k) ~= "number" then
			return true
		end
	end
	return false
end

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

function table.copy(src, dst, no_clear)

	if not no_clear then
	  original_table_clear(dst)
	end

	local len = #dst
	for i = 1, #src do
		dst[len+i] = Copy(src[i])
	end

end

local table_copy = table.copy

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
	return 0
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

	if kEnableUnsafe and #t > 0 then
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

function table.foreachfunctor(t, functor)

	if not t then return end

	 for i = 1, #t do

		  functor(t[i])

	 end

end

function table.removeTable()
	error "Disabled"
end

-- Returns a table full of elements that aren't found in both tables
function table.diff()
	error "Disabled!"
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
	error "Disabled!"
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
	if kEnableUnsafe and #t > 0 then
		return table_imode(t)
	else
		return table_dmode(t)
	end
end

function table.iduplicate(t)
	local t2 = table_new(#t+1, 0)
	for i = 1, #t do
		t2[i] = t[i]
	end
	return t2
end

local table_iduplicate = table.iduplicate

function table.dduplicate(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

local table_dduplicate = table.dduplicate

function table.duplicate(t)
	if kEnableUnsafe and #t > 0 then
		return table_iduplicate(t)
	else
		return table_dduplicate(t)
	end
end

function table.removeConditional(t, filter)

	 if t ~= nil then

		local len = #t
		local i = 1
		while i <= len do

				local e

			::loop:: do
				e = t[i]

				if e ~= nil and filter(e) then
					table_remove(t, i)
					len = len - 1
					goto loop
				end
			end

				i = i + 1

		  end

	 end

end

do
	local old = unpack
	oldunpack = old
	local unpack_table = {}
	for diff = 0, 19 do
		ret = ""
		for i = 0, diff do
			ret = ret .. "t[i+" .. i .. "],"
		end
		ret = ret:sub(1, #ret-1)
		local s = ([[
			return function(t, i)
				return %s
			end
		]]):format(ret)
		unpack_table[diff] =
			assert(loadstring(s))()
	end
	function unpack(t, i, j)
		if i == nil then i = 1  end
		if j == nil then j = #t end
		local diff = j-i
		if     diff < 0  then
		elseif diff < 20 then
			return unpack_table[diff](t, i)
		else
			return old(t, i, j)
		end
	end
end

-- Applies function to each element of an array, then pushes the result to another array.
function table.apply(x, func)
	local y = {}
	for i = 1, #x do
		table_insert(y, func(x[i]))
	end
	return y
end

-- Applies function to each element of an array, then sets corresponding element of another array to result.
function table.map(x, func)
	local y = {}
	for i = 1, #x do
		y[i] = func(x[i])
	end
	return y
end

function table.dmap(x, func)
	local y = {}
	for k, v in pairs(x) do
		y[k] = func(v)
	end
	return y
end
