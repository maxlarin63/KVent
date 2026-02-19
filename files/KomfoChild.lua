class 'KomfoChild' (QuickAppChild)

function KomfoChild:__init(device)
	QuickAppChild.__init(self, device) 

	self.uid = self:getVariable("registry_uid")
end