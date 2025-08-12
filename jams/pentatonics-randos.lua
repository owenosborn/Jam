local jam = {}
local progression = require("lib/progression")

function jam:init(io)
    -- ii-V-I-vi in Bb major
    self.prog = progression.Progression.new():parse("C-7...F7...Bbmaj7...G-7...")
    
    -- Pentatonic patterns relative to chord root
    self.patterns = {
        minor = {0, 3, 5, 7, 10},     -- minor pentatonic from root
        major = {0, 2, 4, 7, 9},      -- major pentatonic from root  
        dom = {0, 3, 5, 6, 10}        -- blues-influenced for dom7
    }
    
    self.phrase_pos = 1
    self.octave_base = 5
    self.div = 1
end

function jam:tick(io)
    local chord = self.prog:tick(io)
    
    -- Choose pentatonic based on chord quality
    local scale = self.patterns.minor
    if chord.name:find("maj") then scale = self.patterns.major
    elseif chord.name:find("7") and not chord.name:find("-") then scale = self.patterns.dom end
   
    if io.on(1) then
        local root = chord:note(1, 3)
        io.playNote(root, 60, io.dur(1/2), 2)
        self.div = math.random(1,6)
    end

    -- Fast eighth note lines
    if io.on(1/self.div) then
        local pattern_idx = ((self.phrase_pos - 1) % #scale) + 1
        local note_offset = scale[pattern_idx]
        
        -- Add some intervallic leaps and sequences
        local octave_mod = 0
        if self.phrase_pos % 7 == 0 then octave_mod = 12 end  -- occasional octave jump
        if self.phrase_pos % 11 == 0 then octave_mod = -12 end -- occasional drop
        
        local note = chord.root + note_offset + (self.octave_base * 12) + octave_mod
        
        -- Velocity variation for phrasing
        local vel = 75 + math.sin(self.phrase_pos * 0.3) * 15
        
        io.playNote(note, math.floor(vel), io.dur(3/8), 1)
        self.phrase_pos = self.phrase_pos + 1
    end
    
    -- Sparse chord comping
    if io.on(2) and math.random() < 0.7 then
        for i = 1, math.min(3, #chord.pitches) do
            local note = chord:note(i, 4)
            io.playNote(note, 45, io.dur(1/4), 3)
        end
    end
end

return jam
