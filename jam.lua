local jam = {}

-- use the counter object to repeat

function jam:init(io)
    local j = require("lib/elements")
    self.c = j.Counter.new(io.tpb // 4)
    self.note = j.Note.new({num=60, dur=50, vel=80})
    self.note.ch = 123
    self.note:print()
end

function jam:tick(io)
    if self.c:tick() then
        self.note:play(io, 10)
    end
end

return jam
