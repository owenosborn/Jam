-- parse a chord and cycle through the notes

local jam = {}

local elements = require("lib/elements")
require("lib/chord_parser")

function jam:init(io)
    self.chord = elements.Chord.new()
    self.chord:parse("C-7")  -- C minor 7    
    self.chord:print()
    self.c=1
end

function jam:tick(io)
    if io.on(4) then 
        io.playNote(self.chord.pitches[1] + self.chord.root + 60, 80, io.dur(1))
        io.playNote(self.chord.pitches[2] + self.chord.root + 60, 80, io.dur(1))
        io.playNote(self.chord.pitches[3] + self.chord.root + 60, 80, io.dur(1))
    end
end

return jam
