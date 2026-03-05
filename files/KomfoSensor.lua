class 'KomfoSensor' (KomfoChild)

function KomfoSensor:__init(device)
	KomfoChild.__init(self, device)

	-- Don't call getUid() here (would trigger "variable not found" for newly created sensors)
	local u = self.uid
	self:debug("KomfoSensor init", u and (tonumber(u, 16) or u) or "?")
end