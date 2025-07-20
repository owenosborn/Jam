local jam = {}

function jam:init(io)
    self.counter = 0
    self.eighth_note_ticks = io.tpb // 2  -- Calculate eighth note duration
    
    -- Set up random pitch range
    self.min_pitch = 60  -- Middle C
    self.max_pitch = 84  -- Two octaves up
    
    -- Initialize random seed
    math.randomseed(os.time())
end

function jam:tick(io)
    -- Play random pitch on every eighth note
    if self.counter % self.eighth_note_ticks == 0 then
        local random_pitch = math.random(self.min_pitch, self.max_pitch)
        io.playNote(random_pitch, 80, self.eighth_note_ticks // 2)  -- Short duration
    end
    
    self.counter = (self.counter + 1) % io.tpb
end

return jam
