-- lib/progression.lua
-- Optimized progression module with cached chord boundaries
-- Eliminates linear search by pre-calculating chord boundaries and tracking current segment

-- Progression class definition
Progression = {}
Progression.__index = Progression

function Progression.new()
    local self = setmetatable({}, Progression)
    self.chords = {}            -- array of Chord objects
    self.beats = {}             -- duration of each chord in beats
    self.boundaries = {}        -- pre-calculated tick boundaries for each chord
    self.length_beats = 0       -- total length in beats
    self.length_ticks = 0       -- total length in ticks (cached)
    self.playhead = 0           -- current position in ticks
    self.time = 0               -- current time position
    self.index = 1              -- current chord index
    self.current_chord_end = 0  -- tick position where current chord ends
    self.chord_changed = true   -- flag for new chord detection
    return self
end

-- Pre-calculate chord boundaries in ticks for given io
function Progression:_calculate_boundaries(io)
    self.boundaries = {}
    local pos_ticks = 0
    
    for i, beat_duration in ipairs(self.beats) do
        local tick_duration = io.dur(beat_duration)
        table.insert(self.boundaries, {
            start = pos_ticks,
            duration = tick_duration,
            chord_end = pos_ticks + tick_duration
        })
        pos_ticks = pos_ticks + tick_duration
    end
    
    self.length_ticks = pos_ticks
    
    -- Set initial current chord end
    if #self.boundaries > 0 then
        self.current_chord_end = self.boundaries[1].chord_end
    end
end

-- Add chord to progression with specified duration in beats
function Progression:add(chord, beats)
    table.insert(self.chords, chord)
    table.insert(self.beats, beats)
    self.length_beats = self.length_beats + beats
    return self
end

-- Get current chord - now O(1) instead of O(n)
function Progression:current()
    if #self.chords == 0 then return nil end
    return self.chords[self.index]
end

-- Optimized tick: only check boundaries when we might cross them
function Progression:tick(io)
    -- Calculate boundaries on first tick or if not yet calculated
    if #self.boundaries == 0 or self.length_ticks == 0 then
        self:_calculate_boundaries(io)
    end
    
    local prev_index = self.index
    self.playhead = (self.playhead + 1) % self.length_ticks
    self.time = self.time + 1
    
    -- Only check for chord changes when we're at or past the current chord's end
    if self.playhead >= self.current_chord_end or self.playhead == 0 then
        self:_update_current_chord()
    end
    
    -- Set chord_changed flag if index changed
    self.chord_changed = (self.index ~= prev_index)
    
    return self:current()
end

-- Find the correct chord index for current playhead (called only when needed)
function Progression:_update_current_chord()
    -- Handle wrap-around to beginning
    if self.playhead == 0 then
        self.index = 1
        if #self.boundaries > 0 then
            self.current_chord_end = self.boundaries[1].chord_end
        end
        return
    end
    
    -- Find which chord segment we're in
    for i, boundary in ipairs(self.boundaries) do
        if self.playhead >= boundary.start and self.playhead < boundary.chord_end then
            self.index = i
            self.current_chord_end = boundary.chord_end
            return
        end
    end
    
    -- If past end, use last chord
    self.index = #self.chords
    if #self.boundaries > 0 then
        self.current_chord_end = self.length_ticks
    end
end

-- Check if we just moved to a new chord
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
    self.chord_changed = false
    if #self.boundaries > 0 then
        self.current_chord_end = self.boundaries[1].chord_end
    end
end

-- Set playhead to specific position
function Progression:seek(position, io)
    if #self.boundaries == 0 then
        self:_calculate_boundaries(io)
    end
    
    local prev_index = self.index
    self.playhead = math.max(0, math.min(position, self.length_ticks - 1))
    self:_update_current_chord()
    self.chord_changed = (self.index ~= prev_index)
    return self:current()
end

-- Parse progression string and build progression
function Progression:parse(prog_string)
    -- Clear existing progression
    self.chords = {}
    self.beats = {}
    self.boundaries = {}  -- Clear cached boundaries
    self.length_beats = 0
    self.length_ticks = 0
    self:reset()
    
    -- Remove spaces
    prog_string = prog_string:gsub("%s+", "")
    
    local i = 1
    while i <= #prog_string do
        local chord_name = ""
        local dot_count = 0
        
        -- Extract chord name
        while i <= #prog_string and prog_string:sub(i, i) ~= "." do
            chord_name = chord_name .. prog_string:sub(i, i)
            i = i + 1
        end
        
        -- Count dots for duration
        while i <= #prog_string and prog_string:sub(i, i) == "." do
            dot_count = dot_count + 1
            i = i + 1
        end
        
        -- Create and add chord
        if chord_name ~= "" then
            local chord = require("lib/chord").Chord.new():parse(chord_name)
            local beats = 1 + dot_count
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
        "Length: %d beats (%d ticks), Time: %d ticks, Playhead: %d ticks, Index: %d",
        self.length_beats, self.length_ticks, self.time, self.playhead, self.index
    ))
end

return {
    Progression = Progression
}