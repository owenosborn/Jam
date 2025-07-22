local jam = {}

-- use the counter object to repeat

function jam:init(io)
    local j = require("lib/elements")
    self.c = j.Counter.new(io.tpb // 4)
    self.c2 = j.Counter.new(io.tpb // 3 - 2)  -- 
    self.note = j.Note.new({num=60, dur=io.tpb // 8, vel=80})
    self.note2 = j.Note.new({num=63, dur=io.tpb // 2, vel=80})
    self.note:print()
end

function jam:tick(io)
    if self.c:tick() then self.note:play(io) end
    if self.c2:tick() then self.note2:play(io) end
end

return jam
