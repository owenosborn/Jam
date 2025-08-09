local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Slow minor chord progression: Am → Dm → Em → Am
    self.prog = progression.Progression.new()
    self.prog:parse("A-7........ D-7........ E-7........ A-7........") -- 8 beats per chord

    self.prog:print()

    -- Chord player for pad-like chords
    self.chord_player = ChordPlayer.new(nil, 5)
    self.chord_player:setStyle("strum", {delay = io.dur(1/4), reverse = false})

    -- For bass notes
    self.bass_octave = 3

    -- For random arpeggios
    self.arp_octaves = {5, 6}
    self.arp_prob = 0.4

    self.ccount = 1
end

function jam:tick(io)
    local chord_now = self.prog:tick(io)

    -- Detect chord change
    if self.prog:isnew() then
        self.chord_player.chord = chord_now
        self.ccount = 1
        print("Now playing: " .. (chord_now.name or "Unknown"))
    end

    -- Keep chord player ticking
    self.chord_player:tick(io)

    -- Play full chord on beat 1 of each measure
    if io.on(8) then
        self.chord_player:play(50, io.dur(6)) -- soft sustained
    end

    -- Pulsing bass line: root note every beat
    if io.on(1) then
        local bass_note = chord_now:note(1, self.bass_octave)
        io.playNote(bass_note, 80, io.dur(3/4))
    end

    -- Random arpeggios: sprinkle notes between beats
    if io.on(1/2) and math.random() < self.arp_prob then
        local pitch_index = math.random(1, #chord_now.pitches)
        local octave = self.arp_octaves[math.random(#self.arp_octaves)]
        local note = chord_now:note(pitch_index, octave)
        io.playNote(note, 70, io.dur(1/3))
    end
end

return jam
