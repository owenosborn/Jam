local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")
local Arpeggio = require("lib/arpeggio").Arpeggio

function jam:init(io)
    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    --self.prog:parse("D-7...G7...Cmaj7...A7...")
    self.prog:parse("C-9...F13...Bbmaj7,#11...Ebmaj7...A-7b5...D7,b9...G-7...C7...") 
    
    -- Print the progression
    self.prog:print()
    
    -- Create chord player for different articulations
    self.player = ChordPlayer.new(nil, 4)  -- octave 4, chord will be set dynamically
    self.player:setStyle("roll", {delay = io.dur(1/8)})
    
    -- Create multiple arpeggios for different musical layers
    self.melody_arp = Arpeggio.new(nil, "updown", 2, 4)    -- High melody arpeggio
    self.bass_arp = Arpeggio.new(nil, "up", 1, 3)          -- Bass arpeggio
    self.counter_arp = Arpeggio.new(nil, "random", 1, 3)   -- Counter-melody
    
    -- Set different timing for each arpeggio
    self.melody_arp:setTiming(io.dur(1), io.dur(1/8))    -- Sixteenth note triplets
    self.bass_arp:setTiming(io.dur(1), io.dur(1/4))      -- Half note steps
    self.counter_arp:setTiming(io.dur(1), io.dur(1/6))   -- Quarter note steps
end

function jam:tick(io)
    -- Always advance the progression
    local chord_now = self.prog:tick(io)
    
    -- Check if we've moved to a new chord  
    if self.prog:isnew() then
        self.player.chord = chord_now  -- Update player's chord
        
        -- Update all arpeggios with new chord
        self.melody_arp:setChord(chord_now)
        self.bass_arp:setChord(chord_now) 
        self.counter_arp:setChord(chord_now)
        
        print("Now playing: " .. (chord_now.name or "Unknown"))
        
        -- Change arpeggio patterns based on chord progression position
        local chord_index = self.prog.index
        if chord_index == 1 then      -- D-7 (ii)
            self.melody_arp:setPattern("up", 2)
            self.counter_arp:setPattern("down", 1)
        elseif chord_index == 2 then  -- G7 (V)
            self.melody_arp:setPattern("updown", 1)
            self.counter_arp:setPattern("random", 1)
        elseif chord_index == 3 then  -- Cmaj7 (I)
            self.melody_arp:setPattern("downup", 2)
            self.counter_arp:setPattern("up", 1)
        else                          -- A7 (VI)
            self.melody_arp:setPattern("random", 2)
            self.counter_arp:setPattern("updown", 1)
        end
    end
    
    -- Always call player tick
    self.player:tick(io)
    
    -- Always tick arpeggios for continuous playback
    self.melody_arp:tick(io)
    self.bass_arp:tick(io)
    self.counter_arp:tick(io)
    
    -- Play chord on beat 1 of each measure
    if io.on(1) then
        self.player:play(70, io.dur(3))  -- Play for 3 beats
    end
    
    -- Start melody arpeggio on beat 2
    if io.on(1) and io.beat_count % 4 == 1 then  -- Beat 2 of every measure
        self.melody_arp:play(60, io.dur(1/8), io.dur(1/6))
    end
    
    -- Start bass arpeggio pattern
    if io.on(1/2) then  -- Every half note
        self.bass_arp:play(80, io.dur(1/4), io.dur(1/2))
    end
    
    -- Trigger counter melody occasionally
    if io.on(1/4) and math.random() < 0.4 then  -- 40% chance every quarter note
        self.counter_arp:play(45, io.dur(1/6), io.dur(1/4))
    end
    
    -- Stop arpeggios occasionally for breathing room
    if io.on(1) and io.beat_count % 8 == 7 then  -- Every 8th beat
        self.melody_arp:stop()
    end
    
    if io.on(1) and io.beat_count % 16 == 15 then  -- Every 16th beat
        self.counter_arp:stop()
    end
end

return jam
