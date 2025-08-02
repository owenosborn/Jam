-- lib/progression.lua
-- Enhanced progression module with new chord detection
-- Collection of chords with timing and playback control
-- Supports automatic playhead advancement and chord indexing

-- Progression class definition
Progression = {}
Progression.__index = Progression

function Progression.new()
    local self = setmetatable({}, Progression)
    self.chords = {}            -- array of Chord objects
    self.beats = {}             -- duration of each chord in beats
    self.length_beats = 0       -- total length in beats
    self.playhead = 0           -- current position in ticks
    self.time = 0               -- current time position
    self.index = 1              -- current chord index
    self.last_index = 0         -- previous chord index for new chord detection
    self.chord_changed = true   -- flag for new chord detection (true initially for first chord)
    return self
end

-- Add chord to progression with specified duration in beats
function Progression:add(chord, beats)
    table.insert(self.chords, chord)
    table.insert(self.beats, beats)
    self.length_beats = self.length_beats + beats
    return self
end

-- Get current chord based on playhead position
function Progression:current(io)
    if #self.chords == 0 then return nil end
    
    local pos_ticks = 0
    for i, beat_duration in ipairs(self.beats) do
        local tick_duration = io.dur(beat_duration)
        if self.playhead >= pos_ticks and self.playhead < pos_ticks + tick_duration then
            self.index = i
            return self.chords[i]
        end
        pos_ticks = pos_ticks + tick_duration
    end
    
    -- If playhead is past end, return last chord
    self.index = #self.chords
    return self.chords[#self.chords]
end

-- Advance playhead by one tick and detect chord changes
function Progression:tick(io)
    local total_ticks = io.dur(self.length_beats)
    self.playhead = (self.playhead + 1) % total_ticks
    self.time = self.time + 1
    
    -- Store previous index
    local prev_index = self.index
    
    -- Get current chord (updates self.index)
    local current_chord = self:current(io)
    
    -- Set chord_changed flag if index changed OR if this is the very first tick (time == 1)
    self.chord_changed = (self.index ~= prev_index) or (self.time == 1)
    
    return current_chord
end

-- Check if we just moved to a new chord
-- Returns true on first call after progression is loaded
function Progression:isnew()
    local result = self.chord_changed
    self.chord_changed = false  -- Reset flag after checking
    return result
end

-- Reset playhead to beginning
function Progression:reset()
    self.playhead = 0
    self.time = 0
    self.index = 1
    self.last_index = 0
    self.chord_changed = false
end

-- Set playhead to specific position
function Progression:seek(position, io)
    local total_ticks = io.dur(self.length_beats)
    self.playhead = math.max(0, math.min(position, total_ticks - 1))
    local prev_index = self.index
    local current_chord = self:current(io)
    self.chord_changed = (self.index ~= prev_index)
    return current_chord
end

-- Parse progression string and build progression
-- Format: "D-7...G7...Cmaj7...A7..." where dots add beats
-- Each chord defaults to 1 beat, each dot adds 1 more beat
-- Spaces are ignored
function Progression:parse(prog_string)
    -- Clear existing progression
    self.chords = {}
    self.beats = {}
    self.length_beats = 0
    self:reset()
    
    -- Remove spaces
    prog_string = prog_string:gsub("%s+", "")
    
    -- Split by non-dot, non-chord characters or use pattern matching
    local i = 1
    while i <= #prog_string do
        local chord_start = i
        local chord_name = ""
        local dot_count = 0
        
        -- Extract chord name (everything until we hit dots or end)
        while i <= #prog_string and prog_string:sub(i, i) ~= "." do
            chord_name = chord_name .. prog_string:sub(i, i)
            i = i + 1
        end
        
        -- Count dots for duration
        while i <= #prog_string and prog_string:sub(i, i) == "." do
            dot_count = dot_count + 1
            i = i + 1
        end
        
        -- Create and add chord if we found a name
        if chord_name ~= "" then
            local chord = require("lib/chord").Chord.new():parse(chord_name)
            local beats = 1 + dot_count  -- 1 beat + extra beats for dots
            self:add(chord, beats)
        end
    end
    
    return self
end

-- Print progression information
function Progression:print(print_callback)
    print_callback = print_callback or print
    print_callback("Progression:")
    local headerFormat = "%-7s | %-20s | %-6s | %-6s | %-6s | %-6s | %-9s"
    local separator = string.rep("-", 80)
    print_callback(separator)
    print_callback(string.format(headerFormat, "Index", "Notes", "Root", "Bass", "Time", "Beats", "Name"))
    print_callback(separator)
    
    local time_pos = 0
    for idx, chord in ipairs(self.chords) do
        local beats = self.beats[idx] or 0
        if chord.print_row then
            chord:print_row(print_callback, idx, time_pos, beats)
        else
            -- Fallback if chord doesn't have print_row method
            local pitches_str = table.concat(chord.pitches or {}, ", ")
            local formatStr = "%-7s | %-20s | %-6s | %-6s | %-6s | %-6s | %-9s"
            local info = string.format(
                formatStr,
                tostring(idx),
                "[" .. pitches_str .. "]",
                tostring(chord.root or 0),
                tostring(chord.bass or 0),
                tostring(time_pos),
                tostring(beats),
                chord.name or ""
            )
            print_callback(info)
        end
        time_pos = time_pos + beats
    end
    
    print_callback(separator)
    print_callback(string.format(
        "Length: %d beats, Time: %d ticks, Playhead: %d ticks, Index: %d",
        self.length_beats, self.time, self.playhead, self.index
    ))
end

return {
    Progression = Progression
}
