local jam = {}
local Chord = require("lib/chord")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Create chord progression: C-7 | F7 | Bb | G7
    self.chords = {}
    self.chord_names = {"C-7", "F7", "Bbmaj7", "G7"}
    
    for i, name in ipairs(self.chord_names) do
        self.chords[i] = Chord.Chord.new()
        self.chords[i]:parse(name)
        self.chords[i]:print()
    end
    
    self.chord_index = 1
    self.chord_length = 4  -- beats per chord
    
    -- Setup chord player
    self.player = ChordPlayer.new(self.chords[1], 5)
    self.player:setStyle("roll", {delay = io.dur(1/8)})
    
end

function jam:tick(io)

    -- Change chord every 4 beats
    if io.on(4) then 
        self.chord_index = (self.chord_index % #self.chords) + 1
        self.player.chord = self.chords[self.chord_index]
        print("Changed to chord: " .. self.chord_names[self.chord_index])
    end
    
    self.player:tick(io)  -- Always call this
    
    -- Play chord every 4 beats
    if io.on(4) then 
        self.player:play(80, io.dur(1))
    end
    
    -- Play root note every beat
    if io.on(1) then
        local current_chord = self.chords[self.chord_index]
        io.playNote(current_chord:note(1), 80, io.dur(1))
    end
    
    -- Add some bass movement 
    if io.on(1, 3) then  
        local current_chord = self.chords[self.chord_index]
        io.playNote(current_chord:note(3) - 12, 60, io.dur(1,2))  -- fifth, octave down
    end
    
    if io.on(3, 5) then 
        local current_chord = self.chords[self.chord_index]
        io.playNote(current_chord:note(2) - 12, 60, io.dur(1,2))  -- third, octave down
    end
end

return jam
