
local jam = {}

local progression = require("lib/progression")
local chord = require("lib/chord")

function jam:init(io)
    
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    self.prog:parse("D-7.E-9.G7...Cmaj7...A7...")
    self.chord = progression.Progression.new()
    self.chord:parse("D-7")
    -- Print the progression
    self.prog:print()
    self.count = 0 
    
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
    if io.on(1/4) and math.random() < .5 then  -- every half note
        local oct = 4
        if io.on(1) then oct = 3 end
        local bass_note = chord_now:note(1, oct)  -- root in octave 3
        io.play_note(bass_note, 60, 1/3)
    end
    
    -- Add melody notes occasionally, random octave chord tones
    if io.on(1/4) and math.random() < 0.8 then  -- 30% chance every beat
        --local melody_note = chord_now:note(math.random(1, #chord_now.pitches), math.random(3,6))  
        local melody_note = chord_now:note(self.count % #chord_now.pitches, 5)
        self.count  = self.count + 1
        io.play_note(melody_note, 60, 1/5)
    end
end

return jam
