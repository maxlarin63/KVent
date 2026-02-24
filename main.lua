-- ==================================================
-- QuickApp Init
-- ==================================================

function QuickApp:onInit()
	__TAG = "QA_KOMFOVENT_C4_" .. plugin.mainDeviceId

	self:debug("QuickApp:onInit")

	-- --------------------------------------------------
	-- Child device classes
	-- --------------------------------------------------

	self:initChildDevices({
		["com.fibaro.binarySwitch"]        = KomfoBinarySwitch,
		["com.fibaro.temperatureSensor"]   = KomfoSensor,
		["com.fibaro.humiditySensor"]      = KomfoSensor,
		["com.fibaro.powerSensor"]         = KomfoSensor,
		["com.fibaro.multilevelSensor"]    = KomfoSensor,
		["com.fibaro.powerMeter"]          = KomfoSensor
	})

	self:setupDevicesMap()

	-- --------------------------------------------------
	-- QuickApp variables (device_ip, device_port, debug)
	-- --------------------------------------------------

	local ip    = self:getVariable("device_ip")
	local port  = self:getVariable("device_port")
	local debug = self:getVariable("debug")
	QA_DEBUG    = (debug == "true" or debug == true or debug == "1")

	if not ip or ip == "" then
		self:error("Device IP is not set")
		return
	end

	self.modbus = ModbusClient(self, ip, port)

	self.modbus:connect(function()
		self:queueReadRegisters()
	end)
end


-- ==================================================
-- Device Mapping
-- ==================================================

function QuickApp:setupDevicesMap()
	self.devicesMap = {}

	for hcId, device in pairs(self.childDevices) do
		self.devicesMap[device.uid] = hcId
	end
end


-- ==================================================
-- Register Polling Loop
-- ==================================================

function QuickApp:queueReadRegisters()
	fibaro.setTimeout(15000, function()

		if self.modbus and self.modbus:hasProcessedAll() then
			for _, reg in pairs(REGISTERS) do
				self.modbus:queueRead(reg)
			end
		end

		self:queueReadRegisters()

	end)
end


-- ==================================================
-- Child Helpers
-- ==================================================

function QuickApp:createChildIfNotExists(registry, createCallback)
	local uid = convert_hex(registry.id)

	if not self.devicesMap[uid] then
		createCallback(uid)
	end
end


function QuickApp:updateChildValue(registry, value)
	self:updateChildProperty(registry, "value", value)
end


function QuickApp:updateChildPower(registry, value)
	self:updateChildProperty(registry, "power", value)
end


function QuickApp:updateChildProperty(registry, property, value)
	local hcId = self.devicesMap[registry.hex]
	if not hcId then return end

	local device = self.childDevices[hcId]
	if device then
		device:updateProperty(property, value)
	end
end


-- ==================================================
-- Buttons
-- ==================================================

function QuickApp:onDeviceSyncRequested()
	self:trace("Creating device tree")
	setup_devices(self)
	self:setupDevicesMap()
end


-- --- Power ------------------------------------------------

function QuickApp:onPowerOnSelected()
	self:debug("Set Power ON")
	self.modbus:queueWrite(REGISTERS.status, string.char(0x00, 0x01))
	self:updateLabelForRegister(REGISTERS.status, 1)
end

function QuickApp:onPowerOffSelected()
	self:debug("Set Power OFF")
	self.modbus:queueWrite(REGISTERS.status, string.char(0x00, 0x00))
	self:updateLabelForRegister(REGISTERS.status, 0)
end


-- --- Season -----------------------------------------------

function QuickApp:onWinterSelected()
	self:debug("Set Winter")
	self.modbus:queueWrite(REGISTERS.season, string.char(0x00, 0x01))
	self:updateLabelForRegister(REGISTERS.season, 1)
end

function QuickApp:onSummerSelected()
	self:debug("Set Summer")
	self.modbus:queueWrite(REGISTERS.season, string.char(0x00, 0x00))
	self:updateLabelForRegister(REGISTERS.season, 0)
end


-- --- Mode -------------------------------------------------

function QuickApp:onAutoOnSelected()
	self:debug("Set Auto")
	self.modbus:queueWrite(REGISTERS.current_mode, string.char(0x00, 0x01))
	self:updateLabelForRegister(REGISTERS.current_mode, 1)
	-- Update child so notifications fire when using main GUI
	self:updateChildProperty(REGISTERS.current_mode, "value", true)
end

function QuickApp:onAutoOffSelected()
	self:debug("Set Manual")
	self.modbus:queueWrite(REGISTERS.current_mode, string.char(0x00, 0x00))
	self:updateLabelForRegister(REGISTERS.current_mode, 0)
	-- Update child so notifications fire when using main GUI
	self:updateChildProperty(REGISTERS.current_mode, "value", false)
end


-- --- Manual Speed -----------------------------------------

local function setManualSpeed(self, level)
	self:debug("Set speed " .. level)
	self.modbus:queueWrite(REGISTERS.speed_manual, string.char(0x00, level))
	self:updateLabelForRegister(REGISTERS.speed_manual, level)
end

function QuickApp:onSpeed1Selected() setManualSpeed(self, 1) end
function QuickApp:onSpeed2Selected() setManualSpeed(self, 2) end
function QuickApp:onSpeed3Selected() setManualSpeed(self, 3) end


-- ==================================================
-- UI Labels
-- ==================================================

function QuickApp:updateLabelState(label, state, textOn, textOff)
	self:updateView(label, "text", state and textOn or textOff)
end


-- Update the GUI immediately after a register write (optimistic update).
function QuickApp:updateLabelForRegister(reg, value)
	if not reg or not reg.hex then return end
	if reg.hex == REGISTERS.status.hex then
		self:updateLabelState("label_power", value == 1, "⚡ Power ON", "⭕ Power OFF")
	elseif reg.hex == REGISTERS.season.hex then
		self:updateLabelState("label_season", value == 1, "❄️ Winter", "☀️ Summer")
	elseif reg.hex == REGISTERS.current_mode.hex then
		self:updateLabelMode(value)
	elseif reg.hex == REGISTERS.speed_manual.hex then
		self:updateLabelSpeed(value)
	end
end


function QuickApp:updateLabelSpeed(state)
	local text
	if type(state) == "number" then
		-- 0 = Standby (valid when power is off); 1–4 = levels
		text = (SPEED_MAP and SPEED_MAP[state]) or (state == 0 and "💤 Standby") or ("🌀 Speed " .. state)
	else
		text = "❓ Speed Unknown"
	end
	self:updateView("label_speed", "text", text)
end


function QuickApp:updateLabelMode(state)
	local mode = MODE_MAP[state] or ("❓ Unknown (" .. tostring(state) .. ")")
	self:updateView("label_mode", "text", mode)
end
