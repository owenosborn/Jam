local jam = {}

function jam:init(io)
    -- A Aeolian (A natural minor) scale: A B C D E F G
    -- MIDI note numbers starting from A3 (57)
    self.aeolian_scale = {57, 59, 60, 62, 64, 65, 67}  -- A B C D E F G
    
    -- Scale position counters for each voice
    self.voice1_pos = 1  -- every 1 beat
    self.voice2_pos = 1  -- every 3 beats  
    self.voice3_pos = 1  -- every 5 beats
    self.voice4_pos = 1  -- every 7 beats
    
    -- Fast sweeping voices
    self.sweep1_pos = 1  -- fast voice 1
    self.sweep2_pos = 1  -- fast voice 2 (following)
end

function jam:tick(io)
    -- Voice 1: every beat, cycles through scale
    if io.on(1) then 
        io.playNote(self.aeolian_scale[self.voice1_pos], 80, io.dur(1,2))
        self.voice1_pos = (self.voice1_pos % #self.aeolian_scale) + 1
    end
    
    -- Voice 2: every 3 beats, cycles through scale
    if io.on(3) then 
        io.playNote(self.aeolian_scale[self.voice2_pos] + 12, 80, io.dur(2))  -- octave higher
        self.voice2_pos = (self.voice2_pos % #self.aeolian_scale) + 1
    end
    
    -- Voice 3: every 5 beats, cycles through scale  
    if io.on(5) then 
        io.playNote(self.aeolian_scale[self.voice3_pos] + 24, 80, io.dur(4))  -- two octaves higher
        self.voice3_pos = (self.voice3_pos % #self.aeolian_scale) + 1
    end
    
    -- Voice 4: every 7 beats, cycles through scale
    if io.on(7) then 
        io.playNote(self.aeolian_scale[self.voice4_pos] - 12, 80, io.dur(4))  -- octave lower
        self.voice4_pos = (self.voice4_pos % #self.aeolian_scale) + 1
    end
    
    -- Fast sweeping voice 1: every sixteenth note
    if io.on(1, 4) then 
        io.playNote(self.aeolian_scale[self.sweep1_pos] + 36, 65, io.dur(1,8))  -- high octave, short notes
        self.sweep1_pos = (self.sweep1_pos % #self.aeolian_scale) + 1
    end
    
    -- Fast sweeping voice 2: every sixteenth note, offset by 32nd note
    if io.on(1, 4) and (io.tc % (io.tpb // 8)) == (io.tpb // 8) then
        io.playNote(self.aeolian_scale[self.sweep2_pos] + 24, 55, io.dur(1,8))  -- medium octave, quieter
        self.sweep2_pos = (self.sweep2_pos % #self.aeolian_scale) + 1
    end
end

return jam
