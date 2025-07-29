local jam = {}

function jam:init(io)
    self.c = 0
end

function jam:tick(io)
    local section_length = io.tpb * 4  -- 16 beats per section
    local current_section = math.floor(io.tc / section_length) % 4  -- Cycles 0, 1, 2, 3
    
    if current_section == 0 then
        -- Section A: Original polyrhythm
        if io.every(1) then io.playNote(63, 80, io.ticks(1,4)) end
        if io.every(2) then io.playNote(69, 80, io.ticks(1,2)) end
        if io.every(2) then io.playNote(71, 80, io.ticks(1)) end
        if io.every(1) then io.playNote(58, 80, io.ticks(2)) end
        
    elseif current_section == 1 then
        -- Section B: Faster polyrhythm
        if io.every(1,2) then io.playNote(60, 70, io.ticks(1,8)) end  -- Eighth notes
        if io.every(2,3) then io.playNote(67, 80, io.ticks(1,4)) end
        if io.every(2) then io.playNote(72, 90, io.ticks(1,2)) end
        
    elseif current_section == 2 then
        -- Section B: faster
        if io.every(1,4) then io.playNote(55, 85, io.ticks(2)) end
        if io.every(1,6) then io.playNote(62, 75, io.ticks(3)) end
        if io.every(1,9) then io.playNote(70, 80, io.ticks(4)) end
        
    else  -- current_section == 3
        -- Section D: Dense, short notes
        if io.every(1,30) then io.playNote(48, 60, io.ticks(1,16)) end  -- crazy fast
        if io.every(1,20) then io.playNote(65, 70, io.ticks(1,8)) end
        if io.every(2) then io.playNote(77, 80, io.ticks(1,4)) end
    end
end

return jam
