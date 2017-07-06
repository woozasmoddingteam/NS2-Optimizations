-- A dynamic array
-- In Lua, tables are usable as arrays, but
-- there are still many things they can't do.
-- Dynamic arrays allow arbitrary freeing of individual
-- slots, and arbitrary allocation, while still being
-- fast.
-- This is a good alternative to using tables as hash
-- maps, for when you want to iterate over the elements.
--
-- NB: Values of `false` are reserved. Don't use Set to Free.

-- Implementation details:
-- self.next refers to the lowest free index.
-- This way we won't have to iterate over the entire
-- array to find a free slot.
-- We could as an alternative to this use an array with
-- free indices as values. Though this doesn't seem to be
-- necessary, since in the most common cases, the amount
-- of time used searching for a free slot should be minimal,
-- since icons that are frequently removed and added
-- will be at the top, thus there will be less to search.

local min = math.min
local array = table.array

if not class then
	local cls = {}
	local meta = {
		__index = cls
	}
	setmetatable(cls, {
		__call = function()
			return setmetatable({}, meta)
		end
	})
	_G.DynArray = cls
else
	class "DynArrayImplementation"
end

local DynArray = DynArrayImplementation

local function New(_, size)
	local da = DynArray()
	da.array = array(size or 0)
	da.next  = 2^52
	da.free  = 0
	return da
end

local function iterator(a, i)
	local length = #a
	repeat
		i = i + 1
		if i > length then return end
	until
		a[i] ~= false
	return i, a[i]
end

function DynArray:Iterate()
	return iterator, self.array, 0
end

function DynArray:Append(v)
	local free  = self.free
	local array = self.array
	local len   = #array
	if free == 0 then
		local slot = len+1
		array[slot] = v
		return slot
	else
		local next  = self.next
		assert(array[next] == false)
		array[next] = v
		self.free = free - 1
		self.next = 2^52
		if free > 1 then
			for i = next+1, len do
				if array[i] == false then
					self.next = i
					break
				end
			end
		end
		return next
	end
end

function DynArray:Free(i)
	self.free = self.free + 1
	self.array[i] = false
	self.next = min(self.next, i)
end

function DynArray:Get(i)
	return self.array[i]
end

function DynArray:Set(i, v)
	self.array[i] = v
end

_G.DynArray = setmetatable({}, {__index = DynArray, __call = New})
