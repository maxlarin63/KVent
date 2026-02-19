class 'KomfoBinarySwitch' (KomfoChild)

function KomfoBinarySwitch:__init(device)
	KomfoChild.__init(self, device) 

	self:debug("KomfoBinarySwitch init", self.uid)
end

function KomfoBinarySwitch:turnOn()
	self:trace("KomfoBinarySwitch Turn ON")
	self.parent.modbus:queueWrite(self.reg, string.char(0x00, 0x01))
end

function KomfoBinarySwitch:turnOff()
	self:trace("KomfoBinarySwitch Turn OFF")
	self.parent.modbus:queueWrite(self.reg, string.char(0x00, 0x00))
end