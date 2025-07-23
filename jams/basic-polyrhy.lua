local jam = {}

function jam:init(io)
end


function jam:tick(io)

    if io.tc % (io.tpb // 2) == 0 then io.playNote(63, 80, io.tpb // 8) end
    if io.tc % (io.tpb // 3) == 0 then io.playNote(69, 80, io.tpb // 8) end
    if io.tc % (io.tpb // 4) == 0 then io.playNote(71, 80, io.tpb // 8) end
    if io.tc % (io.tpb // 5) == 0 then io.playNote(58, 80, io.tpb // 8) end

end

return jam
