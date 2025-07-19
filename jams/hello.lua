local jam = {}

function jam:init(io)
    self.counter = 0
    self.quarter_note_ticks = io.tpb // 4  -- Pre-calculate common divisions
    self.eighth_note_ticks = io.tpb // 8
end

function jam:tick(io)
    -- Musical logic using io.tpb for timing calculations
    self.counter = (self.counter + 1) % io.tpb
    
    if self.counter == 0 then  -- Every beat
        io.playNote(60, 100, self.quarter_note_ticks)  -- Quarter note duration
    end
    
    if self.counter % (io.tpb / 2) == 0 then  -- Every half beat
        io.playNote(67, 80, self.eighth_note_ticks)   -- Eighth note duration
    end
end

return jam
