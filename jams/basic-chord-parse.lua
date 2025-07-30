-- parse a chord and cycle through the notes

local jam = {}

local chord_parser = require("lib/chord_parser")
local elements = require("lib/elements")

function jam:init(io)
    self.chord = elements.Chord.new()
    chord_parser.parse(self.chord, "C-7")  -- C minor 7    
    self.chord:print()
    self.c=1
end

function jam:tick(io)
    if io.on(1/2) then 
        io.playNote(self.chord.pitches[self.c] + 60, 80, io.dur(1,2))
        self.c = (self.c % #self.chord.pitches) + 1
    end 
end

return jam
