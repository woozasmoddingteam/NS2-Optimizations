-- A dynamic array
-- In Lua, tables are usable as arrays, but
-- there are still many things they can't do.
-- Dynamic arrays allow arbitrary freeing of individual
-- slots, and arbitrary allocation, while still being
-- fast.
-- This is a good alternative to using tables as hash
-- maps, for when you want to iterate over the elements.
-- It also has the concept of owners. Basically each
-- array index has to have an owner.
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
local WkTable = WkTable
if array == nil then
	local new = require "table.new"
	function array(n) return new(n+1, 0) end
	local meta = {__mode = "k"}
	function WkTable(t)
		return setmetatable(t, meta)
	end

	local cls = {}
	local meta = {
		__index = cls
	}
	setmetatable(cls, {
		__call = function()
			return setmetatable({}, meta)
		end
	})
	_G.DynArrayImplementation = cls
else
	class "DynArrayImplementation"
end

local DynArray = DynArrayImplementation

local function New(_, size)
	local da = DynArray()
	da.array = array(size or 0)
	da.next  = 2^52
	da.free  = 0
	da.owners = WkTable {}
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

function DynArray:Allocate(owner, v)
	local owners = self.owners
	local array  = self.array
	local free   = self.free
	local len    = #array
	local slot
	if free == 0 then
		slot = len+1
	else
		slot = self.next
		assert(array[slot] == false)
		self.free = free - 1
		self.next = 2^52
		if free > 1 then
			for i = slot+1, len do
				if array[i] == false then
					self.next = i
					break
				end
			end
		end
	end
	array[slot] = v
	owners[owner] = slot
	return slot
end

function DynArray:Set(i, v)
	self.array[i] = v
end

function DynArray:AddOwner(i, owner)
	self.owners[owner] = i
end

function DynArray:Free(i)
	self.array[i] = false
	self.free = self.free + 1
	self.next = min(self.next, i)
end

function DynArray:Get(owner)
	local i = self.owners[owner]
	return self.array[i], i
end

function DynArray:GetIndex(owner)
	return self.owners[owner]
end

_G.DynArray = setmetatable({}, {__index = DynArray, __call = New})
