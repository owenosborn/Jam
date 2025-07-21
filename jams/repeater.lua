local jam = {}

-- use the counter object to repeat

function jam:init(io)
    local elements = require("lib/elements")
    self.sixteenth_counter = elements.Counter.new(io.tpb // 4)
end

function jam:tick(io)
    if self.sixteenth_counter:tick() then
        io.playNote(60, 80, io.tpb // 8)
    end
end

return jam
