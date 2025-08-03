local jam = {}

local progression = require("lib/progression")

function jam:init(io)

    -- Create a ii-V-I-VI progression using parse string
    self.prog = progression.Progression.new()
    self.prog:parse("D-7...G7...Cmaj7...A7...")
    
    -- Print the progression
    self.prog:print()

end

function jam:tick(io)
end

return jam
