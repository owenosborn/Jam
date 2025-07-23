local jam = {}

function jam:init(io)
    self.interval = io.tpb // 2  -- Start with eighth notes
    self.last_note_time = 0
end

function jam:tick(io)
    -- Check if it's time for next note
    if io.tc - self.last_note_time >= self.interval then
        io.playNote(60, 80, io.tpb // 8)
        self.last_note_time = io.tc
        
        -- Make interval smaller (accelerate)
        self.interval = math.max(1, self.interval - 1)
        
        -- Reset when we get too fast
        if self.interval <= 5 then
            self.interval = io.tpb // 2  -- Back to eighth notes
        end
    end
end

return jam
