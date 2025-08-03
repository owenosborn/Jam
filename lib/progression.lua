-- lib/progression.lua

-- Progression class definition
Progression = {}
Progression.__index = Progression

function Progression.new()
    local self = setmetatable({}, Progression)
    self.chords = {}            -- array of Chord objects, each chord object gets time attribute added. time is in beats
    self.length_beats = 0       -- total length in beats
    self.length_ticks = 0       -- total length in ticks, calculated
    self.playhead = 0           -- current position in ticks
    self.index = 1              -- current chord index
    self.chord_changed = true   -- flag for new chord detection
    return self
end

-- Add chord to progression with specified duration in beats
function Progression:add(chord, beats)
    chord.time = self.length_beats  -- Set chord's start time
    table.insert(self.chords, chord)
    self.length_beats = self.length_beats + beats
    return self
end

-- Get current chord - now O(1) instead of O(n)
function Progression:current()
end

-- Advance the playhead
function Progression:tick(io)
end

-- Check if we just moved to a new chord
function Progression:isnew()
end

-- Reset playhead to beginning
function Progression:reset()
end

-- Parse progression string and build progression
function Progression:parse(prog_string)
    -- Clear existing progression
    self.chords = {}
    self.length_beats = 0
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
    local headerFormat = "%-7s | %-6s | %-20s | %-6s | %-6s | %-9s"
    local separator = string.rep("-", 70)
    print_callback(separator)
    print_callback(string.format(headerFormat, "Index", "Time", "Notes", "Root", "Bass", "Name"))
    print_callback(separator)
    
    for idx, chord in ipairs(self.chords) do
        local pitches_str = table.concat(chord.pitches or {}, ", ")
        local formatStr = "%-7s | %-6s | %-20s | %-6s | %-6s | %-9s"
        local info = string.format(
            formatStr,
            tostring(idx),
            tostring(chord.time or 0),
            "[" .. pitches_str .. "]",
            tostring(chord.root or 0),
            tostring(chord.bass or 0),
            chord.name or ""
        )
        print_callback(info)
    end
    
    print_callback(separator)
    print_callback(string.format(
        "Length: %d beats (%d ticks), Playhead: %d ticks, Index: %d",
        self.length_beats, self.length_ticks, self.playhead, self.index
    ))
end

return {
    Progression = Progression
}