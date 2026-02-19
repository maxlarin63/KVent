class 'ModbusClient'

-- ==================================================
-- CONFIG
-- ==================================================

local DEBUG = false   -- <<< set false in production

local DEFAULT_PORT         = "502"
local RECONNECTION_TIMEOUT = 5000
local REQUEST_TIMEOUT      = 2000
local MAX_BLOCK_SIZE       = 20

local NODE_ID     = string.char(0x01)
local PROTOCOL_ID = string.char(0x00, 0x00)
local READ_FUNC   = string.char(0x03)
local WRITE_FUNC  = string.char(0x06)

local function debugLog(qa, ...)
	if DEBUG then
		qa:debug(...)
	end
end


-- ==================================================
-- INIT
-- ==================================================

function ModbusClient:__init(qa, ip, port)
	self.qa   = qa
	self.ip   = ip
	self.port = (port and port ~= "") and port or DEFAULT_PORT

	self.sock        = nil
	self.connected   = false
	self.isProcessing = false

	self.readQueue   = {}
	self.writeQueue  = Queue()
	self.requests    = {}

	self.readId  = 1
	self.writeId = 10001

	debugLog(self.qa, "ModbusClient init", self.ip, self.port)
end


-- ==================================================
-- CONNECTION
-- ==================================================

function ModbusClient:connect(on_ready)
	self.onConnected = on_ready

	self.sock = net.TCPSocket({ timeout = 10000 })

	self.sock:connect(self.ip, tonumber(self.port), {
		success = function()
			self.connected = true
			self.qa:trace("Modbus connected")

			if self.onConnected then
				self.onConnected()
			end

			self:pump()
		end,

		error = function(err)
			self:handleDisconnect("Connect error: " .. tostring(err))
		end
	})
end


function ModbusClient:handleDisconnect(msg)
	self.connected = false
	self.isProcessing = false

	if self.sock then
		self.sock:close()
	end

	self.qa:warning(msg)

	fibaro.setTimeout(RECONNECTION_TIMEOUT, function()
		self:connect(self.onConnected)
	end)
end


-- ==================================================
-- PUBLIC API
-- ==================================================

function ModbusClient:queueRead(registry)
	table.insert(self.readQueue, registry)

	local addr = read_unsigned_i16(registry.id)
	debugLog(self.qa, "Queue read register:", addr)

	self:pump()
end


function ModbusClient:queueWrite(registry, value)
	local id, frame = self:createWriteFrame(registry.id, value)

	self.writeQueue:push({
		id = id,
		frame = frame
	})

	debugLog(self.qa,
		"Queue write id:", id,
		"frame:", convert_hex(frame)
	)

	self:pump()
end


function ModbusClient:hasProcessedAll()
	return #self.readQueue == 0
	   and self.writeQueue:isEmpty()
	   and not self.isProcessing
end


-- ==================================================
-- SEND PUMP
-- ==================================================

function ModbusClient:pump()
	if not self.connected or self.isProcessing then
		return
	end

	-- writes first
	if not self.writeQueue:isEmpty() then
		local item = self.writeQueue:pop()

		debugLog(self.qa,
			"Send write id:", item.id,
			"frame:", convert_hex(item.frame)
		)

		self:sendFrame(item)
		return
	end

	if #self.readQueue > 0 then
		self:sendReadBlock()
	end
end


-- ==================================================
-- CONTIGUOUS BLOCK READ
-- ==================================================

function ModbusClient:sendReadBlock()

	table.sort(self.readQueue, function(a, b)
		return read_unsigned_i16(a.id) < read_unsigned_i16(b.id)
	end)

	local block = {}
	local startReg
	local count = 0

	for _, reg in ipairs(self.readQueue) do
		local addr = read_unsigned_i16(reg.id)

		if not startReg then
			startReg = addr
			block[#block + 1] = reg
			count = 1
		else
			local expected = startReg + count

			if addr == expected and count < MAX_BLOCK_SIZE then
				block[#block + 1] = reg
				count = count + 1
			else
				break
			end
		end
	end

	for i = 1, #block do
		table.remove(self.readQueue, 1)
	end

	local id, frame = self:createBlockReadFrame(startReg, count)

	self.requests[id] = {
		type = "read_block",
		regs = block
	}

	debugLog(self.qa,
		"Send read block id:", id,
		"start:", startReg,
		"count:", count,
		"frame:", convert_hex(frame)
	)

	self:sendFrame({ id = id, frame = frame })
end


-- ==================================================
-- FRAME SEND
-- ==================================================

function ModbusClient:sendFrame(item)
	self.isProcessing = true

	self.sock:write(item.frame, {
		success = function()
			self:startTimeout(item.id)
			self:waitForResponse()
		end,

		error = function(err)
			self.isProcessing = false
			self:handleDisconnect("Write error: " .. tostring(err))
		end
	})
end


function ModbusClient:startTimeout(id)
	fibaro.setTimeout(REQUEST_TIMEOUT, function()
		if self.requests[id] then
			self.qa:warning("Request timeout id:", id)
			self.requests[id] = nil
			self.isProcessing = false
			self:pump()
		end
	end)
end


function ModbusClient:waitForResponse()
	self.sock:read({
		success = function(data)
			self.isProcessing = false
			self:onData(data)
			self:pump()
		end,

		error = function(err)
			self.isProcessing = false
			self:handleDisconnect("Read error: " .. tostring(err))
		end
	})
end


-- ==================================================
-- RESPONSE HANDLING
-- ==================================================

function ModbusClient:onData(data)
	local id = read_unsigned_i16(string.sub(data, 1, 2))
	local function_id = string.byte(data, 8)

	debugLog(self.qa,
		"Received id:", id,
		"frame:", convert_hex(data)
	)

	local req = self.requests[id]
	self.requests[id] = nil

	if not req then
		return
	end

	if req.type == "read_block" then
		local payload = string.sub(data, 10)

		for i, reg in ipairs(req.regs) do
			local offset = (i - 1) * 2
			local part = string.sub(payload, offset + 1, offset + 2)
			reg.on_read_callback(self.qa, reg, part)
		end
	end
end


-- ==================================================
-- FRAME CREATION
-- ==================================================

function ModbusClient:createBlockReadFrame(startReg, count)
	local id = self.readId
	self.readId = (id % 10000) + 1

	local frame_id = string.char(id >> 8, id & 0xFF)

	local addr_hi = startReg >> 8
	local addr_lo = (startReg & 0xFF) - 1

	local size_hi = count >> 8
	local size_lo = count & 0xFF

	local frame = frame_id
			   .. PROTOCOL_ID
			   .. string.char(0x00, 0x06)
			   .. NODE_ID
			   .. READ_FUNC
			   .. string.char(addr_hi, addr_lo)
			   .. string.char(size_hi, size_lo)

	return id, frame
end


function ModbusClient:createWriteFrame(command, value)
	local id = self.writeId
	self.writeId = (id >= 20000) and 10001 or (id + 1)

	local addr_hi = command:byte(1)
	local addr_lo = command:byte(2) - 1

	local frame_id = string.char(id >> 8, id & 0xFF)

	local frame = frame_id
			   .. PROTOCOL_ID
			   .. string.char(0x00, 0x06)
			   .. NODE_ID
			   .. WRITE_FUNC
			   .. string.char(addr_hi, addr_lo)
			   .. value

	return id, frame
end
