-- parse a chord and cycle through the notes

local jam = {}

local elements = require("lib/elements")
local ChordPlayer = require("lib/chord_player")
require("lib/chord_parser")

function jam:init(io)
    self.chord = elements.Chord.new()
    self.chord:parse("C-7")  -- C minor 7    
    self.chord:print()
    self.c=1

    self.player = ChordPlayer.new(self.chord, 5)  -- octave 5
    self.player:setStyle("roll", {delay = io.dur(1/8)})

end

function jam:tick(io)
    self.player:tick(io)  -- Always call this
    if io.on(4) then 
        self.player:play(80, io.dur(1))  -- Trigger chord
    end

    if io.on(1) then
        io.playNote(self.chord:note(1), 80, io.dur(1))
    end
end

return jam
