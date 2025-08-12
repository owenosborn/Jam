-- one-synth-chaos-bed.lua
-- Single-channel jam: musical "drums" + bass/arp/top share one synth
local jam = {}

local progression = require("lib/progression")

local function choice(t) return t[math.random(#t)] end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

local function euclid(hits, steps)
  hits = math.max(0, math.min(hits, steps))
  local pat, bucket = {}, 0
  for i=1,steps do
    bucket = bucket + hits
    if bucket >= steps then bucket = bucket - steps; pat[i]=1 else pat[i]=0 end
  end
  return pat
end

local function swing_offset(io, amt)
  local eighth_tick = (io.tc // io.dur(1/2))
  return (eighth_tick % 2 == 1) and amt or 0
end

local function ratchet(io, note, vel, dur_beats, n, ch)
  n = math.max(2, n)
  local sub = dur_beats / n
  for _=1,n do
    io.playNote(note, vel, io.dur(sub*0.85), ch)
  end
end

function jam:init(io)
  self.prog = progression.Progression.new():parse(
    "A-7.. D7.. G-7.. C7.. F-7.. Bb7.. Ebmaj7.. Ab7.."
  )
  math.randomseed(os.time())

  -- one-channel setup
  self.ch = 1
  self.swing = 0.04
  self.section_len = 8

  -- Background “beat” (musical, same synth)
  -- kick: super short low root; hat: super short high 9th
  self.bed = {
    kick_vel = 56,
    hat_vel  = 32,
    hat_skip_every = 16,
    hat_counter = 0,
    kick_oct = 1,  -- very low
    hat_oct  = 6,  -- very high ping
    hat_deg  = 9,  -- 9th gives a click-y color
  }

  -- Voices (still single channel; separated by register, length, velocity)
  self.bass = { oct=2, vel=80, step=0, len=16, mask=euclid(9,16), rot=0, ratchet_prob=0.30, div=1/2 }
  self.arp  = { oct=5, vel=72, step=0, len=12, mask=euclid(5,12), rot=0, order={1,3,5,7,5,3}, idx=1, div=1/3, burst_prob=0.22 }
  self.top  = { oct=6, vel=66, walk={-2,-1,1,2,3,5}, degree=5, divs={1/4,1/5,1/6}, div_idx=1, prob_gate=0.75 }

  print("=== One Synth Chaos + Musical Bed ===")
end

function jam:tick(io)
  local chord = self.prog:tick(io)
  local sw = swing_offset(io, self.swing)

  -- Section changes
  if io.on(self.section_len) then
    self.bass.rot = (self.bass.rot + math.random(1,3)) % self.bass.len
    self.arp.rot  = (self.arp.rot  + math.random(1,4)) % self.arp.len
    if math.random() < 0.33 then self.bass.mask = euclid(math.random(7,11),16) end
    if math.random() < 0.33 then self.arp.mask  = euclid(math.random(4,7),12)  end
    self.top.div_idx = (self.top.div_idx % #self.top.divs) + 1
  end

  -- ===== Musical Background Bed (same channel) =====
  -- "Kick": 4-on-the-floor low root, super short
  if io.on(1, sw) then
    local n = chord:note(1, self.bed.kick_oct)
    io.playNote(n, self.bed.kick_vel, io.dur(1/10), self.ch)
  end
  -- "Hat": swung 8th tiny 9th ping, very soft; skip one occasionally
  if io.on(1/2, sw) then
    self.bed.hat_counter = (self.bed.hat_counter + 1) % self.bed.hat_skip_every
    if self.bed.hat_counter ~= 0 then
      local n = chord:note(self.bed.hat_deg, self.bed.hat_oct)
      io.playNote(n, self.bed.hat_vel, io.dur(1/12), self.ch)
    end
  end
  -- Rare ghost tick on 16ths
  if io.on(1/4, sw*0.5) and math.random() < 0.07 then
    local n = chord:note(self.bed.hat_deg, self.bed.hat_oct)
    io.playNote(n, self.bed.hat_vel-6, io.dur(1/16), self.ch)
  end
  -- =================================================

  -- BASS: swung 8ths + occasional ratchets
  if io.on(self.bass.div, sw) then
    self.bass.step = (self.bass.step + 1) % self.bass.len
    local i = ((self.bass.step + self.bass.rot) % self.bass.len) + 1
    if self.bass.mask[i] == 1 then
      local n = chord:note(1, self.bass.oct)
      local v = clamp(self.bass.vel + math.random(-6,6), 48, 112)
      if math.random() < self.bass.ratchet_prob then
        ratchet(io, n, v, 1/2, choice({2,3,4}), self.ch)
      else
        io.playNote(n, v, io.dur(1/2*0.95), self.ch)
      end
    end
  end

  -- ARP: polymetric 12-step through chord tones
  if io.on(self.arp.div) then
    self.arp.step = (self.arp.step + 1) % self.arp.len
    local i = ((self.arp.step + self.arp.rot) % self.arp.len) + 1
    if self.arp.mask[i] == 1 then
      local degree = self.arp.order[self.arp.idx]
      self.arp.idx = (self.arp.idx % #self.arp.order) + 1
      local n = chord:note(degree, self.arp.oct)
      local v = clamp(self.arp.vel + math.random(-8,8), 45, 108)
      io.playNote(n, v, io.dur(self.arp.div*0.9), self.ch)
    end
  end

  -- ARP bursts on chord change
  if self.prog.isnew and self.prog:isnew() and math.random() < self.arp.burst_prob then
    local hits = math.random(3,6)
    for k=1,hits do
      local deg = choice({3,5,7,9})
      local n = chord:note(deg, self.arp.oct + (k>3 and 1 or 0))
      io.playNote(n, clamp(60 + math.random(-10,12), 40, 114), io.dur(1/8), self.ch)
    end
  end

  -- TOP: probabilistic random-walk melody
  local top_div = self.top.divs[self.top.div_idx]
  if math.random() < self.top.prob_gate and io.on(top_div, -sw*0.5) then
    self.top.degree = clamp(self.top.degree + choice(self.top.walk), 1, 9)
    local n = chord:note(self.top.degree, self.top.oct)
    local v = clamp(self.top.vel + math.random(-12,10), 40, 104)
    if math.random() < 0.2 then
      ratchet(io, n, v, top_div*0.9, 2, self.ch)
    else
      io.playNote(n, v, io.dur(top_div*0.85), self.ch)
    end
  end

  -- Soft pad clusters on downbeats—keep very low so they don't mask attacks
  if io.on(4) and math.random() < 0.3 then
    for i=1, math.min(4, #chord.pitches) do
      io.playNote(chord:note(i, 4), 28, io.dur(2), self.ch)
    end
  end
end

return jam
