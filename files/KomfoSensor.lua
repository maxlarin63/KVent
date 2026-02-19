class 'KomfoSensor' (KomfoChild)

function KomfoSensor:__init(device)
	KomfoChild.__init(self, device) 

	self:debug("KomfoSensor init", self.uid)
end