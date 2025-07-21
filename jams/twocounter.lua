local jam = {}

function jam:init(io)
    local elements = require("lib/elements")
    
    -- Fixed counter - steady sixteenth notes
    self.steady_counter = elements.Counter.new(io.tpb // 4)
    
    -- Variable counter - starts at eighth notes, will change
    self.variable_counter = elements.Counter.new(io.tpb // 2)
    
    -- Control variables for the variable counter
    self.phase = 0  -- Phase for sine wave oscillation
    self.phase_increment = 0.05  -- How fast the speed changes
    self.min_interval = io.tpb // 8  -- Fastest (32nd notes)
    self.max_interval = io.tpb      -- Slowest (quarter notes)
    
    -- Track when to update the variable counter's max
    self.update_counter = 0
    self.update_frequency = io.tpb // 16  -- Update every 64th note
    
    -- Notes for each counter
    self.steady_note = 60  -- Middle C
    self.variable_note = 67  -- G above middle C
end

function jam:update_variable_interval()
    -- Use sine wave to create smooth acceleration/deceleration
    local sine_value = math.sin(self.phase)
    
    -- Map sine wave (-1 to 1) to interval range
    local normalized = (sine_value + 1) / 2  -- Now 0 to 1
    local new_interval = self.min_interval + (self.max_interval - self.min_interval) * normalized
    
    -- Update the counter's max value
    self.variable_counter.max = math.floor(new_interval)
    
    -- Advance the phase
    self.phase = self.phase + self.phase_increment
    
    -- Keep phase in reasonable range
    if self.phase > math.pi * 4 then
        self.phase = 0
    end
end

function jam:tick(io)
    -- Update variable interval periodically
    if self.update_counter >= self.update_frequency then
        self:update_variable_interval()
        self.update_counter = 0
    end
    self.update_counter = self.update_counter + 1
    
    -- Steady counter - consistent sixteenth notes on channel 1
    if self.steady_counter:tick() then
        io.playNote(self.steady_note, 70, io.tpb // 8, 1)
    end
    
    -- Variable counter - changing speed on channel 2
    if self.variable_counter:tick() then
        -- Vary velocity based on speed for musical expression
        local speed_factor = self.min_interval / self.variable_counter.max
        local velocity = 50 + math.floor(speed_factor * 40)  -- 50-90 velocity range
        
        io.playNote(self.variable_note, velocity, self.variable_counter.max // 2, 2)
    end
end

return jam
