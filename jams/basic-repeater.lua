local jam = {}

function jam:tick(io)
    if io.tc % (io.tpb // 2) == 0 then
        io.playNote(60, 80, io.tpb // 4)
    end
end

return jam
