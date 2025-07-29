local jam = {}

function jam:tick(io)
    if io.on(1) then io.playNote(63, 80, io.dur(1,4)) end  
    if io.on(3) then io.playNote(69, 80, io.dur(1,2)) end  
    if io.on(5) then io.playNote(71, 80, io.dur(1)) end  
    if io.on(7) then io.playNote(58, 80, io.dur(2)) end  
end

return jam
