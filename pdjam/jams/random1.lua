local jam = {}

function jam:init(io)
    print("Random eighth note generator initialized")
    math.randomseed(os.time())
end

function jam:tick(io)
    -- Trigger on every eighth note (1/2 beat)
    if io.on(1/2) then
        -- Random MIDI note between C3 (48) and C5 (72)
        local note = math.random(48, 72)
        
        -- Random velocity between 60 and 100
        local velocity = math.random(60, 100)
        
        -- Random duration between 1/16 (0.0625) and 1/4 (0.25) beats
        local duration = math.random() * (0.25 - 0.0625) + 0.0625
        
        io.play_note(note, velocity, duration)
    end
end

return jam
