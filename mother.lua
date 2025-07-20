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
        print(note, velocity, duration, ch)
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
    local start_time = socket.gettime()  -- Absolute reference point
    local tick_number = 0

    while true do
        local target_time = start_time + (tick_number * tickInterval)
        local current_time = socket.gettime()
        
        if current_time >= target_time then
            -- Update io timing info before calling tick
            io.beat_count = tick_number // io.tpb
            io.tick_count = tick_number % io.tpb
            
            current_jam:tick(io)
            tick_number = tick_number + 1
        else
            -- Sleep for a small amount to avoid busy-waiting
            local sleep_time = math.min(0.0001, (target_time - current_time) * 0.5)
            socket.sleep(sleep_time)
        end
    end
end

run()
