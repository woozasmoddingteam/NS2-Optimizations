local print = Shared and Shared.Message or print
local select       = select
local setmetatable = setmetatable
local byte = string.byte
local sub  = string.sub

local closures  = {}
local clambdas  = {}
local lambdas   = {}
local sclosures = {}
local slambdas  = {}

-- Other types of whitespace not supported!
local space     = string.byte(' ')
local newline   = string.byte('\n')
local tab       = string.byte('\t')
local semicolon = string.byte(';')

local weak_meta = {
	__mode = "kv"
}
local function weakTable(arg)
	return setmetatable(arg, weak_meta)
end

local function isWhite(c)
	return c == space
	    or c == tab
end

local function delimits(c)
	return not c or c == newline or c == semicolon
end

local function trimLeading(str, index)
	while (isWhite(byte(str, index)) or delimits(byte(str, index))) and index <= #str do
		index = index + 1
	end
	return index
end

local function trimLeadingWhite(str, index)
	while isWhite(byte(str, index)) do
		index = index + 1
	end
	return index
end

local function parseArguments(def)
	local self = {}
	local args = {}

	local index = 1

	::loop:: do
		index = trimLeading(def, index)

		if sub(def, index, index+4) == "self " or sub(def, index, index+4) == "self\t" then
			index = index + 5
			while true do

				index = trimLeadingWhite(def, index)

				if delimits(byte(def, index)) then
					goto args
				end

				local start = index

				while not isWhite(byte(def, index)) do
					if delimits(byte(def, index)) then
						table.insert(self, sub(def, start, index-1))
						goto args
					end
					index = index + 1
				end

				table.insert(self, sub(def, start, index-1))

			end
		else
			goto ret
		end

		::args::
		index = trimLeading(def, index)

		if sub(def, index, index+4) == "args " or sub(def, index, index+4) == "args\t" then
			index = index + 5
			while true do

				index = trimLeadingWhite(def, index)

				if delimits(byte(def, index)) then
					goto loop
				end

				local start = index

				while not isWhite(byte(def, index)) do
					if delimits(byte(def, index)) then
						table.insert(args, def:sub(start, index-1))
						goto loop
					end
					index = index + 1
				end

				table.insert(args, def:sub(start, index-1))

			end
		else
			goto ret
		end

		goto loop
	end

	::ret::
	index = byte(def, index) == semicolon and index + 1 or index
	return self, args, sub(def, index)
end

local function fargs(t, b)
	if #t > 0 then
		return (not b and "," or "") .. table.concat(t, ',')
	else
		return (not b and "," or "") .. "..."
	end
end

local function sargs(t)
	if #t == 0 then return "" end

	local s = "local " .. table.concat(t, ',') .. "="
	for i = 1, #t-1 do
		s = s .. "self[" .. i .. "],"
	end
	s = s .. "self[" .. #t .. "];"

	return s
end

local function newClosure(def, cache, is_lambda)
	local old_def = def
	local self, args, def = parseArguments(def)

	local name = is_lambda and "CLambda" or "Closure"

	local total = "return function(self " .. fargs(args) .. ") " .. sargs(self) .. (is_lambda and "return " or "") .. def .. " end"
	print(total)
	local f, msg = loadstring(total, name)
	if not f then
		assert(nil, "Error constructing " .. name .. ": `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	local meta = {__call = f}
	local generator = function(args)
		return setmetatable(args, meta)
	end
	cache[old_def] = generator
	return generator
end

local function newLambda(def)
	local old_def = def
	local self, args, def = parseArguments(def)

	assert(#self == 0, "Can not supply self arguments in a Lambda! Use a CLambda instead.")

	local total = "return function(" .. fargs(args, true) .. ") return " .. def .. " end"
	print(total)
	local f, msg = loadstring(total, "Lambda")
	if not f then
		assert(nil, "Error constructing Lambda: `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	lambdas[old_def] = f
	return f
end

local keySClosureFunc = newproxy()

local function newSClosure(def, cache, is_lambda)
	local old_def = def
	local self, args, def = parseArguments(def)

	local name = is_lambda and "SLambda" or "SClosure"

	local total = "return function(self " .. fargs(args) .. ") " .. sargs(self) .. (is_lambda and "return " or "") .. def .. " end"
	print(total)
	local f, msg = loadstring(total, name)
	if not f then
		assert(nil, "Error constructing " .. name .. ": `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	local funcs = weakTable {}

	local function newSClosureInst(self, len)
		local t = funcs
		for i = 1, len do
			local v = self[i]
			if not t[v] then
				t[v] = weakTable {}
			end
			t = t[v]
		end
		local inst = function(...)
			return f(self, ...)
		end
		t[keySClosureFunc] = inst
		return inst
	end

	local generator = function(...)
		local self = {...}
		local len = select('#', ...)
		local t = funcs
		for i = 1, len do
			local v = self[i]
			if not t[v] then
				return newSClosureInst(self, len)
			end
			t = t[v]
		end
		return t[keySClosureFunc] or newSClosureInst(self)
	end

	cache[old_def] = generator
	return generator
end

function Closure(def)
	return closures[def] or newClosure(def, closures)
end

function CLambda(def)
	return clambdas[def] or newClosure(def, clambdas, true)
end

function Lambda(def)
	return lambdas[def] or newLambda(def)
end

function SClosure(def)
	return sclosures[def] or newSClosure(def, sclosures)
end

function SLambda(def)
	return slambdas[def] or newSClosure(def, slambdas, true)
end

function FunctionizeClosure(closure)
	local args = {}
	for k, v in pairs(closure) do
		args[k] = v
	end
	local f = getmetatable(closure).__call
	return function(...)
		f(args, ...)
	end
end
