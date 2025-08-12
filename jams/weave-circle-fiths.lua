-- Weaving melodies jam
-- 3 melodic voices that weave in and out in different combinations
-- Creates a dynamic texture where voices enter and exit organically

local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")

function jam:init(io)
    -- Jazz-influenced progression with more harmonic movement
    self.prog = progression.Progression.new()
    --self.prog:parse("A-7...D-7...G7...Cmaj7...F7...Bb7...Ebmaj7...G7...")
    --self.prog:parse("A-7...D-7...G7...Cmaj7...F7...Bb7...Ebmaj7...G7...")
    --self.prog:parse("A-7,9..D7.....G-7..C7.....F-7..Bb7.....Ebmaj7......")
    --self.prog:parse("D-9...E-9...Gb7.")
    self.prog:parse("A-7.D7.Gmaj7.Cmaj7.F#-7b5.B7.E-7.E-9.")
    
    -- Weaving pattern: which voices are active in each 8-beat section
    -- 1 = bass, 2 = mid, 3 = high
    self.weave_pattern = {
     --   {1},           -- Solo bass
      --  {2},           -- Solo mid  
       -- {3},           -- Solo high
      --  {1, 2},        -- Bass + mid
      --  {2, 3},        -- Mid + high
      --  {1, 3},        -- Bass + high
        {1, 2, 3},     -- All three
      --  {2},           -- Solo mid again
     --   {1, 3},        -- Bass + high
      --  {3},           -- Solo high
      --  {1, 2},        -- Bass + mid
      --  {1, 2, 3},     -- All three
    }
    
    self.section = 1
    self.section_length = 2  -- beats per weaving section
    self.beat_in_section = 0
    
    -- More sophisticated melody patterns
    self.melodies = {
        -- Bass: Walking-style quarter notes with some syncopation
        bass = {
            notes = {1, 3, 1, 3, 4, 3, 2, 1},
            rhythms = {1, 0, 1/2, 0, 1, 0, 3/4, 1/4}
        },
        
        -- Mid: Flowing eighth notes with chord tone movement
        mid = {
            notes = {3, 1, 3, 1, 1, 2, 4, 2},
            rhythms = {1/4, 1/2, 3/4, 1, 5/4, 3/2, 7/4, 2}
        },
        
        -- High: Decorative sixteenth patterns
        high = {
            notes = {1, 2, 3, 4, 3, 2, 1, 1},
            rhythms = {1/8, 1/4, 3/8, 1/2, 5/8, 3/4, 7/8, 1}
        }
    }
    
    -- Voice characteristics
    self.voices = {
        bass = {octave = 3, channel = 1, base_vel = 85, dur_mult = 1/3},
        mid = {octave = 4, channel = 2, base_vel = 75, dur_mult = 1/4}, 
        high = {octave = 5, channel = 3, base_vel = 65, dur_mult = 1/8}
    }
    
    print("=== Weaving Melodies Jam ===")
    print("3 voices enter and exit in different combinations")
    print("Each section is 32 beats with a different voice combination")
    self:print_current_section()
end

function jam:print_current_section()
    local active_voices = self.weave_pattern[self.section]
    local voice_names = {"bass", "mid", "high"}
    local active_names = {}
    
    for _, voice_num in ipairs(active_voices) do
        table.insert(active_names, voice_names[voice_num])
    end
    
    print(string.format("🎼 Section %d: %s", self.section, table.concat(active_names, " + ")))
end

function jam:is_voice_active(voice_num)
    local active_voices = self.weave_pattern[self.section]
    for _, active in ipairs(active_voices) do
        if active == voice_num then return true end
    end
    return false
end

function jam:play_voice(voice_name, voice_num, io, current_chord)
    if not self:is_voice_active(voice_num) then return end
    
    local voice_config = self.voices[voice_name]
    local melody = self.melodies[voice_name]
    
    -- Get current pattern position (8-beat cycle)
    local beat_in_cycle = io.beat_count % 8
    local pattern_pos = beat_in_cycle + 1
    
    local rhythm = melody.rhythms[pattern_pos]
    if rhythm > 0 and io.on(rhythm) then
        local note_index = melody.notes[pattern_pos]
        local note = current_chord:note(note_index, voice_config.octave)
        
        -- Dynamic velocity based on how many voices are playing
        local active_count = #self.weave_pattern[self.section]
        local velocity_reduction = (active_count - 1) * 8  -- Reduce volume when more voices
        local velocity = voice_config.base_vel - velocity_reduction
        
        -- Add some humanization
        velocity = velocity + math.random(-5, 5)
        velocity = math.max(40, math.min(127, velocity))
        
        local duration = io.dur(voice_config.dur_mult)
        
        io.playNote(note, velocity, duration, voice_config.channel)
    end
end

function jam:tick(io)
    -- Update progression
    local current_chord = self.prog:tick(io)
    
    -- Track section changes
    if io.on(1) then
        self.beat_in_section = self.beat_in_section + 1
        
        if self.beat_in_section >= self.section_length then
            self.section = self.section + 1
            self.beat_in_section = 0
            
            -- Loop the weave pattern
            if self.section > #self.weave_pattern then
                self.section = 1
            end
            
            self:print_current_section()
        end
    end
    
    -- Play each voice if it's active in current section
    self:play_voice("bass", 1, io, current_chord)
    self:play_voice("mid", 2, io, current_chord)
    self:play_voice("high", 3, io, current_chord)
    
    -- Add occasional harmonic support when multiple voices are playing
    local active_count = #self.weave_pattern[self.section]
    if active_count >= 2 and io.on(2) and math.random() < 0.3 then
        -- Soft chord stab
        for i = 1, math.min(3, #current_chord.pitches) do
            local note = current_chord:note(i, 4)
            io.playNote(note, 35, io.dur(1/2), 4)
        end
    end
end

return jam
