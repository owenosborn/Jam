-- mother.lua
local socket = require("socket")

local function initIO(tpb)
    local io = {}
    io.tpb = tpb or 180
    io.tempo = 120
    io.beat_count = 0
    io.tick_count = 0
    
    io.playNote = function(note, velocity, duration, channel)
        ch = channel or 1
        print(note,velocity,duration, ch)
        -- Hardware-specific MIDI output
    end
    
    return io
end

local function run()
    local io = initIO()
    local current_jam = require("jam")
        
    -- Initialize the jam if it has an init function
    if current_jam.init then
        current_jam:init(io)
    end

    local tickInterval = (60 / io.tempo) / io.tpb -- seconds per tick
    local next_tick_time = socket.gettime()  -- Initialize timing reference

    while true do
        current_jam:tick(io)
        
        -- Wait until the next tick time
        next_tick_time = next_tick_time + tickInterval
        while socket.gettime() < next_tick_time do
            socket.sleep(0.0005) -- Sleep in small increments for accuracy
        end
    end

end

run()
