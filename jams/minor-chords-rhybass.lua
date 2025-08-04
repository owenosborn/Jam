
local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    --self.prog:parse("D-7,9...E-7,9...")
    self.prog:parse("D-7,9...E-7,9...A-7.A-9.A-11.A-9.A-7.")
    -- self.prog:parse("C-9...F13...Bbmaj7,#11...Ebmaj7...A-7b5...D7,b9...G-7...C7...") 
    
    -- Print the progression
    self.prog:print()
    
    -- Create chord player for different articulations
    self.player = ChordPlayer.new(nil, 4)  -- octave 4, chord will be set dynamically
    self.player:setStyle("roll", {delay = io.dur(1/4)})
    self.count = 1    
    self.count2 = 1

end

function jam:tick(io)
    -- Always advance the progression
    local chord_now = self.prog:tick(io)
    
    -- Check if we've moved to a new chord  
    if self.prog:isnew() then
        self.player.chord = chord_now  -- Update player's chord
        print("Now playing: " .. (chord_now.name or "Unknown"))
    end 
    
    -- Always call player tick
    self.player:tick(io)
    
    -- Play chord on beat 1 of each measure
    if io.on(1) then
        self.player:play(40, io.dur(1))  -- Play for 3 beats
    end
    
    -- Add some bass notes
    --if io.on(1/self.count2) and math.random() < 0.8 then  -- every half note
    if io.on(1/3) then
        self.count2 = math.random(1, 4)
        local bass_note = chord_now:note(1, math.random(2,4))  -- root in octave 3
        io.playNote(bass_note, 50, io.dur(1/8))
    end
    
    -- Add melody notes occasionally
    if io.on(1/self.count) and math.random() < 0.8 then  -- 30% chance every beat
        self.count = math.random(1, 4)
        local melody_note = chord_now:note(math.random(1, #chord_now.pitches), 4)
       -- io.playNote(melody_note, 60, io.dur(1/4))
    end
end

return jam
