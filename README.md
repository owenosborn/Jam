# Jam - Lua Music Coding System 

## Overview
A modular music coding framework in Lua for sketching musical ideas called "jams". Uses a tick-based timing system for precise rhythmic control with configurable resolution.

## Core Concepts

### Jam Structure
Every jam implements two functions:
- `init(io)` - Called once at startup for initialization
- `tick(io)` - Called every tick for musical logic

### Basic Jam Example
```lua
local jam = {}

function jam:init(io)
end

function jam:tick(io)
    if io.on(1) then  -- Every beat
        io.playNote(60, 100, io.dur(1/4))  -- Play C, velocity 100, sixteenth note
    end
end

return jam
```

### Timing Functions
- `io.on(a, b)` - Returns true when current tick matches rhythmic interval, a is beat multiplier, b is offset)
- `io.dur(a)` - Returns tick duration for rhythmic interval, a is beat multiplier

### Nestable Architecture
Jams can load and coordinate other jams using the utils system, enabling complex musical arrangements from simple building blocks.

## Musical Elements

### Core Objects (lib/elements.lua)
- **Note**: Basic musical unit with pitch, velocity, timing, and duration
- **Pattern**: Collection of notes with playback functionality  
- **Counter**: Utility for counting ticks with automatic rollover

### Chord System (lib/chord.lua)
- **Chord**: Pitch collections with root/bass notes and parsing from symbols like "A-7", "Cmaj7"
- **Progression**: Time-based chord sequences with parsing from strings like "D-7...G7...Cmaj7"

### Utility Modules
Focused modules provide extended functionality, For example:
- **ChordPlayer**: Different chord articulation styles (block, roll, strum, random)
- **Arpeggio**: Generate note sequences from chords with various patterns
- **Pattern Utils**: Transpose, reverse, scale operations on note patterns
- **Chord Utils**: Chord construction, analysis, and progressions

## IO Object
The `io` parameter provides:
- **Timing**: `tpb` ticks per beat, `bpm` beats per minute, `tc`, global tick counter
- **Functions**: `on()`, `dur()` for rhythmic calculations
- **Output**: `playNote()` for MIDI note generation
- **MIDI**: Default channel (`ch`) and future CC support

## System Architecture

### Mother Program
Provides runtime environment that:
- Initializes IO object with timing parameters
- Loads current jam from `jam.lua`
- Calls `init(io)` once, then `tick(io)` repeatedly
- Handles precise timing with drift correction
- Supports various output formats (MIDI, OSC)

### File Organization
```
/
├── mother.lua           -- Runtime environment
├── jam.lua              -- Current working jam
├── jams/                -- User jam collection
└── lib/                 -- Core system and utilities
    ├── elements.lua     -- Basic music objects
    ├── chord.lua        -- Chord system
    ├── progression.lua  -- Chord progressions
    └── *_utils.lua      -- Utility modules
```

### Utility Module Convention
All `lib/` modules follow documentation standards:
- Function comments directly above declarations
- Describes purpose and return values
- Enables automatic API documentation generation

## Design Principles
- **Modularity**: Single-purpose files (50-200 lines optimal)
- **Flexibility**: Configurable timing resolution adapts to different musical needs
- **Simplicity**: Minimal syntax, maximum musical expression
- **Composability**: Jams nest and combine naturally
- **Live Coding**: Hot-reloadable for interactive development

## Getting Started
1. Create a jam in `jam.lua` with `init()` and `tick()` functions
2. Use `io.on()` for timing and `io.playNote()` for output
3. Run with mother program to hear results
4. Explore `jams/` folder for examples and `lib/` for utilities
