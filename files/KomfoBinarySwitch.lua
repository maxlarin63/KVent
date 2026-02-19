class 'KomfoBinarySwitch' (KomfoChild)

function KomfoBinarySwitch:__init(device)
	KomfoChild.__init(self, device)

	self:debug("KomfoBinarySwitch init", self.uid)
end

local function registerByUid(uid)
	if not uid then return nil end
	for _, reg in pairs(REGISTERS) do
		if reg.hex == uid then
			return reg
		end
	end
	return nil
end

function KomfoBinarySwitch:turnOn()
	self:trace("KomfoBinarySwitch Turn ON")
	local reg = registerByUid(self.uid)
	if reg then
		self.parent.modbus:queueWrite(reg, string.char(0x00, 0x01))
	end
end

function KomfoBinarySwitch:turnOff()
	self:trace("KomfoBinarySwitch Turn OFF")
	local reg = registerByUid(self.uid)
	if reg then
		self.parent.modbus:queueWrite(reg, string.char(0x00, 0x00))
	end
end