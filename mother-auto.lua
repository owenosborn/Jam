-- mother-auto.lua with OSC output, drift correction, and auto-reload
local socket = require("socket")
local losc = require("losc")
local plugin = require("losc.plugins.udp-socket")
local lfs = require("lfs")  -- LuaFileSystem for file monitoring

local function initIO(tpb, osc_host, osc_port)

    local io = {}
    io.tpb = tpb or 180                    -- ticks per beat (user configurable)
    io.bpm = 100                        -- beats per minute 
    io.mspt = (60 / io.bpm) / io.tpb * 1000 -- milliseconds per tick
    io.tc = 0                              -- tick count (global counter, starts at 0)
    io.beat_count = 0
    io.tick_count = 0
    io.ch = 1

    -- Enhanced io.on() function with offset support
    -- Usage: io.on(interval, offset)
    -- interval: beat multiplier
    -- offset: beat offset in beats
    io.on = function(interval, offset)
        interval = interval or 1
        offset = offset or 0
        
        -- get local tickcount by subtracting offset
        local tc = io.tc - math.floor(offset * io.tpb)
        
        if tc < 0 then return false end

        local ticks_per_interval = io.tpb * interval  -- e.g., 180 * (1/8) = 22.5
        
        -- Calculate how many complete intervals should have occurred by now
        local expected_intervals = math.floor(tc / ticks_per_interval)
        
        -- Calculate the exact tick where this interval should start
        local interval_start_tick = math.floor(expected_intervals * ticks_per_interval + 0.5)
        
        -- Check if we're exactly at an interval boundary
        return tc == interval_start_tick
    end

    -- Calculate tick intervals, number of ticks in a rhythmic interval.
    io.dur = function(a, b)
        a = a or 1
        b = b or 1
        return (io.tpb * a) // b
    end

    -- Create OSC client using losc
    local udp = plugin.new {sendAddr = osc_host or 'localhost', sendPort = osc_port or 9000}
    local osc = losc.new {plugin = udp}
   
    -- Calculate seconds per tick for duration conversion
    local seconds_per_tick = (60 / io.bpm) / io.tpb

    io.playNote = function(note, velocity, duration, channel)
        local ch = channel or io.ch
        -- Create and send note message
        -- Convert duration to seconds
        dur = math.floor(duration * io.mspt)
        local note_message = osc.new_message {
            address = '/note',
            types = 'iiii',
            math.floor(note), 
            math.floor(velocity), 
            dur, 
            math.floor(ch)
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

-- File monitoring function
local function getFileModTime(filepath)
    local attr = lfs.attributes(filepath)
    return attr and attr.modification or 0
end

-- Safe jam loading function
local function loadJam(filepath)
    -- Clear the package cache for the jam file
    local module_name = filepath:gsub("%.lua$", ""):gsub("/", ".")
    package.loaded[module_name] = nil
    package.loaded["jam"] = nil
    
    local success, jam = pcall(require, "jam")
    if success then
        print("✓ Jam loaded successfully")
        return jam
    else
        print("✗ Error loading jam: " .. tostring(jam))
        return nil
    end
end

local function run()
    -- You can specify OSC destination here
    local io = initIO(180, "localhost", 9000)  -- tpb, host, port
    
    -- File monitoring setup
    local jam_file = "jam.lua"
    local last_mod_time = getFileModTime(jam_file)
    local current_jam = loadJam(jam_file)
    local jam_initialized = false

    local tickInterval = (60 / io.bpm) / io.tpb -- seconds per tick
    local start_time = socket.gettime()
    local tick_number = 0
    local missed_ticks = 0
    local max_catch_up = 5  -- Don't try to catch up more than 5 ticks at once

    print(string.format("Starting Jam system with auto-reload and OSC output to localhost:9000"))
    print(string.format("BPM: %d, TPB: %d, Tick interval: %.4f ms", 
                        io.bpm, io.tpb, tickInterval * 1000))
    print(string.format("Monitoring %s for changes...", jam_file))

    -- Initialize the jam if it loaded successfully
    if current_jam and current_jam.init then
        current_jam:init(io)
        jam_initialized = true
        print("✓ Jam initialized")
    end

    while true do
        -- Check for file changes every few ticks to avoid excessive disk I/O
        if tick_number % 30 == 0 then  -- Check every 30 ticks (~167ms at 180 TPB)
            local current_mod_time = getFileModTime(jam_file)
            if current_mod_time > last_mod_time then
                print("\n" .. string.rep("=", 50))
                print("📁 Detected change in " .. jam_file .. " - reloading...")
                print(string.rep("=", 50))
                
                -- Reset timing to avoid timing issues after reload
                start_time = socket.gettime()
                tick_number = 0
                io.tc = 0
                
                -- Load new jam
                current_jam = loadJam(jam_file)
                jam_initialized = false
                
                -- Initialize if successful
                if current_jam and current_jam.init then
                    current_jam:init(io)
                    jam_initialized = true
                    print("✓ Jam reloaded and initialized")
                else
                    print("✗ Failed to reload jam - continuing with previous version")
                end
                
                last_mod_time = current_mod_time
                print(string.rep("=", 50) .. "\n")
            end
        end

        -- Only run timing loop if we have a valid jam
        if current_jam and current_jam.tick and jam_initialized then
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
                        
                        -- Safe tick execution
                        local success, error_msg = pcall(current_jam.tick, current_jam, io)
                        if not success then
                            print("✗ Error in jam:tick() - " .. tostring(error_msg))
                        end
                        
                        tick_number = tick_number + 1
                        io.tc = io.tc + 1                          -- Global tick counter
                    end
                end
            elseif ticks_behind == 0 and tick_number == expected_tick then
                -- We're on time, run the current tick
                io.beat_count = tick_number // io.tpb
                io.tick_count = tick_number % io.tpb
                
                -- Safe tick execution
                local success, error_msg = pcall(current_jam.tick, current_jam, io)
                if not success then
                    print("✗ Error in jam:tick() - " .. tostring(error_msg))
                end
                
                tick_number = tick_number + 1
                io.tc = io.tc + 1                          -- Global tick counter
            end
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
        else
            -- If no jam is loaded, sleep a bit longer to avoid spinning
            if not (current_jam and jam_initialized) then
                socket.sleep(0.1)
            end
        end
    end
end

run()
