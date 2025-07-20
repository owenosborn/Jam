local jam = {}

function jam:init(io)
    self.counter = 0
    self.sixteenth_note_ticks = io.tpb // 4  -- Actual sixteenth notes (quarter note / 4)
    
    -- Spiral parameters
    self.up_spiral = {
        note = 60,  -- Start at middle C
        direction = 1,  -- Going up
        step = 1,  -- Semitone steps
        min_note = 48,  -- Low boundary
        max_note = 84   -- High boundary
    }
    
    self.down_spiral = {
        note = 72,  -- Start an octave higher
        direction = -1,  -- Going down
        step = 2,  -- Whole tone steps for contrast
        min_note = 48,  -- Low boundary
        max_note = 84   -- High boundary
    }
    
    -- Timing offsets to create interweaving
    self.up_offset = 0
    self.down_offset = self.sixteenth_note_ticks // 2  -- Offset by 32nd note
    
    -- Add some rhythm variation
    self.accent_counter = 0
end

function jam:tick(io)
    -- Check if it's time for an ascending note
    if (self.counter - self.up_offset) % self.sixteenth_note_ticks == 0 and self.counter >= self.up_offset then
        -- Play ascending spiral note
        local velocity = 70
        -- Add accents every 4th note
        if self.accent_counter % 4 == 0 then
            velocity = 90
        end
        
        io.playNote(self.up_spiral.note, velocity, self.sixteenth_note_ticks // 2, 1)
        
        -- Move spiral up
        self.up_spiral.note = self.up_spiral.note + self.up_spiral.step
        
        -- Reverse direction if we hit boundaries
        if self.up_spiral.note >= self.up_spiral.max_note then
            self.up_spiral.direction = -1
            self.up_spiral.note = self.up_spiral.max_note
        elseif self.up_spiral.note <= self.up_spiral.min_note then
            self.up_spiral.direction = 1
            self.up_spiral.note = self.up_spiral.min_note
        end
        
        self.up_spiral.step = self.up_spiral.direction * math.abs(self.up_spiral.step)
    end
    
    -- Check if it's time for a descending note
    if (self.counter - self.down_offset) % self.sixteenth_note_ticks == 0 and self.counter >= self.down_offset then
        -- Play descending spiral note
        local velocity = 60
        -- Different accent pattern for contrast
        if (self.accent_counter + 2) % 6 == 0 then
            velocity = 85
        end
        
        io.playNote(self.down_spiral.note, velocity, self.sixteenth_note_ticks // 2, 2)
        
        -- Move spiral down
        self.down_spiral.note = self.down_spiral.note + self.down_spiral.step
        
        -- Reverse direction if we hit boundaries
        if self.down_spiral.note >= self.down_spiral.max_note then
            self.down_spiral.direction = -1
            self.down_spiral.note = self.down_spiral.max_note
        elseif self.down_spiral.note <= self.down_spiral.min_note then
            self.down_spiral.direction = 1
            self.down_spiral.note = self.down_spiral.min_note
        end
        
        self.down_spiral.step = self.down_spiral.direction * math.abs(self.down_spiral.step)
    end
    
    -- Add occasional harmonic notes at longer intervals
    if self.counter % (io.tpb // 2) == 0 then  -- Every half beat
        -- Play a sustained harmony note
        local harmony_note = 36 + (self.counter // (io.tpb // 2)) % 12  -- Bass note cycling through chromatic
        io.playNote(harmony_note, 45, io.tpb, 3)  -- Long sustained note on channel 3
    end
    
    self.counter = (self.counter + 1) % (io.tpb * 4)  -- Reset every 4 beats
    self.accent_counter = self.accent_counter + 1
end

return jam