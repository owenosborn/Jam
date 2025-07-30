-- parse a chord and cycle through the notes, using several time divisions

local jam = {}

local elements = require("lib/elements")
require("lib/chord_parser")

function jam:init(io)
    self.chord = elements.Chord.new()
    self.chord:parse("C-7,9")  
    self.chord:print()
    self.c=1
    self.c2=1
end

function jam:tick(io)

    if io.on(1/2) then 
        io.playNote(self.chord.pitches[self.c] + 60, 80, io.dur(1/2))
        self.c = (self.c % #self.chord.pitches) + 1
    end 

    if io.on(1/3) then 
        io.playNote(self.chord.pitches[self.c] + 60, 80, io.dur(1/2))
        self.c = (self.c % #self.chord.pitches) + 1
    end 

    if io.on(1/9) then 
        io.playNote(self.chord.pitches[self.c2] + 72, 80, io.dur(3))
        self.c2 = (self.c2 % #self.chord.pitches) + 1
    end 

end

return jam
