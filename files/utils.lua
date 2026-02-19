function read_unsigned_i16(payload)
	return (payload:byte() << 8) | payload:byte(2)
end

function read_unsigned_i32(payload)
	return (payload:byte() << 24) | (payload:byte(2) << 16) | (payload:byte(3) << 8) | payload:byte(4)
end

function read_signed_i16(payload)
  local b1 = payload:byte()
  local b2 = payload:byte(2)
  
  local mask = (1 << 15)
  local res  = (b1 << 8) | (b2 << 0)
  return (res ~ mask) - mask
end

function convert_hex(str)
	local len = string.len(str)
	local hex = ""

	for i = 1, len do
		local ord = string.byte(str, i)
		hex = hex .. string.format("%02x", ord)
	end

	return hex
end
