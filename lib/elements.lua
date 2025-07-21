
-- basic musical unit
Note = {}
Note.__index = Note
function Note.new()
    local self = setmetatable({}, Note)
    self.number = 60        -- MIDI note number
    self.velocity = 100     -- MIDI velocity (0-127)
    self.duration = 90      -- note duration in ticks
    self.time = 0           -- start time offset in ticks
    return self
end

-- collection of pitches 
Chord = {}
Chord.__index = Chord
function Chord.new()
    local self = setmetatable({}, Chord)
    self.pitches = {}      -- array of MIDI note numbers
    self.root = 60         -- root note
    self.bass = 0          -- bass note (0 = use root)
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

return {
    Note = Note,
    Chord = Chord,
    Pattern = Pattern,
    Progression = Progression,
    Counter = Counter
}
