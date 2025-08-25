local jam = {}
local progression = require("lib/progression")
local Bassline = require("lib/bassline")

function jam:init(io)
  self.prog = progression.Progression.new()
  self.prog:parse("Fmaj7.....Asus4.....C6,9.....B-7b5.....E7...........Asus4.....B-7b5.....C6,9.....E7.....C6,9.....B-7b5.....A-7..E7..A-.....")
  self.prog:scale(.5)
  self.prog:print()

    -- Bassline
    self.bass = Bassline.new({
        octave = 3,
        velocity = 78,
        vel_jitter = 10,
        gate = 0.85,
        humanize = 0.06,
        rate = 1/2,           -- quarter notes
    }):setStyle("walk", {sync_prob = 0.65})  -- try "pulse", "octave", "walk", or "sync"

    -- Provide a peek at next chord root (optional, helps approach notes)
    self.bass:setNextRootFn(function()
        -- naive next lookup; if unavailable, just reuse current
        local idx = self.prog.index or 1
        local next_idx = (idx % #self.prog.chords) + 1
        local next_ch = self.prog.chords[next_idx] and self.prog.chords[next_idx].chord
        if next_ch then return next_ch:note(1, self.bass.octave) end
        return nil
    end)
    self.current_chord = nil

end

function jam:tick(io)

  local chord = self.prog:tick(io)
  
  if self.prog:isnew() then
      --chord:print()
     self.bass:update_chord(chord)
  end

  self.bass:tick(io)

  if io.on(3/2, 1/2) then 
--      io.pn(chord:note(3,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

  if io.on(1/8, .01) and math.random(1,100) > 50 then 
      io.pn(chord:note(math.random(1, 5), math.random(6, 7)), {dur=1/3, vel=20} ) 
  end      

  if io.on(1/2)  then 
      io.pn(chord:note(1,5), {dur=1/3, vel=30} ) 
      io.pn(chord:note(2,5), {dur=1/3, vel=30} ) 
      --io.pn(chord:note(1,3), {dur=1/16, vel=math.random(1, 2) * 40} ) 
  end      

end

return jam
