
local jam = {}

local progression = require("lib/progression")

function jam:init(io)
    
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    self.prog:parse("D-7.E-9.G7...Cmaj7...A7...")
    
    -- Print the progression
    self.prog:print()
    
end

function jam:tick(io)
    
    -- Always advance the progression
    local chord_now = self.prog:tick(io)
    
    -- Check if we've moved to a new chord  
    if self.prog:isnew() then
        print("Now playing: " .. (chord_now.name or "Unknown"))
    end
    
    -- play chord tones at different intervals
    -- roots on octaves at eighth notes
    if io.on(1/2) then  -- every half note
        local oct = 4
        if io.on(1) then oct = 3 end
        local bass_note = chord_now:note(1, oct)  -- root in octave 3
        io.playNote(bass_note, 60, io.dur(1/3))
    end
    
    -- Add melody notes occasionally, random octave chord tones
    if io.on(1/3) and math.random() < 0.8 then  -- 30% chance every beat
        local melody_note = chord_now:note(math.random(1, #chord_now.pitches), math.random(3,6))
        io.playNote(melody_note, 50, io.dur(1/5))
    end
end

return jam
