local jam = {}

function jam:init(io)
    self.counter = 0
    self.eighth_note_ticks = io.tpb // 2
    self.sixteenth_note_ticks = io.tpb // 4
    self.quarter_note_ticks = io.tpb
    
    -- A minor scale (natural minor)
    self.minor_scale = {0, 2, 3, 5, 7, 8, 10}  -- Relative to root
    self.root_note = 57  -- A3
    
    -- Fractal melody generators with long, evolving patterns
    self.generators = {
        {
            -- Fast melodic line
            position = 0,
            tick_interval = self.sixteenth_note_ticks,
            channel = 1,
            velocity_base = 75,
            octave = 0,
            fractal_state = {a = 1.7, b = 2.3, c = 0.8},  -- Fractal parameters
            direction = 1,
            last_note = 3,
            step_size = 1
        },
        {
            -- Medium counterpoint
            position = 0,
            tick_interval = self.eighth_note_ticks,
            channel = 2,
            velocity_base = 65,
            octave = 12,
            fractal_state = {a = 2.1, b = 1.6, c = 1.2},
            direction = -1,
            last_note = 5,
            step_size = 2
        },
        {
            -- Slow bass movement
            position = 0,
            tick_interval = self.quarter_note_ticks,
            channel = 3,
            velocity_base = 55,
            octave = -12,
            fractal_state = {a = 0.9, b = 3.1, c = 0.4},
            direction = 1,
            last_note = 1,
            step_size = 3
        }
    }
    
    -- Harmonic rhythm generator
    self.chord_position = 0
    self.chord_progression = {1, 6, 4, 5}  -- i, VI, iv, V in minor
    self.chord_index = 1
    
    -- Global evolution parameters
    self.global_phase = 0
    self.complexity_level = 1
end

function jam:generate_fractal_note(generator)
    -- Use chaotic/fractal function to generate next scale degree
    local state = generator.fractal_state
    local pos = generator.position
    
    -- Modified Hénon map for musical generation
    local x = math.sin(state.a * pos * 0.1) * 7 + math.cos(state.b * pos * 0.07) * 3
    local y = state.c * math.sin(pos * 0.05) * 5
    
    -- Convert to scale degree
    local raw_degree = math.floor(math.abs(x + y)) % (#self.minor_scale * 3) + 1
    
    -- Apply musical intelligence - smooth out big jumps
    local degree_diff = raw_degree - generator.last_note
    if math.abs(degree_diff) > 5 then
        -- Prefer smaller steps, but allow occasional leaps
        if math.random() < 0.3 then
            raw_degree = generator.last_note + generator.direction * generator.step_size
        else
            raw_degree = generator.last_note + (degree_diff > 0 and 2 or -2)
        end
    end
    
    -- Occasionally change direction for more interesting contour
    if math.random() < 0.15 then
        generator.direction = -generator.direction
    end
    
    -- Keep within reasonable range
    raw_degree = math.max(1, math.min(#self.minor_scale * 3, raw_degree))
    
    generator.last_note = raw_degree
    return raw_degree
end

function jam:get_note_from_scale_degree(degree, octave_offset)
    local scale_index = ((degree - 1) % #self.minor_scale) + 1
    local octave_adjustment = math.floor((degree - 1) / #self.minor_scale) * 12
    return self.root_note + self.minor_scale[scale_index] + octave_adjustment + (octave_offset or 0)
end

function jam:get_chord_note(chord_degree, voice)
    -- Get chord tones for harmonic backing
    local chord_tones = {
        [1] = {1, 3, 5},      -- i chord: A, C, E
        [4] = {4, 6, 1},      -- iv chord: D, F, A  
        [5] = {5, 7, 2},      -- V chord: E, G, B
        [6] = {6, 1, 3}       -- VI chord: F, A, C
    }
    
    local progression_degree = self.chord_progression[self.chord_index]
    local tones = chord_tones[progression_degree] or {1, 3, 5}
    local tone_index = ((voice - 1) % #tones) + 1
    
    return tones[tone_index]
end

function jam:evolve_fractal_parameters()
    -- Slowly evolve the fractal parameters for organic development
    for i = 1, #self.generators do
        local gen = self.generators[i]
        local state = gen.fractal_state
        
        -- Gentle parameter drift
        state.a = state.a + (math.random() - 0.5) * 0.02
        state.b = state.b + (math.random() - 0.5) * 0.02  
        state.c = state.c + (math.random() - 0.5) * 0.01
        
        -- Keep parameters in musical ranges
        state.a = math.max(0.5, math.min(3.0, state.a))
        state.b = math.max(0.5, math.min(3.5, state.b))
        state.c = math.max(0.1, math.min(2.0, state.c))
        
        -- Occasionally adjust step size for variety
        if math.random() < 0.05 then
            gen.step_size = math.random(1, 4)
        end
    end
end

function jam:tick(io)
    -- Play fractal melodic lines
    for i = 1, #self.generators do
        local gen = self.generators[i]
        
        if self.counter % gen.tick_interval == 0 then
            local scale_degree = self:generate_fractal_note(gen)
            local note = self:get_note_from_scale_degree(scale_degree, gen.octave)
            
            -- Add some expression through velocity variation
            local velocity_mod = math.sin(gen.position * 0.1) * 20
            local velocity = math.max(30, math.min(120, gen.velocity_base + velocity_mod))
            
            -- Vary note duration slightly
            local duration = gen.tick_interval * (0.7 + math.random() * 0.3)
            
            io.playNote(note, velocity, duration, gen.channel)
            gen.position = gen.position + 1
        end
    end
    
    -- Harmonic progression changes
    if self.counter % (self.quarter_note_ticks * 4) == 0 then
        self.chord_index = (self.chord_index % #self.chord_progression) + 1
        
        -- Play chord tones as harmony
        for voice = 1, 3 do
            local chord_degree = self:get_chord_note(self.chord_progression[self.chord_index], voice)
            local harmony_note = self:get_note_from_scale_degree(chord_degree, -24 + voice * 12)
            io.playNote(harmony_note, 40, self.quarter_note_ticks * 3, 4)
        end
    end
    
    -- Long-term structural changes
    if self.counter % (self.quarter_note_ticks * 32) == 0 then
        self:evolve_fractal_parameters()
        self.complexity_level = (self.complexity_level % 5) + 1
        
        -- Shift the root occasionally for tonal variety
        if math.random() < 0.3 then
            self.root_note = self.root_note + (math.random() < 0.5 and -1 or 1)
        end
    end
    
    -- Add sparse textural elements
    if self.counter % (self.eighth_note_ticks * 7) == 0 and math.random() < 0.4 then
        -- Occasional harmonic intervals or echoes
        local echo_degree = self.generators[1].last_note + 2  -- Third above
        local echo_note = self:get_note_from_scale_degree(echo_degree, 24)
        io.playNote(echo_note, 35, self.eighth_note_ticks, 5)
    end
    
    self.counter = self.counter + 1
    self.global_phase = self.global_phase + 0.001
end

return jam