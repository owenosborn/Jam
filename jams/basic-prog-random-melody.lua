
local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    self.prog = progression.Progression.new()
    --sddelf.prog:parse("D-7,9...E-7,9...")
    self.prog:parse("D-7,9...E-7,9...A-7.A-9.A-11.A-9.A-7.")
    -- self.prog:parse("C-9...F13...Bbmaj7,#11...Ebmaj7...A-7b5...D7,b9...G-7...C7...") 
    
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
        self.player:play(40, io.dur(1))  
        self.count2 = math.random(1, 4)
    end
    
    if io.on(1/self.count2) and math.random() < 0.8 then 
        local n = chord_now:note(math.random(1, #chord_now.pitches), math.random(5,6)) 
        io.playNote(n, 60, io.dur(1/16))
    end
end

return jam
