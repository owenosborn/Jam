# Jam API Documentation

## Global IO Object

The `io` object is passed to every jam's `init()` and `tick()` functions, providing timing, MIDI output, and system configuration.

### Properties

- `io.tpb` - Ticks per beat (default: 180, user configurable)
- `io.bpm` - Beats per minute (default: 100)
- `io.tc` - Global tick counter (starts at 0, increments every tick)
- `io.ch` - Default MIDI channel (default: 1)

### Core Functions

#### `io.on(a)`
Returns true when the current global tick count matches a rhythmic interval. 

- `a` - Number of beats (default: 1)

- **Returns**: boolean - true if current tick aligns with the specified rhythm

```lua
-- Examples
io.on(1)      -- Every beat
io.on(1/4)    -- Every quarter of a beat (sixteenth note)
io.on(2)      -- Every 2 beats
```

#### `io.dur(a)`
Calculate tick intervals for rhythmic durations.

- `a` - Number of beats (default: 1)
- **Returns**: number - duration in ticks

```lua
-- Examples
io.dur(1)     -- One beat duration
io.dur(1/4)   -- Quarter of a beat duration (sixteenth note)
io.dur(3)     -- Three beats duration
```

#### `io.playNote(note, velocity, duration, channel)`

Play a MIDI note via OSC output.

- `note` - MIDI note number (0-127)
- `velocity` - Note velocity (0-127)
- `duration` - Note duration in milliseconds
- `channel` - MIDI channel (optional, defaults to io.ch)

#### `io.sendCC(controller, value, channel)`

Send MIDI Control Change message.

- `controller` - CC controller number (0-127)
- `value` - CC value (0-127)
- `channel` - MIDI channel (optional, defaults to io.ch)

---

## Core Library Modules

### Chord (`lib/chord.lua`)

Represents musical chords with pitch collections and symbolic parsing.

#### `Chord.new()`
Create a new empty Chord object.

#### Properties

- `chord.pitches` - Array of pitch intervals from root (can span octaves)
- `chord.root` - Root note pitch class (0-11)
- `chord.bass` - Bass note pitch class for slash chords
- `chord.name` - Chord symbol string

#### Methods

##### `chord:parse(chord_string)`

Parse chord symbol and set chord properties.

- `chord_string` - Chord symbol like "A-7", "Cmaj7", "Bb7b5"
- **Returns**: self (for chaining)

```lua
local chord = Chord.new():parse("D-7")  -- D minor 7
local chord2 = Chord.new():parse("F#maj7")  -- F# major 7
```

##### `chord:note(index, octave)`
Get specific note from chord at given index and octave.
- `index` - Chord tone index (1-based, wraps around)
- `octave` - MIDI octave (default: 5, where C5 = 60)
- **Returns**: MIDI note number

```lua
local root = chord:note(1, 4)    -- Root in octave 4
local third = chord:note(2, 5)   -- Third in octave 5
```

##### `chord:print(print_callback)`
Print chord information.
- `print_callback` - Optional print function (defaults to print)

#### Supported Chord Symbols

**Qualities:**
- Major: `C`, `Cmaj7`
- Minor: `C-`, `C-7`
- Diminished: `Co`, `Co7`
- Augmented: `C+`

**Extensions:**
- `6`, `7`, `maj7`, `9`, `b9`, `11`, `#11`, `13`, `7b5`

**Examples:**
- `C` → C major triad
- `A-7` → A minor 7
- `F#maj7` → F# major 7
- `Bb7b5` → Bb dominant 7 flat 5

---

### Progression (`lib/progression.lua`)

Time-based sequence of chords with automatic playback control.

#### `Progression.new()`
Create a new empty Progression.

#### Properties
- `progression.chords` - Array of Chord objects with timing
- `progression.length_beats` - Total length in beats
- `progression.playhead` - Current position in ticks
- `progression.index` - Current chord index

#### Methods

##### `progression:add(chord, beats)`
Add chord to progression with specified duration.
- `chord` - Chord object
- `beats` - Duration in beats
- **Returns**: self (for chaining)

##### `progression:parse(prog_string)`
Parse progression string and build progression.
- `prog_string` - String like "D-7...G7...Cmaj7...A7..."
- Each dot (.) represents one beat duration
- **Returns**: self (for chaining)

```lua
local prog = Progression.new():parse("D-7...G7...Cmaj7...A7...")
-- D-7 for 4 beats, G7 for 4 beats, etc.
```

##### `progression:tick(io)`
Advance the progression by one tick.
- `io` - IO object for timing reference
- **Returns**: Current chord object

##### `progression:isnew()`
Check if we just moved to a new chord.
- **Returns**: boolean - true if chord changed this tick

##### `progression:current()`
Get current chord without advancing.
- **Returns**: Current chord object

##### `progression:reset()`
Reset playhead to beginning.
- **Returns**: self (for chaining)

##### `progression:print(print_callback)`
Print progression information.

---

### ChordPlayer (`lib/chord_player.lua`)

Utility for playing chords with different articulation styles.

#### `ChordPlayer.new(chord, octave)`
Create a new ChordPlayer.
- `chord` - Chord object (optional, defaults to Cmaj7)
- `octave` - Base octave (default: 5)

#### Properties
- `player.chord` - Current chord object
- `player.octave` - Base octave for playback
- `player.style` - Current playing style

#### Methods

##### `player:setStyle(style, config)`
Set playing style and configuration.
- `style` - Style name: "block", "roll", "strum", "random", "pattern"
- `config` - Style-specific configuration table
- **Returns**: self (for chaining)

**Style Configurations:**
- `"roll"`: `{delay = ticks}` - Sequential with delay between notes
- `"strum"`: `{delay = ticks, reverse = boolean}` - Like roll with optional reverse
- `"random"`: `{window = ticks}` - Random timing within window
- `"pattern"`: `{pattern = {tick_offsets}}` - Custom timing pattern

```lua
player:setStyle("roll", {delay = io.dur(1/8)})
player:setStyle("strum", {delay = 2, reverse = true})
```

##### `player:play(velocity, duration)`
Trigger chord to be played with current style.
- `velocity` - MIDI velocity (default: 80)
- `duration` - Note duration in ticks (default: 180)

##### `player:tick(io)`
Call every tick to handle scheduled note playback.
- `io` - IO object for note output

---

## Example Jam Structure

```lua
local jam = {}

local chord = require("lib/chord")
local progression = require("lib/progression")
local ChordPlayer = require("lib/chord_player")

function jam:init(io)
    -- Initialize chord progression
    self.prog = progression.Progression.new()
    self.prog:parse("D-7...G7...Cmaj7...A7...")
    
    -- Create chord player
    self.player = ChordPlayer.new(nil, 4)
    self.player:setStyle("roll", {delay = io.dur(1/8)})
end

function jam:tick(io)
    -- Update progression
    local current_chord = self.prog:tick(io)
    
    -- Check for chord changes
    if self.prog:isnew() then
        self.player.chord = current_chord
        print("Now playing: " .. current_chord.name)
    end
    
    -- Update player
    self.player:tick(io)
    
    -- Trigger chord on downbeats
    if io.on(1) then
        self.player:play(70, io.dur(3))
    end
end

return jam
```
