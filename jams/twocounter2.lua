local jam = {}

local elements = require("lib/elements")

function jam:init(io)
    
    -- Fixed interval counter - steady rhythm
    self.steady_counter = elements.Counter.new(io.tpb // 4)  -- Sixteenth notes
    
    -- Variable interval setup
    self.min_interval = io.tpb // 8   -- Fastest: 32nd notes
    self.max_interval = io.tpb // 2   -- Slowest: eighth notes
    self.current_interval = self.min_interval
    self.direction = 1  -- 1 for growing, -1 for shrinking
    self.interval_step = 2  -- How much to change interval each time
    
    -- Variable counter starts with min interval
    self.variable_counter = elements.Counter.new(self.current_interval)
    self.variable_tick_count = 0
end

function jam:tick(io)
    -- Steady rhythm on channel 1
    if self.steady_counter:tick() then
        io.playNote(60, 80, io.tpb // 8, 1)  -- Middle C
    end
    
    -- Variable rhythm on channel 2
    self.variable_tick_count = self.variable_tick_count + 1
    if self.variable_tick_count >= self.current_interval then
        self.variable_tick_count = 0
        io.playNote(67, 90, io.tpb // 16, 2)  -- G above middle C
        
        -- Update interval for next note
        self.current_interval = self.current_interval + (self.direction * self.interval_step)
        
        -- Reverse direction if we hit boundaries
        if self.current_interval >= self.max_interval then
            self.direction = -1
        elseif self.current_interval <= self.min_interval then
            self.direction = 1
        end
        
        -- Create new counter with updated interval
        self.variable_counter = elements.Counter.new(self.current_interval)
    end
end

return jam
