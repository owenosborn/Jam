-- Three-part melody jam
-- 3 melodic parts play sequentially (8 beats each), then all together
-- Part 1: Bass melody (octave 3)
-- Part 2: Mid melody (octave 4) 
-- Part 3: High melody (octave 5)
-- Then all 3 parts play simultaneously

local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")

function jam:init(io)
    -- Simple progression: Am - F - C - G
    self.prog = progression.Progression.new()
    self.prog:parse("A-7...F7...Cmaj7...G7...")
    
    -- Track timing for the 3 sections
    self.section = 1  -- 1, 2, 3 = individual parts, 4 = all together
    self.section_length = 32  -- beats per section (8 measures)
    self.beat_in_section = 0
    
    -- Melody patterns for each part (chord tone indices)
    self.melodies = {
        -- Part 1: Bass melody - simple root movement
        bass = {1, 1, 3, 1, 2, 1, 3, 2},
        
        -- Part 2: Mid melody - more movement
        mid = {1, 3, 2, 4, 3, 1, 2, 3},
        
        -- Part 3: High melody - busier pattern
        high = {3, 4, 3, 2, 4, 3, 1, 2}
    }
    
    -- Timing patterns (when each part plays within a measure)
    self.rhythms = {
        bass = {1, 0, 1/2, 0, 1, 0, 1/2, 1/2},  -- on beats and some off-beats
        mid = {1/4, 1/2, 3/4, 1, 5/4, 3/2, 7/4, 2},  -- eighth note feel
        high = {1/8, 1/4, 3/8, 1/2, 5/8, 3/4, 7/8, 1}  -- sixteenth note feel
    }
    
    self.pattern_index = 1
    
    print("=== Three-Part Melody Jam ===")
    print("Section 1: Bass melody only")
    print("Section 2: Mid melody only") 
    print("Section 3: High melody only")
    print("Section 4: All three together!")
    print("Each section is 32 beats (8 measures)")
end

function jam:tick(io)
    -- Update progression
    local current_chord = self.prog:tick(io)
    
    -- Track position within section
    if io.on(1) then
        self.beat_in_section = self.beat_in_section + 1
        
        -- Check if we need to advance to next section
        if self.beat_in_section >= self.section_length then
            self.section = self.section + 1
            self.beat_in_section = 0
            
            -- Loop back to section 1 after section 4
            if self.section > 4 then
                self.section = 1
            end
            
            -- Announce section changes
            local section_names = {
                "🎵 Section 1: Bass melody only",
                "🎶 Section 2: Mid melody only", 
                "🎼 Section 3: High melody only",
                "🎹 Section 4: All three together!"
            }
            print("\n" .. section_names[self.section])
        end
    end
    
    -- Get current pattern position (cycles through 8 notes per measure)
    local beat_in_measure = io.beat_count % 4
    local pattern_pos = (math.floor(io.beat_count / 4) % 2) * 4 + beat_in_measure + 1
    pattern_pos = ((pattern_pos - 1) % 8) + 1
    
    -- Play bass melody (Section 1 or 4)
    if self.section == 1 or self.section == 4 then
        local rhythm = self.rhythms.bass[pattern_pos]
        if rhythm > 0 and io.on(rhythm) then
            local note_index = self.melodies.bass[pattern_pos]
            local note = current_chord:note(note_index, 3)  -- octave 3
            local velocity = self.section == 4 and 70 or 85  -- quieter when all playing
            io.playNote(note, velocity, io.dur(1/4), 1)
        end
    end
    
    -- Play mid melody (Section 2 or 4)
    if self.section == 2 or self.section == 4 then
        local rhythm = self.rhythms.mid[pattern_pos]
        if rhythm > 0 and io.on(rhythm) then
            local note_index = self.melodies.mid[pattern_pos]
            local note = current_chord:note(note_index, 4)  -- octave 4
            local velocity = self.section == 4 and 65 or 80
            io.playNote(note, velocity, io.dur(1/8), 2)
        end
    end
    
    -- Play high melody (Section 3 or 4)
    if self.section == 3 or self.section == 4 then
        local rhythm = self.rhythms.high[pattern_pos]
        if rhythm > 0 and io.on(rhythm) then
            local note_index = self.melodies.high[pattern_pos]
            local note = current_chord:note(note_index, 5)  -- octave 5
            local velocity = self.section == 4 and 60 or 75
            io.playNote(note, velocity, io.dur(1/16), 3)
        end
    end
    
    -- Add some chord stabs when all parts are playing together
    if self.section == 4 and io.on(1) and math.random() < 0.7 then
        -- Play a chord stab on downbeats
        for i = 1, math.min(3, #current_chord.pitches) do
            local note = current_chord:note(i, 4)
            io.playNote(note, 45, io.dur(1/8), 4)
        end
    end
end

return jam