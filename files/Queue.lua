class 'Queue'

function Queue:__init() 
	self.first = 0
	self.last = -1
end

function Queue:push(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

function Queue:pop ()
  local last = self.last
  if self.first > last then 
	error("list is empty") 
  end
  
  local value = self[last]
  self[last] = nil         -- to allow garbage collection
  self.last = last - 1
  
  return value
end

function Queue:isEmpty()
	return self.first > self.last
end