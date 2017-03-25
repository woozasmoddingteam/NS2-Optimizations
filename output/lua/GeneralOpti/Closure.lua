local print = Shared and Shared.Message or print

local closures = {}
local clambdas = {}
local lambdas  = {}
local sclosures = {}

-- Other types of whitespace not supported!
local space     = string.byte(' ')
local newline   = string.byte('\n')
local tab       = string.byte('\t')
local semicolon = string.byte(';')

local function isWhite(c)
	return c == space
	    or c == tab
end

local function delimits(c)
	return not c or c == newline or c == semicolon
end

local function parseArguments(def)
	local self = {}
	local args = {}

	local index = 1

	while (isWhite(def:byte(index)) or delimits(def:byte(index))) and index <= #def do
		index = index + 1
	end

	if def:sub(index, index+4) == "self " then
		index = index + 5
		::loop:: do

			while isWhite(def:byte(index)) do
				index = index + 1
			end

			if delimits(def:byte(index)) then
				goto args
			end

			local start = index

			while not isWhite(def:byte(index)) do
				if delimits(def:byte(index)) then
					table.insert(self, def:sub(start, index-1))
					goto args
				end
				index = index + 1
			end

			table.insert(self, def:sub(start, index-1))

		end
		goto loop
	end

	::args::
	while (isWhite(def:byte(index)) or delimits(def:byte(index))) and index <= #def do
		index = index + 1
	end

	if def:sub(index, index+4) == "args " then
		index = index + 5
		::loop:: do

			while isWhite(def:byte(index)) do
				index = index + 1
			end

			if delimits(def:byte(index)) then
				goto self
			end

			local start = index

			while not isWhite(def:byte(index)) do
				if delimits(def:byte(index)) then
					table.insert(args, def:sub(start, index-1))
					goto self
				end
				index = index + 1
			end

			table.insert(args, def:sub(start, index-1))

		end
		goto loop
	end

	::self::

	while (isWhite(def:byte(index)) or delimits(def:byte(index))) and index <= #def do
		index = index + 1
	end

	if def:sub(index, index+4) == "self " then
		index = index + 5
		::loop:: do

			while isWhite(def:byte(index)) do
				index = index + 1
			end

			if delimits(def:byte(index)) then
				goto ret
			end

			local start = index

			while not isWhite(def:byte(index)) do
				if delimits(def:byte(index)) then
					table.insert(self, def:sub(start, index-1))
					goto ret
				end
				index = index + 1
			end

			table.insert(self, def:sub(start, index-1))

		end
		goto loop
	end

	::ret::
	index = def:byte(index) == semicolon and index + 1 or index
	return self, args, def:sub(index)
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

local function newClosure(def)
	local old_def = def
	local self, args, def = parseArguments(def)

	local total = "return function(self " .. fargs(args) .. ") " .. sargs(self) .. def .. " end"
	print(total)
	local f, msg = loadstring(total, "Closure")
	if not f then
		assert(nil, "Error constructing Closure: `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	local meta = {__call = f}
	local generator = function(args)
		return setmetatable(args, meta)
	end
	closures[old_def] = generator
	return generator
end

local function newCLambda(def)
	local old_def = def
	local self, args, def = parseArguments(def)

	local total = "return function(self " .. fargs(args) .. ") " .. sargs(self) .. "return " .. def .. " end"
	print(total)
	local f, msg = loadstring(total, "CLambda")
	if not f then
		assert(nil, "Error constructing CLambda: `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	local meta = {__call = f}
	local generator = function(args)
		return setmetatable(args, meta)
	end
	clambdas[old_def] = generator
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

local function newSClosure(def)
	local old_def = def
	local self, args, def = parseArguments(def)

	assert(#self == 0, "Can not supply self arguments in a SClosure! I don't really know what you tried to do.")

	local total = "return function(self " .. fargs(args) .. ") " .. sargs(self) .. def .. " end"
	print(total)
	local f, msg = loadstring(total, "SClosure")
	if not f then
		assert(nil, "Error constructing SClosure: `" .. total .. "`! Reason: " .. msg)
		return
	end
	f = f()

	local funcs = setmetatable({}, {
		__mode = "kv" -- Weak
	})

	local function newSClosureInst(self)
		local inst = function(...)
			return f(self, ...)
		end
		funcs[self] = inst
		return inst
	end

	local generator = function(self)
		return funcs[self] or newSClosureInst(self)
	end
	sclosures[old_def] = generator
	return generator
end

function Closure(def)
	return closures[def] or newClosure(def)
end

function CLambda(def)
	return clambdas[def] or newCLambda(def)
end

function Lambda(def)
	return lambdas[def] or newLambda(def)
end

function SClosure(def)
	return sclosures[def] or newSClosure(def)
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
