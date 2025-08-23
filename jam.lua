-- tiny-groove.lua
local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new():parse("Cmaj7...A-9.A-.D-7.D-7,9,11.G7.F.")
  self.step = 0
end

function jam:tick(io)
  local chord = self.prog:tick(io)
  if io.on(1) then io.pn(chord:note(1,3), {dur=1/16} ) end       -- bass on beats
  if io.on(1/2) then io.pn(chord:note(5,5), {dur=1/16} ) end    -- high ping on 8ths
  if io.on(1/3) and self.step % 3 == 0 then                                  -- simple arp
    io.pn(chord:note((self.step % #chord.pitches)+1, 4), {dur=1/16} )
  end
  if io.on(1/6) and self.step % 3 == 0 then io.pn(chord:note((self.step % #chord.pitches)+2, 4), {dur=1/16} ) end
  self.step = self.step + 1

end

return jam
