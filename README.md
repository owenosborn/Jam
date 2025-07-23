# Jam, Lua Music Coding System 

## Overview
A modular music coding framework implemented in Lua that allows users to sketch musical ideas called jams. The system uses a configurable tick-based approach for fine-grained timing control. We provide fundamental musical objects for creating musical structures, with functionality added through utility modules.

## Core Concepts

- Each musical jam implements `init(io)` and `tick(io)` functions
- `init(io)` called once at start to initialize the jam
- `tick(io)` called every tick, which is a small fraction of the beat
- `io` contains MIDI functions for playing notes and CC, global properties, etc
- The `io.tpb` (ticks per beat) property holds the current resolution
- Users calculate timing based on `io.tpb` for flexibility
- Ticks are always assumed to be integers, so make sure of this when calculating tick values: `sixteenth_note = io.tpb // 4`
- Default `io.tpb = 180` provides good balance of precision and performance

```lua
local jam = {}

function jam:init(io)
    self.counter = 0
    self.quarter_note_ticks = io.tpb  -- Pre-calculate common divisions
    self.eighth_note_ticks = io.tpb // 2
end

function jam:tick(io)
    -- Musical logic using io.tpb for timing calculations
    self.counter = (self.counter + 1) % io.tpb
    
    if self.counter == 0 then  -- Every beat
        io.playNote(60, 100, self.quarter_note_ticks)  -- Quarter note duration
    end
    
    if self.counter % (io.tpb / 2) == 0 then  -- Every eighth
        io.playNote(67, 80, self.eighth_note_ticks)   -- Eighth note duration
    end
end

return jam
```

### Nestable Jams
Jams can load and coordinate other jams:

```lua
local jam = {}
local utils = require("lib/utils")

function jam:init(io)
    self.bassline = utils.loadJam("jams/bassline")
    self.drums = utils.loadJam("jams/rockdrums")
    
    -- Could also set up timing relationships based on io.tpb
    self.coordination_counter = 0
end

function jam:tick(io)
    self.bassline:tick(io)
    self.drums:tick(io)
    
    -- Add coordination logic here
end

return jam
```

### Safe Jam Loading
Utility for handling dependencies and reloading:

```lua
-- lib/utils.lua
local utils = {}
local _loading = {}

function utils.loadJam(path)
    if _loading[path] then
        error("Circular dependency detected: " .. path)
    end
    
    _loading[path] = true
    package.loaded[path] = nil
    local jam = require(path)
    _loading[path] = nil
    
    -- Initialize the jam
    if jam.init then
        jam:init(io)  -- Pass io to init
    end

    return jam
end

return utils
```

## Elemental Music Objects

All core musical objects are defined in `lib/elements.lua`:

### Note
Basic unit of musical information:

```lua
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
```

### Chord
Collection of pitches:

```lua
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
```

### Pattern
Collection of notes with timing:

```lua
Pattern = {}
Pattern.__index = Pattern
function Pattern.new()
    local self = setmetatable({}, Pattern)
    self.notes = {}               -- array of Note objects
    self.length = 0               -- total length in ticks
    self.playhead = 0             -- current position in ticks
    return self
end
```

### Progression
Collection of chords with timing:

```lua
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
```

### Counter
Utility for counting ticks with automatic rollover:

```lua
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
```

## IO Object
The `io` object passed to `tick()` provides:

```lua
    local io = {}
    io.tpb = tpb or 180                     -- ticks per beat 
    io.bpm = 101                            -- beats per minute 
    io.mspt = (60 / io.bpm) / io.tpb * 1000 -- milliseconds per tick
    io.tc = 0                               -- tick count (global counter, starts at 0)
    io.beat_count = 0                       -- current beat number
    io.tick_count = 0                       -- tick within beat
    io.ch = 1                               -- default midi ch

    -- Checks if the current global tick count matches a rhythmic interval.
    io.every = function(a, b)
        a = a or 1
        b = b or 1
        return io.tc % ((io.tpb * a) // b) == 0
    end

    -- Calculate tick intervals, number of ticks in a rhythmic interval.
    io.t = function(a, b)
        a = a or 1
        b = b or 1
        return (io.tpb * a) // b
    end

    -- Core output function
    playNote = function(number, velocity, duration, channel) end,
    
    -- Future extensions could include:
    -- playCC = function(controller, value) end,
    -- setBPM = function(bpm) end,
```

## Extended Functionality
Musical utilities are organized in focused modules, for example:

```lua
-- lib/pattern_utils.lua - Pattern manipulation functions

-- Transpose pattern by semitones, returns new Pattern
function pattern_utils.transpose(pattern, semitones) end

-- Reverse note order in pattern, returns new Pattern  
function pattern_utils.reverse(pattern) end

-- Scale all note velocities by factor (0.5 = half, 2.0 = double)
function pattern_utils.scale_velocity(pattern, factor) end
```

```lua  
-- lib/chord_utils.lua - Chord construction and analysis

-- Build chord from root and chord type, returns Chord
function chord_utils.build(root, chord_type) end

-- Get next chord in circle of fifths, returns Chord
function chord_utils.circle_of_fifths(chord) end
```

### Code Convention for Utility Modules
All utility modules in the `lib/` folder must follow this documentation convention:

- **Function Comments**: Every function declaration should have 0 or more comment lines directly above it describing what it does, and the return value if any
- **No Comment Required**: If a function needs no explanation (self-evident), it can have 0 comment lines
- **Generally Documented**: Most functions should have at least 1 comment line for clarity
- **API Generation**: This convention allows automatic generation of API documentation by extracting function declarations and their preceding comments

Example of proper documentation format:

```lua
-- lib/example_utils.lua

-- Create a new pattern with specified length in ticks
-- Returns empty Pattern object ready for note insertion
function example_utils.create_pattern(length_ticks) end

-- Merge two patterns into one, concatenating their notes
-- Second pattern notes are offset by first pattern's length
function example_utils.merge_patterns(pattern1, pattern2) end

-- Simple getter that needs no explanation
function example_utils.get_length(pattern) end
```

This convention enables script-based generation of a comprehensive API reference file from all utility modules.

## Mother Program

Provides runtime environment: sets up io object, loads jam, calls init(io), and tick(io), handles input/output. A Lua example mother.lua is included. 

### Mother Program Timing

The main mother.lua example runtime uses absolute time-based scheduling with drift correction:
- Calculates expected tick number from elapsed wall-clock time
- Automatically catches up if execution falls behind (up to 5 ticks)
- Logs warnings and jumps ahead if severely behind to prevent infinite catch-up
- Uses adaptive sleep timing: longer sleeps when time permits, micro-sleeps when close to deadline
- Maintains precise timing even under system load or temporary stalls

### Mother OSC example

The mother_osc.lua example sends the note messages as OSC messages to specific UDP port.

## File Organization

```
/
├── mother.lua           -- Main runtime 
├── jam.lua              -- Current working jam 
├── jams/                -- Collection of user jams
│   ├── bassline.lua     -- Individual jams 
│   ├── rockdrums.lua
│   └── ...
└── lib/                 -- Core system and utilities
    ├── elements.lua   -- Basic music objects 
    ├── utils.lua        -- System utilities
    ├── pattern_utils.lua -- Pattern operations 
    ├── chord_utils.lua   -- Chord operations 
    ├── rhythm_utils.lua  -- Rhythm operations 
    └── ...
```

## Design Principles
- **File size**: Keep modules 50-200 lines for optimal LLM collaboration
- **Modularity**: Each file has a single, focused purpose
- **Flexibility**: Variable timing resolution adapts to different use cases
- **Simplicity**: Minimal ceremony, maximum musical expression
- **Composability**: Jams nest and combine naturally

