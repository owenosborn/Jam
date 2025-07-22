-- mother.lua with OSC output and drift correction
local socket = require("socket")
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")

local function initIO(tpb, osc_host, osc_port)
    local io = {}
    io.tpb = tpb or 180
    io.bpm = 101
    io.tt = (60 / io.bpm) / io.tpb * 1000  -- tick time
    io.beat_count = 0
    io.tick_count = 0
    io.ch = 100
    
    -- Create OSC client using losc
    local udp = plugin.new {sendAddr = osc_host or 'localhost', sendPort = osc_port or 9000}
    local osc = losc.new {plugin = udp}
   
    -- Calculate seconds per tick for duration conversion
    local seconds_per_tick = (60 / io.bpm) / io.tpb

    io.playNote = function(note, velocity, duration, channel)
        local ch = channel or io.ch
        -- Create and send note message
        -- Convert duration to seconds
        local note_message = osc.new_message {
            address = '/note',
            types = 'iiii',
            note, velocity, duration, ch
        }
        osc:send(note_message)
    end
    
    -- Additional OSC functions you could add
    io.sendCC = function(controller, value, channel)
        local ch = channel or 1
        local cc_message = osc.new_message {
            address = '/cc',
            types = 'iii',
            ch, controller, value
        }
        osc:send(cc_message)
    end
    
    return io
end

local function run()
    -- You can specify OSC destination here
    local io = initIO(180, "localhost", 9000)  -- tpb, host, port
    local current_jam = require("jam")
        
    -- Initialize the jam if it has an init function
    if current_jam.init then
        current_jam:init(io)
    end

    local tickInterval = (60 / io.bpm) / io.tpb -- seconds per tick
    local start_time = socket.gettime()
    local tick_number = 0
    local missed_ticks = 0
    local max_catch_up = 5  -- Don't try to catch up more than 5 ticks at once

    print(string.format("Starting Jam system with OSC output to localhost:9000"))
    print(string.format("bpm: %d BPM, TPB: %d, Tick interval: %.4f ms", 
                        io.bpm, io.tpb, tickInterval * 1000))

    while true do
        local current_time = socket.gettime()
        local elapsed_time = current_time - start_time
        local expected_tick = elapsed_time // tickInterval
        
        -- Check for drift/missed ticks
        local ticks_behind = expected_tick - tick_number
        
        if ticks_behind > 0 then
            if ticks_behind > max_catch_up then
                -- Too far behind, jump ahead and log the issue
                print(string.format("WARNING: Missed %d ticks, jumping ahead", ticks_behind))
                missed_ticks = missed_ticks + ticks_behind
                tick_number = expected_tick
            else
                -- Catch up by running multiple ticks
                for i = 1, ticks_behind do
                    io.beat_count = tick_number // io.tpb
                    io.tick_count = tick_number % io.tpb
                    current_jam:tick(io)
                    tick_number = tick_number + 1
                end
            end
        elseif ticks_behind == 0 and tick_number == expected_tick then
            -- We're on time, run the current tick
            io.beat_count = tick_number // io.tpb
            io.tick_count = tick_number % io.tpb
            current_jam:tick(io)
            tick_number = tick_number + 1
        end
        
        -- Sleep until next tick is due
        local next_tick_time = start_time + (tick_number * tickInterval)
        local sleep_time = next_tick_time - socket.gettime()
        
        if sleep_time > 0 then
            if sleep_time > 0.001 then
                -- Longer sleep for efficiency when we have time
                socket.sleep(sleep_time * 0.8)  -- Sleep most of the time, but wake up early
            else
                -- Very short sleep to avoid busy waiting
                socket.sleep(0.0001)
            end
        end
    end
end

run()
