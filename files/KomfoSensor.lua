class 'KomfoSensor' (KomfoChild)

function KomfoSensor:__init(device)
	KomfoChild.__init(self, device) 

	self:debug("KomfoSensor init", tonumber(self.uid, 16) or self.uid)
end