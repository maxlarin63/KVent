function setup_devices(qa)
	local child = nil
	
	-- [[ Switches ]]

	-- Create Switch for Power status
	setup_switch(qa, REGISTERS.status, "Komfovent Power Switch")

	-- Create Switch for Season status
	setup_switch(qa, REGISTERS.season, "Komfovent Winter Switch")

	-- Create Switch for Auto mode switch
	setup_switch(qa, REGISTERS.current_mode, "Komfovent Auto Mode Switch")

	-- Create Switch for Service warning (register 1007, bit 14)
	setup_switch(qa, REGISTERS.service, "Komfovent Service Switch")

	-- [[ Temp sensors ]]

	-- Create Supply Temp sensor
	setup_temp_sensor(qa, REGISTERS.supply_temp, "Komfovent Supply Temp")

	-- Create Setpoint Temp sensor
	setup_temp_sensor(qa, REGISTERS.setpoint, "Komfovent Setpoint Temp")
end

function setup_switch(qa, registry, name)
	qa:createChildIfNotExists(registry, function(uid) 
		child = qa:createChildDevice({
			name = name,
			type = "com.fibaro.binarySwitch",
		}, KomfoBinarySwitch)

		qa:trace(child.name, " created: ", child.id)
		child:setVariable("registry_uid", uid)
	end)
end

function setup_temp_sensor(qa, registry, name)
	setup_sensor(qa, registry, "com.fibaro.temperatureSensor", name)
end

function setup_humidity_sensor(qa, registry, name) 
	setup_sensor(qa, registry, "com.fibaro.humiditySensor", name)
end

function setup_power_sensor(qa, registry, name)
	setup_sensor(qa, registry, "com.fibaro.powerSensor", name)
end

function setup_power_meter(qa, registry, name)
	setup_sensor(qa, registry, "com.fibaro.powerMeter", name)
end

function setup_custom_sensor(qa, registry, name, unit)
	setup_sensor(qa, registry, "com.fibaro.multilevelSensor", name, unit)
end

function setup_sensor(qa, registry, type, name, unit)
	qa:createChildIfNotExists(registry, function(uid) 
		child = qa:createChildDevice({
			name = name,
			type = type,
		}, KomfoSensor)

		qa:trace(child.name, " created: ", child.id)
		child:setVariable("registry_uid", uid)

		if unit and unit ~= "" then
			child:updateProperty("unit", unit)
		end
	end)
end