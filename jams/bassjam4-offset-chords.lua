-- bassjam1.lua
local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new():parse("A-9.A-.D-7.D-7,9,11.G7.F..")
  self.prog:print()
end

function jam:tick(io)

  local chord = self.prog:tick(io)
  
  if self.prog:isnew() then
        chord:print()
  end

  if io.on(1/4) then 
      io.pn(chord:note(1,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

  if io.on(1/4, 1/16) and math.random(1,100) > 30 then 
      io.pn(chord:note(math.random(1, 8), math.random(5, 7)), {dur=1/4, vel=20} ) 
  end      

  if io.on(2, 1/4) then 
      io.pn(chord:note(1,math.random(4,5)), {dur=1, vel=30} ) 
      io.pn(chord:note(2,math.random(4,5)), {dur=1.9, vel=30} ) 
  end      
  if io.on(2, 1/4 + 1/16) then 
      io.pn(chord:note(3,math.random(4,5)), {dur=1, vel=30} ) 
      io.pn(chord:note(4,math.random(4,5)), {dur=1.9, vel=30} ) 
  end      


end

return jam
