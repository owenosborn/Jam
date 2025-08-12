-- Simplest possible example of io.on(interval, offset)
-- Just 2 notes showing the difference

local jam = {}

function jam:init(io)
    print("=== Simple Offset Example ===")
    print("Note 1: C5 on the beat (no offset)")
    print("Note 2: D5 offset by 1/2 beat")
    print("Listen for the 'ta-ka' rhythm!")
end

function jam:tick(io)
    -- Note 1: C5 every beat, right on time
    if io.on(1) then
        io.playNote(60, 80, io.dur(1/8))  -- C5
    end
    
    -- Note 2: D5 every beat, but offset by half
    if io.on(1, 1/2) then
        io.playNote(62, 70, io.dur(1/8))  -- D5
    end
end

return jam
