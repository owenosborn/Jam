local jam = {}

function jam:init(io)
    print("Initialized")
end

function jam:tick(io)
    if io.on(1) then
        io.play_note(60, 100, 100)
    end
end

function jam:on_note(io, note, velocity)
    print("Received note: " .. note .. " vel: " .. velocity)
    io.play_note(note + 12, velocity, 100)  -- Echo an octave up
end

function jam:on_cc(io, controller, value)
    print("CC " .. controller .. " = " .. value)
end

return jam
