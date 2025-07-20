local jam = {}

function jam:init(io)
    self.counter = 0
    self.eighth_note_ticks = io.tpb // 8  -- Calculate eighth note duration
    self.hihat_note = 42  -- MIDI note for closed hi-hat (GM standard)
end

function jam:tick(io)
    -- Play hi-hat on every eighth note
    if self.counter % self.eighth_note_ticks == 0 then
        io.playNote(self.hihat_note, 80, self.eighth_note_ticks // 2)  -- Short duration
    end
    
    self.counter = (self.counter + 1) % io.tpb
end

return jam
