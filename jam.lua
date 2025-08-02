-- progression_demo.lua
-- Simple jam demonstrating chord progressions
-- Plays a ii-V-I-VI progression in C major with different rhythmic patterns
-- Uses the enhanced progression.isnew() method for cleaner chord change detection

local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    self.prog:parse("D-7...G7...Cmaj7...A7...")
    
    -- Print the progression
    self.prog:print()
    
    -- Create chord player for different articulations
    self.player = ChordPlayer.new(nil, 4)  -- octave 4, chord will be set dynamically
    self.player:setStyle("roll", {delay = io.dur(1/8)})
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
        self.player:play(70, io.dur(3))  -- Play for 3 beats
    end
    
    -- Add some bass notes
    if io.on(1/2) then  -- every half note
        local bass_note = chord_now:note(1, 3)  -- root in octave 3
        io.playNote(bass_note, 60, io.dur(1/3))
    end
    
    -- Add melody notes occasionally
    if io.on(1) and math.random() < 0.3 then  -- 30% chance every beat
        local melody_note = chord_now:note(math.random(1, #chord_now.pitches), 6)
        io.playNote(melody_note, 50, io.dur(1/4))
    end
end

return jam
