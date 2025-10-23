local jam = {}

function jam:init(io)
    print("Random eighth note generator initialized")
    math.randomseed(os.time())
    self.div1 = 1
end

function jam:tick(io)

    if io.on(self.div1) then
        -- Random low MIDI note between C1 (24) and C3 (48)
        local note = math.random(60, 95)
        
        -- Random velocity between 40 and 80 (softer)
        local velocity = math.random(40, 80)
        
        -- Random long duration between 1 and 4 beats
        local duration = .3--math.random() * 3 + 1
        
        io.play_note(note, velocity, duration)
        self.div1 = math.random() * 2 + .1  -- 2 to 4 beats
    end


end

return jam
