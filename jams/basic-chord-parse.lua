-- parse a chord and cycle through the notes

local jam = {}

local Chord = require("lib/chord")

function jam:init(io)
    self.chord = Chord.Chord.new()
    self.chord:parse("C-7")  -- C minor 7    
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
