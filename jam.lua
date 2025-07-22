local jam = {}

-- use the counter object to repeat

function jam:init(io)
    local j = require("lib/elements")
    self.c = j.Counter.new(io.tpb // 4)
    self.c2 = j.Counter.new(io.tpb // 4)
    self.note = j.Note.new({num=60, dur=50, vel=80})
    self.note2 = j.Note.new({num=65, dur=50, vel=80})
    self.note:print()
end

function jam:tick(io)
    if self.c:tick() then
        --io.playNote(60, 80, 50, 6)
        self.note:play(io)
    end
end

return jam
