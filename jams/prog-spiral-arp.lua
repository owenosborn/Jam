local jam = {}
local progression = require("lib/progression")

function jam:init(io)
    self.prog = progression.Progression.new():parse("A-7...D-7...G-7...C-7...")
    self.spirals = {
        {rate = 1/4, oct = 4, dir = 1, vel = 70},   -- fast upward
        {rate = 1/3, oct = 5, dir = -1, vel = 60},  -- medium downward  
        {rate = 1/2, oct = 3, dir = 1, vel = 80}    -- slow upward
    }
end

function jam:tick(io)
    local chord = self.prog:tick(io)
    
    for i, spiral in ipairs(self.spirals) do
        if io.on(spiral.rate) then
            local beat_pos = math.floor(io.beat_count / spiral.rate) * spiral.dir
            local note_idx = (beat_pos % #chord.pitches) + 1
            local octave_shift = math.floor(beat_pos / #chord.pitches) % 3
            local note = chord:note(note_idx, spiral.oct + octave_shift * spiral.dir)
            io.playNote(note, spiral.vel, io.dur(spiral.rate * 0.8), i)
        end
    end
end

return jam