-- tiny-groove.lua
local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new():parse("Cmaj7...A-7...D-7...G7...")
  self.step = 0
end

function jam:tick(io)
  local chord = self.prog:tick(io)
  if io.on(1) then io.playNote(chord:note(1,3), 70, io.dur(1/2), 1) end       -- bass on beats
  if io.on(1/2) then io.playNote(chord:note(5,5), 50, io.dur(1/4), 1) end    -- high ping on 8ths
  if io.on(1/4) and self.step % 3 == 0 then                                  -- simple arp
    io.playNote(chord:note((self.step % #chord.pitches)+1, 4), 60, io.dur(1/4), 1)
  end
  self.step = self.step + 1
end

return jam
