local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")
local Bassline = require("lib/bassline")

function jam:init(io)
    -- Slow minor vibe: Am9 → Dm9 → Em7 → Am9 (8 beats each)
    self.prog = progression.Progression.new()
    --self.prog:parse("A-9... D-9... E-7... A-9...")
    --self.prog:parse("A-9... D-9...")
    --a = chord.Chord.new()
    self.prog:add(chord.Chord.new():parse("F7"), 8)
    self.prog:add(chord.Chord.new():parse("Bb7"), 4)
    self.prog:add(chord.Chord.new():parse("F7"), 4)
    self.prog:add(chord.Chord.new():parse("B7"), 2)
    self.prog:add(chord.Chord.new():parse("Bb7"), 2)
    self.prog:add(chord.Chord.new():parse("F7"), 8)


    --self.prog:parse("F-9...Bb7...EbMaj7...Ab7...DbMaj7...G7...CMaj7...F#7...")
    --self.prog:parse("C-9...F13...Bbmaj7,#11...Ebmaj7...A-7b5...D7,b9...G-7...C7...") 
    --self.prog:parse("C-7....... G-7...C7... Fmaj7....... F-7...Bb7... Ebmaj7...Eb-7.Ab7. Dbmaj7...D-7b5.G7.") 
    self.prog:print()

    -- Pad-ish chords
    self.chords = ChordPlayer.new(nil, 5)
    self.chords:setStyle("strum", {delay = io.dur(1/4), reverse = false})

    -- Bassline
    self.bass = Bassline.new({
        octave = 3,
        velocity = 78,
        vel_jitter = 10,
        gate = 0.85,
        humanize = 0.06,
        rate = 1/2,           -- quarter notes
    }):setStyle("octave", {sync_prob = 0.65})  -- try "pulse", "octave", "walk", or "sync"

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
    self.div = 1
end

function jam:tick(io)
    local ch = self.prog:tick(io)

    if self.prog:isnew() then
        self.current_chord = ch
        self.chords.chord = ch
        self.bass:update_chord(ch)
        print("Now playing: " .. (ch.name or "Unknown"))
        self.chords:play(50, io.dur(1/2))
    end


    -- tick bass line and chord player
    self.chords:tick(io)
    self.bass:tick(io)

    if io.on(1) then
        self.div = math.random(1, 3) + 1
    end

    -- some other random notes
    if io.on(1/self.div) and math.random() < 0.9 then 
        local n = self.current_chord:note(math.random(1, #self.current_chord.pitches), math.random(4,6)) 
        io.playNote(n, 60, io.dur(1/self.div))
    end

end

return jam
