local jam = {}
local progression = require("lib/progression")

function jam:init(io)
  self.prog = progression.Progression.new()
  self.prog:parse("Fmaj7.....Asus4.....C6,9.....B-7b5.....E7...........Asus4.....B-7b5.....C6,9.....E7.....C6,9.....B-7b5.....A-7..E7..A-.....")
  self.prog:scale(.5)
  self.prog:print()
end

function jam:tick(io)

  local chord = self.prog:tick(io)
  
  if self.prog:isnew() then
      --chord:print()
  end

  if io.on(3/2, 1/2) then 
      io.pn(chord:note(3,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

  if io.on(1/4) and math.random(1,100) > 50 then 
      io.pn(chord:note(math.random(1, 5), math.random(6, 7)), {dur=1/3, vel=20} ) 
  end      

  if io.on(1/2)  then 
      io.pn(chord:note(1,5), {dur=1/3, vel=30} ) 
      io.pn(chord:note(2,5), {dur=1/3, vel=30} ) 
      io.pn(chord:note(1,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

end

return jam
