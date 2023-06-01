local Class = require "libs.classic"

local Enum = Class:extend()

function Enum:new(table)
    self.values = table
    self.length = #self.values
end

function Enum:__index(key)
    for i = 1, self.length do
        if self.values[i] == key then
            return i
        end
    end
end

return Enum