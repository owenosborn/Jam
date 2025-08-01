-- Minor chord progression with slow rolls and random chord tones

local jam = {}

local chord = require("lib/chord")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Create progression of minor chords
    self.chords = {}
    self.chord_names = {"A-7,9", "D-9", "E-7", "F#-9"}  -- i, iv, v, vi in A minor
    
    -- Parse all chords
    for i, name in ipairs(self.chord_names) do
        local chord = chord.Chord.new()
        chord:parse(name)
        chord:print()
        table.insert(self.chords, chord)
    end
    
    -- Chord progression state
    self.current_chord_index = 1
    self.chord_duration = io.dur(4)  -- 4 beats per chord
    self.chord_counter = 0
    
    -- Chord player for rolls
    self.chord_player = ChordPlayer.new(self.chords[1], 4)  -- octave 4
    self.chord_player:setStyle("roll", {delay = io.dur(1, 8)})  -- eighth note delays
    
    -- Random note state
    self.random_counter = 0
    self.random_interval = io.dur(1, 4)  -- quarter note intervals for random checks
    
    print("Starting minor chord progression:")
    for i, name in ipairs(self.chord_names) do
        print("  " .. i .. ": " .. name)
    end
end

function jam:tick(io)
    -- Always call chord player tick
    self.chord_player:tick(io)
    
    -- Chord progression timing
    self.chord_counter = self.chord_counter + 1
    
    -- Change chord every 4 beats
    if self.chord_counter >= self.chord_duration then
        self.chord_counter = 0
        self.current_chord_index = (self.current_chord_index % #self.chords) + 1
        
        -- Update chord player with new chord
        self.chord_player.chord = self.chords[self.current_chord_index]
        
        print("Now playing: " .. self.chord_names[self.current_chord_index])
    end
    
    -- Play chord roll at start of each chord (every 4 beats)
    if io.on(4) then
        self.chord_player:play(70, io.dur(1))  -- medium velocity, quarter note duration
    end
    
    -- Random chord tone notes
    self.random_counter = self.random_counter + 1
    if self.random_counter >= self.random_interval then
        self.random_counter = 0
        
        -- 30% chance to play a random note
        if math.random() < 0.8 then
            local current_chord = self.chords[self.current_chord_index]
            local note_index = math.random(1, #current_chord.pitches)
            local octave = math.random(5, 6)  -- higher octaves for sparkle
            local note = current_chord:note(note_index, octave)
            local velocity = math.random(40, 80)  -- varied dynamics
            local duration = io.dur(1, math.random(4, 8))  -- quarter to eighth notes
            
            io.playNote(note, velocity, duration)
        end
    end
end

return jam
