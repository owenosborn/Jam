local jam = {}

function jam:init(io)
    self.counter = 0
    
    -- Timing calculations
    self.whole_note_ticks = io.tpb * 4
    self.half_note_ticks = io.tpb * 2  
    self.quarter_note_ticks = io.tpb
    self.eighth_note_ticks = io.tpb // 2
    self.sixteenth_note_ticks = io.tpb // 4
    
    -- Musical scale - C major for clarity
    self.scale = {0, 2, 4, 5, 7, 9, 11}  -- C D E F G A B
    self.root = 60  -- Middle C
    
    -- Chord progressions in C major
    self.chord_progression = {
        {1, 3, 5},    -- C major (I)
        {6, 1, 3},    -- A minor (vi) 
        {4, 6, 1},    -- F major (IV)
        {5, 7, 2}     -- G major (V)
    }
    self.chord_index = 1
    self.chord_duration = self.whole_note_ticks * 2  -- 2 measures per chord
    
    -- Voice parts with different ranges and roles
    self.voices = {
        -- Soprano - highest voice, often carries melody
        {
            name = "soprano",
            channel = 1,
            octave_offset = 12,     -- One octave above middle C
            current_note = 1,       -- Scale degree
            phrase_position = 0,
            velocity = 85,
            note_duration = self.half_note_ticks,
            pattern = {1, 3, 5, 3, 2, 1, 7, 1},  -- Melodic pattern
            pattern_index = 1
        },
        
        -- Alto - second highest, harmonic support
        {
            name = "alto", 
            channel = 2,
            octave_offset = 5,      -- Slightly above middle C
            current_note = 3,
            phrase_position = 0,
            velocity = 75,
            note_duration = self.half_note_ticks,
            pattern = {3, 1, 2, 5, 4, 3, 2, 3},  -- Counter-melody
            pattern_index = 1
        },
        
        -- Tenor - third voice, often melodic
        {
            name = "tenor",
            channel = 3, 
            octave_offset = -7,     -- Below middle C
            current_note = 5,
            phrase_position = 0,
            velocity = 80,
            note_duration = self.quarter_note_ticks,
            pattern = {5, 4, 3, 2, 1, 2, 3, 5},  -- Flowing line
            pattern_index = 1
        },
        
        -- Bass - lowest voice, harmonic foundation
        {
            name = "bass",
            channel = 4,
            octave_offset = -12,    -- One octave below middle C  
            current_note = 1,
            phrase_position = 0,
            velocity = 90,
            note_duration = self.whole_note_ticks,
            pattern = {1, 6, 4, 5},  -- Root movement following chord changes
            pattern_index = 1
        }
    }
    
    -- Phrase structure
    self.phrase_length = self.whole_note_ticks * 4  -- 4 measures
    self.current_phrase = 1
    self.total_phrases = 8
    
    -- Breathing and phrasing
    self.breath_rests = {}  -- Track when voices should rest
    
    print("Choral jam initialized - 4 voice parts ready")
end

function jam:get_note_from_scale_degree(degree, octave_offset)
    -- Convert scale degree to MIDI note number
    local scale_index = ((degree - 1) % #self.scale) + 1
    local octave_adjustment = math.floor((degree - 1) / #self.scale) * 12
    return self.root + self.scale[scale_index] + octave_adjustment + (octave_offset or 0)
end

function jam:get_current_chord_tone(voice_index, prefer_chord_tone)
    -- Get appropriate note for current chord
    local chord = self.chord_progression[self.chord_index]
    local voice = self.voices[voice_index]
    
    if prefer_chord_tone then
        -- Choose chord tone closest to voice's current melodic position
        local target_degree = voice.pattern[voice.pattern_index]
        local closest_chord_tone = chord[1]  -- Default to root
        local min_distance = math.abs(target_degree - chord[1])
        
        for _, tone in ipairs(chord) do
            local distance = math.abs(target_degree - tone)
            if distance < min_distance then
                min_distance = distance
                closest_chord_tone = tone
            end
        end
        
        return closest_chord_tone
    else
        -- Use melodic pattern
        return voice.pattern[voice.pattern_index]
    end
end

function jam:should_voice_rest(voice_index)
    -- Create natural breathing patterns - voices rest at different times
    local voice = self.voices[voice_index]
    local phrase_progress = (self.counter % self.phrase_length) / self.phrase_length
    
    -- Different rest patterns for each voice
    local rest_patterns = {
        [1] = {0.75, 0.875},  -- Soprano rests near end of phrase
        [2] = {0.25, 0.375},  -- Alto rests in first quarter  
        [3] = {0.5, 0.625},   -- Tenor rests in middle
        [4] = {0.0, 0.125}    -- Bass rests at beginning (except first phrase)
    }
    
    local rest_times = rest_patterns[voice_index] or {}
    
    for _, rest_time in ipairs(rest_times) do
        if phrase_progress >= rest_time and phrase_progress < rest_time + 0.125 then
            return true
        end
    end
    
    return false
end

function jam:add_expression(voice_index, base_velocity)
    -- Add musical expression through velocity changes
    local voice = self.voices[voice_index]
    local phrase_progress = (self.counter % self.phrase_length) / self.phrase_length
    
    -- Phrase shaping - crescendo and diminuendo
    local phrase_dynamic = 1.0
    if phrase_progress < 0.3 then
        phrase_dynamic = 0.7 + phrase_progress  -- Gentle entrance
    elseif phrase_progress > 0.7 then
        phrase_dynamic = 1.3 - phrase_progress  -- Fade out
    else
        phrase_dynamic = 1.0  -- Sustained middle
    end
    
    -- Add slight randomization for humanization
    local humanization = 0.9 + math.random() * 0.2
    
    return math.floor(base_velocity * phrase_dynamic * humanization)
end

function jam:tick(io)
    -- Change chords every chord_duration ticks
    if self.counter > 0 and self.counter % self.chord_duration == 0 then
        self.chord_index = (self.chord_index % #self.chord_progression) + 1
        print(string.format("Chord change to: %d", self.chord_index))
    end
    
    -- Process each voice
    for i, voice in ipairs(self.voices) do
        -- Check if it's time for this voice to sing a new note
        if self.counter % voice.note_duration == 0 then
            
            -- Check if voice should rest (breathing)
            if not self:should_voice_rest(i) then
                
                -- Determine which note to sing
                local scale_degree
                if voice.name == "bass" then
                    -- Bass follows chord root movement more strictly
                    scale_degree = self:get_current_chord_tone(i, true)
                elseif self.counter % (self.phrase_length // 2) == 0 then
                    -- Strong chord tones on phrase boundaries
                    scale_degree = self:get_current_chord_tone(i, true)
                else
                    -- Use melodic pattern
                    scale_degree = voice.pattern[voice.pattern_index]
                end
                
                -- Convert to MIDI note
                local note = self:get_note_from_scale_degree(scale_degree, voice.octave_offset)
                
                -- Add expression
                local velocity = self:add_expression(i, voice.velocity)
                
                -- Play the note
                io.playNote(note, velocity, voice.note_duration, voice.channel)
                
                -- Update voice state
                voice.current_note = scale_degree
                voice.pattern_index = (voice.pattern_index % #voice.pattern) + 1
                voice.phrase_position = voice.phrase_position + 1
            end
        end
    end
    
    -- Add occasional harmonic embellishments
    if self.counter % (self.quarter_note_ticks * 3) == 0 and math.random() < 0.3 then
        -- Soprano descant or alto harmony
        local chord = self.chord_progression[self.chord_index]
        local embellishment_note = self:get_note_from_scale_degree(chord[2], 24) -- Third in high octave
        io.playNote(embellishment_note, 60, self.eighth_note_ticks, 5)
    end
    
    -- Track phrase changes
    if self.counter > 0 and self.counter % self.phrase_length == 0 then
        self.current_phrase = (self.current_phrase % self.total_phrases) + 1
        print(string.format("New phrase: %d", self.current_phrase))
        
        -- Evolve patterns slightly each phrase for development
        if self.current_phrase % 2 == 0 then
            for _, voice in ipairs(self.voices) do
                -- Occasionally modify melodic patterns
                if math.random() < 0.4 then
                    local random_index = math.random(1, #voice.pattern)
                    voice.pattern[random_index] = math.random(1, 7)  -- Random scale degree
                end
            end
        end
    end
    
    self.counter = self.counter + 1
end

return jam