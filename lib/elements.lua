
-- basic musical unit
Note = {}
Note.__index = Note

function Note.new(params)
    local self = setmetatable({}, Note)
    params = params or {}
    self.number = params.num or 60        -- MIDI note number
    self.velocity = params.vel or 100   -- MIDI velocity
    self.time = params.time or 0             -- time at which the note plays in ticks
    self.duration = params.dur or 180   -- note duration in ticks
    return self
end

-- collection of pitches 
Chord = {}
Chord.__index = Chord
function Chord.new()
    local self = setmetatable({}, Chord)
    self.pitches = {}      -- array of pitches, starting from 0, can be more than one octave for extensions
    self.root = 0         -- root note pitch class, 0-11
    self.bass = 0          -- bass note for slash chords, pitch class 0-11
    self.name = ""         -- chord symbol e.g. "Am7"
    return self
end

-- collection of notes in time
Pattern = {}
Pattern.__index = Pattern
function Pattern.new()
    local self = setmetatable({}, Pattern)
    self.notes = {}               -- array of Note objects
    self.length = 0               -- total length in ticks
    self.playhead = 0             -- current position in ticks
    return self
end

-- collection of chords in time
Progression = {}
Progression.__index = Progression
function Progression.new()
    local self = setmetatable({}, Progression)
    self.chords = {}            -- array of Chord objects
    self.durations = {}         -- duration of each chord in ticks
    self.length = 0             -- total length in ticks  
    self.playhead = 0           -- current position in ticks
    return self
end

Counter = {}
Counter.__index = Counter
function Counter.new(max)
    local self = setmetatable({}, Counter)
    self.max = max or 1
    self.count = 0
    return self
end

function Counter:tick()
    self.count = (self.count + 1) % self.max
    return self.count == 0  -- returns true on rollover
end


----------- a few useful methods


function Note:print()
    local formatStr = "%-11s | %-9s | %-6s | %-9s"
    local info = string.format(
        formatStr,
        tostring(self.number),
        tostring(self.velocity),
        tostring(self.time),
        tostring(self.duration)
    )
    print(info)
end

function Note:print_row(index)
    local formatStr = "%-7s | %-11s | %-9s | %-6s | %-9s"
    local info = string.format(
        formatStr,
        tostring(index),
        tostring(self.number),
        tostring(self.velocity),
        tostring(self.time),
        tostring(self.duration)
    )
    print(info)
end

function Note:play(io, c)
    local ch = c or self.channel or io.ch
    io.playNote(self.number, self.velocity, self.duration, ch)
end

function Chord:print(print_callback)
    print_callback = print_callback or print
    print_callback("Chord:")
    local formatStr = "%-20s | %-6s | %-6s | %-9s"
    local headerFormat = "%-20s | %-6s | %-6s | %-9s"
    local separator = string.rep("-", 50)
    print_callback(separator)
    print_callback(string.format(headerFormat, "Pitches", "Root", "Bass", "Name"))
    print_callback(separator)
    local pitches_str = table.concat(self.pitches, ", ")
    local info = string.format(
        formatStr,
        "[" .. pitches_str .. "]",
        tostring(self.root),
        tostring(self.bass),
        self.name
    )
    print_callback(info)
    print_callback(separator)
end

function Chord:note(index, octave)
    octave = octave or 5  -- default to octave 5 (60 = C5)
    index = ((index - 1) % #self.pitches) + 1
    return self.pitches[index] + self.root + (octave * 12)
end


return {
    Note = Note,
    Chord = Chord,
    Pattern = Pattern,
    Progression = Progression,
    Counter = Counter
}
