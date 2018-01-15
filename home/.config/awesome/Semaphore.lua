local Semaphore = {}
Semaphore.__index = Semaphore

setmetatable(Semaphore, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

function Semaphore.new(callback_lock, callback_unlock)
    local self = setmetatable({}, Semaphore)
    self.callback_lock = callback_lock
    self.callback_unlock = callback_unlock
    self.value = 0

    return self
end

function Semaphore:lock()
    self.value = self.value + 1
    if self.value == 1 then
        self.callback_lock()
    end
end

function Semaphore:unlock()
    if self.value == 0 then
        return
    end

    self.value = self.value - 1
    if self.value == 0 then
        self.callback_unlock()
    end
end

function Semaphore:is_locked()
    return self.value > 0
end

return Semaphore
