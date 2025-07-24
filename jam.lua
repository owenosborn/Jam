local jam = {}

function jam:tick(io)
    if io.every(1) then io.playNote(63, 80, io.ticks(1,4)) end  
    if io.every(3) then io.playNote(69, 80, io.ticks(1,2)) end  
    if io.every(5) then io.playNote(71, 80, io.ticks(1)) end  
    if io.every(7) then io.playNote(58, 80, io.ticks(2)) end  
end

return jam
