
local jam = {}

local progression = require("lib/progression")

function jam:init(io)
    
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    --self.prog:parse("D-7.E-9.G7...Cmaj7...A7...")
    --self.prog:parse("C-9...F13...BbMaj7#11...EbMaj7...A-7b5...D7alt...G-7...C7...") 
    --self.prog:parse("F-9...Bb7...EbMaj7...Ab7...DbMaj7...G7...CMaj7...F#7...")
    --self.prog:parse("E-7.....A-7.....D7.....GMaj7.....C#-7b5.....F#7.....B-7.....E7.....")
    --self.prog:parse("CMaj7...C#dim7.D-7...D#dim7.E-7...A7...D-7...G7...")
    self.prog:parse("A-7,9..D7.....G-7..C7.....F-7..Bb7.....Ebmaj7......")
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
    if io.on(1/4) then  -- every half note
        local oct = 4
        if io.on(1) then oct = 3 end
        local bass_note = chord_now:note(1, oct)  -- root in octave 3
        io.playNote(bass_note, 60, io.dur(1/5))
    end
    
    -- Add melody notes occasionally, random octave chord tones
    if io.on(1/3) and math.random() < 0.8 then  -- 30% chance every beat
        local melody_note = chord_now:note(math.random(1, #chord_now.pitches), math.random(3,6))
        io.playNote(melody_note, 50, io.dur(1/5))
    end
end

return jam
