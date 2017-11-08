Script.Load "lua/TraceTracker.lua"

local jit = require "jit"
local tracelogger = require "tracelogger"

local Tracer = {}

local bc = require "jit.bc"
local vmdef = require "jit.vmdef"
local jit_util = require "jit.util"
local traceinfo, traceir, tracek = jit_util.traceinfo, jit_util.traceir, jit_util.tracek
local tracemc, tracesnap = jit_util.tracemc, jit_util.tracesnap
local funcline = jit_util.funcline

local function fmtfunc(func, pc)
  local fi = funcinfo(func, pc)
  if fi.loc then
    return fi.loc
  elseif fi.ffid then
    return vmdef.ffnames[fi.ffid]
  elseif fi.addr then
    return format("C:%x", fi.addr)
  else
    return "(?)"
  end
end

local function fmterr(err, info)
  if type(err) == "number" then
    if type(info) == "function" then info = fmtfunc(info) end
    err = format(vmdef.traceerr[err], info)
  end
  return err
end

local file

local function find_abort(what, tr, func, pc, otr, oex)
	if what ~= "abort" then
		return
	end
	file:write(fmtfunc(func, pc), " -- ", fmterr(otr, oex), "\n")
	file:flush()
end

function Tracer.start(...)
	assert(..., "Please supply a file to dump to!")
	file = io.open(..., "w")
	jit.attach(find_abort, "trace")
end

function Tracer.stop()
	jit.attach(find_abort)
	file = nil
end

return Tracer
