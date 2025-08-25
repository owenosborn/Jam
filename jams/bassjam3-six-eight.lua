-- bassjam1.lua
local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new():parse("Fmaj7..A-7..Cmaj9..B-7b5..E7.....")
  self.prog:print()
end

function jam:tick(io)

  local chord = self.prog:tick(io)
  
  if self.prog:isnew() then
      chord:print()
  end

  if io.on(3/2, 1/2) then 
      io.pn(chord:note(1,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

  if io.on(1/8) and math.random(1,100) > 50 then 
      io.pn(chord:note(math.random(1, 4), math.random(4, 8)), {dur=1/16, vel=20} ) 
  end      

  if io.on(1/2) then 
      io.pn(chord:note(1,5), {dur=1, vel=30} ) 
      io.pn(chord:note(2,5), {dur=1, vel=30} ) 
  end      

end

return jam
