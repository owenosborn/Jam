-- bassjam1.lua
local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new():parse("Cmaj7...A-9.A-.D-7.D-7,9,11.G7.F.")
  self.prog:print()
end

function jam:tick(io)
  local chord = self.prog:tick(io)
  
  if self.prog:isnew() then
        chord:print()
  end

  if io.on(1/4) then 
      io.pn(chord:note(1,3), {dur=1/16} ) 
  end      

end

return jam
