local jam = {}

function jam:init(io)
    self.c = 0
    self.section_1_cycle = 0  -- Track how many times we've been to section 1
    
    -- Different note sets for section 1
    self.note_sets = {
        {60, 64, 67, 72},  -- Original
        {60, 63, 67, 74},  -- Set 2
        {65, 72, 76, 53},  -- Set 3
        {60, 62, 64, 66}   -- Set 4
    }
end

function jam:tick(io)
    local section_length = io.tpb * 4
    local current_section = math.floor(io.tc / section_length) % 4
    
    -- Track when we enter section 1 (check if we're at the start of section 0)
    if current_section == 0 and (io.tc % section_length) == 0 and io.tc > 0 then
        self.section_1_cycle = (self.section_1_cycle + 1) % #self.note_sets
    end
    
    if current_section == 0 then
        -- Use current note set
        local notes = self.note_sets[self.section_1_cycle + 1]
        if io.every(1) then io.playNote(notes[1], 80, io.ticks(1,4)) end
        if io.every(2) then io.playNote(notes[2], 80, io.ticks(1,2)) end
        if io.every(2) then io.playNote(notes[3], 80, io.ticks(1)) end
        if io.every(1) then io.playNote(notes[4], 80, io.ticks(2)) end
        
    elseif current_section == 1 then
        -- Section B: Faster polyrhythm
        if io.every(1,2) then io.playNote(60, 70, io.ticks(1,8)) end  -- Eighth notes
        if io.every(2,3) then io.playNote(67, 80, io.ticks(1,4)) end
        if io.every(2) then io.playNote(72, 90, io.ticks(1,2)) end
        
    elseif current_section == 2 then
        -- Section C: faster
        if io.every(1,4) then io.playNote(55, 85, io.ticks(2)) end
        if io.every(1,6) then io.playNote(62, 75, io.ticks(3)) end
        if io.every(1,9) then io.playNote(70, 80, io.ticks(4)) end
        
    else  -- current_section == 3
        -- Section D: Dense, short notes
        if io.every(1,9) then io.playNote(48, 60, io.ticks(1,16)) end  -- crazy fast
        if io.every(1,6) then io.playNote(65, 70, io.ticks(1,8)) end
        if io.every(2) then io.playNote(77, 80, io.ticks(1,4)) end
    end
end

return jam
