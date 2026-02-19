-- ==================================================
-- Registers.lua
-- Clean + optimized + DEBUG-controlled trace
-- ==================================================


-- ==================================================
-- Debug (set in main from quickAppVariables.debug)
-- ==================================================

local function debugTrace(qa, ...)
	if QA_DEBUG then
		qa:trace(...)
	end
end


-- ==================================================
-- Helpers
-- ==================================================

local function regId(addr)
	return string.char(addr >> 8, addr & 0xFF)
end

local function regHex(addr)
	return string.format("%04x", addr)
end

local function makeRegister(addr, callback)
	return {
		id = regId(addr),
		hex = regHex(addr),
		on_read_callback = callback
	}
end


-- ==================================================
-- Lookup Tables (defined once)
-- ==================================================

local SPEED_MAP = {
	[0] = "Standby",
	[1] = "Level 1",
	[2] = "Level 2",
	[3] = "Level 3",
	[4] = "Boost"
}

local MODE_MAP = {
	[0] = "Manual",
	[1] = "Auto"
}


-- ==================================================
-- Register Type Helpers
-- ==================================================

-- Boolean (0 / 1)
local function boolRegister(addr, debugName, labelId, textOn, textOff)
	return makeRegister(addr, function(qa, reg, payload)
		local raw   = read_unsigned_i16(payload)
		local state = raw == 1
		local text  = state and textOn or textOff

		debugTrace(qa, debugName .. ":", text, "(raw:", raw .. ")")

		qa:updateLabelState(labelId, state, textOn, textOff)
	end)
end


-- Integer (updates child by reg.hex if device exists)
local function intRegister(addr, debugName)
	return makeRegister(addr, function(qa, reg, payload)
		local raw = read_unsigned_i16(payload)

		debugTrace(qa, debugName .. ":", raw, "(raw:", raw .. ")")

		qa:updateChildValue(reg, raw)
	end)
end


-- Temperature (signed /10, updates child by reg.hex if device exists)
local function tempRegister(addr, debugName)
	return makeRegister(addr, function(qa, reg, payload)
		local raw   = read_signed_i16(payload)
		local value = raw / 10

		debugTrace(qa, debugName .. ":", value .. " °C", "(raw:", raw .. ")")

		qa:updateChildValue(reg, value)
	end)
end


-- ==================================================
-- REGISTERS
-- ==================================================

REGISTERS = {

	--------------------------------------------------
	-- Power / Season
	--------------------------------------------------

	status = boolRegister(
		1000,
		"Power",
		"label_power",
		"Power ON",
		"Power OFF"
	),

	season = boolRegister(
		1001,
		"Season",
		"label_season",
		"Winter",
		"Summer"
	),


	--------------------------------------------------
	-- Service warning (bitfield → BIT 14)
	--------------------------------------------------

	service = makeRegister(1007, function(qa, reg, payload)
		local raw = read_unsigned_i16(payload)

		-- bit 14 mask (0x4000)
		local serviceActive = (raw & 0x4000) ~= 0
		local text = serviceActive and "Service NOW" or "Service OK"

		debugTrace(qa, "Service:", text, "(raw:", raw .. ")")

		qa:updateLabelState(
			"label_service",
			serviceActive,
			"Service NOW",
			"Service OK"
		)
	end),


	--------------------------------------------------
	-- Ventilation
	--------------------------------------------------

	speed_manual = intRegister(
		1100,
		"Manual speed"
	),

	speed = makeRegister(1101, function(qa, reg, payload)
		local raw = read_unsigned_i16(payload)
		local speedText = SPEED_MAP[raw] or ("Unknown (" .. raw .. ")")

		debugTrace(qa, "Current speed:", speedText, "(raw:", raw .. ")")

		qa:updateLabelSpeed(raw)
	end),

	current_mode = makeRegister(1102, function(qa, reg, payload)
		local raw = read_unsigned_i16(payload)
		local modeText = MODE_MAP[raw] or ("Unknown (" .. raw .. ")")

		debugTrace(qa, "Mode:", modeText, "(raw:", raw .. ")")

		qa:updateLabelMode(raw)
	end),


	--------------------------------------------------
	-- Temperatures
	--------------------------------------------------

	supply_temp = tempRegister(
		1200,
		"Supply temperature"
	),

	setpoint = tempRegister(
		1201,
		"Setpoint temperature"
	),
}
